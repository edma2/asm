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

; Scanning method: Use connect(2) to try to establish TCP connections for a set
; of sockets (32), each mapped to a different port. Then use select(2) to
; determine which sockets have non-blocking read and writes.  If the port is
; open, we should be able to read from and write to the socket.  Otherwise it
; is considered filtered or closed. 
tcp_scan:
        ; Use ebx to track the port we're currently on, start at port 0
        xor ebx, ebx
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; Scan the next set of ports
        parallel_scan:
                ; Reset array pointer
                mov edi, fd_array
                ; Initiate connections in parallel for multiple sockets
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                gather_sockets:
                        ; Open socket with arguments
                        ; PF_INET, SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                        call_socket:
                        push dword 6
                        push dword (1 | 4000q)
                        push dword 2
                        call f_socket
                        add esp, 12

                        ; Check returned fildes
                        test eax, eax
                        js open_failed
                        jmp store_fd
                        
                        ; Close all the sockets we opened up so far, print
                        ; error message and quit
                        open_failed:
                        ; Save -errno
                        push eax
                        ; Extract the last 5 bits of ebx to obtain the offset
                        ; into fd_array, since we scan 32 ports at a time
                        ; before reseting the pointer.
                        and ebx, 0x1f
                        push ebx
                        push fd_array
                        call f_close_fd_array
                        add esp, 8
                        ; Print socket error message and exit
                        push msg_sock_err
                        call f_print_str
                        add esp, 4
                        ; Set -errno as exit status
                        pop ebx
                        jmp exit

                        ; If the file descriptor was good, store it in the array.
                        store_fd:
                        stosd
                        ; Also store it in fd_set structs which are monitored
                        ; later by select(2)
                        push eax
                        push fdset_write
                        call f_fdset_add
                        mov [esp], dword fdset_read
                        call f_fdset_add
                        add esp, 4
                        ; Restore fd in eax
                        pop eax

                        call_connect:
                        ; Load port
                        mov [sockaddr+2], byte bh
                        mov [sockaddr+3], byte bl
                        ; Initiate TCP handshake
                        push sockaddr_len
                        push sockaddr        
                        push eax
                        call f_connect
                        add esp, 12
                        ; Increase the port counter (e.g. 0->1)
                        inc word bx

                        check_return_value:
                        ; Is it EAGAIN or EINPROGRESS, as expected?
                        cmp eax, ERRNO_EAGAIN
                        je connect_ok
                        cmp eax, ERRNO_EINPROGRESS
                        je connect_ok
                        ; Impossible for a non-blocking socket?
                        cmp eax, 0
                        je connect_ok

                        ; Bail out if errno was not one of the above
                        wrong_errno:
                        ; Save -errno
                        push eax
                        and ebx, 0x1f
                        push ebx
                        push fd_array
                        call f_close_fd_array
                        add esp, 8
                        push msg_connect_err
                        call f_print_str
                        add esp, 4
                        ; Set -errno as error status
                        pop ebx
                        jmp exit

                        connect_ok:
                        ; Check if we should call select(2) or gather more sockets
                        test bx, word 0x1f
                        jz wait_for_slow_connects
                        jmp gather_sockets
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                ; Sleep for one second in case some connections are slow
                ; zzz... zzz...
                wait_for_slow_connects:
                push one_sec_timeout
                push dword 0
                push dword 0
                push dword 0
                push dword 0
                call f_select
                add esp, 20
        
                ; Wake up and smell the ashes...
                ; It's time to check up on our sockets
                call_select:
                push zero_timeout
                push dword 0
                push dword fdset_write
                push dword fdset_read
                push dword [fd_array+32]
                call f_select
                add esp, 20

                ; If select returned 0, then no sockets were able to connect
                ; Otherwise, select will return the total number of fildes that
                ; are ready. In case of error, it returns -errno.
                cmp eax, 0
                js select_failed
                je close_sockets
                jmp check_for_connected_sockets

                ; Something went wrong with our select(2) call
                select_failed:
                ; Store -errno in ebx
                mov ebx, eax
                ; Close all the sockets we opened up
                push 32
                push fd_array
                call f_close_fd_array
                add esp, 8
                ; Print error message and exit
                push msg_select_err
                call f_print_str
                add esp, 4
                jmp exit

                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                check_for_connected_sockets:
                ; Check each file descriptor in the array for its status in
                ; fdset_read and fdset_write, printing out the ports that are
                ; non-blocking  We'll load fds one at a time from the array to
                ; eax using lodsd, so point esi to fd_array.
                mov esi, fd_array
                process_next_fd:
                        ; Load next fd in eax
                        lodsd

                        ; Will a read block?
                        push eax
                        push fdset_read
                        call f_fdset_check
                        add esp, 4

                        ; Restore eax in case we still need it. No flags are
                        ; set by the pop instruction. This is neccesary in the
                        ; case we have to jump; the stack will be properly
                        ; aligned. Otherwise, we will have the original fd
                        ; preserved and loaded in eax.
                        cmp eax, 0
                        pop eax
                        je process_next_fd

                        ; Will a write block?
                        push eax
                        push fdset_write
                        call f_fdset_check
                        add esp, 8
                        cmp eax, 0
                        je process_next_fd
                        
                        ; If we reached this point, then the socket connected
                        ; successfully to the remote host. Notify the user as
                        ; open ports are found by printing the open port to
                        ; standard output.

                        ; Calculate port number associated with the fd
                        ; esi is a pointer to offset within fd_array
                        ; ebx is the highest port number so far
                        ; Thus, port is ebx - 32 + offset
                        lea edx, [ebx + esi - 32]
                        sub edx, fd_array

                        ; Convert the port to a string and store the result in
                        ; port_buf, then print the string to standard output.
                        push dword port_buf
                        push edx
                        call f_ultostr
                        ; port_buf now on stack
                        add esp, 4
                        call f_print_str

                        ; Replace port_buf with buffer containing newline and
                        ; print it 
                        mov [esp], dword newline
                        call f_print_str
                        add esp, 4

                        ; Calculate offset and figure out if we finished loop
                        mov edx, esi
                        sub edx, fd_array
                        cmp edx, 32
                        jne process_next_fd
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                close_sockets:
                ; Close all the sockets we opened 
                push dword 32
                push fd_array
                call f_close_fd_array
                add esp, 8
                ; Quit when we've scanned ports 0-65535 
                cmp bx, word 0
                jne parallel_scan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
