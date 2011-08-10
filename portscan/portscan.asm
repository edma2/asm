; vim: ft=nasm
; Usage: portscan [OPTIONS] HOST
; Author: Eugene Ma

section .data
        socket_error_msg:       db 'error: sys_socket failed', 10, 0
        select_error_msg:       db 'error: sys_select failed', 10, 0
        parse_error_msg:        db 'error: Malformed IP address', 10, 0
        connect_error_msg:      db 'error: Unexpected connect error', 10, 0
        newline_msg:            db 10, 0

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        timeval_1s:             dd 0, 400000
        timeval_0s:             dd 0, 0

        errno_eagain            equ -115
        errno_einprogress       equ -11
        max_parallel_sockets             equ 64

        ;icmp_header:            db: 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss
        ; struct sockaddr_in {
        ;       short int          sin_family;  // Address family, AF_INET
        ;       unsigned short int sin_port;    // Port number
        ;       struct in_addr     sin_addr;    // Internet address
        ;       unsigned char      sin_zero[8]; // Same size as struct sockaddr
        ; };
        sockaddr:       resb 16
        sockaddrlen     equ (2+2+4+8)

        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        writefds:       resb 128
        
        ; Where socket fds live
        sockets:        resd max_parallel_sockets 
        ; Map each socket to a port (e.g. port of socket i = portsmap[sockets[i]])        
        portsmap:       resw max_parallel_sockets
        ; Put octets here after parsing
        octets:         resd 1 
        ; For port to string conversion 
        portstr:        resb 12 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        mov ebp, esp

parse_string_to_octets:
        ; Parse the ip string into octets 
        push octets             
        push dword [ebp+8]   
        call parse_octets
        add esp, 8
        
        ; Check the return value
        test eax, eax
        js malformed_ip
        jmp load_struct_sockaddr

        ; Print error message and exit
        malformed_ip:
        push parse_error_msg
        call printstr
        add esp, 4
        ; Set error status to -1
        xor ebx, ebx
        not ebx
        jmp exit

ping_host:
        ; We do this to minimize the timeout required to wait for TCP
        ; connections. Called with arguments:
        ; PF_INET, SOCK_RAW, IPPROTO_ICMP
        push dword 6 
        push dword 3
        push dword 1 
        call sys_socket
        add esp, 12

load_struct_sockaddr:
        mov edi, sockaddr
        cld            
        ; sin_family = AF_INET
        mov ax, word 2 
        stosw           
        ; Fill in the port later (sin_port)
        add edi, 2
        ; sin_addr 
        mov eax, [octets]
        stosd
        ; Fill padding
        xor eax, eax
        rep stosd
        rep stosd

; Scan ports 0-1023, last port always stored in ebx
; cdecl: ebx/esi/edi should always be perserved by the callee
xor ebx, ebx 
tcp_scan: 
        ; Reset index into sockets, portsmap
        xor esi, esi 
        ; Store nfds (= 1 + maximum fd) for sys_select
        xor edi, edi 
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
                push sockets
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
                mov [sockets + 4 * esi], eax 
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
                mov [sockaddr+2], byte bh 
                mov [sockaddr+3], byte bl 
                push sockaddrlen
                push sockaddr        
                push eax 
                call sys_connect
                add esp, 12

                check_errno:
                ; We expect to see EAGAIN or EINPROGRESS
                cmp eax, errno_eagain
                je connect_in_progress
                cmp eax, errno_einprogress
                je connect_in_progress
                cmp eax, 0
                ; This would be very unexpected!
                je connect_complete

                wrong_errno:
                ; Connect failed for reasons other than being "in progress"
                ; Save -errno on stack
                push eax 
                push esi
                push sockets
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
                cmp esi, max_parallel_sockets
                jl gather_sockets

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        wait_for_connections:
        ; Wait for requested connects to finish
        push timeval_1s
        push dword 0
        push dword 0
        push dword 0
        push dword 0
        call sys_select
        add esp, 20
        ; Linux select(3) will mangle timeval structs
        mov [timeval_1s+4], dword 400000

        call_select: 
        ; Wake up and smell the ashes...
        ; Time to check up on our sockets
        push timeval_0s
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
        push max_parallel_sockets
        push sockets
        call kill_sockets
        add esp, 8
        push select_error_msg
        call printstr
        add esp, 4
        pop ebx
        not ebx
        inc ebx
        jmp exit

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        check_for_connected_sockets:
        ; Check writefds for our sockets
        ; Reset index into socket array
        xor esi, esi
        iterate_through_fds:
                check_if_write_blocks:
                ; Fetch file descriptor
                mov eax, [sockets + 4 * esi]
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
                cmp esi, max_parallel_sockets
                jl iterate_through_fds

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        free_sockets:
        ; Kill all the sockets we opened 
        push dword max_parallel_sockets
        push sockets
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; printstr - print a string to standard output
;       expects: string address
;       returns: bytes written in eax, -errno on error
printstr:
        push ebp
        mov ebp, esp
        
        push dword [ebp+8]
        call strlen
        add esp, 4
        
        push eax
        push dword [ebp+8]
        push dword 1
        call sys_write
        add esp, 12

        mov esp, ebp
        pop ebp
        ret

; strlen - calculate the length of null-terminated string
;       expects: string address
;       returns: length in eax
strlen:
        push ebp     
        mov ebp, esp
        push edi

        cld     
        xor eax, eax
        xor ecx, ecx
        not ecx
        mov edi, [ebp+8]
        repne scasb
        
        not ecx
        lea eax, [ecx-1]
        
        pop edi
        mov esp, ebp
        pop ebp
        ret

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

        mov esi, [ebp+8]
        mov ebx, [ebp+12]
        lea edi, [ebp-4]
        ; This value comes in handy when its on the stack
        push edi
        cld
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
                ; Now load the octet into the destination buffer in big endian
                ; order/network byte order
                mov [ebx], eax
                count_octets:
                push ebx
                sub ebx, [ebp+12]
                cmp ebx, 3
                pop ebx
                je last_octet
                cmp [esi-1], byte '.' 
                jne invalid_ip
                ; We still have more work to do!
                prepare_next_octet:
                ; First, make sure we increment the destination address.
                inc ebx
                ; Finally, reset buffer pointer to start of buffer so we can
                ; write another octet 
                lea edi, [ebp-4]
                jmp parse_loop
                last_octet:
                ; All four octets are supposedly loaded in the destination
                ; buffer. This means esi is must be pointing to a null byte.
                cmp [esi-1], byte 0
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

; strtoul - convert a number from text to binary form
;       expects: string address
;       returns: 32-bit unsigned integer in eax
strtoul:
        push ebp
        mov ebp, esp

        ; Load string address in edx
        mov edx, [ebp+8]
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

; ultostr - convert an unsigned integer to a C string
;       expects: 32-bit unsigned integer, buffer 
;       returns: nothing
ultostr:
        push ebp  
        mov ebp, esp
        push esi
        push edi
        
        mov eax, [ebp+8]
        mov edi, [ebp+12]
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
        mov [edi+1], byte 0

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

; fdset - add a file descriptor to struct fd_set
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

        mov edx, [ebp+8]
        mov eax, [ebp+12]
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

; fdisset - check if a file descriptor is present in fd_set
;       expects: pointer to struct fd_set, fd
;       returns: 1 in eax, 0 otherwise
fdisset:
        push ebp
        mov ebp, esp

        mov edx, [ebp+8]
        mov eax, [ebp+12]
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

; kill_sockets - close first n fd in the socket array 
;       expects: array, n
;       returns: nothing
kill_sockets:
        push ebp
        mov ebp, esp

        mov esi, [ebp+8]
        mov ecx, [ebp+12]

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

; sys_read - read from file
;       expects: fd, buffer, buffer len
;       returns: number of bytes read, or -errno
sys_read:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 3
        mov ebx, [ebp+8]
        mov ecx, [ebp+12]
        mov edx, [ebp+14]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret

; sys_write - write to file
;       expects: fd, buffer, buffer len
;       returns: number of bytes written, or -errno
sys_write:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 4
        mov ebx, [ebp+8]
        mov ecx, [ebp+12]
        mov edx, [ebp+16]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret

; sys_close - close a file descriptor
;       expects: file descriptor
;       returns: 0 in eax | -errno in eax if error
sys_close:
        push ebp
        mov ebp, esp
        push ebx
        
        mov eax, 6
        mov ebx, [ebp+8]
        int 0x80
        
        pop ebx
        mov esp, ebp
        pop ebp
        ret

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
        lea ecx, [ebp+8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret

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
        lea ecx, [ebp+8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret

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
        mov ebx, [ebp+8]
        mov ecx, [ebp+12]
        mov edx, [ebp+16]
        mov esi, [ebp+20]
        mov edi, [ebp+24]
        int 0x80

        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
