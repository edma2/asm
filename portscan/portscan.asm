; vim: ft=nasm
; Usage: asmscan [OPTIONS] HOST
; Author: Eugene Ma

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

        numBuffer:      resb 12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        ; Reset frame pointer and allocate local storage
        mov     ebp, esp
        ; Allocate local storage for socket file descriptor
        sub     esp, 4

create_sock:
        ; Create socket
        push    dword 6
        push    dword 1
        push    dword 2
        call    createSock
        add     esp, 12

        ; Check return value
        test    eax, eax
        js      sock_error
        ; If successful, store return value local variable
        mov     [ebp-4], eax
        jmp     prepare_sock

        sock_error:
        ; Otherwise, store return value as exit status
        mov     ebx, eax
        ; Print error message and exit
        push    msgSocketErrorLen
        push    msgSocketError
        call    printStr
        add     esp, 8
        jmp     exit

prepare_sock:
        ; Prepare the sockaddr structure!
        mov     edi, sockAddr
        cld            
        ; sin_family = AF_INET
        mov     ax, 2   
        stosw           
        ; sin_port = 0 (temporary)
        ; This value with be incremented with each port scan cycle
        xor     ax, ax
        stosw
        ; Generate the correct IPv4 address given the input string
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
        jmp     initialize_ports

        malformed_ip:
        mov     ebx, eax
        push    msgParseErrorLen
        push    msgParseError
        call    printStr
        add     esp, 8
        jmp     clean_up_and_exit

initialize_ports:
        ; Iterate through ports with ebx
        xor     ebx, ebx
        mov     ebx, 80
        jmp     cycle_ports

; Scan ports 0-1024
cycle_ports:
        ; Store in network byte order
        mov     [sockAddr+2], byte bh
        mov     [sockAddr+3], byte bl

        connect_sock:
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
                inc     ebx
                cmp     ebx, 1024
                jle     cycle_ports

clean_up_and_exit:
clean_up:
        push    dword [ebp-4]
        call    closefd
        add     esp, 4
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
;       Arguments: ip string, destination buffer
;       Returns: 0 in eax if successful, -1 otherise    
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
;       Arguments: string address
;       Returns: 32-bit unsigned integer in eax
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
;       Expects: 32-bit unsigned integer, buffer at least 12 bytes
;       Returns: 0 in eax on success, ~0 otherwise
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
;       Expects: string address, string length
;       Returns: bytes written in eax | -errno in eax if error
printStr:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        ; Syscall 4 - sys_write
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
;       Arguments: string address
;       Returns: length in eax
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
;       Arguments: file descriptor
;       Returns: 0 in eax | -errno in eax if error
closefd:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        ; Syscall 6 - sys_close
        mov     eax, 6
        mov     ebx, [ebp+8]
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; connectSock
; Connect a socket       
;       expects: int socket, address, address length
;       returns: 0 in eax or -errno on error
connectSock:
        push    ebp
        mov     ebp, esp
        push    ebx
        push    edi

        ; Syscall 102/3 - sys_connect
        mov     eax, 102
        mov     ebx, 3
        lea     ecx, [ebp+8]
        int     0x80

        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; createSock
; Create a socket       
;       expects: int domain, int type, int protocol
;       returns: 0 in eax or -errno on error
createSock:
        push    ebp
        mov     ebp, esp
        push    ebx
        push    edi

        ; Syscall 102/1 - sys_socket
        mov     eax, 102
        mov     ebx, 1
        lea     ecx, [ebp+8]
        int     0x80

        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret
