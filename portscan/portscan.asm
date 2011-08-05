; vim: ft=nasm
; Usage: portscan [OPTIONS] HOST
; Author: Eugene Ma
; TODO: 

section .data
        msg_start:              db 'Scanning ports...', 10, 0
        msg_sock_err:           db 'Error: failed to create socket', 10, 0
        msg_select_err:         db 'Error: select(3) failed', 10, 0
        msg_parse_err:          db 'Error: malformed IP address', 10, 0
        msg_connect_err:        db 'Error: failed to connect socket', 10, 0
        msg_connect_success:    db 'Connect succeeded!', 10, 0
        msg_write_success:      db 'Port open!!', 10, 0
        msg_write_fail:         db 'Write failed...', 10, 0
        msg_port_open_start:    db 'port ', 0
        msg_port_open_end:      db ' is open!', 10, 0

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        one_sec_timeout: dd 1, 0
        zero_timeout:    dd 0, 0

        ERRNO_EAGAIN          equ -115
        ERRNO_EINPROGRESS     equ -11

        MAX_SOCKETS           equ 64 ; optimal?
        
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
        sockaddr_len     equ (2+2+4+8)

        ; Defined in /include/linux/posix_types.h
        ;
        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        fds_write:     resb 128
        fds_read:      resb 128
        socket_array:  resd MAX_SOCKETS ; socket 0 - socket MAX_SOCKET
        ; Map each socket to a port
        ; e.g. port of socket i = port_map[socket_array[i]]        
        port_map:      resw MAX_SOCKETS

        octet_buf:       resd 1
        ; For storing the port string
        port_buf:        resb 12

        read_buf:       resb 256
        read_buf_len    equ $-read_buf
        write_buf:       resb 256
        write_buf_len    equ $-read_buf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        mov ebp, esp

parse_octets:
        ; Parse the ip string into octets 
        push octet_buf             
        push dword [ebp+8]   
        call f_parse_ip
        add esp, 8
        
        ; Check the returned octets
        test eax, eax
        ; If signed, it means the IPv4 address was malformed
        js malformed_ip
        jmp load_sockaddr

        ; Print error message and exit
        malformed_ip:
        push msg_parse_err
        call f_print_str
        add esp, 4
        ; Set error status to -1
        xor ebx, ebx
        not ebx
        jmp exit

load_sockaddr:
        ; Load the struct sockaddr 
        push dword [octet_buf]
        ; The port changes dynamically
        ; Zero it out for now
        push dword 0
        push sockaddr
        call f_load_sockaddr    
        add esp, 12

tcp_scan:
        ; TODO: use array of ports instead of simple counter
        xor ebx, ebx ; current port

        ; scan another round of sockets
        max_parallel_sockets_loop: 
                ; reset...
                xor ecx, ecx ; index into socket_array, port_map
                xor edx, edx ; nfds = 1 + maximum fd

                ; "gather" sockets one by one with socket(2) and connect(2)
                gather_sockets_loop:
                        spawn_socket:
                        push ecx ; save
                        push edx ; save
                        push dword 6 ; PF_INET
                        push dword (1 | 4000q) ; SOCK_STREAM | O_NONBLOCK
                        push dword 2 ; IPPROTO_TCP
                        call f_socket
                        add esp, 12
                        pop edx
                        pop ecx

                        ; check return value
                        test eax, eax
                        js open_failed ; socket(2) failed with -errno
                        jmp save_socket
                        
                        open_failed:
                        push eax ; push -errno
                        ; We should close(2) all our open sockets
                        push ecx
                        push socket_array
                        call f_close_socket_array
                        add esp, 8
                        ; Print socket error message and exit(2)
                        push msg_sock_err
                        call f_print_str
                        add esp, 4
                        pop ebx ; pop -errno
                        jmp exit

                        save_socket:
                        mov [socket_array+4*ecx], eax ; save fd in array
                        mov [port_map+2*ecx], word bx ; map socket to port
                        inc ecx ; increase index
                        cmp eax, edx ; update nfds
                        cmovg edx, eax

                        ; Add socket to both fdsets
                        add_to_fds:
                        push ecx ; save 
                        push edx ; save
                        push eax
                        push fds_write
                        call f_fds_set
                        mov [esp], dword fds_read ; swap struct pointers
                        call f_fds_set
                        add esp, 4
                        pop eax ; restore fd
                        pop edx
                        pop ecx

                        connect_socket:
                        ; load port in sockaddr struct
                        mov [sockaddr+2], byte bh ; htons() 
                        mov [sockaddr+3], byte bl ; ""
                        ; Initiate TCP handshake
                        push ecx ; save
                        push edx ; save
                        push sockaddr_len
                        push sockaddr        
                        push eax ; socket fd
                        call f_connect
                        add esp, 12
                        pop edx
                        pop ecx
                
                        ; is it EAGAIN or EINPROGRESS, as expected?
                        cmp eax, ERRNO_EAGAIN
                        je connect_ok
                        cmp eax, ERRNO_EINPROGRESS
                        je connect_ok
                        ; impossible for a non-blocking socket?
                        cmp eax, 0
                        je connect_ok

                        wrong_errno:
                        push eax ; save -errno
                        push ecx
                        push socket_array
                        call f_close_socket_array
                        add esp, 8
                        push msg_connect_err
                        call f_print_str
                        add esp, 4
                        pop ebx ; pop -errno
                        jmp exit

                        ; Did we "gather" enough sockets?
                        connect_ok:
                        inc word bx
                        cmp ecx, MAX_SOCKETS ; i.e. for (i = 0; i < max; i++)
                        jl gather_sockets_loop

                ;------------------------------------

                ; zzz... zzz...
                wait_for_slow_connects:
                push ecx ; save
                push edx ; save
                push one_sec_timeout
                push dword 0
                push dword 0
                push dword 0
                push dword 0
                call f_select
                add esp, 20
                pop edx
                pop ecx

                ; on Linux, select(2) mangles one_sec_timeout
                mov [one_sec_timeout], dword 1
        
                ; Wake up and smell the ashes...
                ; it's time to check up on our sockets
                call_select: 
                inc edx ; nfds = maximum fd + 1
                push zero_timeout
                push dword 0
                push dword fds_write
                push dword fds_read
                push edx
                call f_select
                add esp, 20

                cmp eax, 0
                js select_failed ; select(2) returned -errno
                je free_sockets ; no sockets were ready
                jmp check_for_connected_sockets ; eax is number of fd ready

                select_failed:
                mov ebx, eax ; store -errno
                push MAX_SOCKETS ; kill all our sockets
                push socket_array
                call f_close_socket_array
                add esp, 8
                push msg_select_err
                call f_print_str
                add esp, 4
                jmp exit

                ;------------------------------------

                ; check for the presence of each fd in fds structs
                check_for_connected_sockets:
                xor ecx, ecx ; reset index into socket_array
                fd_loop:
                        mov eax, [socket_array + 4*ecx]

                        ; Check if socket is ready to be written
                        push ecx ; save index
                        push eax
                        push fds_write
                        call f_fdset_check
                        add esp, 4
                        cmp eax, 0
                        pop eax
                        pop ecx
                        je check_next_socket ; port was FILTERED

                        ; Try to send a zero byte
                        write_ready:
                        push ecx ; save
                        push dword 0
                        push write_buf
                        push eax
                        call f_write_fd
                        add esp, 12
                        pop ecx

                        ; Write failed! Port was CLOSED 
                        test eax, eax
                        js check_next_socket
                        
                        ; if we reach here, we found an open port!
                        print_port:
                        push ecx ; save index

                        movzx edx, word [port_map + 2*ecx]
                        push port_buf
                        push edx
                        call f_ultostr ; convert port to string
                        add esp, 8
                        
                        push msg_port_open_start ; "Port " ...
                        call f_print_str
                        mov [esp], dword port_buf 
                        call f_print_str ; %s = port
                        mov [esp], dword msg_port_open_end 
                        call f_print_str ; ..." is open!\n"
                        add esp, 4

                        pop ecx ; restore index

                        check_next_socket:
                        inc ecx
                        cmp ecx, MAX_SOCKETS
                        jl fd_loop

                ;------------------------------------

                ; close all the sockets we opened 
                free_sockets:
                push dword MAX_SOCKETS
                push socket_array
                call f_close_socket_array
                add esp, 8
                cmp bx, word 0 ; 0xffff -> 0x0000
                jne max_parallel_sockets_loop

exit:
        mov ebp, esp
        mov eax, 1
        ; We expect ebx to contain exit status 
        int 0x80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; f_parse_ip - convert IPv4 address from text to binary form
;       expects: ip string, destination buffer
;       returns: 0 in eax, ~0 on error
f_parse_ip:
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
                call f_strtoul
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

; f_strtoul - convert a number from text to binary form
;       expects: string address
;       returns: 32-bit unsigned integer in eax
f_strtoul:
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

; f_ultostr - convert an unsigned integer to a C string
;       expects: 32-bit unsigned integer, buffer 
;       returns: nothing
f_ultostr:
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

; f_write_stdout - write buffer to standard output
;       expects: buffer, length
;       returns: bytes written in eax, -errno on error
f_write_stdout:
        push ebp
        mov ebp, esp
        push ebx
        
        mov eax, 4
        mov ebx, 1
        mov ecx, [ebp+8]   
        mov edx, [ebp+12]   
        int 0x80
        
        pop ebx
        mov esp, ebp
        pop ebp
        ret

; f_print_str - print a string to standard output
;       expects: string address
;       returns: bytes written in eax, -errno on error
f_print_str:
        push ebp
        mov ebp, esp
        
        push dword [ebp+8]
        call f_strlen
        add esp, 4
        
        push eax
        push dword [ebp+8]
        call f_write_stdout
        add esp, 8

        mov esp, ebp
        pop ebp
        ret

; f_strlen - calculate the length of null-terminated string
;       expects: string address
;       returns: length in eax
f_strlen:
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

; f_close - close a file descriptor
;       expects: file descriptor
;       returns: 0 in eax | -errno in eax if error
f_close:
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

; f_connect - connect a socket       
;       expects: int socket, address, address length
;       returns: 0 in eax or -errno on error
f_connect:
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

; f_socket - create a socket       
;       expects: int domain, int type, int protocol
;       returns: 0 in eax or -errno on error
f_socket:
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

; f_select - wrapper around sys_select
;       expects: int nfds, fd_set *readfds, fd_set *writefds,
;                fd_set *exceptfds, struct timeval *timeout
;       returns: total number of fildes set in fd_set structs, -errno if error
f_select:
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

; f_fds_set - add a file descriptor to struct fd_set
;       expects: pointer to struct fd_set, fd
;       returns: nothing
;
; description:
; Here we roll our own struct fd_set that the kernel uses as an interface for
; select(2). struct fd_set is implemented as a bit array, composed of 32-bit
; ints, and every possible file descriptor is mapped to a bit position.
; e.g. (31|30|29|...|1|0) (63|62|61|...|33|32) ...
f_fds_set:
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

; f_fdset_check - check if a file descriptor is present in fd_set
;       expects: pointer to struct fd_set, fd
;       returns: !0 if true, 0 otherwise
f_fdset_check:
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

        mov esp, ebp
        pop ebp
        ret

; f_close_socket_array - close first n fildes in the array 
;       expects: array, n
;       returns: nothing
f_close_socket_array:
        push ebp
        mov ebp, esp

        mov esi, [ebp+8]
        mov ecx, [ebp+12]

        close_loop:
        lodsd 
        ; next fd in eax
        push eax
        call f_close
        add esp, 4
        dec ecx
        jnz close_loop

        mov esp, ebp
        pop ebp
        ret

; f_load_sockaddr - load the struct sockaddr 
;       expects: pointer to struct sockaddr, port, octets
;       returns: nothing
;       note: port and octets must be in network byte order.
f_load_sockaddr:
        push ebp
        mov ebp, esp
        push edi
        
        mov edi, [ebp+8]
        cld            
        ; sin_family = AF_INET
        mov ax, word 2   
        stosw           
        ; sin_port
        mov ax, word [ebp+12]
        stosw
        ; sin_addr
        mov eax, [ebp+16]
        stosd
        ; padding
        xor eax, eax
        mov ecx, 2
        rep stosd

        pop edi
        mov esp, ebp
        pop ebp
        ret

; f_block_fd - block a previously unblocked file descriptor
;       expects: fd
;       returns: >= 0 if successful, -errno otherwise
f_block_fd:
        push ebp
        mov ebp, esp
        push ebx
                
        mov eax, 55 ; fcntl
        mov ebx, [ebp+8]
        mov ecx, 4 ; F_SETFL
        mov edx, 4000q
        not edx ; ~O_NONBLOCK
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret

; f_read_fd - read from file
;       expects: fd, buffer, buffer len
;       returns: number of bytes read, or -errno
f_read_fd:
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

; f_write_fd - write to file
;       expects: fd, buffer, buffer len
;       returns: number of bytes written, or -errno
f_write_fd:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 4
        mov ebx, [ebp+8]
        mov ecx, [ebp+12]
        mov edx, [ebp+14]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
