; platform/main: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern CloseWindow
extern DrawGame
extern GetFrameTime
extern InitGame
extern InitWindow
extern SetConfigFlags
extern SetRandomSeed
extern UnloadRenderTexture
extern UpdateGame
extern WindowShouldClose
extern game
extern time

section .rodata align=16
align 16
fp_01: dd 0.1
align 16
title: db 'Aetherium Vanguard - PRESTIGE EDITION v3.1.0 (Physics, Movement & Pathfinding Fixed)',0

section .text
global main
main:
    FRAME 16
    mov edi, 32                 ; FLAG_MSAA_4X_HINT
    call SetConfigFlags wrt ..plt
    mov edi, 1280
    mov esi, 800
    lea rdx, [title]
    call InitWindow wrt ..plt
    xor edi, edi
    call time wrt ..plt
    mov edi, eax
    call SetRandomSeed wrt ..plt
    call InitGame
.frame:
    call WindowShouldClose wrt ..plt
    test al, al
    jnz .exit
    call GetFrameTime wrt ..plt
    ucomiss xmm0, [fp_01]
    jbe .dt_ready
    jp .dt_ready
    movss xmm0, [fp_01]
.dt_ready:
    movss xmm1, [game+G_globalTime]
    addss xmm1, xmm0
    movss [game+G_globalTime], xmm1
    call UpdateGame
    call DrawGame wrt ..plt
    jmp .frame
.exit:
    cmp byte [game+G_mapRTBuilt], 0
    je .close
    sub rsp, 48                 ; RenderTexture2D is passed by value on stack
    movdqu xmm0, [game+G_mapRT]
    movdqu [rsp], xmm0
    movdqu xmm0, [game+G_mapRT+16]
    movdqu [rsp+16], xmm0
    movdqu xmm0, [game+G_mapRT+28]
    movdqu [rsp+28], xmm0
    call UnloadRenderTexture wrt ..plt
    add rsp, 48
.close:
    call CloseWindow wrt ..plt
    xor eax, eax
    RETURN 16

section .note.GNU-stack noalloc noexec nowrite progbits
