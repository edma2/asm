; vim: ft=nasm
; Usage: portscan [OPTIONS] HOST
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

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        connectTimeout: dd 3, 0

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

        ; Defined in /include/linux/posix_types.h
        ;
        ; #define __NFDBITS (8 * sizeof(unsigned long))  // bits per file descriptor
        ; #define __FD_SETSIZE 1024                      // bits per fd_set
        ; #define __FDSET_LONGS (__FD_SETSIZE/__NFDBITS) // ints per fd_set
        ;
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        fdWriteSet:     resd 32
        fdReadSet:      resd 32

        numBuffer:      resb 12

        octetBuffer:    resd 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        mov     ebp, esp
        sub     esp, 4

parse_octets:
        ; Parse the ip string into octets that are stored in big-endian/network
        ; byte order
        push    octetBuffer             
        push    dword [ebp+8]   
        call    iptoOctets
        add     esp, 8
        
        ; Check the return value
        test    eax, eax
        js      malformed_ip
        jmp     load_sockaddr

        ; If signed, it means the IPv4 address was malformed
        ; Print error message and exit
        malformed_ip:
        push    msgParseErrorLen
        push    msgParseError
        call    printStr
        add     esp, 8
        jmp     exit

load_sockaddr:
        ; Load the struct sockaddr 
        push    dword [octetBuffer]
        push    dword 0x5000
        push    sockAddr
        call    loadSockAddr    
        add     esp, 12

load_fdsets:
        ; Load up the fd_sets
        push    fdWriteSet
        call    loadFdSet
        add     esp, 4
        push    fdReadSet
        call    loadFdSet
        add     esp, 4

cycle_ports:
        create_sock:
                ; Create socket with arguments
                ; PF_INET, SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                push    dword 6
                ;push    dword (1 | 4000q)
                push    dword 1
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
                ;mov     [sockAddr+2], byte bh
                ;mov     [sockAddr+3], byte bl
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
                push    dword 80
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
;       Converts IPv4 address from text to binary form
;               Arguments: ip string, destination buffer
;               Returns: 0 in eax if successful, -1 otherise    
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
        parse_loop:
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
                call    strtoul
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
                jmp     parse_loop
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

; strtoul 
;       Converts a number from text to binary form
;               Arguments: string address
;               Returns: 32-bit unsigned integer in eax
strtoul:
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
                je      exit_strtoul
                ; Multiply current result by 10,
                ; then add current character - '0'
                lea     eax, [eax + eax * 4]
                lea     eax, [ecx + eax * 2 - '0']
                jmp     loop_digits
        exit_strtoul:

        mov     esp, ebp
        pop     ebp
        ret

; ultoStr (maybe use a lookup table instead?)
;       Converts a number from binary to null terminated string
;               Arguments: 32-bit unsigned integer, buffer 
;               Returns: nothing
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
        mov     [edi+1], byte 0

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
;       Prints a string to standard output
;               Arguments: string address, string length
;               Returns: number of bytes written in eax on success, -errno otherwise
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
;       Gets the length of a string
;               Arguments: string address
;               Returns: length in eax
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
;       Closes a file descriptor
;               Arguments: file descriptor
;               Returns: 0 in eax | -errno in eax if error
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
;       Connect a socket       
;               Arguments: int socket, address, address length
;               Returns: 0 in eax or -errno on error
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

; createSock:
;       Create a socket       
;               Arguments: int domain, int type, int protocol
;               Returns: 0 in eax or -errno on error
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

; loadFdSet:
;       Fill up a struct fd_set. See description.
;               Arguments: pointer to struct fd_set
;               Returns: nothing
;
; Description:
;
; Here we roll our own struct fd_set that the kernel uses as an interface for
; select(2). struct fd_set is implemented as a bit array, composed of 32-bit
; ints, and every possible file descriptor is mapped to a bit position.
; e.g. (31|30|29|...|1|0) (63|62|61|...|33|32) ...
;
; Since we plan on using 128 (?) ports at a time, we'll have to open up
; 128 additional file descriptors, the mappings will start at 3 and end
; at 130, assuming they are assigned to our program in sequential order
; (otherwise we're screwed).
loadFdSet:
        push    ebp
        mov     ebp, esp

        ; Load address into ecx
        mov     ecx, [ebp+8]
        ; Turn on all bits in eax
        xor     eax, eax
        not     eax
        ; Shift out lower 3 bits (0b...11111000)
        shl     eax, 3
        ; Turn on bits 3-31
        mov     dword [ecx], eax
        ; Load bits 32-63
        sar     eax, 3
        mov     dword [ecx+4], eax
        ; Load bits 64-95
        mov     dword [ecx+8], eax
        ; Load bits 64-95
        mov     dword [ecx+12], eax
        ; Load bits 96-127
        mov     dword [ecx+16], eax
        ; Load bits 128-130
        shr     eax, 29
        mov     dword [ecx+20], eax

        mov     esp, ebp
        pop     ebp
        ret

; loadSockAddr:
;       Loads the struct sockaddr used by the kernel to make network socket
;       system calls. Port and octets must be in network byte order.
;               Arguments: pointer to struct sockaddr, port, octets
;               Returns: nothing
loadSockAddr:
        push    ebp
        mov     ebp, esp
        push    edi
        
        ; Set edi to point to struct
        mov     edi, [ebp+8]
        ; Set direction flag so our pointer to the struct (edi) increments as
        ; we fill it out
        cld            
        ; Set struct member sin_family to AF_INET
        mov     ax, word 2   
        stosw           
        ; Struct member sin_port is set to lowest 16 bits of port
        mov     eax, [ebp+12]
        stosw
        ; Store struct member sin_addr with 4 octets in network byte order
        mov     eax, [ebp+16]
        stosd
        ; If everything is fine, zero out the remaining 8 bytes of the sockaddr
        ; struct
        xor     eax, eax
        mov     ecx, 2
        rep stosd

        pop     edi
        mov     esp, ebp
        pop     ebp
        ret
