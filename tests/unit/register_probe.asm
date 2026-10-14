; Check callee-saved registers across a callback into the real game systems.
bits 64
section .text
global av_test_preserves_registers
av_test_preserves_registers:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov ebp, 0x12340100
    mov ebx, 0x12340200
    mov r12d, 0x12340300
    mov r13d, 0x12340400
    mov r14d, 0x12340500
    mov r15d, 0x12340600
    call rdi
    xor eax, eax
    cmp rbp, 0x12340100
    jne .return
    cmp rbx, 0x12340200
    jne .return
    cmp r12, 0x12340300
    jne .return
    cmp r13, 0x12340400
    jne .return
    cmp r14, 0x12340500
    jne .return
    cmp r15, 0x12340600
    jne .return
    mov eax, 1
.return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
