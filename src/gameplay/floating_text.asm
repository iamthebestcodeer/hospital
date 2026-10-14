; gameplay/floating_text: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern GetRandomValue
extern game
extern strncpy
extern vsnprintf

section .rodata align=16
align 16
fp_100: dd 100.0

section .text
text_allocate:
    xor eax, eax
    lea r8, [game+G_floatingTexts]
    mov ecx, 100
    movss xmm1, [fp_100]
.slot:
    cmp byte [r8+F_active], 0
    je .free
    movss xmm2, [r8+F_lifetime]
    ucomiss xmm2, xmm1
    jae .next
    jp .next
    movaps xmm1, xmm2
    mov rax, r8
.next:
    add r8, F_SIZE
    dec ecx
    jnz .slot
    ret
.free:
    mov rax, r8
    ret

text_initialize:
    FRAME 16
    mov rbx, rdi
    mov r12d, esi
    mov r13d, edx
    movq [rsp], xmm0
    mov byte [rbx+F_active], 1
    mov edi, -5
    mov esi, 5
    call GetRandomValue wrt ..plt
    mov r14d, eax
    mov edi, -5
    mov esi, 5
    call GetRandomValue wrt ..plt
    movd xmm1, r14d
    movd xmm2, eax
    punpckldq xmm1, xmm2
    cvtdq2ps xmm1, xmm1
    movq xmm0, [rsp]
    addps xmm0, xmm1
    movq [rbx+F_position], xmm0
    mov [rbx+F_color], r12d
    mov [rbx+F_critical], r13b
    test r13b, r13b
    jnz .critical
    FLOAT dword [rbx+F_lifetime], 1.5
    FLOAT dword [rbx+F_velocityY], -40.0
    jmp .done
.critical:
    FLOAT dword [rbx+F_lifetime], 2.0
    FLOAT dword [rbx+F_velocityY], -80.0
.done:
    RETURN 16

global AddFloatingText
AddFloatingText:
    FRAME 16
    movq [rsp], xmm0
    mov r12, rdi
    mov r13d, esi
    mov r14d, edx
    call text_allocate
    test rax, rax
    jz .done
    mov rbx, rax
    mov rdi, rbx
    mov esi, r13d
    mov edx, r14d
    movq xmm0, [rsp]
    call text_initialize
    lea rdi, [rbx+F_text]
    mov rsi, r12
    mov edx, 31
    call strncpy wrt ..plt
    mov byte [rbx+F_text+31], 0
.done:
    RETURN 16

global AddFloatingTextFmt
AddFloatingTextFmt:
    FRAME 272
    movq [rsp], xmm0
    mov r12d, edi
    mov r14d, esi
    mov r13, rdx
    ; Register save area at +80: 6 GP slots followed by 8 XMM slots.
    mov [rsp+104], rcx
    mov [rsp+112], r8
    mov [rsp+120], r9
    movaps [rsp+144], xmm1
    movaps [rsp+160], xmm2
    movaps [rsp+176], xmm3
    movaps [rsp+192], xmm4
    movaps [rsp+208], xmm5
    movaps [rsp+224], xmm6
    movaps [rsp+240], xmm7
    call text_allocate
    test rax, rax
    jz .done
    mov rbx, rax
    mov rdi, rbx
    mov esi, r12d
    mov edx, r14d
    movq xmm0, [rsp]
    call text_initialize
    mov dword [rsp+48], 24      ; gp_offset: edi, esi, rdx are fixed args
    mov dword [rsp+52], 64      ; fp_offset: xmm0 holds the fixed Vector2
    lea rax, [rbp+16]
    mov [rsp+56], rax           ; caller's first stack argument
    lea rax, [rsp+80]
    mov [rsp+64], rax
    lea rdi, [rbx+F_text]
    mov esi, 32
    mov rdx, r13
    lea rcx, [rsp+48]
    call vsnprintf wrt ..plt
    mov byte [rbx+F_text+31], 0
.done:
    RETURN 272

section .note.GNU-stack noalloc noexec nowrite progbits
