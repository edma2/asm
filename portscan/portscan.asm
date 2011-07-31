; vim: ft=nasm
; Usage: portscan [OPTIONS] HOST
; Author: Eugene Ma
; TODO: 
;       - Implement parallel port scanning with select
;       - Multiple hosts?
;       - for reference? http://linux.die.net/man/1/strobe

section .data
        msg_start:              db 'Scanning ports...', 10, 0
        msg_sock_err:           db 'Error: failed to create socket', 10, 0
        msg_select_err:         db 'Error: select(3) failed', 10, 0
        msg_parse_err:          db 'Error: malformed IP address', 10, 0
        msg_connect_err:        db 'Error: failed to connect socket', 10, 0
        msg_connect_success:    db 'Connect succeeded!', 10, 0
                
        newline:                db 10, 0

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        one_sec_timeout: dd 1, 0
        zero_timeout:    dd 0, 0

        ERRNO_EAGAIN          equ -115
        ERRNO_EINPROGRESS     equ -11

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
        fdset_write:     resd 32
        fdset_read:      resd 32
        fd_array:        resd 32

        octet_buf:       resd 1
        ; For storing the port string
        port_buf:        resb 12

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
        add esp, 8
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

;-----------------------------------------[
tcp_scan:
        initialize_scan:
        ; Initialize port counter (e.g. for (i = 0...))
        xor ebx, ebx
        ; JUMP here for after every 32 ports scanned
        ;-----------------------------------------[
        main_loop:
                ; Reset array pointer
                mov edi, fd_array
                ; JUMP here to prepare a port for select
                ;-----------------------------------------[
                connect_loop:
                        connect_fds:
                        ; Open socket with arguments
                        ; PF_INET, SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                        call_socket:
                        push dword 6
                        push dword (1 | 4000q)
                        push dword 2
                        call f_socket
                        add esp, 12

                        ; Check returned fd
                        test eax, eax
                        js open_failed
                        jmp store_fd
                        
                        open_failed:
                        ; Close all the sockets we opened up so far
                        and bx, word 0x1f
                        push ebx
                        push fd_array
                        call f_close_fd_array
                        add esp, 8
                        ; Print socket error message and exit
                        push msg_sock_err
                        call f_print_str
                        add esp, 4
                        jmp exit

                        store_fd:
                        ; If the file descriptor was good, store it in the array
                        ; DF should already be set, so edi is incremented 
                        stosd
                        ; Then add it to fdsets so we can check it later with select
                        push eax
                        push fdset_write
                        call f_fdset_add
                        mov [esp], dword fdset_read
                        call f_fdset_add
                        add esp, 4
                        pop eax

                        call_connect:
                        ; Load port
                        xchg bl, bh
                        mov [sockaddr+2], word bx
                        xchg bl, bh
                        ; Initiate TCP handshake
                        push sockaddr_len
                        push sockaddr        
                        push eax
                        call f_connect
                        add esp, 12

                        check_return_value:
                        ; Impossible for a non-blocking socket?
                        cmp eax, 0
                        je connect_ok
                        ; Is it EAGAIN or EINPROGRESS, as expected?
                        cmp eax, ERRNO_EAGAIN
                        je connect_ok
                        cmp eax, ERRNO_EINPROGRESS
                        je connect_ok

                        ; If not, something went wrong
                        wrong_errno:
                        and bx, word 0x1f
                        push ebx
                        push fd_array
                        call f_close_fd_array
                        add esp, 8
                        push msg_connect_err
                        call f_print_str
                        add esp, 4
                        jmp exit

                        connect_ok:
                        inc word bx
                        ; Check if port is a multiple of 32, which is true if
                        ; the lowest 5 bits are cleared
                        test bx, word 0x1f
                        jz wait_for_sockets
                        jmp connect_loop
                ;-----------------------------------------[

                ; Sleep for a few seconds before selecting 
                wait_for_sockets:
                push one_sec_timeout
                push dword 0
                push dword 0
                push dword 0
                push dword 0
                call f_select
                add esp, 20
        
                monitor_fds:
                push zero_timeout
                push dword 0
                push dword fdset_write
                push dword fdset_read
                push dword [fd_array+32]
                call f_select
                add esp, 20
                cmp eax, 0
                js select_failed
                ; Scan the next 32 ports
                je main_loop
                jmp check_fdset

                select_failed:
                ; Close all the sockets we opened up so far
                push 32
                push fd_array
                call f_close_fd_array
                add esp, 8
                ; Print socket error message and exit
                push msg_select_err
                call f_print_str
                add esp, 4
                jmp exit

                check_fdset:
                ; Check each file descriptor in the array for its status in
                ; fdset, print out the ports that are set 
                mov esi, fd_array
                mov ecx, 32
                fdset_loop:
                        lodsd
                        ; fd in eax
                        push eax
                        push fdset_read
                        call f_fdset_check
                        add esp, 4
                        ; If eax is 0, then fildes not set
                        cmp eax, 0
                        pop eax
                        jz fdset_loop
                        ; Otherwise print the port number followed by a newline
                        push dword port_buf
                        push eax
                        call f_ultostr
                        add esp, 4
                        call f_print_str
                        mov [esp], dword newline
                        call f_print_str
                        add esp, 4
                        dec ecx
                        jnz fdset_loop
                cmp bx, word 0
                jne main_loop
        ;-----------------------------------------[
exit:
        mov ebp, esp
        mov eax, 1
        ; ebx contains exit status 
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

        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret

; f_fdset_add - add a file descriptor to struct fd_set
;       expects: pointer to struct fd_set, fd
;       returns: nothing
;
; description:
; Here we roll our own struct fd_set that the kernel uses as an interface for
; select(2). struct fd_set is implemented as a bit array, composed of 32-bit
; ints, and every possible file descriptor is mapped to a bit position.
; e.g. (31|30|29|...|1|0) (63|62|61|...|33|32) ...
f_fdset_add:
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

; f_close_fd_array - close first n fildes in the array 
;       expects: array, n
;       returns: nothing
f_close_fd_array:
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
