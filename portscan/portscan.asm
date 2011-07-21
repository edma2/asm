; vim: ft=nasm
; Usage: asmscan [OPTIONS] HOST
; Author: Eugene Ma

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
        msgSocketError:         db 'Error: failed to create socket', 10
        msgSocketErrorLen       equ $-msgSocketError
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
        push    dword [ebp+8]
        call    iptoOctets
        add     esp, 4
        ; Reverse bytes for host-to-network byte order
        bswap   eax 
        stosd
        ; Zero out remaining 8 bytes
        xor     eax, eax
        mov     ecx, 2
        rep stosd

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
;               Arguments: ip string 
;               Returns: four octets in EAX
;
iptoOctets:
        push    ebp
        mov     ebp, esp
        sub     esp, 4
        push    ebx
        push    esi
        push    edi

        lea     edi, [ebp-4]
        mov     esi, [ebp+8]
        xor     ebx, ebx
        cld

        ; Leave this value on top of the stack, it will come in handy later
        ; because we can restore EDI to the start of local storage, and also,
        ; it's pre-loaded as an argument for a function call.
        push    edi
        process_string_loop:
                load_string_loop:
                        ; Load the next octet into the allocated local storage. This
                        ; "local string" can contain up to 3 octet characters, and a
                        ; null byte. It starts at EBP-4 and ends at EBP.
                        movsb
                        ; Check if we reached a terminating character, which
                        ; can be either a dot or a null byte.
                        cmp     [esi], byte 0
                        je      convert_str_to_octet
                        cmp     [esi], byte '.'
                        je      convert_str_to_octet
                        ; Still here? That means we are looking at a character
                        ; that's neither a dot nor a null char. If EDI is
                        ; already past the third digit get out of here.
                        cmp     edi, ebp
                        je      octets_ready
                        jmp     load_string_loop
                convert_str_to_octet:
                ; Once we're here, EDI should be pointing to one byte past the
                ; last octet digit, so terminate the string with a null byte.
                mov     [edi], byte 0
                ; Beginning of octet string (EDI) is already on stack, so call
                ; atoul on it, then restore EDI to beginning of local storage.
                call    atoul
                mov     edi, [esp]
                ; Load the octet represented as a binary number into the lowest
                ; 8 bits of EBX. Shift existing octets to the left.
                store_octet:
                shl     ebx, 8
                mov     bl, al
                ; ESI should be pointing to either a dot or a null character at
                ; this point, we're done if its the latter. Increment ESI in
                ; case its the former (This has no ill-effects otherwise).
                inc     esi
                cmp     [esi-1], byte 0
                jne     process_string_loop
        octets_ready:
        ; Pop ebp-4 off the stack
        add     esp, 4
        mov     eax, ebx

        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; atoul 
;       Converts a null terminated ascii string to an unsigned integer. Does
;       not check for errors.
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
