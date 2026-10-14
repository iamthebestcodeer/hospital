; Call the entry point directly: no C adapter may hide a callee's clobbers.
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
    mov r11, rdi
    mov rax, rsi                  ; six GP arguments, then eight packed FP arguments
    movq xmm0, [rax+48]
    movq xmm1, [rax+56]
    movq xmm2, [rax+64]
    movq xmm3, [rax+72]
    movq xmm4, [rax+80]
    movq xmm5, [rax+88]
    movq xmm6, [rax+96]
    movq xmm7, [rax+104]
    mov rdi, [rax]
    mov rsi, [rax+8]
    mov rdx, [rax+16]
    mov rcx, [rax+24]
    mov r8, [rax+32]
    mov r9, [rax+40]
    mov rbp, 0x12345678abcdef01
    mov rbx, 0x12345678abcdef02
    mov r12, 0x12345678abcdef03
    mov r13, 0x12345678abcdef04
    mov r14, 0x12345678abcdef05
    mov r15, 0x12345678abcdef06
    mov eax, 8                   ; upper bound for variadic XMM argument count
    call r11
    xor eax, eax
%macro CHECK_REGISTER 2
    mov r10, %2
    cmp %1, r10
    jne .return
%endmacro
    CHECK_REGISTER rbp, 0x12345678abcdef01
    CHECK_REGISTER rbx, 0x12345678abcdef02
    CHECK_REGISTER r12, 0x12345678abcdef03
    CHECK_REGISTER r13, 0x12345678abcdef04
    CHECK_REGISTER r14, 0x12345678abcdef05
    CHECK_REGISTER r15, 0x12345678abcdef06
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
; Negative controls verify that every individual clobber is detected.
%macro CLOBBER 1
global av_test_clobber_%1
av_test_clobber_%1:
    xor %1, %1
    ret
%endmacro
CLOBBER rbp
CLOBBER rbx
CLOBBER r12
CLOBBER r13
CLOBBER r14
CLOBBER r15
section .note.GNU-stack noalloc noexec nowrite progbits
