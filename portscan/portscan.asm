; vim: ft=nasm
; Usage: portscan [OPTIONS] HOST
; Author: Eugene Ma
; TODO: 
;       - maintain a list of open/closed/filtered ports?
;       - process ports from an array instead of counter
;       - store sockets in a "master fds" bitfield instead of array?

section .data
        msg_sock_err:           db 'error: sys_socket failed', 10, 0
        msg_select_err:         db 'error: sys_select failed', 10, 0
        msg_parse_err:          db 'error: Malformed IP address', 10, 0
        msg_connect_err:        db 'error: Unexpected sys_connect errno', 10, 0

        ; "Port %s is open!" 
        msg_port_open_start:    db 'Port ', 0
        msg_port_open_end:      db ' is open!', 10, 0

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        timeval_1s:             dd 1, 0
        timeval_0s:             dd 0, 0

        ERRNO_EAGAIN            equ -115
        ERRNO_EINPROGRESS       equ -11
        MAX_SOCKETS             equ 64 ; optimal?
        
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

        ; Defined in /include/linux/posix_types.h
        ;
        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        writefds:       resb 128
        
        sockets:        resd MAX_SOCKETS ; socket_0 ... socket_max
        ; Map each socket to a port
        ; e.g. port of socket i = portsmap[sockets[i]]        
        portsmap:       resw MAX_SOCKETS
        octets:         resd 1  ; temporary storage for octets
        portstr:        resb 12 ; for port to string conversion 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        mov ebp, esp

parse_octets:
        ; Parse the ip string into octets 
        push octets             
        push dword [ebp+8]   
        call parseip
        add esp, 8
        
        ; Check the return value
        test eax, eax
        js malformed_ip
        jmp load_struct_sockaddr

        ; Print error message and exit
        malformed_ip:
        push msg_parse_err
        call printstr
        add esp, 4
        ; Set error status to -1
        xor ebx, ebx
        not ebx
        jmp exit

load_struct_sockaddr:
        mov edi, sockaddr
        cld            
        ; sin_family = AF_INET
        mov ax, word 2   
        stosw           
        ; sin_port = 0
        xor ax, ax
        stosw
        ; sin_addr
        mov eax, [octets]
        stosd
        ; padding
        xor eax, eax
        mov ecx, 2
        rep stosd

tcp_scan:
        ; cdecl: ebx/esi/edi should always be perserved by the callee
        ; Scan ports 0-1023, last port always stored in ebx
        xor ebx, ebx 
        max_parallel_sockets_loop: 
                ; Scan another round of ports
                ; Reset index into sockets, portsmap
                xor esi, esi 
                ; Store nfds (= 1 + maximum fd) for sys_select
                xor edi, edi 
                gather_sockets_loop:
                        spawn_socket:
                        ; "Gather" sockets one by one using socket(3) and connect(3)
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
                        call killsockets
                        add esp, 8
                        ; Print socket error message and exit(3)
                        push msg_sock_err
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
                        writefds_set:
                        push eax
                        push writefds
                        call fdset
                        add esp, 4
                        pop eax 

                        connect_socket:
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
                        cmp eax, ERRNO_EAGAIN
                        je connect_ok
                        cmp eax, ERRNO_EINPROGRESS
                        je connect_ok
                        cmp eax, 0
                        ; This would be very unexpected!
                        je connect_ok

                        wrong_errno:
                        ; Connect failed for reasons other than being "in progress"
                        ; Save -errno on stack
                        push eax 
                        push esi
                        push sockets
                        call killsockets
                        add esp, 8
                        push msg_connect_err
                        call printstr
                        add esp, 4
                        pop ebx
                        not ebx
                        inc ebx
                        jmp exit

                        connect_ok:
                        ; "Gather" next socket-port combination or proceed to next step
                        inc word bx
                        cmp esi, MAX_SOCKETS
                        jl gather_sockets_loop
        
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                wait_for_connects:
                ; We should timeout one second to wait for connections
                push timeval_1s
                push dword 0
                push dword 0
                push dword 0
                push dword 0
                call sys_select
                add esp, 20
                ; Linux select(3) will mangle timeval structs
                mov [timeval_1s], dword 1
        
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
                ; sys_select returned -errno
                js select_failed 
                ; No sockets were ready for writing
                je free_sockets 
                ; Otherwise, eax stores number of file descriptors ready for writing
                jmp check_for_connected_sockets 

                select_failed:
                ; Save -errno on stack and kill all sockets
                push eax
                push MAX_SOCKETS
                push sockets
                call killsockets
                add esp, 8
                push msg_select_err
                call printstr
                add esp, 4
                pop ebx
                not ebx
                inc ebx
                jmp exit

                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                check_for_connected_sockets:
                ; Check for the presence of each socket in writefds
                ; Reset index into sockets
                xor esi, esi
                fd_loop:
                        check_fds:
                        ; Fetch file descriptor
                        mov eax, [sockets + 4 * esi]
                        push eax
                        push writefds
                        call fdisset
                        add esp, 4
                        cmp eax, 0
                        pop eax
                        ; The port didn't send a response
                        ; This means it was probably filtered
                        je port_filtered 

                        write_zero_byte:
                        ; Seems like the socket can be written to
                        ; Let's try to send an empty dud packet to the host
                        push dword 0
                        push dword 0
                        push eax
                        call sys_write
                        add esp, 12 
                        test eax, eax
                        ; There was an error in writing
                        ; The port was probably closed
                        js port_closed
                        
                        print_port:
                        ; We found an open port!
                        ; Convert the port number to a printable string
                        movzx edx, word [portsmap + 2 * esi]
                        push portstr
                        push edx
                        call ultostr 
                        add esp, 8
                        ; "Port %s is open!"
                        push msg_port_open_start 
                        call printstr
                        mov [esp], dword portstr 
                        call printstr 
                        mov [esp], dword msg_port_open_end 
                        call printstr
                        add esp, 4

                        ; TODO: add failed ports to arrays/sets?
                        port_filtered:
                        port_closed:
                        check_next_socket:
                        inc esi
                        cmp esi, MAX_SOCKETS
                        jl fd_loop

                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                free_sockets:
                ; Kill all the sockets we opened 
                push dword MAX_SOCKETS
                push sockets
                call killsockets
                add esp, 8
                ; Check to see if we're done
                cmp bx, word 1024 
                jl max_parallel_sockets_loop

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

; parseip - convert IPv4 address from text to binary form
;       expects: ip string, destination buffer
;       returns: 0 in eax, ~0 on error
parseip:
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

; killsockets - close first n fd in the socket array 
;       expects: array, n
;       returns: nothing
killsockets:
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
