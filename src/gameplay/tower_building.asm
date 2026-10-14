; gameplay/tower_building: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingText
extern AddFloatingTextFmt
extern ConfigureTowerStats
extern GetTowerCost
extern IsTileBuildable
extern SpawnParticles
extern TileToWorldCenter
extern WorldToTile
extern game

section .rodata align=16
align 16
fp_two: dd 2.0
align 16
fp_10: dd 10.0
align 16
fp_150: dd 150.0
align 16
txt_sold: db 'SOLD +%dG',0
align 16
txt_cannot_build: db 'Cannot build here!',0
align 16
txt_no_gold: db 'Not enough gold!',0

section .text
global PlaceTower
PlaceTower:
    FRAME 16
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    call IsTileBuildable
    test al, al
    jnz .cost
    lea rbx, [txt_cannot_build]
    jmp .error
.cost:
    mov edi, r14d
    call GetTowerCost
    mov r15d, eax
    cmp [game+G_gold], eax
    jge .find_slot
    lea rbx, [txt_no_gold]
.error:
    mov edi, r12d
    mov esi, r13d
    call TileToWorldCenter
    mov rdi, rbx
    mov esi, 0xff3232ff
    xor edx, edx
    call AddFloatingText
    xor eax, eax
    jmp .done
.find_slot:
    lea rbx, [game+G_towers]
    mov ecx, 100
.slot:
    cmp byte [rbx+T_active], 0
    je .place
    add rbx, T_SIZE
    dec ecx
    jnz .slot
    xor eax, eax
    jmp .done
.place:
    sub [game+G_gold], r15d
    mov rdi, rbx
    xor eax, eax
    mov ecx, T_SIZE/4
    rep stosd
    mov byte [rbx+T_active], 1
    mov [rbx+T_type], r14d
    mov edi, r12d
    mov esi, r13d
    call TileToWorldCenter
    movq [rbx+T_position], xmm0
    ; These validated tile coordinates round-trip through the center exactly.
    imul r13d, 24
    add r13d, r12d
    lea rax, [game+G_occupied]
    mov byte [rax+r13], 1
    mov dword [rbx+T_targetIndex], -1
    mov dword [rbx+T_targetEnemyId], -1
    mov dword [rbx+T_stats+S_level], 1
    mov [rbx+T_totalCost], r15d
    mov rdi, rbx
    call ConfigureTowerStats
    movq xmm0, [rbx+T_position]
    mov edi, 40
    mov esi, 0xffffdc00
    mov edx, 0x00ffdc00
    xor ecx, ecx
    mov eax, __float32__(80.0)
    movd xmm1, eax
    mov eax, __float32__(8.0)
    movd xmm2, eax
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    mov eax, 1
.done:
    RETURN 16

global SellTower
SellTower:
    cmp edi, 100
    jae .ignore
    imul eax, edi, T_SIZE
    lea rdx, [game+G_towers]
    add rdx, rax
    cmp byte [rdx+T_active], 0
    je .ignore
    FRAME 16
    mov rbx, rdx
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [rbx+T_totalCost]
    mov eax, __float32__(0.6)
    movd xmm1, eax
    mulss xmm0, xmm1
    cvttss2si r12d, xmm0
    add [game+G_gold], r12d
    movq xmm0, [rbx+T_position]
    call WorldToTile
    cvttss2si eax, xmm0
    shufps xmm0, xmm0, 0x55
    cvttss2si edx, xmm0
    cmp eax, 24
    jae .feedback
    cmp edx, 20
    jae .feedback
    imul edx, 24
    add edx, eax
    lea rax, [game+G_occupied]
    mov byte [rax+rdx], 0
.feedback:
    movq xmm0, [rbx+T_position]
    mov edi, 0xff00d7ff
    xor esi, esi
    lea rdx, [txt_sold]
    mov ecx, r12d
    mov eax, 1
    call AddFloatingTextFmt
    movq xmm0, [rbx+T_position]
    mov edi, 30
    mov esi, 0xff828282
    mov edx, 0x00828282
    mov ecx, 1
    mov eax, __float32__(80.0)
    movd xmm1, eax
    mov eax, __float32__(8.0)
    movd xmm2, eax
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    mov byte [rbx+T_active], 0
    mov dword [game+G_selectedTowerIndex], -1
    RETURN 16
.ignore:
    ret

global UpgradeTower
UpgradeTower:
    xor eax, eax
    test rdi, rdi
    jz .ignore
    cmp byte [rdi+T_active], 0
    je .ignore
    mov edx, [rdi+T_type]
    cmp edx, 4
    jae .ignore
    lea edx, [rdx*2+4]
    mov ecx, esi
    sub ecx, edx
    cmp ecx, 1
    ja .ignore
    FRAME 0
    mov rbx, rdi
    mov [rdi+T_type], esi
    call ConfigureTowerStats
    movq xmm0, [rbx+T_position]
    mov edi, 100
    mov esi, 0xffff64b4
    mov edx, 0x0000f9fd
    xor ecx, ecx
    movss xmm1, [fp_150]
    movss xmm2, [fp_10]
    mov eax, __float32__(3.0)
    movd xmm3, eax
    call SpawnParticles wrt ..plt
    mov eax, 1
    RETURN 0
.ignore:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
