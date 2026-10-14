; gameplay/tower_targeting: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern ApplyStatusEffect
extern CalculateDamage
extern FireProjectile
extern GetAimToleranceDegrees
extern HandleEnemyDeath
extern LerpAngle
extern atan2f
extern av_enemy_from_pair
extern fmodf
extern game

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_15: dd 1.5
align 16
fp_8: dd 8.0
align 16
fp_18: dd 18.0
align 16
fp_2560: dd 2560.0
align 16
fp_rad2deg: dd 57.2957763671875
align 16
align 16
fp_abs: dd 0x7fffffff,0x7fffffff,0x7fffffff,0x7fffffff
align 16
fp_5: dd 5.0
align 16
fp_10: dd 10.0
align 16
fp_180: dd 180.0
align 16
fp_360: dd 360.0

section .text
global UpdateTowers
UpdateTowers:
    FRAME 32
    movss [rsp], xmm0
    mulss xmm0, [fp_15]
    movss [rsp+24], xmm0        ; short beam/aura status duration
    lea rbx, [game+G_towers]
    xor r12d, r12d
.tower:
    cmp byte [rbx+T_active], 0
    je .next_tower
    movss xmm0, [rbx+T_cooldownTimer]
    subss xmm0, [rsp]
    movss [rbx+T_cooldownTimer], xmm0
    movss xmm0, [rbx+T_visualRecoil]
    pxor xmm1, xmm1
    subss xmm1, xmm0
    movss xmm2, [rsp]
    mulss xmm2, [fp_10]
    mulss xmm1, xmm2
    addss xmm0, xmm1
    movss [rbx+T_visualRecoil], xmm0
    cmp dword [rbx+T_type], 8
    je .blizzard
    movss xmm0, [rbx+T_stats+S_range]
    ucomiss xmm0, [fp_2560]
    setae byte [rsp+4]
    mulss xmm0, xmm0
    movss [rsp+16], xmm0
    mov edi, [rbx+T_targetIndex]
    mov esi, [rbx+T_targetEnemyId]
    call av_enemy_from_pair
    mov r13, rax
    test r13, r13
    jz .acquire
    cmp byte [rsp+4], 0
    jne .aim
    movq xmm0, [rbx+T_position]
    movq xmm1, [r13+E_position]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    ucomiss xmm0, [rsp+16]
    jbe .aim
.acquire:
    xor r13d, r13d
    mov dword [rbx+T_targetIndex], -1
    mov dword [rbx+T_targetEnemyId], -1
    FLOAT dword [rsp+8], -1.0
    mov dword [rsp+12], 0x7f7fffff
    mov dword [rsp+20], -1
    lea r14, [game+G_enemies]
    xor r15d, r15d
.candidate:
    cmp byte [r14+E_active], 0
    je .next_candidate
    movq xmm0, [rbx+T_position]
    movq xmm1, [r14+E_position]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    cmp byte [rsp+4], 0
    jne .metric
    ucomiss xmm0, [rsp+16]
    ja .next_candidate
.metric:
    mov eax, [rbx+T_targetingMode]
    test eax, eax
    jz .first
    cmp eax, 1
    je .closest
    cmp eax, 2
    je .strongest
    cmp eax, 3
    je .weakest
    jmp .next_candidate
.first:
    pxor xmm3, xmm3
    movsxd rax, dword [r14+E_waypointIndex]
    cvtsi2ss xmm3, eax
    mov edx, 0x7f7fffff
    movd xmm4, edx
    cmp eax, [game+G_map+M_waypointCount]
    jge .first_compare
    lea rdx, [game+G_map+M_waypoints]
    movq xmm0, [r14+E_position]
    movq xmm1, [rdx+rax*8]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    movaps xmm4, xmm0
.first_compare:
    cmp dword [rsp+20], -1
    je .first_better
    ucomiss xmm3, [rsp+8]
    ja .first_better
    jne .next_candidate
    jp .next_candidate
    ucomiss xmm4, [rsp+12]
    jae .next_candidate
    jp .next_candidate
.first_better:
    movss [rsp+8], xmm3
    movss [rsp+12], xmm4
    jmp .better
.closest:
    cmp dword [rsp+20], -1
    je .secondary_better
    ucomiss xmm0, [rsp+12]
    jae .next_candidate
    jp .next_candidate
    jmp .secondary_better
.strongest:
    movss xmm0, [r14+E_hp]
    cmp dword [rsp+20], -1
    je .primary_better
    ucomiss xmm0, [rsp+8]
    jbe .next_candidate
.primary_better:
    movss [rsp+8], xmm0
    jmp .better
.weakest:
    movss xmm0, [r14+E_hp]
    cmp dword [rsp+20], -1
    je .secondary_better
    ucomiss xmm0, [rsp+12]
    jae .next_candidate
    jp .next_candidate
.secondary_better:
    movss [rsp+12], xmm0
.better:
    mov [rsp+20], r15d
    mov r13, r14
.next_candidate:
    add r14, E_SIZE
    inc r15d
    cmp r15d, 300
    jb .candidate
    test r13, r13
    jz .idle
    mov eax, [rsp+20]
    mov [rbx+T_targetIndex], eax
    mov eax, [r13+E_id]
    mov [rbx+T_targetEnemyId], eax
.aim:
    movq xmm0, [r13+E_position]
    movq xmm1, [rbx+T_position]
    subps xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm0, xmm0, 0x55
    call atan2f wrt ..plt
    mulss xmm0, [fp_rad2deg]
    movss [rbx+T_desiredRotation], xmm0
    movss xmm2, [fp_18]
    mov eax, [rbx+T_type]
    cmp eax, 5
    je .slow_rotation
    cmp eax, 1
    je .slow_rotation
    cmp eax, 6
    jne .rotation_speed
.slow_rotation:
    movss xmm2, [fp_8]
.rotation_speed:
    mulss xmm2, [rsp]
    minss xmm2, [fp_one]
    movaps xmm1, xmm0
    movss xmm0, [rbx+T_rotation]
    call LerpAngle
    movss [rbx+T_rotation], xmm0
    subss xmm0, [rbx+T_desiredRotation]
    addss xmm0, [fp_180]
    movss xmm1, [fp_360]
    call fmodf wrt ..plt
    ; fmodf keeps the dividend's sign; wrap into [0,360) before measuring.
    ucomiss xmm0, [fp_zero]
    jae .angle_wrapped
    jp .angle_wrapped
    addss xmm0, [fp_360]
.angle_wrapped:
    subss xmm0, [fp_180]
    andps xmm0, [fp_abs]
    movss [rsp+28], xmm0        ; XMM registers are caller-saved across modules.
    mov edi, [rbx+T_type]
    call GetAimToleranceDegrees
    movss xmm1, [rbx+T_cooldownTimer]
    ucomiss xmm1, [fp_zero]
    jp .next_tower
    ja .next_tower
    cmp byte [rsp+4], 0
    jne .fire
    movss xmm4, [rsp+28]
    ucomiss xmm4, xmm0
    ja .next_tower
    jp .next_tower
.fire:
    mov eax, [rbx+T_type]
    cmp eax, 2
    je .cryo
    cmp eax, 9
    je .freezer
    mov rdi, rbx
    mov rsi, r13
    call FireProjectile
    mov eax, [rbx+T_type]
    cmp eax, 1
    je .cannon_recoil
    cmp eax, 6
    je .cannon_recoil
    cmp eax, 7
    je .cannon_recoil
    FLOAT dword [rbx+T_visualRecoil], 4.0
    jmp .reload
.cannon_recoil:
    FLOAT dword [rbx+T_visualRecoil], 8.0
.reload:
    movss xmm0, [fp_one]
    movss xmm1, [rbx+T_stats+S_fireRate]
    ucomiss xmm1, [fp_zero]
    jbe .reload_ready
    divss xmm0, xmm1
.reload_ready:
    movss [rbx+T_cooldownTimer], xmm0
    jmp .next_tower
.cryo:
    mov rdi, r13
    mov esi, 1
    movss xmm0, [rsp+24]
    mov eax, __float32__(0.6)
    movd xmm1, eax
    call ApplyStatusEffect
    mov rdi, r13
    mov esi, 16
    movss xmm0, [rsp+24]
    mov eax, __float32__(1.15)
    movd xmm1, eax
    call ApplyStatusEffect
    jmp .beam_damage
.freezer:
    mov rdi, r13
    mov esi, 4
    movss xmm0, [rbx+T_stats+S_fireRate]
    movss xmm1, [fp_one]
    call ApplyStatusEffect
.beam_damage:
    movss xmm0, [rbx+T_stats+S_damage]
    mulss xmm0, [rsp]
    mov edi, [rbx+T_damageType]
    mov rsi, r13
    call CalculateDamage
    movss xmm1, [r13+E_hp]
    subss xmm1, xmm0
    movss [r13+E_hp], xmm1
    ucomiss xmm1, [fp_zero]
    jp .next_tower
    ja .next_tower
    mov rax, r13
    lea rdx, [game+G_enemies]
    sub rax, rdx
    xor edx, edx
    mov ecx, E_SIZE
    div ecx
    mov edi, eax
    mov esi, r12d
    call HandleEnemyDeath
    jmp .next_tower
.idle:
    mov dword [rbx+T_desiredRotation], 0
    movss xmm0, [rbx+T_stats+S_range]
    ucomiss xmm0, [fp_2560]
    jae .next_tower
    jp .next_tower
    movss xmm2, [rsp]
    mulss xmm2, [fp_5]
    minss xmm2, [fp_one]
    movss xmm0, [rbx+T_rotation]
    pxor xmm1, xmm1
    call LerpAngle
    jmp .idle_rotated
.blizzard:
    lea r14, [game+G_enemies]
    xor r15d, r15d
.aura_enemy:
    cmp byte [r14+E_active], 0
    je .aura_next
    movq xmm0, [rbx+T_position]
    movq xmm1, [r14+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [rbx+T_stats+S_range]
    ja .aura_next
    jp .aura_next
    mov rdi, r14
    mov esi, 1
    movss xmm0, [rsp+24]
    movss xmm1, [rbx+T_stats+S_fireRate]
    call ApplyStatusEffect
    mov rdi, r14
    mov esi, 16
    movss xmm0, [rsp+24]
    mov eax, __float32__(1.2)
    movd xmm1, eax
    call ApplyStatusEffect
    movss xmm0, [rbx+T_stats+S_damage]
    mulss xmm0, [rsp]
    mov edi, [rbx+T_damageType]
    mov rsi, r14
    call CalculateDamage
    movss xmm1, [r14+E_hp]
    subss xmm1, xmm0
    movss [r14+E_hp], xmm1
    ucomiss xmm1, [fp_zero]
    jp .aura_next
    ja .aura_next
    mov edi, r15d
    mov esi, r12d
    call HandleEnemyDeath
.aura_next:
    add r14, E_SIZE
    inc r15d
    cmp r15d, 300
    jb .aura_enemy
    jmp .next_tower
.idle_rotated:
    movss [rbx+T_rotation], xmm0
.next_tower:
    add rbx, T_SIZE
    inc r12d
    cmp r12d, 100
    jb .tower
    RETURN 32

section .note.GNU-stack noalloc noexec nowrite progbits
