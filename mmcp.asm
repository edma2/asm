; vim: ft=nasm
; cp-mmap - copy files and directories with memory mapped files
; Usage: cp <src> <dest>
; Returns exit code of 0 on success, or 1 on error
; Author: Eugene Ma

; Performance:
; TODO: Do some more robust testing
; % time ./cp-mmap2 Blade\ Runner.mp4 foo.mp4
; ./cp-mmap2 Blade\ Runner.mp4 foo.mp4  0.20s user 0.76s system 11% cpu 8.356 total

; % time cp Blade\ Runner.mp4 foo.mp4
; cp -i Blade\ Runner.mp4 foo.mp4  0.01s user 1.24s system 11% cpu 10.719 total

; With CDECL, all general-purpose registers are preserved except for EAX, ECX, and EDX.
; Stack with arguments pushed in right to left order
; 12(ebp) = second function parameter
; 8(ebp) = first function parameter
; 4(ebp) = return address (old EIP)
; 0(ebp) = old base pointer (old EBP)
; ... saved registers ...
; ... local variables ...

; [ebp+12] = destination file path 
; [ebp+8] = source file path
; [ebp+4] = program name 
; [ebp] = argument count
; [ebp-4] = source file descriptor
; [ebp-8] = destination file descriptor
; [ebp-12] = source file length
; [ebp-16] = src mmap return value
; [ebp-20] = dest mmap return value

section .data
        zeroByte:               db 0

        msg_usage_error:        db 'Usage: cp-mmap [src] [dst]', 10
        msg_usage_error_len     equ $-msg_usage_error

        msg_open_src_error:     db 'Error: unable to open source file', 10
        msg_open_src_error_len  equ $-msg_open_src_error

        msg_create_dest_error:  db 'Error: unable to create destination file', 10
        msg_create_dest_error_len equ $-msg_create_dest_error

        msg_lseek_error:        db 'Error: unable to seek file', 10
        msg_lseek_error_len     equ $-msg_lseek_error

        msg_mmap_error:         db 'Error: unable to map file to memory', 10
        msg_mmap_error_len      equ $-msg_mmap_error

        msg_write_error:        db 'Error: write I/O error', 10
        msg_write_error_len     equ $-msg_write_error

section .text
        global  _start

; Set up base pointer for sanity
_start:
        mov     ebp, esp
        sub     esp, 20

; Check that program is called with source and destination 
check_argument_count:
        cmp     dword [ebp], 3 
        je      open_src_file

        ; Otherwise, print usage string
        push    msg_usage_error_len
        push    msg_usage_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     exit

; Open source file and store its file descriptor 
open_src_file:
        ; Mode is only used for setting permissions of a new file.
        ; Since mode is ignored here, pass an arbitrary value
        push    dword 0
        ; int oflag = O_RDWR
        push    dword 2q
        push    dword [ebp+8]
        call    fn_open
        add     esp, 12

        ; Check return value
        test    eax, eax        
        js      open_src_error

        ; If successful, store file descriptor in EBP - 4
        mov     [ebp-4], eax
        jmp     get_file_length

        ; Otherwise, print error message
        open_src_error:
        push    msg_open_src_error_len
        push    msg_open_src_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     exit

; Use sys_lseek to determine length of the source file
get_file_length:
        ; Seek to end of file, returned offset is file length
        ; int fildes = [ebp-4]
        ; int whence = SEEK_END
        ; off_t offset = 0
        push    dword 2
        push    dword 0
        push    dword [ebp-4]
        call    fn_lseek
        add     esp, 12

        ; Check return value
        test    eax, eax        
        js      get_file_length_error

        ; If successful, store source file length in EBP - 12
        mov     [ebp-12], eax
        jmp     mmap_src_file

        ; Otherwise, print error message 
        get_file_length_error:
        push    msg_lseek_error_len
        push    msg_lseek_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_src_fd

; Map source file to memory
mmap_src_file:
        ; sys_old_mmap
        ; Arguments:
        ;       void *addr = NULL
        ;       size_t len = [ebp-12]
        ;       int prot = PROT_READ
        ;       int flags = MAP_SHARED
        ;       int fildes = [ebp-4]
        ;       off_t off = 0
        mov     eax, 192
        mov     ebx, 0          
        mov     ecx, [ebp-12]
        mov     edx, 0x1
        mov     esi, 0x1 
        mov     edi, [ebp-4]
        ; Save ebp before call
        push    ebp
        mov     ebp, 0          
        int     0x80
        ; Restore ebp after call
        pop     ebp

        ; Check return value
        test    eax, eax        
        jz      mmap_src_file_error

        ; If successful, store source address in EBP - 16
        mov     [ebp-16], eax
        jmp     create_dest_file

        ; Otherwise, print error message
        mmap_src_file_error:
        push    msg_mmap_error_len
        push    msg_mmap_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_src_fd

; Create destination file and store its file descriptor
create_dest_file:
        ; Set permissions of new file
        push    dword 666q
        ; int oflag = O_CREAT | O_RDWR | O_TRUNC
        ; Note: O_WRONLY mode is not sufficient for mmapping
        push    dword (100q | 2q | 1000q)
        push    dword [ebp+12]
        call    fn_open
        add     esp, 12

        ; Check return value
        test    eax, eax
        js      create_dest_error

        ; If successful, store file descriptor in EBP - 8
        mov     [ebp-8], eax
        jmp     stretch_dest_length    

        ; Otherwise, print error message 
        create_dest_error:
        push    msg_create_dest_error_len
        push    msg_create_dest_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_mmap_src

; Seek to offset in destination file equal to target file size
stretch_dest_length:
        ; int whence = SEEK_SET
        push    dword 0
        ; int offset = [ebp-12] - 1
        push    dword [ebp-12]
        dec     dword [esp]
        push    dword [ebp-8]
        call    fn_lseek
        add     esp, 12

        ; Check return value
        test    eax, eax        
        jz      stretch_dest_length_error
        jmp     write_zero_byte

        ; If error, print error message
        stretch_dest_length_error:
        push    msg_lseek_error_len
        push    msg_lseek_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_dest_fd

; Write a zero byte to the end in order to set an EOF (?)
; I'm not sure how an EOF is actually made, is this just an mmap workaround?
; This is why I think setting an EOF before mmapping is needed, from mmap(3p):
; References within the address range starting at pa and continuing for len bytes to whole
; pages following the end of an object shall result in delivery of a SIGBUS signal.
write_zero_byte:
        ; sys_write(int fildes, const void *buf, size_t nbyte);
        ; Arguments:
        ;       int fildes = [ebp-8]
        ;       const void *buf = zeroByte
        ;       size_t nbyte = 1
        mov     eax, 4
        mov     ebx, [ebp-8]
        mov     ecx, zeroByte
        mov     edx, 1
        int     0x80

        ; Check return value
        cmp     eax, 1
        je      mmap_dest_file

        ; If error, print error message
        push    msg_write_error_len
        push    msg_write_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_dest_fd

; Map destination file to memory
mmap_dest_file:
        ; sys_old_mmap
        ; Arguments:
        ;       void *addr = NULL
        ;       size_t len = [ebp-12]
        ;       int prot = PROT_READ|PROT_WRITE
        ;       int flags = MAP_SHARED
        ;       int fildes = [ebp-8]
        ;       off_t off = 0
        mov     eax, 192
        mov     ebx, 0          
        mov     ecx, [ebp-12]
        mov     edx, (0x1|0x2)
        mov     esi, 0x1 
        mov     edi, [ebp-8]
        ; Save ebp before call
        push    ebp
        mov     ebp, 0          
        int     0x80
        ; Restore ebp after call
        pop     ebp

        ; Check return value
        test    eax, eax        
        jz      mmap_dest_file_error

        ; If successful, store destination address in EBP - 20
        mov     [ebp-20], eax
        jmp     main_copy

        ; Otherwise, print error message
        mmap_dest_file_error:
        push    msg_mmap_error_len
        push    msg_mmap_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, 1
        jmp     cleanup_dest_fd

; The main loop of the program
main_copy:
        ; Use MOVS instructions to move bytes from memory to memory
        ; Clear DF flag. Now ESI and EDI are automatically incremented.
        cld
        ; Set memory pointers
        mov     esi, [ebp-16]
        mov     edi, [ebp-20]
        ; Set ECX to file size
        mov     ecx, [ebp-12]
        ; Move dwords at a time for efficiency
        ; Divide ECX by 4 since we are moving dwords at a time
        shr     ecx, 2
        ; Execute, ignoring the lowest 2 bits of filesize for now
        rep movsd    

        ; At this point, memory pointers will be pointing to filesize & 0xfffffffc.
        ; Let's recover the last two bits in order to take care of the offset.
        mov     ecx, [ebp-12]
        and     ecx, 0x3
        rep movsb    

        ; Store successful exit status
        mov     ebx, 0

; Consolidated clean up procedures start here
cleanup_all:
        ; Unmap destination file from memory
        push    dword [ebp-12]
        push    dword [ebp-20]
        call    fn_munmap
        add     esp, 8
cleanup_dest_fd:
        ; Close destination file 
        push    dword [ebp-8]
        call    fn_close_fd
        add     esp, 4
cleanup_mmap_src:
        ; Unmap source file from memory
        push    dword [ebp-12]
        push    dword [ebp-16]
        call    fn_munmap
        add     esp, 8
cleanup_src_fd:
        ; Close source file 
        push    dword [ebp-4]
        call    fn_close_fd
        add     esp, 4
exit:
        ; Clean up stack frame
        mov     esp, ebp
        ; EBX should contain status code. Call sys_exit
        mov     eax, 1
        int     0x80

; Some helpful subroutines
_functions:

;
; fn_write_stderr
;       Write a string to standard error
;               Arguments: string address, string length
;               Returns: number of bytes written, or -1 if error
;
fn_write_stderr:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        ; sys_write
        ; Arguments:
        ;       int fildes = standard error
        ;       const void *buf = first argument on stack
        ;       size_t nbyte = second argument on stack
        mov     eax, 4
        mov     ebx, 2
        mov     ecx, [ebp+8]
        mov     edx, [ebp+12]
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; fn_open       
;       Open or create a file
;               Arguments: file descriptor, flags, mode
;               Returns: if successful, file descriptor, else -1
; Note: ECX and EDX will be clobbered, along with the usual EAX
fn_open:
        push    ebp
        mov     ebp, esp
        push    ebx

        ; sys_open
        ; Arguments:
        ;       char path = first argument
        ;       int oflag = second argument
        ;       int mode = third argument
        ; Mode is ignored unless oflag has O_CREAT
        mov     eax, 5 
        mov     ebx, [ebp+8]
        mov     ecx, [ebp+12]
        mov     edx, [ebp+16]
        int     0x80       

        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; fn_close_fd
;       Close a file descriptor
;               Arguments: file descriptor
;               Returns: if successful, 0, else -1
;
fn_close_fd:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        ; sys_close
        ; Arguments:
        ;       int fildes = first argument on stack
        mov     eax, 6
        mov     ebx, [ebp+8]
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; fn_munmap
;       Unmap previously mapped memory
;               Arguments: memory address, length
;               Returns: if successful, 0, else -1
;
fn_munmap:
        push    ebp
        mov     ebp, esp
        push    ebx
        
        ; sys_munmap
        ; Arguments:
        ;       void *addr = first argument on stack
        ;       size_t len = second argument on stack
        mov     eax, 91
        mov     ebx, [ebp+8]
        mov     ecx, [ebp+12]
        int     0x80
        
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;
; fn_lseek
;       Seek in a file with given file descriptor and offset 
;               Arguments: file descriptor, offset, whence
;               Returns: if successful, file offset, otherwise -1
;       
fn_lseek:
        push    ebp
        mov     ebp, esp
        push    ebx

        ; sys_lseek
        ; Arguments:
        ;       int fildes = first argument
        ;       off_t offset = second argument
        ;       int whence = third argument
        mov     eax, 19
        mov     ebx, [ebp+8]
        mov     ecx, [ebp+12]         
        mov     edx, [ebp+16]
        int     0x80

        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret
