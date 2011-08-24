; vim: ft=nasm
; Usage: asmscan <host>
; Author: Eugene Ma

; ==============================================================================

section .data
        ; Error messages to call before exit
        open_error_msg:         db 'Error: sys_open failed', 10, 0
        socket_error_msg:       db 'Error: sys_socket failed', 10, 0
        select_error_msg:       db 'Error: sys_select failed', 10, 0
        connect_error_msg:      db 'Error: sys_connect failed', 10, 0
        sendto_error_msg:       db 'Error: sys_sendto failed', 10, 0
        recvfrom_error_msg:     db 'Error: sys_recvfrom failed', 10, 0
        parse_error_msg:        db 'Error: malformed ip address', 10, 0
        usage_msg:              db 'Usage: asmscan <target ip>', 10, 0
        
        ; Formatting strings: ex. printf("%d open", port)
        port_open_fmtstr        db ' open', 10, 0
        port_closed_fmtstr      db ' closed', 10, 0

        latency_fmtstr1:        db 'Latency: ', 0
        latency_fmtstr2:        db ' ms', 10, 0

        ; Pointer to length of socket address 
        sockaddrlen_addr:       dd sockaddrlen

        ; The (pseudo-)random number generator we will use; urandom(4) is
        ; sufficient and cheap 
        devrpath:               db '/dev/urandom', 0

; ==============================================================================

section .bss
        ; This struct needs to be filled in before using a sockets
        ; struct sockaddr_in {
        ;       short int          sin_family;  // Address family, AF_INET
        ;       unsigned short int sin_port;    // Port number
        ;       struct in_addr     sin_addr;    // Internet address
        ;       unsigned char      sin_zero[8]; // Same size as struct sockaddr
        ; };
        sockaddr:               resb (2+2+4+8)
        sockaddrlen             equ $-sockaddr

        ; The bitmap used to track living sockets and passed to select 
        ; typedef struct {
        ;       unsigned long fds_bits [__FDSET_LONGS];
        ; } __kernel_fd_set;
        masterfds:              resd 32
        masterfdslen            equ 32                       
        wrfds:                  resd 32                
        rdfds:                  resd 32                 

        ; Maximum number of sockets to open in parallel 
        max_parallel_sockets    equ 64

        ; For storing socket descriptors we we care about
        socketarray:           resd max_parallel_sockets        
        ; Used in conjunction with socketarray to map socket to port
        portarray:             resw max_parallel_sockets        

        ; The source and target IPv4 addresses in network byte order
        victimaddr:             resd 1                  
        myaddr:                 resd 1                 

        ; Temporary storage for strings
        writebuf:               resb 256                 

        ; Maximum time to wait for incoming packets in usec
        max_timeout             equ 500000      

        ; struct timeval {
        ;     int tv_sec;     // seconds
        ;     int tv_usec;    // microseconds
        ; }; 
        ; This can be mangled by us or the kernel at any time!
        tv_volatile:            resd 2                  
        ; This is always zero
        tv_zero:                resd 2                  
        ; This is the default delay we use between sending packets
        tv_master:              resd 2

        ; The global buffers we use to send and recieve datagrams
        sendbuf:                resb 1024               
        recvbuf:                resb 1024             
        sendbuflen:             resd 1                 
        recvbuflen:             resd 1               

        ; For storing the file descriptor mapped to /dev/urandom
        devrfd:                 resd 1

        ; Useful constants 
        iphdrlen                equ 20                  
        icmphdrlen              equ 8                  
        EINPROGRESS             equ -115
        EAGAIN                  equ -11
        TH_SYN                  equ 0x2 
        TH_RST                  equ 0x3 

; ==============================================================================

section .text
        global  _start

_start:
        mov ebp, esp
        ; String operations will hereby increment pointers by default
        cld                             

check_argc:
        ; We want to make sure program was invoked with a single argument
        cmp [ebp], dword 2
        jne wrong_argument_count
        jmp parse_argv
        
        wrong_argument_count:
        ; Print usage string
        ; Exit with exit code 1
        push dword -1 
        push dword usage_msg
        call premature_exit

parse_argv:
        ; Parse first argument and store octets into buffer
        push dword victimaddr           
        push dword [ebp + 8]           
        call parse_octets             
        add esp, 8                   

        ; Check return value
        test eax, eax      
        js malformed_ip_error           
        jmp load_sockaddr

        malformed_ip_error:
        ; The IPv4 address didn't look right
        ; Print error message complaining about malformed ip
        ; Exit with exit code 1
        push dword -1
        push dword parse_error_msg            
        call premature_exit                  

load_sockaddr: 
        mov edi, sockaddr
        ; Set the protocol family to AF_INET
        mov ax, 2
        stosw
        ; Zero out the port for now
        xor ax, ax
        stosw
        ; IPv4 address was valid; point socket address to it
        ; From now on, use this struct when sending packets to host
        mov eax, [victimaddr]
        stosd

check_root:
        ; If root user, attempt ICMP ping and perform SYN scan
        call sys_getuid
        cmp eax, 0
        je isr00t

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; non-root users start here

; Attempt to establish TCP connections for ports 0-1023, printing port if successful 
; Scan ports 0-1023, current port always stored in ebx
xor ebx, ebx 
connect_scan_loop: 
        ; Reset index into sockets, portarray
        xor esi, esi 
        ; Store nfds (= 1 + maximum fd) for sys_select
        xor edi, edi 
        connect_scan_gather_sockets:
                ; Create socket with arguments
                ; SOCK_STREAM|O_NONBLOCK, IPPROTO_TCP
                push dword 6 
                push dword (1 | 4000q) 
                call spawn_socket
                add esp, 8

                ; Check return value
                test eax, eax
                ; sys_socket failed with -errno
                js connect_scan_socket_error 
                jmp connect_scan_save_socket

                connect_scan_socket_error:
                ; We had trouble creating the socket
                ; Save socket(2) errno on stack
                push eax 
                push socket_error_msg
                call premature_exit

                connect_scan_save_socket:
                ; Socket seems good, save it to our array and map the port 
                mov [socketarray + 4 * esi], eax 
                mov [portarray + 2 * esi], word bx 
                inc esi
                ; Update nfds: max(nfds, fd)
                cmp eax, edi
                cmovg edi, eax

                connect_scan_attempt_connect:
                ; Initiate TCP handshake to port
                ; Load port to sockaddr struct in htons() order
                mov [sockaddr + 2], byte bh 
                mov [sockaddr + 3], byte bl 
                push sockaddrlen
                push sockaddr        
                push eax 
                call sys_connect
                add esp, 12

                connect_scan_check_connect_errno:
                ; We expect to see EAGAIN or EINPROGRESS
                cmp eax, EINPROGRESS
                je connect_scan_socket_in_progress
                cmp eax, EAGAIN
                je connect_scan_socket_in_progress
                cmp eax, 0
                ; This would be very unexpected!
                je connect_scan_socket_complete

                ; Connect failed for reasons other than being "in progress"
                ; Save connect(2) -errno on stack
                push eax 
                push connect_error_msg
                call premature_exit

                connect_scan_socket_complete:
                connect_scan_socket_in_progress:
                ; "Gather" next socket-port combination or proceed to next step
                inc word bx
                cmp esi, max_parallel_sockets
                jl connect_scan_gather_sockets

        connect_scan_sleep:
        ; Copy default timeout to tv_volatile
        mov [tv_volatile + 4], dword 500000
        ; Wait for requested connects to finish
        push tv_volatile
        push dword 0
        push dword 0
        push dword 0
        push dword 0
        call sys_select
        add esp, 20

        connect_scan_monitor:
        ; Copy masterfds to wrfds 
        mov esi, masterfds
        mov edi, wrfds
        mov ecx, masterfdslen
        rep movsd
        ; Wake up and smell the ashes...
        ; Time to check up on our sockets
        push tv_zero
        push dword 0
        push dword wrfds
        push dword 0
        ; nfds = maximum fd + 1
        inc edi 
        push edi
        call sys_select
        add esp, 20

        ; Check return value
        cmp eax, 0
        ; All sockets will block on write, skip to next iteration
        je connect_scan_cleanup
        jns connect_scan_check_for_connected_sockets 

        ; We had some sort of trouble with select(2)
        ; Save select(2) -errno on stack 
        push eax
        push select_error_msg
        call premature_exit

        connect_scan_check_for_connected_sockets:
        ; Check wrfds for our sockets
        ; Reset index into socket array
        xor esi, esi
        connect_scan_iterate_through_fds:
                ; Check if write_blocks:
                ; Fetch file descriptor
                mov eax, [socketarray + 4 * esi]
                bt [wrfds], eax

                ; This port didn't respond to our TCP request:
                ; this means it was probably filtered
                jnc connect_scan_port_was_filtered 

                connect_scan_send_empty_packet:
                ; Seems like the socket can be written to
                ; Let's try to send an empty dud packet to the host
                push dword 0
                push dword 0
                push eax
                call sys_write
                add esp, 12 
                test eax, eax
                ; We had trouble sending: 
                ; the port was probably closed
                js connect_scan_port_was_closed
                
                connect_scan_print_port:
                ; We found an open port!
                ; Convert the port number to a printable string
                push port_open_fmtstr
                movzx eax, word [portarray + 2 * esi]
                push eax
                call print_port
                add esp, 4

                connect_scan_port_was_filtered:
                connect_scan_port_was_closed:
                connect_scan_check_next_socket:
                inc esi
                cmp esi, max_parallel_sockets
                jl connect_scan_iterate_through_fds

        connect_scan_cleanup:
        ; Kill all the sockets we opened 
        call free_all_sockets
        ; Check if we're done
        cmp bx, word 1024 
        jl connect_scan_loop
        jmp exit

isr00t:
ping_host:
        ;;; Send an ICMP echo packet, and wait for an ICMP request packet ;;;

        create_icmp_socket:
        ; To create a raw socket, user need root permissions
        ; SOCK_RAW|O_NONBLOCK, IPPROTO_ICMP
        push dword 1                    
        push dword (3 | 4000q)         
        call spawn_socket                 
        add esp, 8                  

        ; Check return value
        test eax, eax                   
        ; Give up immediately if we couldn't create an icmp socket
        js create_icmp_socket_failed
        ; Store the raw socket file descriptor in socket array
        mov [socketarray], eax             
        jmp build_icmp_packet

        create_icmp_socket_failed:
        ; We had trouble creating the socket, print error message and exit
        ; Save socket(2) -errno on stack
        push eax 
        push socket_error_msg
        call premature_exit

        build_icmp_packet:
        ; Build an ICMP packet with message type 8 (Echo request). The kernel
        ; will craft the IP header for us because IP_HDRINCL is disabled by
        ; default, so we don't build the IP header.
        mov edi, sendbuf            
        ; Type: 8 (Echo request)
        mov al, 8                     
        stosb                           
        ; Code: 0 (Cleared for this type)
        xor al, al                      
        stosb                          
        ; Calculate ICMP checksum later
        xor eax, eax                    
        stosw                         
        ; Identifier: 0, Sequence number: 0
        stosd                           
        ; Now we have to zero out 56 bytes of ICMP padding data
        xor eax, eax                    
        mov ecx, 14                    
        rep stosd                       
        ; Calculate ICMP checksum which includes ICMP header and data
        push dword ((icmphdrlen+56)/2)
        push dword sendbuf        
        call cksum                     
        add esp, 8                  
        ; Store result in packet ICMP header
        mov [sendbuf + 2], word ax   
        ; Before sending/receiving packets, store the length after filling out
        ; the packet.
        mov [sendbuflen], dword (icmphdrlen + 56)

        ;;; Send the packet thrice through the created ICMP socket ;;;

        mov ebx, 3                             
        ; Socket is in non-blocking mode, so we send and receieve data
        ; asynchronously. In this case, send 3 pings and block until socket has
        ; data ready to be read.
        send_ping_requests:
                push dword [socketarray]
                call send_packet
                add esp, 4
                cmp eax, EINPROGRESS   
                je .next
                cmp eax, EAGAIN
                je .next
                test eax, eax
                js ping_send_failed
                .next:
                dec ebx
                jnz send_ping_requests
                jmp calculate_delay

        ping_send_failed:
        ; We had trouble sending data to host, print error message and exit
        ; Save sendto(2) -errno on stack
        push eax
        push sendto_error_msg
        call premature_exit

        calculate_delay:
        ;;; Check how long it takes to get our first ICMP Echo reply ;;;

        ; Timeout is an upper bound on how long to wait before select(2)
        ; returns. Linux will adjust the timeval struct to reflect the time
        ; remaining. Furthermore, we only care about the first reply we get,
        ; and ignore the rest.

        ; Initialize tv_usec to maximum timeout 
        mov edi, tv_volatile
        xor eax, eax
        stosd
        mov eax, max_timeout
        stosd

        ; Copy masterfds to rdfds
        mov esi, masterfds
        mov edi, rdfds
        mov ecx, masterfdslen
        rep movsd
        ; Block until data is ready to be read, or we exceed timeout
        push tv_volatile       
        push dword 0                    
        push dword 0                   
        push rdfds                  
        push dword [socketarray]
        inc dword [esp]
        call sys_select                 
        add esp, 20
                
        ; Check return value
        cmp eax, 0
        js ping_select_failed
        jz ping_no_reply
        jmp ping_get_reply

        ping_select_failed:
        ; Something went wrong with select(2), print error message and exit
        ; Save select(2) errno on stack
        push eax
        push dword select_error_msg
        call premature_exit

        ping_no_reply:
        ; We didn't get a reply from victim, use default timeout instead
        push dword [socketarray]
        call free_socket
        add esp, 4
        mov [tv_master + 4], dword max_timeout
        jmp ping_cleanup
        
        ;;; Receieve data and calculate packet delay ;;;

        ping_get_reply:
        ; First we should calculate the packet delay in tv_volatile
        mov eax, max_timeout
        mov ecx, [tv_volatile + 4]
        sub eax, ecx
        ; Extrapolate the time it would take to send and recieve packets
        shl eax, 2
        mov [tv_master + 4], eax   

        ; Data will be stored in recvbuf
        ; Set number of bytes we expect to receive in packet
        mov [recvbuflen], dword (iphdrlen+icmphdrlen+56)
        push dword [socketarray]
        call recv_packet
        add esp, 4
        
        ; Check return value
        test eax, eax
        js ping_recv_failed
        ; Swipe the IP address from the ICMP packet we recieved 
        ; This should get the destination address field of the IP header
        lea esi, [recvbuf + 16]
        mov edi, myaddr
        movsd
        jmp ping_print_result
                
        ping_recv_failed:
        ; recvfrom(2) failed, print error message and exit
        ; Save recvfrom(2) errno on stack
        push eax
        push dword recvfrom_error_msg
        call premature_exit
        
        ping_print_result:
        ; Convert microseconds to milliseconds
        mov eax, [tv_master + 4]
        mov ecx, 1000
        div ecx

        ; Convert this number to a string
        push writebuf
        push eax
        call ultostr
        add esp, 8

        ; "Latency: %d ms"
        push latency_fmtstr1
        call printstr
        mov [esp], dword writebuf
        call printstr
        mov [esp], dword latency_fmtstr2
        call printstr
        add esp, 4

        ping_cleanup:
        ; We're done with the socket
        push dword [socketarray]
        call free_socket
        add esp, 4

syn_scan:
        ;;; Create raw socket with TCP protocol ;;;
        ; SOCK_RAW|NON_BLOCK, IPPROTO_TCP
        push dword 6
        push dword (3|4000q)
        call spawn_socket
        add esp, 8
        
        ; Check return value
        test eax, eax                   
        ; Give up immediately if we couldn't create a raw tcp socket
        js create_tcp_socket_failed

        ; Store the raw socket file descriptor in socketarray array
        mov [socketarray], eax             
        jmp setup_random_number_generator

        create_tcp_socket_failed:
        ; We had trouble creating the socket, print error message and exit
        ; Save socket(2) -errno on stack
        push eax 
        push socket_error_msg
        call premature_exit

        ;;; Set up pseudo-random number generator ;;;

        setup_random_number_generator:
        ; O_RDONLY
        push dword 0
        ; "/dev/urandom"
        push dword devrpath
        call sys_open
        add esp, 8
        
        ; Check return value 
        test eax, eax
        jns store_devrfd
        ; We were unable to open /dev/urandom
        ; Save open(2) -errno on stack
        push dword eax
        push dword open_error_msg
        call premature_exit

        store_devrfd:
        ; Save the returned file descriptor
        mov [devrfd], eax

        ;;; Send out multiple SYN packets at once, then try to receieve them ;;;

        ; ebx = 0; ebx < high_port; ebx++
        xor ebx, ebx
        syn_scan_loop:
                ; esi = 0; esi < maximum_parallel_ports; esi++
                xor esi, esi
                syn_scan_send_syn_loop:
                        push dword TH_SYN
                        push dword ebx
                        push dword [socketarray]
                        call send_tcp_raw
                        add esp, 12
                                
                        test eax, eax
                        jns syn_scan_send_next_syn
                        ; We had issues sending a SYN packet to the victim
                        ; Push sendto(2) -errno on stack
                        push eax
                        push dword sendto_error_msg
                        call premature_exit

                        syn_scan_send_next_syn:
                        inc esi
                        inc ebx
                        cmp esi, max_parallel_sockets
                        jl syn_scan_send_syn_loop

                syn_scan_sleep:
                ; Give some time for the packets to arrive
                ; Copy tv_master to tv_volatile
                lea esi, [tv_master + 4]
                lea edi, [tv_volatile + 4]
                movsd
                push tv_volatile
                push dword 0
                push dword 0
                push dword 0
                push dword 0
                call sys_select
                add esp, 20

                syn_scan_monitor:
                ; Monitor socket
                mov esi, masterfds
                mov edi, rdfds
                mov ecx, masterfdslen
                rep movsd
                push tv_zero
                push dword 0
                push dword 0
                push dword rdfds
                push dword [socketarray]
                inc dword [esp] 
                call sys_select
                add esp, 20

                ; Check returned value of select in eax
                cmp eax, 0
                je syn_scan_next_batch
                jns syn_scan_recv_reply_loop

                ; Select failed with -errno in eax
                push eax
                push dword select_error_msg
                call premature_exit
                
                syn_scan_recv_reply_loop:
                        ; Read the socket for a response
                        mov [recvbuflen], dword 0xffff
                        push dword [socketarray]
                        call recv_packet
                        add esp, 4

                        ; Check return value of recvfrom in eax
                        test eax, eax
                        ; If signed, then we were unable to read any more data
                        js syn_scan_next_batch
                
                        syn_scan_examine_packet:
                        ; Get IP header length located in last 4 bits of first byte
                        movzx eax, byte [recvbuf]
                        and eax, 0xf
                        ; Convert from words to bytes
                        shl eax, 2
                        ; Store the address of TCP header start in edi
                        mov edi, eax
                        ; Point to flags field
                        add eax, 13
                        ; Bitwise separation of flags in the target byte:
                        ; 0 | 0 | URG | ACK | PSH | RST | SYN | FIN
                        lea esi, [recvbuf + eax]
                        lodsb
                        ; Filter for the flags we're interested in (ACK and SYN)
                        ; ACK = 1, SYN = 1
                        and al, 0x12
                        cmp al, 0x12
                        je syn_scan_port_open
                        jmp syn_scan_recv_reply_loop
                
                        ; The port is considered closed, otherwise
                        push dword port_closed_fmtstr
                        jmp syn_scan_print_port

                        syn_scan_port_open:
                        push dword port_open_fmtstr

                        syn_scan_print_port:
                        ; Extract the port from the TCP header
                        movzx eax, word [recvbuf + edi]
                        xchg al, ah
                        push eax
                        call print_port
                        add esp, 8
                        ; Keep receiving packets until we're unable to
                        jmp syn_scan_recv_reply_loop
                
                syn_scan_next_batch:
                ; Everything seems normal, scan the next batch of ports
                cmp ebx, 1024
                jl syn_scan_loop
        
        syn_scan_done:
        push dword [devrfd]
        call sys_close
        add esp, 4
        call free_all_sockets

exit:
        mov ebp, esp
        mov eax, 1
        xor ebx, ebx
        int 0x80

; ------------------------------------------------------------------------------
; send_tcp_raw
;       Send a raw tcp header to the specified port
;               Expects: stack - socket file descriptor, port, type
;                        devrfd - contains file descriptor mapped to random
;                        number generator device
;               Returns: number of bytes sent in eax, or -errno on error
send_tcp_raw:
        push ebp
        mov ebp, esp
        push edi

        ; Prepare the raw TCP packet to send
        mov edi, sendbuf
        ; Load the source port
        mov ax, 31337
        xchg al, ah
        stosw
        ; Load the destination port
        mov ax, [ebp + 12]
        xchg al, ah
        stosw
        ; SEQ = rand()
        call rand
        stosd
        ; ACK = 0
        xor eax, eax
        stosd
        ; Data offset = 5 << 4 (length of header in dwords)
        mov al, 0x5
        shl al, 4
        stosb
        ; Flags = type; 0x2 = SYN, 0x3 = RST
        xor al, al
        or al, [ebp + 16]
        stosb
        ; Max window size = 4096 bytes
        mov ax, 4096
        xchg al, ah
        stosw
        ; Checksum = 0
        xor ax, ax
        stosw
        ; Urgent pointer = 0 (not used)
        stosw

        ;;; Prepare TCP pseudo-header ;;;
        ; struct pseudo_hdr {
        ;       u_int32_t src;          /* 32bit source ip address*/
        ;       u_int32_t dst;          /* 32bit destination ip address */      
        ;       u_char mbz;             /* 8 reserved bits (all 0)      */
        ;       u_char proto;           /* protocol field of ip header */
        ;       u_int16_t len;          /* tcp length (both header and data) */
        ; }
        ; Load source ip address
        mov eax, [myaddr]
        stosd
        ; Load destination ip address
        mov eax, [victimaddr]
        stosd
        ; 8 reserved bits (all 0)
        xor al, al
        stosb
        ; Protocol field of ip header = IPPROTO_TCP
        mov al, 6
        stosb
        ; Length of TCP header and data (20 + 0) in bytes
        mov ax, 20
        xchg al, ah
        stosw

        ;;; Calculate TCP header + pseudo-header checksum ;;;
        push dword (20+12)
        push sendbuf
        call cksum
        add esp, 8
        ; Store checksum in TCP header
        mov [sendbuf + 16], ax

        ; Set the length in bytes to send
        mov [sendbuflen], dword 20

        ;;; Send the SYN packet! ;;;
        push dword [ebp + 8]
        call send_packet
        add esp, 4

        pop edi
        mov esp, ebp
        pop ebp
        ret

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; cksum:  
;       IP header style checksum for given length in words (16-bit) 
;               Expects: pointer to data, data length in words 
;               Returns: checksum 
cksum:
        push ebp
        mov ebp, esp
        push esi

        ; Address
        mov esi, [ebp + 8]
        ; Length
        mov ecx, [ebp + 12]
        ; The accumulator
        xor edx, edx

        ; For the strange condition that length given was zero
        cmp ecx, 0
        jz .done
        .loop:
                xor eax, eax
                ; Load esi to lower 16 bis of eax
                lodsw
                add edx, eax
                dec ecx 
                jnz .loop

        ; Take the upper 16 bits of edx and add it to lower 16 bits
        mov eax, edx
        and eax, 0xffff
        shr edx, 16
        add eax, edx
        ; Take care of the carry
        mov edx, eax
        shr edx, 16
        add eax, edx
        ; Take the one's complement
        not eax

        .done:
        pop esi
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; printstr: 
;       Print a string to standard output
;               Expects: string address
;               Returns: bytes written, -errno on error
printstr:
        push ebp         
        mov ebp, esp      
        
        push dword [ebp + 8] 
        call strlen         
        add esp, 4         
        
        push eax               
        push dword [ebp + 8]  
        push dword 1         
        call sys_write        
        add esp, 12          

        mov esp, ebp          
        pop ebp              
        ret                 
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; strlen: 
;       Calculate the length of null-terminated string
;               Expects: string address
;               Returns: length in eax
strlen:
        push ebp     
        mov ebp, esp
        push edi

        xor eax, eax
        xor ecx, ecx
        not ecx
        mov edi, [ebp + 8]
        repne scasb
        
        not ecx
        lea eax, [ecx - 1]
        
        pop edi
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; parse_octets:
;       Convert IPv4 address from text to binary form
;               Expects: ip string, destination buffer
;               Returns: 0 in eax, ~0 on error
parse_octets:
        push ebp
        mov ebp, esp
        sub esp, 4
        push ebx
        push esi
        push edi

        mov esi, [ebp + 8]
        mov ebx, [ebp + 12]
        lea edi, [ebp - 4]
        ; This value comes in handy when its on the stack
        push edi
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
                call strtoul
                ; An octet has to be an 8-bit value
                cmp eax, 255
                jg invalid_ip
                ; Now load the next octet into the destination octet buffer 
                mov [ebx], byte al
                count_octets:
                push ebx
                sub ebx, [ebp + 12]
                cmp ebx, 3
                pop ebx
                je last_octet
                cmp [esi - 1], byte '.' 
                jne invalid_ip
                ; We still have more work to do!
                prepare_next_octet:
                ; First, make sure we increment the destination address.
                inc ebx
                ; Finally, reset buffer pointer to start of buffer so we can
                ; write another octet 
                lea edi, [ebp - 4]
                jmp parse_loop
                last_octet:
                ; All four octets are supposedly loaded in the destination
                ; buffer. This means esi is must be pointing to a null byte.
                cmp [esi - 1], byte 0
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
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; strtoul:
;       Convert a number from text to binary form
;               Expects: string address
;               Returns: 32-bit unsigned integer in eax
strtoul:
        push ebp
        mov ebp, esp

        ; Load string address in edx
        mov edx, [ebp + 8]
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
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; ultostr: 
;       Convert an unsigned integer to a C string
;               Expects: 32-bit unsigned integer, buffer 
;               Returns: nothing
ultostr:
        push ebp  
        mov ebp, esp
        push ebx
        push edi
        push esi

        ; Push string characters onto stack in reverse order
        dec esp
        mov [esp], byte 0
        ; ecx counts how many characters to write
        xor ecx, ecx
        inc ecx
        mov eax, [ebp + 8]
        ; This is our divisor
        mov ebx, 10
        ; eax: quotient contains the rest of input number
        ; edx: remainder contains the digit we want to write
        .loop:
                xor edx, edx
                div ebx
                add dl, byte '0'
                dec esp
                mov [esp], byte dl
                inc ecx
                ; Stop if eax is 0
                cmp eax, 0
                jne .loop
        ; Copy chars on stack to destination buffer
        ; They will be in order because stack grows down
        mov esi, esp
        mov edi, [ebp + 12]
        repne movsb
        ; Realign stack pointer
        mov esp, esi

        pop esi
        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; spawn_socket:
;       Create a new socket and add it to masterfds
;               Expects: socket type, protocol
;               Returns: eax - socket fd, -errno if error
spawn_socket:
        push ebp
        mov ebp, esp

        ; push protocol
        push dword [ebp + 12]
        ; push type
        push dword [ebp + 8]
        ; PF_INET by default
        push dword 2
        call sys_socket
        add esp, 12

        ; Check return value
        test eax, eax
        js .done
        
        ; Add it to "master" fd bitfield
        bts [masterfds], eax

        .done:
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; free_socket:
;       Close a socket and remove it from masterfds
;               Expects: socket 
;               Returns: nothing
free_socket:
        push ebp
        mov ebp, esp

        push dword [ebp + 8]
        call sys_close
        add esp, 4
        btr [masterfds], eax

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; free_all_sockets:
;       Close all living sockets 
;               Expects: nothing
;               Returns: nothing
free_all_sockets:
        push ebp
        mov ebp, esp

        ; Initialize bitmap index to 1023, which is the highest file descriptor
        ; that can exist in a fdset.
        mov eax, 1023
        lea ecx, [masterfds + masterfdslen]
        ; Find dword containing highest numbered file descriptor
        .find:
                cmp [ecx], dword 0
                jnz .loop
                sub eax, 32
                sub ecx, 4
                jmp .find

        ; Loop through remaining bits in fdset
        .loop:
                ; Clear bit to zero and store original bit in CF
                btr [masterfds], eax
                ; If bit was set, close the mapped socket
                jc .close
                jmp .next

                .close:
                push eax
                call sys_close
                pop eax

                .next:
                dec eax
                jns .loop

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; premature_exit:
;       Print error message, clean up file descriptors, then exit with exit code
;               Expects: error msg, -errno
;               Returns: nothing
premature_exit:
        push ebp
        mov ebp, esp
        
        ; Print error message
        push dword [ebp + 8]
        call printstr
        add esp, 4

        ; Close file descriptor mapped to /dev/urandom 
        cmp dword [devrfd], 0
        jz premature_exit_close_sockets
        push dword [devrfd]
        call sys_close
        add esp, 4
        
        ; Free all open sockets (raw, icmp, tcp, etc...)
        premature_exit_close_sockets:
        call free_all_sockets

        ; Convert -errno to errno
        mov ebx, [ebp + 12]
        not ebx
        inc ebx
        ; Exit and send errno to shell
        mov eax, 1
        int 0x80

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_getuid:
;       Return the user ID of process
;               Expects: nothing
;               Returns: uid in eax
sys_getuid:
        push ebp
        mov ebp, esp
        
        mov eax, 199
        int 0x80

        mov esp, ebp
        pop ebp
        ret

; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_read:
;       Read from file
;               Expects: fd, buffer, buffer len
;               Returns: number of bytes read, or -errno
sys_read:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 3
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 16]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_write:
;       Write to file
;               Expects: fd, buffer, buffer len
;               Returns: number of bytes written, or -errno
sys_write:
        push ebp
        mov ebp, esp
        push ebx

        mov eax, 4
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 16]
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_close:
;       Close a file descriptor
;               Expects: file descriptor
;               Returns: 0 in eax | -errno in eax if error
sys_close:
        push ebp
        mov ebp, esp
        push ebx
        
        mov eax, 6
        mov ebx, [ebp + 8]
        int 0x80
        
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_open:
;       Open a file descriptor
;               Expects: file descriptor
;               Returns: fd in eax, or -errno if error
sys_open:
        push ebp
        mov ebp, esp
        push ebx
        
        ; int open(const char *pathname, int flags);
        mov eax, 5
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        int 0x80
        
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_connect:
;       Connect a socket       
;               Expects: int socket, address, address length
;               Returns: 0 in eax or -errno on error
sys_connect:
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
        lea ecx, [ebp + 8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_socket: 
;       Create a socket       
;               Expects: int domain, int type, int protocol
;               Returns: 0 in eax or -errno on error
sys_socket:
        push ebp
        mov ebp, esp
        push ebx
        push edi

        mov eax, 102
        mov ebx, 1
        lea ecx, [ebp + 8]
        int 0x80

        pop edi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_select:
;       Wrapper around sys_select
;               Expects: int nfds, fd_set *rdfds, fd_set *wrfds,
;                       fd_set *exceptfds, struct timeval *timeout
;               Returns: total number of fildes set in fd_set structs, -errno if error
sys_select:
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        mov eax, 142
        mov ebx, [ebp + 8]
        mov ecx, [ebp + 12]
        mov edx, [ebp + 16]
        mov esi, [ebp + 20]
        mov edi, [ebp + 24]
        int 0x80

        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_sendto 
;       Send a packet to target host
;               Expects: socket, buffer, length, flags, sockaddr, sockaddrlen
;               Returns: number of characters sent, -errno on error
sys_sendto:
        push ebp
        mov ebp, esp
        push ebx

        ; sys_socketcall = 102
        mov eax, 102
        mov ebx, 11
        lea ecx, [ebp + 8] 
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; sys_recvfrom 
;       Receieve a packet from target host
;               Expects: socket, buffer, length, flags, sockaddr, sockaddrlen
;               Returns: number of characters received, -errno on error
sys_recvfrom:
        push ebp
        mov ebp, esp
        push ebx

        ; sys_socketcall = 102
        mov eax, 102
        mov ebx, 12
        lea ecx, [ebp + 8] 
        int 0x80

        pop ebx
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; send_packet
;       Send a packet to target host
;               Expects: stack - socket
;                        sockaddr - points to target host
;                        sendbuf - filled out for us
;                        sendbuflen - filled out for us
;               Returns: number of bytes sent, or -errno
send_packet:
        push ebp
        mov ebp, esp
        
        push dword sockaddrlen         
        push dword sockaddr           
        push dword 0                 
        push dword [sendbuflen]     
        push dword sendbuf         
        push dword [ebp + 8]      
        call sys_sendto          
        add esp, 24            

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; recv_packet
;       Receive a packet from target host
;               Expects: stack - socket
;                        sockaddr - points to target host
;                        recvbuf - filled out for us
;                        recvbuflen - filled out for us
;               Returns: number of bytes received, or -errno
recv_packet:
        push ebp
        mov ebp, esp
        
        push dword sockaddrlen_addr     
        push dword sockaddr        
        push dword 0                
        push dword [recvbuflen]      
        push dword recvbuf  
        push dword [ebp + 8]  
        call sys_recvfrom    
        add esp, 24            

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; rand
;       Get a random 32-bit integer from /dev/urandom
;               Expects: stack - nothing 
;                        devrfd - fd with read perms mapped to /dev/urandom 
;               Returns: random int in eax
rand:
        push ebp
        mov ebp, esp
        sub esp, 4
        push esi

        lea esi, [ebp - 4]

        push dword 4
        push esi
        push dword [devrfd]
        call sys_read
        add esp, 12

        lodsd

        pop esi
        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; print_port
;       Write to output telling the user if the port was open or closed.       
;               Expects: port, open/closed message buffer
;               Returns: nothing
print_port:
        push ebp
        mov ebp, esp

        ; Convert port number to string 
        push writebuf
        push dword [ebp + 8]
        call ultostr 
        add esp, 8

        ; Print port number
        push dword writebuf 
        call printstr 

        ; Swap buffers
        ; Examples:
        ; printf("%d is closed\n", port);
        ; printf("%d is open\n", port);
        mov eax, [ebp + 12]
        mov [esp], eax
        call printstr
        add esp, 4

        mov esp, ebp
        pop ebp
        ret
; ------------------------------------------------------------------------------
; EOF ==========================================================================
