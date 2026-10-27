.intel_syntax noprefix
.global atoi

atoi:
        xor rax, rax            # Clear accumulator
        xor r10, r10            # Sign flag (0 = positive, 1 = negative)

        test rdi, rdi
        jz .L_atoi_ret

        # Look for leading minus sign configuration
        cmp byte ptr [rdi], 0x2D 
        jne .L_atoi_loop
        inc r10                 # Flag number as signed negative
        inc rdi                 # Advance pointer past the '-' symbol

.L_atoi_loop:
        movzx rcx, byte ptr [rdi] 
        test rcx, rcx           # Break on null terminator
        jz .L_atoi_done

        # Strict boundary validation: Drop anything outside '0'-'9'
        cmp rcx, 0x30
        jl .L_atoi_done
        cmp rcx, 0x39
        jg .L_atoi_done

        sub rcx, 0x30           # Convert ASCII character to raw integer value
        imul rax, 10            # Shift base-10 value space left
        add rax, rcx            # Append integer value
        inc rdi                 # Move forward 1 byte
        jmp .L_atoi_loop

.L_atoi_done:
        test r10, r10           
        jz .L_atoi_ret
        neg rax                 # Apply absolute sign conversion

.L_atoi_ret:
        ret
