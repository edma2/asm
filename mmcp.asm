; vim: ft=nasm
; mmcp - copy files and directories with memory mapped files
; Author: Eugene Ma
; Usage: mmcp <src> <dest>
; Returns exit status 0 on success, or non-zero on failure.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data
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

        zeroByte:               db 0
        block_size              equ 1048576 ; 1MB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text
        global  _start

_start:
        ; Set up base pointer for sanity
        mov     ebp, esp
        ; [ebp+12] = destination file path 
        ; [ebp+8] = source file path
        ; [ebp+4] = program name 
        ; [ebp] = argument count
        ; [ebp-4] = source file descriptor
        ; [ebp-8] = destination file descriptor
        ; [ebp-12] = source file length in bytes
        ; [ebp-16] = src mmap address 
        ; [ebp-20] = dest mmap address
        ; [ebp-24] = current offset in bytes
        sub     esp, 24

check_argument_count:
        ; Check that program is called with appropriate arguments
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

open_src_file:
        ; Open source file and store its file descriptor 
        ; Mode is only used for setting permissions of a new file.
        ; Since mode is ignored here, pass an arbitrary value
        sub     esp, 4
        ; int oflag = O_RDWR
        push    dword 2q
        ; const char *path = source file ([ebp+8])
        push    dword [ebp+8]
        call    fn_open
        add     esp, 12

        ; Check return value
        test    eax, eax        
        js      open_src_error

        ; If successful, store file descriptor as local variable
        mov     [ebp-4], eax
        jmp     get_file_length

        ; Otherwise, print error message
        open_src_error:
        push    msg_open_src_error_len
        push    msg_open_src_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, eax
        jmp     exit

get_file_length:
        ; Use sys_lseek to determine length of the source file.
        ; The current implementation only works file lengths less than 2 gigabytes.
        ; Look into using llseek for anything bigger than that.
        ; Seek to end of file, returned offset is file length
        ; int whence = SEEK_END
        push    dword 2
        ; off_t offset = 0
        push    dword 0
        ; int fildes = [ebp-4]
        push    dword [ebp-4]
        call    fn_lseek
        add     esp, 12

        ; Check return value
        test    eax, eax        
        js      get_file_length_error

        ; If successful, store source file length as local variable
        mov     [ebp-12], eax
        ; Also, store the initial file offset 
        mov     dword [ebp-24], 0
        jmp     create_dest_file

        ; Otherwise, print error message 
        get_file_length_error:
        push    msg_lseek_error_len
        push    msg_lseek_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, eax
        jmp     close_src

create_dest_file:
        ; Create destination file and store its file descriptor
        ; mode_t mode = 0666
        push    dword 666q
        ; int oflag = O_CREAT | O_RDWR | O_TRUNC
        ;       Note: O_WRONLY mode is not sufficient for mmapping
        push    dword (100q | 2q | 1000q)
        ; const char *path = destination file ([ebp+12])
        push    dword [ebp+12]
        call    fn_open
        add     esp, 12

        ; Check return value
        test    eax, eax
        js      create_dest_error

        ; If successful, store file descriptor as local variable
        mov     [ebp-8], eax
        jmp     stretch_dest_length    

        ; Otherwise, print error message 
        create_dest_error:
        push    msg_create_dest_error_len
        push    msg_create_dest_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, eax
        jmp     close_src

stretch_dest_length:
        ; Seek to offset in destination file equal to target file size.
        ; Use lseek to "stretch" file to specified size
        ; int whence = SEEK_SET
        push    dword 0
        ; int offset = file length ([ebp-12] - 1)
        push    dword [ebp-12]
        dec     dword [esp]
        ; int fildes = destination file descriptor ([ebp-8])
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
        mov     ebx, eax
        jmp     close_all

write_zero_byte:
        ; Write a zero byte to the end of our newly stretched file to mark an EOF
        ; sys_write(int fildes, const void *buf, size_t nbyte);
        mov     eax, 4
        ; int fildes = destination file descriptor ([ebp-8])
        mov     ebx, [ebp-8]
        ; const void *buf = zeroByte
        mov     ecx, zeroByte
        ; size_t nbyte = 1
        mov     edx, 1
        int     0x80

        ; Check return value
        cmp     eax, 1
        je      main_loop

        ; If error, print error message
        push    msg_write_error_len
        push    msg_write_error
        call    fn_write_stderr
        add     esp, 8
        ; Store exit status code and exit
        mov     ebx, eax
        jmp     close_all

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

main_loop:
        set_count:
                ; Move default value to ECX register
                mov     ecx, block_size
                ; Compare block size with count of remaining bytes
                cmp     ecx, [ebp-12]
                ; If block_size > remaining bytes, we've reached the last block
                ; Overwrite default value with count of remaining bytes
                cmovg   ecx, [ebp-12]

        mmap_src_file:
                ; Map source file to memory
                ; size_t len already set in ECX
                ; sys_old_mmap
                mov     eax, 192
                ; void *addr = NULL
                xor     ebx, ebx          
                ; int prot = PROT_READ
                mov     edx, 0x1
                ; int flags = MAP_SHARED
                mov     esi, 0x1 
                ; int fildes = source file descriptor ([ebp-4])
                mov     edi, [ebp-4]
                ; Save ebp before call
                push    ebp
                ; off_t off = current offset in pages ([ebp-24])
                mov     ebp, [ebp-24]          
                ; Convert bytes to pages
                shr     ebp, 12
                int     0x80
                ; Restore ebp after call
                pop     ebp

                ; Check return value
                cmp     eax, -1        
                je      mmap_src_file_error

                ; If successful, store source address as local variable
                mov     [ebp-16], eax
                jmp     mmap_dest_file

                ; Otherwise, print error message
                mmap_src_file_error:
                push    msg_mmap_error_len
                push    msg_mmap_error
                call    fn_write_stderr
                add     esp, 8
                ; Store exit status code and exit
                mov     ebx, eax
                jmp     close_all

        mmap_dest_file:
                ; Map destination file to memory
                ; sys_old_mmap
                ; void *addr already set in EBX
                ; size_t len already set in ECX
                ; int flags already set in ESI
                mov     eax, 192
                ; int prot = PROT_READ | PROT_WRITE
                ;       Note: PROT_WRITE may not be enough to mmap
                mov     edx, (0x1|0x2)
                ; int fildes = destination file descriptor ([ebp-8])
                mov     edi, [ebp-8]
                ; Save ebp before call
                push    ebp
                ; off_t off = current offset in pages ([ebp-24])
                mov     ebp, [ebp-24]          
                ; Convert bytes to pages
                shr     ebp, 12
                int     0x80
                ; Restore ebp after call
                pop     ebp

                ; Check return value
                cmp     eax, -1        
                je      mmap_dest_file_error

                ; If successful, store destination address as local variable
                mov     [ebp-20], eax
                jmp     copy_block

                ; Otherwise, print error message
                mmap_dest_file_error:
                push    msg_mmap_error_len
                push    msg_mmap_error
                call    fn_write_stderr
                add     esp, 8
                ; Store exit status code and exit
                mov     ebx, eax
                jmp     unmap_src

                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                copy_block:
                        ; Use MOVS instructions to move data between memory locations
                        ; Clear DF flag. Now ESI and EDI are automatically incremented by MOVS
                        cld
                        ; Set memory pointers
                        mov     esi, [ebp-16]
                        mov     edi, [ebp-20]

                        ; Store ECX so we can use it again after we perform bit shift
                        push    ecx
                        ; Move dwords at a time for efficiency
                        ; Divide ECX by 4 since we are moving dwords at a time
                        shr     ecx, 2
                        ; Execute, ignoring the lowest 2 bits of filesize for now
                        rep movsd    

                        ; At this point, memory pointers will be pointing to ECX & 0xfffffffc.
                        ; Let's recover the last two bits in order to take care of the offset.
                        mov     ecx, [esp]
                        and     ecx, 0x3
                        rep movsb    

                        ; Recover count of bytes written this block
                        pop     ecx
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                ; Local clean up procedure
                ; Unmap source block from memory
                push    ecx
                push    dword [ebp-16]
                call    fn_munmap
                add     esp, 8
                ; Unmap destination block from memory
                push    ecx
                push    dword [ebp-20]
                call    fn_munmap
                add     esp, 8

                ; Store successful exit status
                ; We might use this later if we are finished
                mov     ebx, 0

                ; Increment offset by bytes written
                add     [ebp-24], ecx
                ; Decrement count of remaining bytes to write 
                sub     [ebp-12], ecx

                ; Leave loop if we're done
                jz      close_all

                ; Otherwise continue next iteration
                jmp     main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_src:
        ; Unmap source file from memory
        ;       Note: ECX should contain number of bytes mapped
        push    ecx
        push    dword [ebp-16]
        call    fn_munmap
        add     esp, 8
close_all:
        ; Close destination file 
        push    dword [ebp-8]
        call    fn_close_fd
        add     esp, 4
close_src:
        ; Close source file 
        push    dword [ebp-4]
        call    fn_close_fd
        add     esp, 4
exit:
        ; Clean up stack frame and exit
        ;       Note: EBX should contain status code
        mov     esp, ebp
        mov     eax, 1
        int     0x80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
        mov     eax, 4
        ; int fildes = standard error
        mov     ebx, 2
        ; const void *buf = first argument on stack
        mov     ecx, [ebp+8]
        ; size_t nbyte = second argument on stack
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
;       Note: ECX and EDX will be clobbered, along with the usual EAX
fn_open:
        push    ebp
        mov     ebp, esp
        push    ebx

        ; sys_open
        mov     eax, 5 
        ; char path
        mov     ebx, [ebp+8]
        ;int oflag
        mov     ecx, [ebp+12]
        ; int mode
        ;       Note: Mode is ignored unless oflag has O_CREAT
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
        mov     eax, 6
        ; int fildes
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
        mov     eax, 91
        ; void *addr
        mov     ebx, [ebp+8]
        ; size_t len
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
        mov     eax, 19
        ; int fildes
        mov     ebx, [ebp+8]
        ; off_t offset
        mov     ecx, [ebp+12]         
        ; int whence
        mov     edx, [ebp+16]
        int     0x80

        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
