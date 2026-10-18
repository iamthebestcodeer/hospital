; domain/tower_catalog: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"

section .rodata align=16
align 16
one4: dd 1.0,1.0,1.0,1.0
align 16
float_lanes: dd 0xffffffff,0xffffffff,0xffffffff,0
align 16
dp_19: dq 1.9
dp_150: dq 150.0
fp_20: dd 20.0
align 16
costs: dd 100,250,200,400,800,1000,1500,900,700,850,1100,1300
align 16
aether_costs: dd 0,0,0,0,90,100,125,95,85,92,105,115
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
; damage, range, fire-rate slopes; the integer damageType lane is never scaled.
align 16
slopes:
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.0,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.0,0.0
    dd 0.35,0.10,0.0,0.0
    dd 0.35,0.10,0.15,0.0
    dd 0.35,0.10,0.15,0.0

%if S_range != S_damage+4 || S_fireRate != S_damage+8 || T_damageType != T_stats+S_damage+12
    %error "Tower SIMD record must contain damage, range, fireRate, damageType"
%endif

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
    mov eax, 5049              ; Preserve 50 + 99999/20 for invalid positive types.
    cmp edi, 12
    jae .done
    lea rdx, [aether_costs]
    mov eax, [rdx+rdi*4]
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
    ; Exponents are 0 or 1. Keep the level-2 multiply under the caller's MXCSR.
    mov ecx, [rdi+T_type]
    mov eax, 99999
    cmp ecx, 3
    ja .xp_ready
    mov edx, [rdi+T_stats+S_level]
    cmp edx, 3
    jge .xp_ready
    mov eax, 150
    cmp edx, 2
    jne .xp_ready
    movsd xmm0, [dp_19]
    mulsd xmm0, [dp_150]
    cvttsd2si eax, xmm0
.xp_ready:
    mov [rdi+T_stats+S_xpToNextLevel], eax
    cmp ecx, 12
    jae .done
    mov eax, [rdi+T_stats+S_level]
    test eax, eax
    jg .scaling_level
    mov eax, 1
.scaling_level:
    dec eax
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    shufps xmm0, xmm0, 0
    shl ecx, 4
    lea rdx, [slopes]
    mulps xmm0, [rdx+rcx]
    addps xmm0, [one4]
    lea rdx, [tower_stats]
    movaps xmm1, [rdx+rcx]
    mov eax, [rdx+rcx+12]
    ; Clear the integer lane before floating-point arithmetic, avoiding denormals.
    andps xmm1, [float_lanes]
    mulps xmm0, xmm1
    movups [rdi+T_stats+S_damage], xmm0
    mov [rdi+T_damageType], eax
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
