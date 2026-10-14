; domain/status_effects: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"


section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_half: dd 0.5
align 16
fp_03: dd 0.3

section .text
global ApplyStatusEffect
ApplyStatusEffect:
    test rdi, rdi
    jz .done
    cmp byte [rdi+E_active], 0
    je .done
    test esi, esi
    jz .done
    cmp dword [rdi+E_type], 7
    jne .find
    mulss xmm0, [fp_half]
    cmp esi, 4
    jne .boss_slow
    mulss xmm0, [fp_03]
.boss_slow:
    cmp esi, 1
    jne .find
    mulss xmm1, [fp_half]
.find:
    mov ecx, [rdi+E_statusCount]
    lea rdx, [rdi+E_status]
    xor eax, eax
.scan:
    cmp eax, ecx
    jge .new
    cmp [rdx], esi
    je .existing
    add rdx, 16
    inc eax
    jmp .scan
.existing:
    ucomiss xmm1, [rdx+8]
    ja .replace
    jp .done
    jne .done
    movss xmm2, [rdx+4]
    subss xmm2, [rdx+12]
    ucomiss xmm0, xmm2
    jbe .done
    jp .done
    movss [rdx+4], xmm0
    mov dword [rdx+12], 0
    ret
.replace:
    movss [rdx+8], xmm1
    movss [rdx+4], xmm0
    mov dword [rdx+12], 0
    ret
.new:
    cmp ecx, 6
    jge .done
    mov [rdx], esi
    movss [rdx+4], xmm0
    movss [rdx+8], xmm1
    mov dword [rdx+12], 0
    inc dword [rdi+E_statusCount]
.done:
    ret

global ProcessStatusEffects
ProcessStatusEffects:
    pxor xmm1, xmm1             ; accumulated burn damage
    movss xmm2, [fp_one]        ; speed multiplier
    xor r8d, r8d               ; stunned
    xor ecx, ecx
    mov r9d, [rdi+E_statusCount]
    lea rax, [rdi+E_status]
.loop:
    cmp ecx, r9d
    jge .apply
    movss xmm3, [rax+12]
    addss xmm3, xmm0
    movss [rax+12], xmm3
    ucomiss xmm3, [rax+4]
    jae .expire
    mov edx, [rax]
    cmp edx, 2
    je .burn
    cmp edx, 4
    je .stun
    cmp edx, 1
    jne .advance
    movss xmm3, [fp_one]
    subss xmm3, [rax+8]
    ucomiss xmm3, xmm2
    jae .advance
    jp .advance
    movaps xmm2, xmm3
    jmp .advance
.burn:
    movss xmm3, [rax+8]
    mulss xmm3, xmm0
    addss xmm1, xmm3
    jmp .advance
.stun:
    mov r8d, 1
.advance:
    inc ecx
    add rax, 16
    jmp .loop
.expire:
    dec r9d
    cmp ecx, r9d
    jge .loop
    mov edx, r9d
    shl edx, 4
    movups xmm3, [rdi+rdx+E_status]
    movups [rax], xmm3
    jmp .loop
.apply:
    mov [rdi+E_statusCount], r9d
    ucomiss xmm1, [fp_zero]
    jbe .speed
    movss xmm3, [rdi+E_hp]
    subss xmm3, xmm1
    movss [rdi+E_hp], xmm3
.speed:
    test r8d, r8d
    jnz .stopped
    mulss xmm2, [rdi+E_baseSpeed]
    movss [rdi+E_speed], xmm2
    ret
.stopped:
    mov dword [rdi+E_speed], 0
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
