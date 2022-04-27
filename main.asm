%macro sys_call 1
	mov rax, %1
	syscall
%endmacro

	section .data

msg:	db "HTTP/1.1 200 OK",13,10,"content-length: 28",13,10,"content-type: text/html",13,10,10,"<h1>Hello, NASM server!</h1>"
msg_l:	equ $-msg

	section .text
	global _start

_start: mov rdi, 2	; family   = PF_INET
	mov rsi, 1	; type     = SOCK_STREAM
	mov rdx, 6	; protocol = IPPROTO_TCP
	sys_call 41	; create socket (SYS_SOCKET, opcode 41)

	; bind
	push qword 0	; end struct on stack (arguments get pushed in reverse order)
	push word 0x6022 ; move port=htons(8800) on stack
	push word 2	; move family onto stack AF_INET=2
	mov rdi, rax	; save listen descriptor
	mov rsi, rsp	; save sokaddr ptr
	mov rdx, 0x10	; save addrlen
	sys_call 49	; bind socket (SYS_BIND, opcode 49) 

	; listen
	mov rsi, 64	; backlog=64
	sys_call 50	; listen socket (SYS_LISTEN, opcode 50)

	jmp _accept

	; garbage finished children
_clr:	push qword rdi
	mov rdi, -1
	mov rsi, 0
	mov rdx, 1	; =WNOHANG
	mov r10, 0
	sys_call 61	; wait any children (SYS_WAIT4)
	pop qword rdi
	test rax, rax
	jnz _clr

_accept:
	; accept new connection
	mov rsi, 0
	mov rdx, 0
	sys_call 43	; accept socket (SYS_ACCEPT, opcode 43)

	; fork
	mov rsi, rax	; move return value of SYS_SOCKET into esi (file descriptor for accepted socket, or -1 on error)
	sys_call 57	; create a new process by request (SYS_FORK, opcode 2)

	test rax, rax	; if return value of SYS_FORK in eax is zero we are in the child process
	jnz _clr	; jmp on new listen iterration if it not child process

	; write
	mov rdi, rsi	; move accepted file descriptor
	mov rsi, msg	; move reponse address
	mov rdx, msg_l	; move response size 
	sys_call 1	; write on socket (SYS_WRITE)
	mov rdi, rdi
	sys_call 3	; close listen descriptor (SYS_CLOSE)
	mov rdi, rsi
	sys_call 3	; close accept descriptor (SYS_CLOSE)

_exit:	mov rdi, 0	; 0 errors
	sys_call 60	; invoke SYS_EXIT

