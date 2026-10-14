; gameplay/environment: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern ColorLerp
extern GetRandomValue
extern cosf
extern game

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_half: dd 0.5
align 16
fp_two: dd 2.0
align 16
fp_04: dd 0.4
align 16
fp_10: dd 10.0
align 16
fp_cycle: dd 0.008333333767950534820556640625
align 16
fp_pi: dd 3.14159265358979323846

section .text
global UpdateEnvironment
UpdateEnvironment:
    FRAME 16
    movss [rsp], xmm0
    mulss xmm0, [fp_cycle]
    addss xmm0, [game+G_dayNightCycle]
    ucomiss xmm0, [fp_two]
    jb .cycle_ready
    subss xmm0, [fp_two]
.cycle_ready:
    movss [game+G_dayNightCycle], xmm0
    mulss xmm0, [fp_pi]
    call cosf wrt ..plt
    addss xmm0, [fp_one]
    mulss xmm0, [fp_half]
    CLAMP xmm0, fp_04, fp_one
    mov edi, 0xff965050
    mov esi, 0xffffffff
    call ColorLerp wrt ..plt
    mov [game+G_environmentColor], eax
    movss xmm0, [game+G_screenShakeTime]
    ucomiss xmm0, [fp_zero]
    jbe .settle
    subss xmm0, [rsp]
    movss [game+G_screenShakeTime], xmm0
    divss xmm0, [game+G_screenShakeDuration]
    CLAMP xmm0, fp_zero, fp_one
    mulss xmm0, [game+G_screenShakeIntensity]
    ucomiss xmm0, [fp_zero]
    jae .intensity_ready
    jp .intensity_ready
    pxor xmm0, xmm0
.intensity_ready:
    cvttss2si ebx, xmm0
    mov esi, ebx
    mov edi, ebx
    neg edi
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    movss [game+G_camera], xmm0
    mov esi, ebx
    mov edi, ebx
    neg edi
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    movss [game+G_camera+4], xmm0
    jmp .done
.settle:
    movss xmm0, [rsp]
    mulss xmm0, [fp_10]
    shufps xmm0, xmm0, 0
    movq xmm1, [game+G_camera]
    pxor xmm2, xmm2
    subps xmm2, xmm1
    mulps xmm2, xmm0
    addps xmm1, xmm2
    movq [game+G_camera], xmm1
.done:
    RETURN 16

global ScreenShake
ScreenShake:
    ucomiss xmm0, [game+G_screenShakeIntensity]
    ja .set
    movss xmm2, [game+G_screenShakeTime]
    ucomiss xmm2, [fp_zero]
    jp .done
    ja .done
.set:
    movss [game+G_screenShakeIntensity], xmm0
    movss [game+G_screenShakeTime], xmm1
    movss [game+G_screenShakeDuration], xmm1
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
