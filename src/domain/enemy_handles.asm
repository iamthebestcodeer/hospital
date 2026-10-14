; domain/enemy_handles: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern game

section .text
global GetEnemyById
GetEnemyById:
    test edi, edi
    jle .missing
    lea rax, [game+G_enemies]
    lea rdx, [game+G_enemies+300*E_SIZE]
.scan:
    cmp byte [rax+E_active], 0
    je .next
    cmp [rax+E_id], edi
    je .done
.next:
    add rax, E_SIZE
    cmp rax, rdx
    jb .scan
.missing:
    xor eax, eax
.done:
    ret

global GetEnemyIndexById
GetEnemyIndexById:
    test edi, edi
    jle .missing
    xor eax, eax
    lea rdx, [game+G_enemies]
.scan:
    cmp byte [rdx+E_active], 0
    je .next
    cmp [rdx+E_id], edi
    je .done
.next:
    add rdx, E_SIZE
    inc eax
    cmp eax, 300
    jb .scan
.missing:
    mov eax, -1
.done:
    ret

global av_enemy_from_pair
av_enemy_from_pair:
    xor eax, eax
    cmp edi, 300
    jae .done
    imul edx, edi, E_SIZE
    lea rcx, [game+G_enemies]
    add rcx, rdx
    cmp byte [rcx+E_active], 0
    je .done
    cmp [rcx+E_id], esi
    jne .done
    mov rax, rcx
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
