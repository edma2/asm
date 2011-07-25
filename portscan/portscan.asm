; vim: ft=nasm
; Usage: asmscan [OPTIONS] HOST
; Author: Eugene Ma
; TODO: 
;       - Implement parallel port scanning with select
;       - Multiple hosts?
;       - for reference? http://linux.die.net/man/1/strobe

section .data
        msgStart:               db 'Scanning ports...', 10, 0
        msgStartLen             equ $-msgStart

        msgSocketError:         db 'Error: failed to create socket', 10, 0
        msgSocketErrorLen       equ $-msgSocketError
        msgParseError:          db 'Error: malformed IP address', 10, 0
        msgParseErrorLen        equ $-msgParseError
        msgConnectError:        db 'Error: failed to connect socket', 10, 0
        msgConnectErrorLen      equ $-msgConnectError
        msgConnectSuccess:      db 'Connected!', 10, 0
        msgConnectSuccessLen    equ $-msgConnectSuccess

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
        sockAddr:       resb 16
        sockAddrLen     equ (2+2+4+8)

        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        fdWriteSet:     resb 256
        fdReadSet:      resb 256

        numBuffer:      resb 12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        mov     ebp, esp
        sub     esp, 4

prepare_sockaddr_struct:
        ; Fill out the socket structure we use for our connect calls 
        cld            
        mov     edi, sockAddr
        ; sin_family - AF_INET
        mov     ax, 2   
        stosw           
        ; sin_port - dynamic
        ; Zero out for now
        xor     ax, ax
        stosw
        ; sin_inaddr -
        ; Convert argv[1] string to four IPv4 octets, and write directly to
        ; <sockAddr>
        push    edi             
        push    dword [ebp+8]   
        call    iptoOctets
        add     esp, 8
        ; If there are no errors, then the next 4 bytes of structure contains
        ; 4 IP octets in network byte order
        test    eax, eax
        js      malformed_ip
        ; Zero out remaining 8 bytes
        add     edi, 4
        xor     eax, eax
        mov     ecx, 2
        rep stosd

        ; The argument did not represent a valid IP address
        malformed_ip:
        mov     ebx, eax
        push    msgParseErrorLen
        push    msgParseError
        call    printStr
        add     esp, 8
        jmp     exit

cycle_ports:
        create_sock:
                ; Create socket with arguments
                ; PF_INET, SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                push    dword 6
                push    dword (1 | 4000q)
                push    dword 2
                call    createSock
                add     esp, 12

                ; Check return value
                test    eax, eax
                js      sock_error
                ; If successful, store return value 
                mov     [ebp-4], eax
                jmp     connect_sock

                sock_error:
                ; Otherwise, store return value as exit status
                mov     ebx, eax
                ; Print error message and exit
                push    msgSocketErrorLen
                push    msgSocketError
                call    printStr
                add     esp, 8
                jmp     exit
        connect_sock:
                ; Store port in network byte order
                mov     [sockAddr+2], byte bh
                mov     [sockAddr+3], byte bl
                ; Attempt to connect 
                push    sockAddrLen
                push    sockAddr        
                push    dword [ebp-4]
                call    connectSock
                add     esp, 4
                ; Connect is successful if it returned 0
                cmp     eax, 0
                je      connect_success
                jmp     close_connection
        connect_success:
                ; If the connect succeeded, print out the port as a string
                push    numBuffer
                push    ebx
                call    ultoStr
                add     esp, 4
                call    strlen
                add     esp, 4
                push    eax
                push    numBuffer
                call    printStr
                add     esp, 8
        close_connection:
                push    dword [ebp-4]
                call    closefd 
                add     esp, 4
                inc     ebx
                cmp     ebx, 1024
                ;jle     cycle_ports

exit:
        ; ebx contains exit status 
        mov     ebp, esp
        mov     eax, 1
        int     0x80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; iptoOctets
; Converts IPv4 address from text to binary form
;       expects: ip string, destination buffer
;       returns: 0 in eax if successful, -1 otherise    
iptoOctets:
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        push    ebx
        push    esi
        push    edi

        mov     esi, [ebp+8]
        mov     ebx, [ebp+12]
        lea     edi, [ebp-4]
        ; This value comes in handy when its on the stack
        push    edi
        cld
        parse_ip:
                ; Load the string into the four byte buffer we allocated
                load_string:
                        ; This loads the next byte from [esi] into al
                        lodsb
                        ; Check for termination characters
                        cmp     al, byte 0
                        je      convert_octet
                        cmp     al, byte '.'
                        je      convert_octet
                        ; Make sure its a valid octet digit (0-9)
                        cmp     al, byte '0'
                        jl      invalid_ip
                        cmp     al, byte '9'
                        jg      invalid_ip
                        ; Otherwise this is a valid digit, store it in buffer
                        stosb
                        ; Make sure we stored less than 4 bytes in the buffer
                        cmp     edi, ebp
                        jg      invalid_ip
                        jmp     load_string
                ; If we reached here, we're ready to convert the octet into its
                ; binary representation
                convert_octet:
                ; First make sure we stored at least one digit
                cmp     edi, [esp]
                je      invalid_ip
                ; Okay, now we've confirmed our octet consists of 1 to 3
                ; digits, terminate the string by writing the null byte.
                mov     [edi], byte 0
                ; The argument we need is already on the stack, it points to
                ; the first byte of the octet string
                call    atoul
                ; An octet has to be an 8-bit value
                cmp     eax, 255
                jg      invalid_ip
                ; Now load the octet into the destination buffer in big endian
                ; order/network byte order
                mov     [ebx], eax
                count_octets:
                push    ebx
                sub     ebx, [ebp+12]
                cmp     ebx, 3
                pop     ebx
                je      last_octet
                cmp     [esi-1], byte '.' 
                jne     invalid_ip
                ; We still have more work to do!
                prepare_next_octet:
                ; First, make sure we increment the destination address.
                inc     ebx
                ; Finally, reset buffer pointer to start of buffer so we can
                ; write another octet 
                lea     edi, [ebp-4]
                jmp     parse_ip
                last_octet:
                ; All four octets are supposedly loaded in the destination
                ; buffer. This means esi is must be pointing to a null byte.
                cmp     [esi-1], byte 0
                jne     invalid_ip        
                jmp     parse_success
        invalid_ip:
        xor     eax, eax
        not     eax
        jmp     exit_ip_to_octets
        parse_success:
        xor     eax, eax
        exit_ip_to_octets:
        add     esp, 4

        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

; atoul 
; Converts a number from text to binary form
;       expects: string address
;       returns: 32-bit unsigned integer in eax
atoul:
        push    ebp
        mov     ebp, esp

        ; Load string address in edx
        mov     edx, [ebp+8]
        ; Clear "result" register
        xor     eax, eax
        loop_digits:
                ; Load ecx with character
                movzx   ecx, byte [edx]
                inc     edx
                ; Terminate if NUL byte
                cmp     cl, byte 0
                je      exit_atoul
                ; Multiply current result by 10,
                ; then add current character - '0'
                lea     eax, [eax + eax * 4]
                lea     eax, [ecx + eax * 2 - '0']
                jmp     loop_digits
        exit_atoul:

        mov     esp, ebp
        pop     ebp
        ret

; ultoStr
; Converts a number from binary to printable string with newline
;       expects: 32-bit unsigned integer, buffer at least 12 bytes
;       returns: nothing
ultoStr:
        push    ebp  
        mov     ebp, esp
        push    esi
        push    edi
        
        mov     eax, [ebp+8]
        mov     edi, [ebp+12]
        ; Save original buffer for reference 
        mov     esi, edi
        mov     ecx, 10

        ; Fairly self-explanatory, right?
        calculate_number_of_digits:
        cmp     eax, 9
        jle     terminate_string
        inc     edi
        cmp     eax, 99
        jle     terminate_string
        inc     edi
        cmp     eax, 999
        jle     terminate_string
        inc     edi
        cmp     eax, 9999
        jle     terminate_string
        inc     edi
        cmp     eax, 99999
        jle     terminate_string
        inc     edi
        cmp     eax, 999999
        jle     terminate_string
        inc     edi
        cmp     eax, 9999999
        jle     terminate_string
        inc     edi
        cmp     eax, 99999999
        jle     terminate_string
        inc     edi
        cmp     eax, 999999999
        jle     terminate_string
        inc     edi

        terminate_string:
        mov     [edi+2], byte 0
        mov     [edi+1], byte 10

        ; Start writing bytes to the buffer from least to most significant
        ; digit (right to left)
        divide_loop:
        ; Else divide edx:eax by 10
        ; eax: quotient contains the rest of input number
        ; edx: remainder contains the digit we want to write
        xor     edx, edx
        div     ecx
        add     dl, byte '0'
        mov     [edi], byte dl
        dec     edi
        ; Stop if we reached the start of the buffer
        cmp     edi, esi
        jge     divide_loop

        pop     edi
        pop     esi
        mov     esp, ebp
        pop     ebp
        ret

; printStr
; Prints a string to standard output
;       expects: string address, string length
;       returns: number of bytes written in eax on success, -errno otherwise
printStr:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        mov     eax, 4
        mov     ebx, 1
        mov     ecx, [ebp+8]   
        mov     edx, [ebp+12]   
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

; strlen
; Gets the length of a string
;       expects: string address
;       returns: length in eax
strlen:
        push    ebp     
        mov     ebp, esp
        push    edi

        cld     
        xor     eax, eax
        xor     ecx, ecx
        not     ecx
        mov     edi, [ebp+8]
        repne scasb
        
        not     ecx
        lea     eax, [ecx-1]
        
        pop     edi
        mov     esp, ebp
        pop     ebp
        ret

; closefd
; Closes a file descriptor
;       expects: file descriptor
;       returns: 0 in eax | -errno in eax if error
closefd:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        mov     eax, 6
        mov     ebx, [ebp+8]
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

; connectSock
; Connect a socket       
;       expects: int socket, address, address length
;       returns: 0 in eax or -errno on error
connectSock:
        push    ebp
        mov     ebp, esp
        push    ebx
        push    edi

        mov     eax, 102
        mov     ebx, 3
        ; sys_socketcall is a wrapper around all the socket system calls, and
        ; takes as an argument a pointer to the arguments specific to the
        ; socket call we want to use, so load ecx with the address of the first
        ; argument on the stack
        lea     ecx, [ebp+8]
        int     0x80

        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

; createSock
; Create a socket       
;       expects: int domain, int type, int protocol
;       returns: 0 in eax or -errno on error
createSock:
        push    ebp
        mov     ebp, esp
        push    ebx
        push    edi

        mov     eax, 102
        mov     ebx, 1
        lea     ecx, [ebp+8]
        int     0x80

        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

; fdSet
; Add a file descriptor to an fd_set
;       expects: file descriptor, address of fd_set
;       returns: nothing
;
; static inline void __FD_SET(unsigned long fd, __kernel_fd_set *fdsetp)
; {
;       unsigned long _tmp = fd / __NFDBITS;
;       unsigned long _rem = fd % __NFDBITS;
;       fdsetp->fds_bits[_tmp] |= (1UL<<_rem);
; }
; 
; Apparently what this does is use the array as a bitmask...
fdSet:
        push    ebp
        mov     ebp, esp

        mov     eax, [ebp+8]
        mov     edx, [ebp+12]
        ; Save an additional copy of fd
        mov     ecx, eax

        ; Divide fd by the number of bits in a 32-bit long, this gives us our
        ; index into the fds_bits array. 
        shr     eax, 5
        ; Note: index is a dword aligned offset 
        lea     edx, [edx + eax * 4]
        ; Figure out the appropriate bit to set in the dword-sized array
        ; element by looking at the last 5 bits of file descriptor
        and     ecx, 0x1f
        ; fd_bits[fd/32] |= (1<<rem)
        xor     eax, eax
        inc     eax
        shl     eax, ecx
        or      [edx], eax

        mov     esp, ebp
        pop     ebp
        ret
