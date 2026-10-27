.intel_syntax noprefix
.global _start
.extern itoa
.extern atoi

_start:
	push rbp		# Push callee save register
	push r12
	push r13
	push r14

	xor r12, r12		# Clear r12 for argc counter
	xor r13, r13		# Clear r13 for storage of argv pointer 
	xor r14, r14		# String marker buffer
	mov r12, 0x02

	lea rbp, [rsp+32]	# Set rbp to argc
	
        mov rcx, [rbp]          # load Argc
        cmp rcx, 0x02           # Ensure a user argument is provided (1 is the name of the program)
        jb no_args

        push rbx                # Callee save
        xor rbx, rbx            # Use this register to track the position within the argv[1] buffer

        mov rbx, [rbp+16]       # Load the argv[1] pointer into rbx

        sub rsp, 0x20           # Give 32 bytes of scratch space
        xor rcx, rcx            # Use this value to track our position within rsp and the size of the buffer

.loop:
        cmp byte ptr [rbx], 0x00        # Check whether we have reached the null terminator
        jz clean_exit

        mov al, byte ptr [rbx] 	        # Load the value into the al register to prevent memory to memory mov

	cmp byte ptr [rbx], 0x5c	# Validate whether the character is a backslash
	jz process_escape_char	

	cmp byte ptr [rbx], 0x25	# Compare character to a format marker
	jz process_format_marker

	character_processed:
        mov byte ptr [rsp], al      # Place the value into our buffer, + 8 because i pushed rbx

	call print_text

        inc rbx                         # Move the reading pointer up by 1 byte
        inc rcx                         # Increase our counter

        jmp .loop

process_format_marker:
	inc rbx
	
	cmp byte ptr [rbx], 0x25 	# compare to % symbol
	jz process_percent_sign

	cmp byte ptr [rbx], 0x64	# compare to %d
	jz process_decimal_marker

	cmp byte ptr [rbx], 0x73	# compare to %s
	jz process_string_marker

	nop

	process_percent_sign:
	mov al, 0x25			# Set al to '%' 
	jmp character_processed

process_string_marker:
	xor rcx, rcx
	inc r12
	mov r13, [rbp+r12*8]

	check_next_character:
		cmp byte ptr [r13], 0x00
		jz output_string

		movzx r14, byte ptr [r13]
		mov byte ptr [rsp+rcx], r14b
		inc rcx
		inc r13
		jmp check_next_character

	output_string:
		mov rax, 0x01
		mov rdi, 0x01
		mov rsi, rsp
		mov rdx, rcx
		syscall

		inc rbx
		inc rcx

		jmp .loop	

process_decimal_marker:
	inc r12
	mov r13, [rbp+r12*8]	 	# Move the argument pointer into r13

	cmp byte ptr [r13], 0x00 	# Compare the characater to a null pointer
	jz character_processed

	push rcx			# caller save	

	mov rdi, r13	 
	call atoi

	mov rdi, rax
	call itoa

	pop rcx				# retrieve rcx

	inc rbx
	inc rcx

	jmp .loop

process_escape_char:
	inc rbx				# Increment the buffer pointer to access the escaped character

	cmp byte ptr [rbx], 0x6e	# Compare to n
	jz process_new_line

	cmp byte ptr [rbx], 0x5c	# compare to \
	jz process_backslash

	cmp byte ptr [rbx], 0x78	# Compare to x
	jz process_byte_escape

	process_new_line:		# Set al to a new line
	mov al, 0x0a
	jmp character_processed

	process_backslash:		# Set al to '\'
	mov al, 0x5c

	jmp character_processed	

process_byte_escape:
	xor r13, r13	# Hex counter
	xor r14, r14	# Buffer Nibble 1	
	xor rdx, rdx	# Buffer Nibble 2

	byte_escape_loop:
	cmp r13, 0x02
	jz load_into_al

	inc rbx
	mov cl, byte ptr [rbx]

	cmp cl, 0x39
	ja hex_check

	process_digit:
	sub cl, 0x30
	cmp r13, 0x00
	jz load_buffer_one
	jmp load_buffer_two

	hex_check:
	cmp cl, 0x46
	ja process_hex_lower
	jmp process_hex_upper

	process_hex_upper:
	sub cl, 0x41
	add cl, 0xA
	cmp r13, 0x00
	jz load_buffer_one
	jmp load_buffer_two

	process_hex_lower:
	sub cl, 0x61
	add cl, 0xA
	cmp r13, 0x00
	jz load_buffer_one
	jmp load_buffer_two

	
	load_buffer_one:
	inc r13
	mov r14b, cl
	shl r14, 0x04
	jmp byte_escape_loop

	load_buffer_two:
	inc r13
	mov dl, cl
	jmp byte_escape_loop

	load_into_al:
	or r14, rdx
	mov al, r14b
	jmp character_processed

print_text:
        mov rdi, 0x01           # Set FD to stdout
        lea rsi, [rsp+8]            # Set buffer to rsp
        mov rdx, 0x01           # Set buffer size to counter
        mov rax, 0x01           # Set syscall to write()
        syscall

	ret

no_args:
        mov rax, 60
        mov rdi, 1
        syscall

clean_exit:
        add rsp, 0x20   # Clean up stack frame
        pop rbx         # Retrieve original RBX in epilogue
	pop r14
	pop r13
	pop r12		# Retrieve original r12 in epilogue
	pop rbp		# Retrieve original RBP in epilogue
	pop r14

        mov rdi, 0x00
        mov rax, 60
        syscall
