; gameplay/enemy_movement: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingTextFmt
extern HandleEnemyDeath
extern ProcessStatusEffects
extern ScreenShake
extern SpawnParticles
extern game

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_two: dd 2.0
align 16
fp_03: dd 0.3
align 16
fp_0001: dd 0.001
align 16
fp_5: dd 5.0
align 16
fp_10: dd 10.0
align 16
fp_100: dd 100.0
align 16
txt_healing: db '+%.0f HP',0

section .text
global UpdateEnemies
UpdateEnemies:
    FRAME 32
    movss [rsp], xmm0
    lea rbx, [game+G_enemies]
    xor r12d, r12d
.enemy:
    cmp byte [rbx+E_active], 0
    je .next
    mov rdi, rbx
    movss xmm0, [rsp]
    call ProcessStatusEffects
    cmp dword [rbx+E_type], 4
    jne .death
    movss xmm0, [rbx+E_abilityTimer]
    subss xmm0, [rsp]
    movss [rbx+E_abilityTimer], xmm0
    ucomiss xmm0, [fp_zero]
    jp .death
    ja .death
    FLOAT dword [rbx+E_abilityTimer], 2.0
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [game+G_currentWave]
    mulss xmm0, [fp_5]
    mov eax, __float32__(50.0)
    movd xmm1, eax
    addss xmm0, xmm1
    movss [rsp+4], xmm0
    lea r13, [game+G_enemies]
    xor r14d, r14d
.heal:
    cmp byte [r13+E_active], 0
    je .heal_next
    cmp r14d, r12d
    je .heal_next
    movq xmm0, [rbx+E_position]
    movq xmm1, [r13+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [fp_100]
    ja .heal_next
    jp .heal_next
    movss xmm0, [r13+E_hp]
    ucomiss xmm0, [r13+E_maxHp]
    jae .heal_next
    jp .heal_next
    addss xmm0, [rsp+4]
    minss xmm0, [r13+E_maxHp]
    movss [r13+E_hp], xmm0
    movq xmm0, [r13+E_position]
    cvtss2sd xmm1, [rsp+4]
    mov edi, 0xff30e400
    xor esi, esi
    lea rdx, [txt_healing]
    mov eax, 2
    call AddFloatingTextFmt
.heal_next:
    add r13, E_SIZE
    inc r14d
    cmp r14d, 300
    jb .heal
    movq xmm0, [rbx+E_position]
    mov edi, 10
    mov esi, 0xff30e400
    mov edx, 0x0030e400
    xor ecx, ecx
    mov eax, __float32__(50.0)
    movd xmm1, eax
    movss xmm2, [fp_5]
    movss xmm3, [fp_one]
    call SpawnParticles wrt ..plt
.death:
    movss xmm0, [rbx+E_hp]
    ucomiss xmm0, [fp_zero]
    jp .movement
    ja .movement
    mov edi, r12d
    mov esi, -1
    call HandleEnemyDeath
    jmp .next
.movement:
    movss xmm0, [rbx+E_speed]
    ucomiss xmm0, [fp_zero]
    jbe .end_check
    mulss xmm0, [rsp]
    movss [rsp+8], xmm0
    lea r13, [game+G_map+M_waypoints]
.segment:
    movss xmm3, [rsp+8]
    ucomiss xmm3, [fp_zero]
    jbe .end_check
    movsxd rax, dword [rbx+E_waypointIndex]
    cmp eax, [game+G_map+M_waypointCount]
    jge .end_check
    movq xmm4, [r13+rax*8]
    movaps xmm0, xmm4
    movq xmm1, [rbx+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [fp_0001]
    jb .snap
    ucomiss xmm1, xmm3
    jbe .consume
    movss xmm2, [fp_one]
    divss xmm2, xmm1
    shufps xmm2, xmm2, 0
    mulps xmm0, xmm2
    shufps xmm3, xmm3, 0
    mulps xmm0, xmm3
    movq xmm1, [rbx+E_position]
    addps xmm0, xmm1
    movq [rbx+E_position], xmm0
    jmp .end_check
.consume:
    subss xmm3, xmm1
    movss [rsp+8], xmm3
.snap:
    movq [rbx+E_position], xmm4
    inc dword [rbx+E_waypointIndex]
    jmp .segment
.end_check:
    mov eax, [rbx+E_waypointIndex]
    cmp eax, [game+G_map+M_waypointCount]
    jl .next
    dec dword [game+G_lives]
    mov byte [rbx+E_active], 0
    movq xmm0, [rbx+E_position]
    mov edi, 50
    mov esi, 0xff3232ff
    mov edx, esi
    xor ecx, ecx
    movss xmm1, [fp_100]
    movss xmm2, [fp_10]
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    movss xmm0, [fp_5]
    movss xmm1, [fp_03]
    call ScreenShake
.next:
    add rbx, E_SIZE
    inc r12d
    cmp r12d, 300
    jb .enemy
    RETURN 32

section .note.GNU-stack noalloc noexec nowrite progbits
