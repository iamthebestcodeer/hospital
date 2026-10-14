; domain/geometry: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern fmodf

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_20: dd 20.0
align 16
fp_40: dd 40.0
align 16
fp_180: dd 180.0
align 16
fp_360: dd 360.0

section .text
global TileToWorldCenter
TileToWorldCenter:
    imul edi, 40
    imul esi, 40
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    cvtsi2ss xmm0, edi
    cvtsi2ss xmm1, esi
    addss xmm0, [fp_20]
    addss xmm1, [fp_20]
    unpcklps xmm0, xmm1
    ret

global WorldToTile
WorldToTile:
    ; floor(x/40), without SSE4.1 round instructions or libm calls.
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    divss xmm0, [fp_40]
    divss xmm1, [fp_40]
    unpcklps xmm0, xmm1
    cvttps2dq xmm1, xmm0
    cvtdq2ps xmm1, xmm1
    cmpltps xmm0, xmm1
    movss xmm2, [fp_one]
    shufps xmm2, xmm2, 0
    andps xmm0, xmm2
    subps xmm1, xmm0
    movaps xmm0, xmm1
    ret

global LerpAngle
LerpAngle:
    FRAME 16
    movss [rsp], xmm0
    movss [rsp+4], xmm2
    subss xmm1, xmm0
    movaps xmm0, xmm1
    addss xmm0, [fp_360]
    movss xmm1, [fp_360]
    call fmodf wrt ..plt
    ucomiss xmm0, [fp_180]
    jbe .ready
    jp .ready
    subss xmm0, [fp_360]
.ready:
    mulss xmm0, [rsp+4]
    addss xmm0, [rsp]
    RETURN 16

global ClosestPointOnSegment
ClosestPointOnSegment:
    ; Packed Vector2 arguments in xmm0=P, xmm1=A, xmm2=B.
    subps xmm2, xmm1
    movaps xmm3, xmm2
    mulps xmm3, xmm3
    movaps xmm4, xmm3
    shufps xmm4, xmm4, 0x55
    addss xmm3, xmm4
    ucomiss xmm3, [fp_zero]
    jp .project
    je .point
.project:
    subps xmm0, xmm1
    mulps xmm0, xmm2
    movaps xmm4, xmm0
    shufps xmm4, xmm4, 0x55
    addss xmm0, xmm4
    divss xmm0, xmm3
    CLAMP xmm0, fp_zero, fp_one
    shufps xmm0, xmm0, 0
    mulps xmm0, xmm2
    addps xmm0, xmm1
    ret
.point:
    movaps xmm0, xmm1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
