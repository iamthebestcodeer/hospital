; domain/tower_catalog: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern pow

section .rodata align=16
align 16
fp_one: dd 1.0
align 16
fp_01: dd 0.1
align 16
fp_035: dd 0.35
align 16
fp_015: dd 0.15
align 16
fp_20: dd 20.0
align 16
dp_19: dq 1.9
align 16
dp_150: dq 150.0
align 16
costs: dd 100,250,200,400,800,1000,1500,900,700,850,1100,1300
align 16
aim_tolerance: dd 30.0,12.0,15.0,20.0,30.0,12.0,12.0,30.0,20.0,15.0,20.0,20.0
; damage, range, fire rate, damage type. One 16-byte record per tower.
align 16
tower_stats:
    dd 20.0,150.0,2.5,1
    dd 80.0,130.0,0.5,0
    dd 20.0,140.0,0.0,1
    dd 50.0,180.0,1.1,1
    dd 25.0,160.0,8.0,1
    dd 300.0,400.0,0.8,1
    dd 500.0,9999.0,0.3,0
    dd 30.0,140.0,10.0,0
    dd 10.0,120.0,0.75,1
    dd 50.0,150.0,1.5,1
    dd 80.0,200.0,1.5,1
    dd 200.0,220.0,0.9,1
; Integer tile coordinates, in traversal order.

section .text
global GetTowerCost
GetTowerCost:
    mov eax, 99999
    cmp edi, 12
    jae .done
    lea rdx, [costs]
    mov eax, [rdx+rdi*4]
.done:
    ret

global GetTowerAetherCost
GetTowerAetherCost:
    xor eax, eax
    cmp edi, 4
    jl .done
    mov eax, 99999
    cmp edi, 12
    jae .divide
    lea rdx, [costs]
    mov eax, [rdx+rdi*4]
.divide:
    xor edx, edx
    mov ecx, 20
    div ecx
    add eax, 50
.done:
    ret

global GetAimToleranceDegrees
GetAimToleranceDegrees:
    movss xmm0, [fp_20]
    cmp edi, 12
    jae .done
    lea rax, [aim_tolerance]
    movss xmm0, [rax+rdi*4]
.done:
    ret

global ConfigureTowerStats
ConfigureTowerStats:
    FRAME 16
    mov rbx, rdi
    mov dword [rbx+T_stats+S_xpToNextLevel], 99999
    cmp dword [rbx+T_type], 3
    ja .base_stats
    mov eax, [rbx+T_stats+S_level]
    cmp eax, 3
    jge .base_stats
    test eax, eax
    jg .effective_level
    mov eax, 1
.effective_level:
    dec eax
    pxor xmm1, xmm1
    cvtsi2sd xmm1, eax
    movsd xmm0, [dp_19]
    call pow wrt ..plt
    mulsd xmm0, [dp_150]
    cvttsd2si eax, xmm0
    mov [rbx+T_stats+S_xpToNextLevel], eax
.base_stats:
    mov eax, [rbx+T_type]
    cmp eax, 12
    jae .done
    lea rdx, [tower_stats]
    shl eax, 4
    movups xmm0, [rdx+rax]
    movups [rbx+T_stats+S_damage], xmm0
    ; The fourth table element lands exactly on Tower.damageType.
    mov eax, [rbx+T_stats+S_level]
    test eax, eax
    jg .scaling_level
    mov eax, 1
.scaling_level:
    dec eax
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    movaps xmm1, xmm0
    mulss xmm1, [fp_035]
    addss xmm1, [fp_one]
    mulss xmm1, [rbx+T_stats+S_damage]
    movss [rbx+T_stats+S_damage], xmm1
    movaps xmm1, xmm0
    mulss xmm1, [fp_01]
    addss xmm1, [fp_one]
    mulss xmm1, [rbx+T_stats+S_range]
    movss [rbx+T_stats+S_range], xmm1
    mov eax, [rbx+T_type]
    cmp eax, 2
    je .done
    cmp eax, 8
    je .done
    cmp eax, 9
    je .done
    mulss xmm0, [fp_015]
    addss xmm0, [fp_one]
    mulss xmm0, [rbx+T_stats+S_fireRate]
    movss [rbx+T_stats+S_fireRate], xmm0
.done:
    RETURN 16

section .note.GNU-stack noalloc noexec nowrite progbits
