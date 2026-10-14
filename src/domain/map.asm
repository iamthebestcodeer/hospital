; domain/map: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern game

section .rodata align=16
align 16
path_tiles:
    db 0,3,1,3,2,3,3,3,4,3,5,3,6,3
    db 6,4,6,5,6,6,6,7,6,8,6,9
    db 5,9,4,9,3,9,2,9
    db 2,10,2,11,2,12,2,13,2,14
    db 3,14,4,14,5,14,6,14,7,14,8,14,9,14,10,14,11,14
    db 11,13,11,12,11,11,11,10,11,9,11,8,11,7
    db 12,7,13,7,14,7,15,7,16,7,17,7
    db 17,8,17,9,17,10,17,11,17,12
    db 18,12,19,12,20,12,21,12
    db 21,11,21,10,21,9,21,8,21,7,21,6,21,5,22,5,23,5
path_end:
; Direction changes of the same path, including its offscreen endpoints.
align 16
path_waypoints:
    dd -60.0,140.0,260.0,140.0,260.0,380.0,100.0,380.0
    dd 100.0,580.0,460.0,580.0,460.0,300.0,700.0,300.0
    dd 700.0,500.0,860.0,500.0,860.0,220.0,940.0,220.0
    dd 1020.0,220.0

section .text
global InitMap
InitMap:
    lea rdi, [game+G_map+M_tiles]
    xor eax, eax
    mov ecx, 480
    rep stosd
    lea rsi, [path_tiles]
    lea rdi, [game+G_map+M_tiles]
    lea r8, [path_end]
.tile:
    movzx eax, byte [rsi+1]
    imul eax, 24
    movzx edx, byte [rsi]
    add eax, edx
    mov dword [rdi+rax*4], 1
    add rsi, 2
    cmp rsi, r8
    jb .tile
    lea rsi, [path_waypoints]
    lea rdi, [game+G_map+M_waypoints]
    mov ecx, 13
    rep movsq
    mov dword [game+G_map+M_waypointCount], 13
    ret

global IsTileBuildable
IsTileBuildable:
    xor eax, eax
    cmp edi, 24
    jae .done
    cmp esi, 20
    jae .done
    imul esi, 24
    add esi, edi
    lea rdx, [game+G_map+M_tiles]
    cmp dword [rdx+rsi*4], 0
    jne .done
    lea rdx, [game+G_occupied]
    cmp byte [rdx+rsi], 0
    sete al
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
