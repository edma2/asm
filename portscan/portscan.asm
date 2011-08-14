; vim: ft=nasm
; Usage: portscan <host>
; Author: Eugene Ma

; ==============================================================================

section .data
        sockaddr:
                .sin_family:    dw 2            ; AF_INET
                .sin_port:      dw 0            ; Dynamically set before creating each socket
                .sin_addr:      dd 0            ; Load octets here after parsing
                .sin_zero:      db 0,0,0,0,0,0,0,0
        sockaddrlen             equ $-sockaddr
        sockaddrlen_addr:       dd sockaddrlen  ; recvfrom(2) expects this as an address ?!

        socket_error_msg:       db 'error: sys_socket failed', 10, 0
        select_error_msg:       db 'error: sys_select failed', 10, 0
        parse_error_msg:        db 'error: Malformed IP address', 10, 0
        connect_error_msg:      db 'error: Unexpected connect error', 10, 0
        sendto_error_msg:       db 'error: sys_sendto failed', 10, 0
        recvfrom_error_msg:     db 'error: sys_recvfrom failed', 10, 0
        newline_msg:            db 10, 0

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        zerotimeout:            dd 0, 0         ; No wait
        max_sockets             equ 64

        val_one:                dd 1

; ==============================================================================

section .bss
        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        writefds:               resd 32                 ; Used as select(2) argument
        readfds:                resd 32                 ; Used as select(2) argument
        sockfds:                resd max_sockets        ; Where we save all open sockets 
        portsmap:               resw max_sockets        ; Each socket is mapped to a port
        hostaddr:               resd 1                  ; Address of host in binary format octets
        myaddr:                 resd 1                  ; Address of localhost in binary format octets
        portstr:                resb 12 
        timeout_volatile:       resd 2                  ; Linux will mangle this after select(2) returns
        timeout_master:         resd 2                  ; A "master" copy

        iphdr:                  resb 20                 ; Pointer to start of packet
        iphdrlen                equ 84                  ; Total size of packet
        icmphdr:                resb 64                 ; For sending "ping" packet           
        icmphdrlen              equ 64                  ; 8 byte header + 56 byte data

; ==============================================================================

section .text
        global  _start

_start:
        mov ebp, esp
        cld                             ; String operations will increment pointers by default

; Parse command line arguments into valid octets
; Usage: portscan <host ip>
parse_argv:
        push dword hostaddr             ; Load destination address
        push dword [ebp + 8]            ; Load first argument argv[1]
        call parse_octets               ; Parse destination address
        add esp, 8                      ; Clean up stack
        test eax, eax                   ; Check return value
        js malformed_ip                 ; User invoked program incorrectly

        ; IPv4 address was valid; inject in sockaddr->sin_addr 
        load_sockaddr: 
        mov esi, hostaddr           
        mov edi, sockaddr.sin_addr
        movsd
        jmp ping_host                   ; Send a "ping" to the target host

; The IPv4 address didn't look right
malformed_ip:
        push parse_error_msg            ; Load error message
        call printstr                   ; Print the error message string             
        add esp, 4                      ; Clean up stack
        xor ebx, ebx                    ; Zero out ebx...
        not ebx                         ; and turn on all the bits (ebx = -1)
        jmp exit                        ; Exit with error status 

ping_host:
        push dword sockaddrlen
        push dword sockaddr
        call fn_ping
        add esp, 8
        ; Adjust for connect time
        shl eax, 2
        mov [timeout_master + 4], eax

; ------------------------------------------------------------------------------

; Scan ports 0-1023, last port always stored in ebx
; cdecl: ebx/esi/edi should always be perserved by the callee
xor ebx, ebx 
tcp_scan: 
        ; Reset index into sockets, portsmap
        xor esi, esi 
        ; Store nfds (= 1 + maximum fd) for sys_select
        xor edi, edi 
        ; Reset writefds
        push writefds
        call fdzero
        add esp, 4
        gather_sockets:
                ; "Gather" sockets one by one using socket(3) and connect(3)
                spawn_socket:
                ; Call sys_socket with arguments
                ; PF_INET, SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                push dword 6 
                push dword (1 | 4000q) 
                push dword 2 
                call sys_socket
                add esp, 12

                ; Check return value
                test eax, eax
                ; sys_socket failed with -errno
                js socket_create_error 
                jmp save_socket

                socket_create_error:
                ; We had trouble creating the socket
                ; Save -errno on stack
                push eax 
                ; We should close(3) all our open sockets
                ; esi should contain count of open sockets
                push esi
                push sockfds
                call kill_sockets
                add esp, 8
                ; Print socket error message and exit(3)
                push socket_error_msg
                call printstr
                add esp, 4
                ; Save errno in ebx
                pop ebx 
                not ebx
                inc ebx
                jmp exit

                save_socket:
                ; Socket seems good, save it to our array and map the port 
                mov [sockfds + 4 * esi], eax 
                mov [portsmap + 2 * esi], word bx 
                inc esi
                ; Update nfds: max(nfds, fd)
                cmp eax, edi
                cmovg edi, eax
                ; Add socket to writefds
                push eax
                push writefds
                call fdset
                add esp, 4
                pop eax 

                attempt_connect:
                ; Initiate TCP handshake to port
                ; Load port to sockaddr struct in htons() order
                mov [sockaddr.sin_port], byte bh 
                mov [sockaddr.sin_port + 1], byte bl 
                push sockaddrlen
                push sockaddr        
                push eax 
                call sys_connect
                add esp, 12

                check_errno:
                ; We expect to see EAGAIN or EINPROGRESS
                cmp eax, -115
                je connect_in_progress
                cmp eax, -11
                je connect_in_progress
                cmp eax, 0
                ; This would be very unexpected!
                je connect_complete

                wrong_errno:
                ; Connect failed for reasons other than being "in progress"
                ; Save -errno on stack
                push eax 
                push esi
                push sockfds
                call kill_sockets
                add esp, 8
                push connect_error_msg
                call printstr
                add esp, 4
                pop ebx
                not ebx
                inc ebx
                jmp exit

                connect_complete:
                connect_in_progress:
                ; "Gather" next socket-port combination or proceed to next step
                inc word bx
                cmp esi, max_sockets
                jl gather_sockets

; ------------------------------------------------------------------------------

        wait_for_connections:
        ; Reset latency timer
        lea esi, [timeout_master + 4]
        lea edi, [timeout_volatile + 4]
        movsd
        ; Wait for requested connects to finish
        push timeout_volatile
        push dword 0
        push dword 0
        push dword 0
        push dword 0
        call sys_select
        add esp, 20

        call_select: 
        ; Wake up and smell the ashes...
        ; Time to check up on our sockets
        push zerotimeout
        push dword 0
        push dword writefds
        push dword 0
        ; nfds = maximum fd + 1
        inc edi 
        push edi
        call sys_select
        add esp, 20

        cmp eax, 0
        ; All sockets will block on write, skip to next iteration
        je free_sockets
        jns check_for_connected_sockets 

        select_error:
        ; We had some sort of trouble with select(2)
        ; Save -errno on stack and kill all sockets
        push eax
        push max_sockets
        push sockfds
        call kill_sockets
        add esp, 8
        push select_error_msg
        call printstr
        add esp, 4
        pop ebx
        not ebx
        inc ebx
        jmp exit

; ------------------------------------------------------------------------------

        check_for_connected_sockets:
        ; Check writefds for our sockets
        ; Reset index into socket array
        xor esi, esi
        iterate_through_fds:
                check_if_write_blocks:
                ; Fetch file descriptor
                mov eax, [sockfds + 4 * esi]
                push eax
                push writefds
                call fdisset
                add esp, 4
                cmp eax, 0
                pop eax
                ; This port didn't respond to our TCP request:
                ; this means it was probably filtered
                je port_was_filtered 

                send_empty_packet:
                ; Seems like the socket can be written to
                ; Let's try to send an empty dud packet to the host
                push dword 0
                push dword 0
                push eax
                call sys_write
                add esp, 12 
                test eax, eax
                ; We had trouble sending: 
                ; the port was probably closed
                js port_was_closed
                
                print_port:
                ; We found an open port!
                ; Convert the port number to a printable string
                movzx edx, word [portsmap + 2 * esi]
                push portstr
                push edx
                call ultostr 
                add esp, 8
                push dword portstr 
                call printstr 
                ; Print new line after port
                mov [esp], dword newline_msg
                call printstr
                add esp, 4
                jmp check_next_socket

                port_was_filtered:
                port_was_closed:
                check_next_socket:
                inc esi
                cmp esi, max_sockets
                jl iterate_through_fds

; ------------------------------------------------------------------------------

        free_sockets:
        ; Kill all the sockets we opened 
        push dword max_sockets
        push sockfds
        call kill_sockets
        add esp, 8
        ; Check if we're done
        cmp bx, word 1024 
        jl tcp_scan

exit:
        ; We expect ebx to contain exit status 
        mov ebp, esp
        mov eax, 1
        int 0x80

; ------------------------------------------------------------------------------
; cksum - IP header style checksum for given length in words (16-bit) 
;  Expects: pointer to data, data length in words 
;  Returns: checksum 
cksum:
        push ebp                ; Save frame pointer
        mov ebp, esp            ; Set new frame pointer
        push esi                ; Preserve esi

        mov esi, [ebp + 8]      ; Load data pointer        
        mov ecx, [ebp + 12]     ; Load data length

        cmp ecx, 0              ; Check word counter
        je .done                ; Exit immediately if 0 was passed as argument

        xor dx, dx              ; Accumulate result in dx
        .loop:
                lodsw           ; Load next word into ax
                add dx, ax      ; Perform 16-bit (word size) addition 
                dec ecx
                jnz .loop       ; Repeat next word
        
        .done:
        not dx                  ; Take one's complement of result
        movzx eax, dx           ; Save result in return register

        pop esi                 ; Restore esi
        mov esp, ebp            ; Deallocate local storage
        pop ebp                 ; Restore old frame pointer
        ret                     ; Return
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; printstr - print a string to standard output
;  Expects: string address
;  Returns: bytes written, -errno on error
printstr:
        push ebp                ; Save frame pointer
        mov ebp, esp            ; Set new frame pointer
        
        push dword [ebp + 8]      ; Load string on stack
        call strlen             ; Get string length (null terminated)
        add esp, 4              ; Clean up stack
        
        push eax                ; Push length on stack
        push dword [ebp + 8]      ; Push string on stack
        push dword 1            ; Push standard output file descriptor
        call sys_write          ; Write string to standard output
        add esp, 12             ; Clean up stack

        mov esp, ebp            ; Deallocate local storage
        pop ebp                 ; Restore old frame pointer
        ret                     ; Return
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; strlen - calculate the length of null-terminated string
;       expects: string address
;       returns: length in eax
strlen:
        push ebp     
        mov ebp, esp
        push edi

        xor eax, eax
        xor ecx, ecx
        not ecx
        mov edi, [ebp + 8]
        repne scasb
        
        not ecx
        lea eax, [ecx - 1]
        
        pop edi
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; parse_octets - convert IPv4 address from text to binary form
;       expects: ip string, destination buffer
;       returns: 0 in eax, ~0 on error
parse_octets:
        push ebp
        mov ebp, esp
        sub esp, 4
        push ebx
        push esi
        push edi

        mov esi, [ebp + 8]
        mov ebx, [ebp + 12]
        lea edi, [ebp - 4]
        ; This value comes in handy when its on the stack
        push edi
        parse_loop:
                ; Load the string into the four byte buffer we allocated
                load_string:
                        ; This loads the next byte from [esi] into al
                        lodsb
                        ; Check for termination characters
                        cmp al, byte 0
                        je convert_octet
                        cmp al, byte '.'
                        je convert_octet
                        ; Make sure its a valid octet digit (0-9)
                        cmp al, byte '0'
                        jl invalid_ip
                        cmp al, byte '9'
                        jg invalid_ip
                        ; Otherwise this is a valid digit, store it in buffer
                        stosb
                        ; Make sure we stored less than 4 bytes in the buffer
                        cmp edi, ebp
                        jg invalid_ip
                        jmp load_string
                ; If we reached here, we're ready to convert the octet into its
                ; binary representation
                convert_octet:
                ; First make sure we stored at least one digit
                cmp edi, [esp]
                je invalid_ip
                ; Okay, now we've confirmed our octet consists of 1 to 3
                ; digits, terminate the string by writing the null byte.
                mov [edi], byte 0
                ; The argument we need is already on the stack, it points to
                ; the first byte of the octet string
                call strtoul
                ; An octet has to be an 8-bit value
                cmp eax, 255
                jg invalid_ip
                ; Now load the next octet into the destination octet buffer 
                mov [ebx], byte al
                count_octets:
                push ebx
                sub ebx, [ebp + 12]
                cmp ebx, 3
                pop ebx
                je last_octet
                cmp [esi - 1], byte '.' 
                jne invalid_ip
                ; We still have more work to do!
                prepare_next_octet:
                ; First, make sure we increment the destination address.
                inc ebx
                ; Finally, reset buffer pointer to start of buffer so we can
                ; write another octet 
                lea edi, [ebp - 4]
                jmp parse_loop
                last_octet:
                ; All four octets are supposedly loaded in the destination
                ; buffer. This means esi is must be pointing to a null byte.
                cmp [esi - 1], byte 0
                jne invalid_ip        
                jmp parse_success
        invalid_ip:
        xor eax, eax
        not eax
        jmp exit_ip_to_octets
        parse_success:
        xor eax, eax
        exit_ip_to_octets:
        add esp, 4

        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; strtoul - convert a number from text to binary form
;       expects: string address
;       returns: 32-bit unsigned integer in eax
strtoul:
        push ebp
        mov ebp, esp

        ; Load string address in edx
        mov edx, [ebp + 8]
        ; Clear "result" register
        xor eax, eax
        loop_digits:
                ; Load ecx with character
                movzx ecx, byte [edx]
                inc edx
                ; Terminate if NUL byte
                cmp cl, byte 0
                je exit_strtoul
                ; Multiply current result by 10,
                ; then add current character - '0'
                lea eax, [eax + eax * 4]
                lea eax, [ecx + eax * 2 - '0']
                jmp loop_digits
        exit_strtoul:
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; ultostr - convert an unsigned integer to a C string
;       expects: 32-bit unsigned integer, buffer 
;       returns: nothing
ultostr:
        push ebp  
        mov ebp, esp
        push esi
        push edi
        
        mov eax, [ebp + 8]
        mov edi, [ebp + 12]
        ; Save original buffer for reference 
        mov esi, edi
        mov ecx, 10

        ; Fairly self-explanatory, right?
        calculate_number_of_digits:
        cmp eax, 9
        jle terminate_string
        inc edi
        cmp eax, 99
        jle terminate_string
        inc edi
        cmp eax, 999
        jle terminate_string
        inc edi
        cmp eax, 9999
        jle terminate_string
        inc edi
        cmp eax, 99999
        jle terminate_string
        inc edi
        cmp eax, 999999
        jle terminate_string
        inc edi
        cmp eax, 9999999
        jle terminate_string
        inc edi
        cmp eax, 99999999
        jle terminate_string
        inc edi
        cmp eax, 999999999
        jle terminate_string
        inc edi

        terminate_string:
        mov [edi + 1], byte 0

        ; Start writing bytes to the buffer from least to most significant
        ; digit (right to left)
        divide_loop:
        ; Else divide edx:eax by 10
        ; eax: quotient contains the rest of input number
        ; edx: remainder contains the digit we want to write
        xor edx, edx
        div ecx
        add dl, byte '0'
        mov [edi], byte dl
        dec edi
        ; Stop if we reached the start of the buffer
        cmp edi, esi
        jge divide_loop

        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; fdset - add or remove file descriptor to struct fd_set
;       expects: pointer to struct fd_set, fd
;       returns: nothing
;
; description:
; Here we roll our own struct fd_set that the kernel uses as an interface for
; select(2). struct fd_set is implemented as a bit array, composed of 32-bit
; ints, and every possible file descriptor is mapped to a bit position.
; e.g. (31|30|29|...|1|0) (63|62|61|...|33|32) ...
fdset:
        push ebp
        mov ebp, esp

        mov edx, [ebp + 8]
        mov eax, [ebp + 12]
        ; Save an additional copy of fd
        mov ecx, eax

        ; Divide fd by the number of bits in a 32-bit long, this gives us our
        ; index into the fds_bits array. 
        shr eax, 5
        ; Note: index is a dword aligned offset 
        lea edx, [edx + eax * 4]
        ; Figure out the appropriate bit to set in the dword-sized array
        ; element by looking at the last 5 bits of file descriptor
        and ecx, 0x1f
        ; fd_bits[fd/32] |= (1<<rem)
        xor eax, eax
        inc eax
        shl eax, cl
        or [edx], eax  

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; fdisset - check if a file descriptor is present in fd_set
;       expects: pointer to struct fd_set, fd
;       returns: 1 in eax, 0 otherwise
fdisset:
        push ebp
        mov ebp, esp

        mov edx, [ebp + 8]
        mov eax, [ebp + 12]
        mov ecx, eax

        shr eax, 5
        lea edx, [edx + eax * 4]
        and ecx, 0x1f
        ; fd_bits[fd/32] & (1<<rem)
        xor eax, eax
        inc eax
        shl eax, cl
        and eax, [edx]
        shr eax, cl ; so we return 1 on success

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; fdzero - zero out an fd_set
;       expects: pointer to struct fd_set
;       returns: nothing
fdzero:
        push ebp
        mov ebp, esp

        xor eax, eax
        mov ecx, 32
        mov edi, [ebp + 8]
        rep stosd

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; kill_sockets - close first n fd in the socket array 
;       expects: array, n
;       returns: nothing
kill_sockets:
        push ebp
        mov ebp, esp

        mov esi, [ebp + 8]
        mov ecx, [ebp + 12]

        close_loop:
        lodsd 
        ; next fd in eax
        push eax
        call sys_close
        add esp, 4
        dec ecx
        jnz close_loop

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_read - read from file
;       expects: fd, buffer, buffer len
;       returns: number of bytes read, or -errno
sys_read:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 3
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 14]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_write - write to file
;       expects: fd, buffer, buffer len
;       returns: number of bytes written, or -errno
sys_write:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 4
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 16]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_close - close a file descriptor
;       expects: file descriptor
;       returns: 0 in eax | -errno in eax if error
sys_close:
        push ebp
        mov ebp, esp
        push ebx
        
        mov eax, 6
        mov ebx, [ebp + 8]
        int 0x80
        
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_connect - connect a socket       
;       expects: int socket, address, address length
;       returns: 0 in eax or -errno on error
sys_connect:
        push ebp
        mov ebp, esp
        push ebx
        push edi

        mov eax, 102
        mov ebx, 3
        ; sys_socketcall is a wrapper around all the socket system calls, and
        ; takes as an argument a pointer to the arguments specific to the
        ; socket call we want to use, so load ecx with the address of the first
        ; argument on the stack
        lea ecx, [ebp + 8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_socket - create a socket       
;       expects: int domain, int type, int protocol
;       returns: 0 in eax or -errno on error
sys_socket:
        push ebp
        mov ebp, esp
        push ebx
        push edi

        mov eax, 102
        mov ebx, 1
        lea ecx, [ebp + 8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_select - wrapper around sys_select
;       expects: int nfds, fd_set *readfds, fd_set *writefds,
;                fd_set *exceptfds, struct timeval *timeout
;       returns: total number of fildes set in fd_set structs, -errno if error
sys_select:
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        mov eax, 142
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 16]
        mov esi, [ebp + 20]
        mov edi, [ebp + 24]
        int 0x80

        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_sendto 
;       Send a packet to target host
;               Expects: socket, buffer, length, flags, sockaddr, sockaddrlen
;               Returns: number of characters sent, -errno on error
sys_sendto:
        push ebp
        mov ebp, esp
        push ebx

        ; sys_socketcall = 102
        mov eax, 102
        mov ebx, 11
        lea ecx, [ebp + 8] 
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_recvfrom 
;       Receieve a packet from target host
;               Expects: socket, buffer, length, flags, sockaddr, sockaddrlen
;               Returns: number of characters received, -errno on error
sys_recvfrom:
        push ebp
        mov ebp, esp
        push ebx

        ; sys_socketcall = 102
        mov eax, 102
        mov ebx, 12
        lea ecx, [ebp + 8] 
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------
; ------------------------------------------------------------------------------
; sys_setsockopt
;       Set socket options
;               Expects: socket, level, option_name, option_value, option_len
sys_setsockopt:
        push ebp
        mov ebp, esp
        push ebx
        
        mov eax, 102
        mov ebx, 14
        lea ecx, [ebp + 8]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; fn_ping
;       Send an ICMP Echo request to target host 
;               Expects: pointer to sockaddr, sockaddr length
;               Returns: latency in microseconds to use
fn_ping:
        push ebp
        mov ebp, esp
        ; Allocate buffer for ICMP header and data, socket, timer, fdset
        sub esp, (64 + 4 + 8 + 4 * 32)                     
        push ebx
        push edi
        
        ; Initialize "local" fdset on stack
        push ebp
        sub [esp], dword 204
        call fdzero
        add esp, 4

        ; Build an ICMP packet with message type 8 (Echo request). The kernel will craft
        ; the IP header for us because IP_HDRINCL is disabled by default
        assemble_packet:
        lea edi, [ebp - 64]             ; Point esi to start of packet
        mov al, 8                       ; Type: 8 (Echo request)
        stosb                           
        xor al, al                      ; Code: 0 (Cleared for this type)
        stosb                          
        xor eax, eax                    ; Calculate ICMP checksum later
        stosw                         
        stosd                           ; Identifier: 0, Sequence number: 0
        
        ; Now we have to zero out 56 bytes of ICMP padding data
        xor eax, eax                    
        mov ecx, 14                     ; 56 bytes = 14 words
        rep stosd                       ; Load 56 zero bytes

        ; Calculate ICMP checksum which includes ICMP header and data
        push dword (64/2)               ; Length of packet in words
        push dword ebp                  ; Load pointer to packet on stack
        sub [esp], dword 64
        call cksum                     
        add esp, 8                      ; Clean up stack
        mov [ebp - 62], word ax         ; Inject checksum result into packet

        ; To create a raw socket, user need root permissions
        create_icmp_socket:
        push dword 1                    ; Protocol: IPPROTO_ICMP
        push dword (3 | 4000q)          ; Type: SOCK_RAW | O_NONBLOCK
        push dword 2                    ; Domain: PF_INET
        call sys_socket                 ; Create raw socket
        add esp, 12                     ; Clean up stack
        
        ; Check return value
        test eax, eax                   
        js ping_socket_error

        ; Store raw socket file descriptor
        mov [ebp - 68], eax             
        ; Initialize ping counter to 10. Try to ping this many times until we
        ; get a response from the host (or give up)!
        mov ebx, 10                             
        jmp send_ping

        ; On failure, exit with -1 in eax
        ping_socket_error:
        mov eax, 500000
        jmp ping_exit                   

        ; Now we should be ready to send bytes to the other host 
        send_ping:
                ; Socket is in non-blocking mode, so we send and receieve data
                ; asynchronously. In this case, send an ICMP Echo request, and block
                ; until socket has data ready to be read.
                push dword [ebp + 12]   ; Socket address length
                push dword [ebp + 8]    ; Socket address
                push dword 0            ; No flags
                push dword 64           ; Packet length
                push dword ebp          ; Packet start
                sub [esp], dword 64     ; Packet start
                push dword [ebp - 68]   ; Socket file descriptor
                call sys_sendto         ; Send data asynchronously
                add esp, 24             ; Clean up stack
                
                test eax, eax
                jns recv_response       ; This shouldn't happen
                cmp eax, -115           ; errno was EAGAIN as expected
                je recv_response
                cmp eax, -11            ; Or EINPROGRESS as expected
                jne send_failed
        
                recv_response:
                push dword [ebp + 12]   ; Address of socket address length
                push dword [ebp + 8]    ; Socket address
                push dword 0            ; No flags
                push dword 0            ; Length of buffer 
                push dword 0            ; Buffer (=NULL)
                push dword [ebp - 68]   ; Socket
                call sys_recvfrom       ; Receieve data asynchronously
                add esp, 24             ; Clean up stack

                test eax, eax
                jns get_latency
                cmp eax, -115
                je get_latency
                cmp eax, -11
                je get_latency

                recv_failed:
                send_failed:
                mov eax, 500000
                jmp ping_clean_up        

        get_latency:
        ; Timeout is an upper bound on how long to wait before select(2)
        ; returns. Linux will adjust the timeval struct to reflect the time
        ; remaining, this solution is is not portable, as the man page for
        ; select(2) tells us to consider the value of the struct undefined
        ; after select returns. 

        ; Add socket to "local" fdset
        push dword [ebp - 68]           
        push ebp
        sub [esp], dword 204
        call fdset
        add esp, 8                      ; Clean up stack
        
        ; Reset timer
        mov [ebp - 72], dword 500000    ; Initialize timer to 0.5 seconds

        push ebp                        ; Push timer on stack
        sub [esp], dword 76
        push dword 0                    ; Don't wait for exceptfds
        push dword 0                    ; Don't wait for writefds
        push ebp
        sub [esp], dword 204
        push dword [ebp - 68]           ; nfds = highest fd + 1
        inc dword [esp]
        call sys_select                 
        add esp, 20                     ; Clean up stack

        ; Check return value 
        cmp eax, 0                      
        je try_again                    ; Sockets did not respond to ICMP Echo request
        test eax, eax
        js ping_select_error            ; select(2) returned -errno in eax

        jmp calculate_latency
        
        ; Should we try again?
        try_again:
        dec ebx                         ; Decrement ping "tries" counter
        jz ping_select_error            ; We used up all 10 tries
        jmp send_ping

        ping_select_error:
        mov eax, 500000
        jmp ping_clean_up

        calculate_latency:
        ; Now calculate the latency
        mov eax, 500000
        sub eax, [ebp - 72]

        ping_clean_up:
        push eax                        ; Save return value
        push dword [ebp - 68]           ; Close "ping" socket                           
        call sys_close
        add esp, 4
        pop eax                         ; Restore return value

        ; eax should contain exit code
        ping_exit:
        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
        
; ------------------------------------------------------------------------------
; EOF ==========================================================================
