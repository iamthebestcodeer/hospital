; domain/damage: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"


section .rodata align=16
align 16
fp_one: dd 1.0
align 16
fp_half: dd 0.5
align 16
fp_100: dd 100.0
align 16
fp_neg99: dd -99.0

section .text
global CalculateDamage
CalculateDamage:
    movss xmm1, [fp_one]         ; energy multiplier
    movaps xmm2, xmm1           ; physical multiplier
    mov ecx, [rsi+E_statusCount]
    lea rax, [rsi+E_status]
    test ecx, ecx
    jle .resistance
.status:
    mov edx, [rax]
    cmp edx, 8
    jne .physical_status
    mulss xmm1, [rax+8]
.physical_status:
    ; Keep exact enum tests: unknown combinations must not count.
    cmp edx, 16
    je .physical_mult
    cmp edx, 32
    jne .next
.physical_mult:
    mulss xmm2, [rax+8]
.next:
    add rax, 16
    dec ecx
    jnz .status
.resistance:
    test edi, edi
    jz .physical
    cmp edi, 1
    jne .minimum
    mulss xmm0, xmm1
    movss xmm1, [rsi+E_energyResist]
    jmp .reduce
.physical:
    mulss xmm0, xmm2
    movss xmm1, [rsi+E_armor]
.reduce:
    ; fmaxf(resistance,-99) also picks -99 for a NaN resistance.
    maxss xmm1, [fp_neg99]
    addss xmm1, [fp_100]
    movss xmm2, [fp_100]
    divss xmm2, xmm1
    mulss xmm0, xmm2
.minimum:
    maxss xmm0, [fp_half]
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
