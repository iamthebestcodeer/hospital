; NASM x86-64, System V ABI. See tools/generate.py.
bits 64
default rel
extern GetRandomValue
extern game
extern sincosf
; Handwritten x86-64 System V implementation, converted to NASM syntax.
; Lowest-free-slot allocation is unchanged, but the scan resumes after each
; allocation: earlier slots cannot become free during this synchronous call.
; O(MAX_PARTICLES + count) instead of O(MAX_PARTICLES * count).
%include "src/include/layout.inc"
section .rodata
align 4
__gas_Lten:
dd 0x41200000
__gas_Ldeg_to_rad:
dd 0x3c8efa35
__gas_Lminus_half:
dd 0xbf000000
section .text
global SpawnParticles
SpawnParticles:
    test edi, edi
    jle __gas_Lreturn
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    movq qword [rsp], xmm0
    movss dword [rsp+8], xmm1
    movss dword [rsp+12], xmm2
    movss dword [rsp+16], xmm3
    mov byte [rsp+20], cl
    mov ebx, edi
    mov r14d, esi
    mov r15d, edx
    lea r12, [rel GAME_PARTICLES+game]
    lea r13, [r12+PARTICLE_SIZE*PARTICLE_COUNT]
__gas_Lscan:
    cmp byte [r12+P_ACTIVE], 0
    je __gas_Lallocate
__gas_Ladvance:
    add r12, PARTICLE_SIZE
    cmp r12, r13
    jb __gas_Lscan
    jmp __gas_Ldone
__gas_Lallocate:
    mov byte [r12+P_ACTIVE], 1
    mov rax, qword [rsp]
    mov qword [r12+P_POSITION], rax
    mov dword [r12+P_START_COLOR], r14d
    mov dword [r12+P_END_COLOR], r15d
    mov dword [r12+P_LIFE], 0
    mov edi, 5
    mov esi, 20
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    divss xmm0, dword [rel __gas_Lten]
    movss dword [r12+P_MAX_LIFE], xmm0
    mov edi, 8
    mov esi, 12
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    divss xmm0, dword [rel __gas_Lten]
    mulss xmm0, dword [rsp+12]
    movss dword [r12+P_START_SIZE], xmm0
    movss xmm0, dword [rsp+16]
    movss dword [r12+P_END_SIZE], xmm0
    mov al, byte [rsp+20]
    mov byte [r12+P_GRAVITY], al
    xor edi, edi
    mov esi, 360
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    mulss xmm0, dword [rel __gas_Ldeg_to_rad]
    lea rdi, [rsp+24]
    lea rsi, [rsp+28]
    call sincosf wrt ..plt
    mov edi, 10
    cvttss2si esi, dword [rsp+8]
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    movss xmm1, dword [rsp+28]
    mulss xmm1, xmm0
    movss dword [r12+P_VELOCITY], xmm1
    mulss xmm0, dword [rsp+24]
    movss dword [r12+P_VELOCITY+4], xmm0
    cmp byte [rsp+20], 0
    je __gas_Lnext
    pxor xmm1, xmm1
    comiss xmm0, xmm1
    jbe __gas_Lnext
    mulss xmm0, dword [rel __gas_Lminus_half]
    movss dword [r12+P_VELOCITY+4], xmm0
__gas_Lnext:
    dec ebx
    jnz __gas_Ladvance
__gas_Ldone:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
__gas_Lreturn:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
