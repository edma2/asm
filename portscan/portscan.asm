; vim: ft=nasm
; Usage: asmscan [OPTIONS] HOST
; Author: Eugene Ma

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
        msgSocketError:         db 'Error: failed to create socket', 10
        msgSocketErrorLen       equ $-msgSocketError
        msgParseError:          db 'Error: malformed IP', 10
        msgParseErrorLen        equ $-msgParseError
        msgConnectError:        db 'Error: failed to connect socket', 10
        msgConnectErrorLen      equ $-msgConnectError
        msgConnectSuccess:      db 'Connected!', 10
        msgConnectSuccessLen    equ $-msgConnectSuccess

        ; PF_INET, SOCK_STREAM, IPPROTO_TCP
        sockArgs:     dd 2, 1, 6

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

        ; socket, sockaddr *address, address_len
        connectArgs:    resb (4+4+4)

        octetBuffer:    resb 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        ; Reset frame pointer and allocate local storage
        mov     ebp, esp
        sub     esp, 4

create_sock:
        ; Create a stream socket
        mov     eax, 102
        mov     ebx, 1
        mov     ecx, sockArgs
        int     0x80
        test    eax, eax
        js      sock_error
        ; Store sockfd as local variable
        mov     [ebp-4], eax
        jmp     prep_sockAddr
        
        sock_error:
        ; Store return value as exit status
        mov     ebx, eax
        push    msgSocketErrorLen
        push    msgSocketError
        call    printStr
        add     esp, 8
        jmp     exit

prep_sockAddr:
        mov     edi, sockAddr
        cld            
        ; sin_family = AF_INET
        mov     ax, 2   
        stosw           
        ; sin_port = 80
        ;;; TODO: Cycle through ports 0-1024
        mov     ax, 80  
        ; Swap bytes for host-to-network byte order
        xchg    al, ah
        stosw
        push    octetBuffer
        push    dword [ebp+8]
        call    iptoOctets
        add     esp, 8
        test    eax, eax
        js      malformed_ip
        mov     eax, [octetBuffer]
        stosd
        ; Zero out remaining 8 bytes
        xor     eax, eax
        mov     ecx, 2
        rep stosd
        jmp     connect_sock

        malformed_ip:
        push    msgParseErrorLen
        push    msgParseError
        call    printStr
        add     esp, 8
        jmp     done

connect_sock:
        ; Load up arguments to connect
        cld
        mov     edi, connectArgs
        ; Connect socket to socket address
        mov     eax, [ebp-4]
        stosd
        mov     eax, sockAddr
        stosd
        mov     eax, sockAddrLen
        stosd
        ; Attempt to connect 
        mov     eax, 102
        mov     ebx, 3
        mov     ecx, connectArgs
        int     0x80
        ; Connect is successful if it returned 0
        cmp     eax, 0
        je      next_step 

        ; Otherwise store return value as exit status
        mov     ebx, eax

        ; Clean up and exit
        push    msgConnectErrorLen
        push    msgConnectError
        call    printStr
        add     esp, 8
        jmp     done

next_step:
        push    msgConnectSuccessLen
        push    msgConnectSuccess
        call    printStr
        add     esp, 8
        push    dword [ebp-4]
        call    closefd
        add     esp, 4
        ; Store successful exit status (0)
        xor     ebx, ebx

done:
clean_up:
        push    dword [ebp-4]
        call    closefd
        add     esp, 4
exit:
        ; EBX contains exit status 
        mov     ebp, esp
        mov     eax, 1
        int     0x80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 
; iptoOctets
;       Converts IPv4 address from text to binary form. 
;               Arguments: ip string, destination buffer
;               Returns: 0 if successful, -1 otherise    
;
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
                        ; This loads the next byte from [ESI] into AL
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
                ; buffer. This means ESI is must be pointing to a null byte.
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

;
; atoul 
;       Converts a number from text to binary form. 
;               Arguments: string address
;               Returns: 32-bit unsigned integer in EAX
;
atoul:
        push    ebp
        mov     ebp, esp

        ; Load string address in EDX
        mov     edx, [ebp+8]
        ; Clear "result" register
        xor     eax, eax
        .loop:
                ; Load ECX with character
                movzx   ecx, byte [edx]
                inc     edx
                ; Terminate if NUL byte
                cmp     cl, 0
                je      .done
                ; Multiply current result by 10,
                ; then add current character - '0'
                lea     eax, [eax + eax * 4]
                lea     eax, [ecx + eax * 2 - '0']
                jmp     .loop
        .done:

        mov     esp, ebp
        pop     ebp
        ret

;
; printStr
;       Prints a string to standard output.
;               Arguments: string address, string length
;               Returns: bytes written in EAX | -errno in EAX if error
;
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

;
; closefd
;       Closes a file descriptor
;               Arguments: file descriptor
;               Returns: 0 in EAX | -errno in EAX if error
;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
