.intel_syntax noprefix
.global itoa

itoa:
        push rbp
        mov rbp, rsp
        sub rsp, 32             # Allocate 32 bytes of secure scratch memory
                                # Memory extends backwards from rbp to [rbp - 32]

        # Handle explicit zero case
        test rdi, rdi
        jz .L_itoa_zero

        xor r11, r11            # r11 = tracks final string length counter
        lea r9, [rbp]           # Start tracking buffer slots from top downwards

        cmp rdi, 0
        jge .L_positive_path

        # Negative configuration: Safe magnitude conversion
        not rdi
        add rdi, 1
        mov rax, rdi            
        
        # We process the digits backwards first, but note that we need to add the '-'
        # at the absolute front later.
        mov r10, 1              # Remember that this number is negative (r10 flag = 1)
        jmp .L_prepare_divisor

.L_positive_path:
        mov rax, rdi            
        xor r10, r10            # Remember that this number is positive (r10 flag = 0)

.L_prepare_divisor:
        mov r8, 10              

.L_divide_loop:
        xor rdx, rdx            
        div r8                  # RAX = quotient, RDX = remainder
        add dl, 0x30            # Convert remainder to ASCII digit
        
        dec r9                  # Move cursor backwards 1 byte
        mov byte ptr [r9], dl   # Write digit safely to memory buffer
        inc r11                 # Increment string length counter
        
        test rax, rax           
        jnz .L_divide_loop      

        # If it was negative, prepend the '-' character directly in front of our digits
        test r10, r10
        jz .L_flush_buffer
        
        dec r9                  # Move cursor backwards one more byte
        mov byte ptr [r9], 0x2D # Write '-' character into the buffer space
        inc r11                 # Add 1 to total string length counter

.L_flush_buffer:
        # Now r9 points EXACTLY to the first character ('-' or first digit)
        # and r11 contains the EXACT number of characters to print.
        mov rax, 1              # sys_write
        mov rdi, 1              # stdout
        mov rsi, r9             # Address of our completed text string
        mov rdx, r11            # Exact length of bytes to write
        syscall

        mov rax, r11            # Return final length in rax
        mov rsp, rbp            # Restore stack safety
        pop rbp
        ret

.L_itoa_zero:
        mov byte ptr [rbp - 32], 0x30 # Place '0' in scratch memory space
        mov rax, 1              # sys_write
        mov rdi, 1              # stdout
        lea rsi, [rbp - 32]     
        mov rdx, 1              
        syscall
        
        mov rax, 1              
        mov rsp, rbp            
        pop rbp
        ret
