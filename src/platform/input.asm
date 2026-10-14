; platform/input: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern CheckCollisionPointRec
extern GetMousePosition
extern GetScreenToWorld2D
extern IsKeyDown
extern IsKeyPressed
extern IsMouseButtonPressed
extern PlaceTower
extern WorldToTile
extern game

section .rodata align=16
align 16
fp_20: dd 20.0
align 16
fp_40: dd 40.0

section .text
global HandleInput
HandleInput:
    FRAME 32
    mov edi, 71
    call IsKeyPressed wrt ..plt
    test al, al
    jz .mouse
    xor byte [game+G_showGrid], 1
.mouse:
    call GetMousePosition wrt ..plt
    movq [rsp], xmm0
    sub rsp, 32
    movups xmm1, [game+G_camera]
    movups [rsp], xmm1
    movq xmm1, [game+G_camera+16]
    movq [rsp+16], xmm1
    call GetScreenToWorld2D wrt ..plt
    add rsp, 32
    movq [rsp+8], xmm0
    movss xmm1, [rsp]
    mov eax, __float32__(960.0)
    movd xmm2, eax
    ucomiss xmm1, xmm2
    jae .cancel
    jp .cancel
    call WorldToTile
    cvttss2si r12d, xmm0
    shufps xmm0, xmm0, 0x55
    cvttss2si r13d, xmm0
    xor edi, edi
    call IsMouseButtonPressed wrt ..plt
    test al, al
    jz .cancel
    mov edx, [game+G_placingTower]
    cmp edx, -1
    je .select
    mov edi, r12d
    mov esi, r13d
    call PlaceTower
    test al, al
    jz .cancel
    mov edi, 340
    call IsKeyDown wrt ..plt
    test al, al
    jnz .cancel
    mov edi, 344
    call IsKeyDown wrt ..plt
    test al, al
    jnz .cancel
    mov dword [game+G_placingTower], -1
    jmp .cancel
.select:
    mov dword [game+G_selectedTowerIndex], -1
    xor ebx, ebx
    lea r12, [game+G_towers]
.select_loop:
    cmp byte [r12+T_active], 0
    je .next_tower
    movq xmm1, [r12+T_position]
    movss xmm2, [fp_20]
    shufps xmm2, xmm2, 0
    subps xmm1, xmm2
    movss xmm2, [fp_40]
    shufps xmm2, xmm2, 0
    movq xmm0, [rsp+8]
    call CheckCollisionPointRec wrt ..plt
    test al, al
    jz .next_tower
    mov [game+G_selectedTowerIndex], ebx
    jmp .cancel
.next_tower:
    add r12, T_SIZE
    inc ebx
    cmp ebx, 100
    jb .select_loop
.cancel:
    mov edi, 1
    call IsMouseButtonPressed wrt ..plt
    test al, al
    jnz .clear
    mov edi, 256
    call IsKeyPressed wrt ..plt
    test al, al
    jz .keys
    mov eax, [game+G_state]
    cmp eax, 2
    je .keys
    cmp eax, 4
    je .keys
.clear:
    mov dword [game+G_placingTower], -1
    mov dword [game+G_selectedTowerIndex], -1
.keys:
    xor ebx, ebx
.key_loop:
    lea edi, [rbx+49]
    call IsKeyPressed wrt ..plt
    test al, al
    jz .next_key
    mov [game+G_placingTower], ebx
    mov dword [game+G_selectedTowerIndex], -1
.next_key:
    inc ebx
    cmp ebx, 4
    jb .key_loop
    RETURN 32

section .note.GNU-stack noalloc noexec nowrite progbits
