; gameplay/projectiles: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingTextFmt
extern ApplyStatusEffect
extern CalculateDamage
extern GetEnemyIndexById
extern GetRandomValue
extern GetTowerColor
extern HandleEnemyDeath
extern ScreenShake
extern SpawnParticles
extern av_enemy_from_pair
extern game

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_two: dd 2.0
align 16
fp_0001: dd 0.001
align 16
fp_005: dd 0.05
align 16
fp_025: dd 0.25
align 16
fp_07: dd 0.7
align 16
fp_5: dd 5.0
align 16
fp_10: dd 10.0
align 16
fp_20: dd 20.0
align 16
fp_150: dd 150.0
align 16
txt_damage: db '%.0f',0

section .text
global FireProjectile
FireProjectile:
    lea rax, [game+G_projectiles]
    mov ecx, 500
.slot:
    cmp byte [rax+J_active], 0
    je .create
    add rax, J_SIZE
    dec ecx
    jnz .slot
    ret
.create:
    FRAME 0
    mov rbx, rax
    mov r12, rdi
    mov r13, rsi
    mov rdi, rbx
    xor eax, eax
    mov ecx, J_SIZE/8
    rep stosq
    mov byte [rbx+J_active], 1
    movq xmm0, [r12+T_position]
    movq [rbx+J_position], xmm0
    mov eax, [r12+T_stats+S_damage]
    mov [rbx+J_damage], eax
    mov eax, [r12+T_damageType]
    mov [rbx+J_damageType], eax
    mov r14d, [r12+T_type]
    mov [rbx+J_sourceType], r14d
    mov rax, r12
    lea rdx, [game+G_towers]
    sub rax, rdx
    xor edx, edx
    mov ecx, T_SIZE
    div ecx
    mov [rbx+J_sourceTowerIndex], eax
    mov rax, r13
    lea rdx, [game+G_enemies]
    sub rax, rdx
    xor edx, edx
    mov ecx, E_SIZE
    div ecx
    mov [rbx+J_targetIndex], eax
    mov eax, [r13+E_id]
    mov [rbx+J_targetEnemyId], eax
    movq xmm0, [r13+E_position]
    movq [rbx+J_targetPosition], xmm0
    cmp r14d, 0
    je .pulse
    cmp r14d, 4
    je .pulse
    cmp r14d, 5
    je .sniper
    cmp r14d, 1
    je .cannon
    cmp r14d, 6
    je .mortar
    cmp r14d, 7
    je .vulcan
    cmp r14d, 3
    je .tesla
    cmp r14d, 11
    je .tesla
    cmp r14d, 10
    je .chain
    mov byte [rbx+J_active], 0
    jmp .done
.pulse:
    FLOAT dword [rbx+J_speed], 650.0
    jmp .done
.sniper:
    FLOAT dword [rbx+J_speed], 1200.0
    jmp .done
.cannon:
    FLOAT dword [rbx+J_speed], 350.0
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [r12+T_stats+S_level]
    mulss xmm0, [fp_10]
    mov eax, __float32__(50.0)
    movd xmm1, eax
    addss xmm0, xmm1
    movss [rbx+J_aoeRadius], xmm0
    jmp .burn
.vulcan:
    FLOAT dword [rbx+J_speed], 700.0
    jmp .burn
.mortar:
    FLOAT dword [rbx+J_speed], 250.0
    FLOAT dword [rbx+J_aoeRadius], 150.0
    movss xmm0, [r13+E_baseSpeed]
    ucomiss xmm0, [fp_zero]
    jbe .burn
    movsxd rax, dword [r13+E_waypointIndex]
    cmp eax, [game+G_map+M_waypointCount]
    jge .burn
    lea rdx, [game+G_map+M_waypoints]
    movq xmm0, [r13+E_position]
    movq xmm1, [rdx+rax*8]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    ucomiss xmm0, [fp_one]
    jbe .burn
    movq xmm0, [rdx+rax*8]
    movq xmm1, [r13+E_position]
    subps xmm0, xmm1
    NORMALIZE
    movss xmm1, [r13+E_baseSpeed]
    shufps xmm1, xmm1, 0
    mulps xmm0, xmm1
    movaps xmm4, xmm0          ; velocity prediction
    movq xmm0, [rbx+J_position]
    movq xmm1, [r13+E_position]
    subps xmm0, xmm1
    LENGTH
    divss xmm1, [rbx+J_speed]
    shufps xmm1, xmm1, 0
    mulps xmm4, xmm1
    movq xmm0, [r13+E_position]
    addps xmm0, xmm4
    movq [rbx+J_targetPosition], xmm0
.burn:
    mov dword [rbx+J_applyStatus], 2
    FLOAT dword [rbx+J_statusDuration], 5.0
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [r12+T_stats+S_level]
    mulss xmm0, [fp_5]
    addss xmm0, [fp_10]
    movss [rbx+J_statusIntensity], xmm0
    jmp .done
.tesla:
    FLOAT dword [rbx+J_speed], 900.0
    mov dword [rbx+J_applyStatus], 4
    FLOAT dword [rbx+J_statusDuration], 0.6
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [r12+T_stats+S_level]
    mov eax, __float32__(7.0)
    movd xmm1, eax
    mulss xmm0, xmm1
    addss xmm0, [fp_20]
    movss [rbx+J_statusIntensity], xmm0
    jmp .done
.chain:
    FLOAT dword [rbx+J_speed], 900.0
    mov eax, [r12+T_stats+S_level]
    add eax, 3
    mov [rbx+J_chainCount], eax
.done:
    RETURN 0

global UpdateProjectiles
UpdateProjectiles:
    FRAME 32
    movss [rsp], xmm0
    lea rbx, [game+G_projectiles]
    mov r12d, 500
.projectile:
    cmp byte [rbx+J_active], 0
    je .next
    mov edi, [rbx+J_targetIndex]
    mov esi, [rbx+J_targetEnemyId]
    call av_enemy_from_pair
    mov r13, rax
    cmp dword [rbx+J_sourceType], 6
    jne .homing
    movq xmm0, [rbx+J_targetPosition]
    jmp .target_ready
.homing:
    test r13, r13
    jnz .live_target
    mov byte [rbx+J_active], 0
    jmp .next
.live_target:
    movq xmm0, [r13+E_position]
.target_ready:
    movq [rsp+8], xmm0
    movss xmm4, [fp_10]
    mov eax, [rbx+J_sourceType]
    cmp eax, 1
    je .large_radius
    cmp eax, 6
    je .large_radius
    cmp eax, 5
    jne .radius_ready
    movss xmm4, [fp_5]
    jmp .radius_ready
.large_radius:
    mov eax, __float32__(15.0)
    movd xmm4, eax
.radius_ready:
    movq xmm1, [rbx+J_position]
    subps xmm0, xmm1
    LENGTH
    movss xmm3, [rbx+J_speed]
    mulss xmm3, [rsp]
    addss xmm4, xmm3
    ucomiss xmm1, xmm4
    jbe .impact
    ucomiss xmm1, [fp_0001]
    jbe .zero_direction
    movss xmm2, [fp_one]
    divss xmm2, xmm1
    shufps xmm2, xmm2, 0
    mulps xmm0, xmm2
    jmp .advance
.zero_direction:
    pxor xmm0, xmm0
.advance:
    shufps xmm3, xmm3, 0
    mulps xmm0, xmm3
    movq xmm1, [rbx+J_position]
    addps xmm0, xmm1
    movq [rbx+J_position], xmm0
    jmp .next
.impact:
    movq xmm0, [rsp+8]
    movq [rbx+J_position], xmm0
    mov byte [rbx+J_active], 0
    test r13, r13
    jz .dispatch
    cmp byte [r13+E_active], 0
    je .invalid_primary
    cmp dword [rbx+J_sourceType], 6
    jne .dispatch
    movq xmm1, [r13+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [rbx+J_aoeRadius]
    jbe .dispatch
.invalid_primary:
    xor r13d, r13d
.dispatch:
    mov rdi, rbx
    mov rsi, r13
    call HandleProjectileImpact
.next:
    add rbx, J_SIZE
    dec r12d
    jnz .projectile
    RETURN 32

global ApplyDamageAndEffects
ApplyDamageAndEffects:
    cmp byte [rsi+E_active], 0
    je .ignore
    FRAME 16
    mov rbx, rdi
    mov r12, rsi
    mov r13d, edx
    movss xmm0, [rbx+J_damage]
    mov edi, [rbx+J_damageType]
    call CalculateDamage
    test r13b, r13b
    jz .damage_ready
    mulss xmm0, [fp_two]
.damage_ready:
    movss xmm1, [r12+E_hp]
    subss xmm1, xmm0
    movss [r12+E_hp], xmm1
    mov edi, 0xff008cff
    cmp dword [rbx+J_damageType], 1
    jne .color_ready
    mov edi, 0xffffdc00
.color_ready:
    test r13b, r13b
    jz .text
    mov edi, 0xff00f9fd
.text:
    cvtss2sd xmm1, xmm0
    movq xmm0, [r12+E_position]
    mov esi, r13d
    lea rdx, [txt_damage]
    mov eax, 2
    call AddFloatingTextFmt
    mov eax, [rbx+J_applyStatus]
    test eax, eax
    jz .death
    mov eax, [rbx+J_statusIntensity]
    mov [rsp], eax
    mov r14d, 1
    cmp dword [rbx+J_applyStatus], 4
    jne .synergy
    xor edi, edi
    mov esi, 100
    call GetRandomValue wrt ..plt
    cvttss2si edx, [rbx+J_statusIntensity]
    cmp eax, edx
    setl r14b
    FLOAT dword [rsp], 1.0
.synergy:
    cmp dword [rbx+J_applyStatus], 2
    jne .apply
    mov rdi, r12
    mov esi, 32
    movss xmm0, [rbx+J_statusDuration]
    mov eax, __float32__(1.15)
    movd xmm1, eax
    call ApplyStatusEffect
.apply:
    test r14b, r14b
    jz .death
    mov rdi, r12
    mov esi, [rbx+J_applyStatus]
    movss xmm0, [rbx+J_statusDuration]
    movss xmm1, [rsp]
    call ApplyStatusEffect
.death:
    movss xmm0, [r12+E_hp]
    ucomiss xmm0, [fp_zero]
    jp .done
    ja .done
    mov rax, r12
    lea rdx, [game+G_enemies]
    sub rax, rdx
    xor edx, edx
    mov ecx, E_SIZE
    div ecx
    mov edi, eax
    mov esi, [rbx+J_sourceTowerIndex]
    call HandleEnemyDeath
.done:
    RETURN 16
.ignore:
    ret

global HandleProjectileImpact
HandleProjectileImpact:
    FRAME 32
    mov rbx, rdi
    mov r12, rsi
    mov edi, [rbx+J_sourceType]
    call GetTowerColor wrt ..plt
    mov r13d, eax
    mov dword [rsp], 15
    FLOAT dword [rsp+4], 60.0
    FLOAT dword [rsp+8], 5.0
    movss xmm0, [rbx+J_aoeRadius]
    ucomiss xmm0, [fp_zero]
    jbe .spawn
    mov dword [rsp], 60
    FLOAT dword [rsp+4], 150.0
    FLOAT dword [rsp+8], 9.0
    mulss xmm0, [fp_005]
    movss xmm1, [fp_025]
    call ScreenShake
.spawn:
    movq xmm0, [rbx+J_position]
    mov edi, [rsp]
    mov esi, r13d
    mov edx, 0x0000f9fd
    xor ecx, ecx
    cmp dword [rbx+J_damageType], 0
    sete cl
    movss xmm1, [rsp+4]
    movss xmm2, [rsp+8]
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    test r12, r12
    jz .chain
    mov ecx, [rbx+J_hitCount]
    cmp ecx, 10
    jge .chain
    mov edx, [r12+E_id]
    xor eax, eax
.history:
    cmp eax, ecx
    jge .record
    cmp [rbx+rax*4+J_hitHistory], edx
    je .chain
    inc eax
    jmp .history
.record:
    mov [rbx+rcx*4+J_hitHistory], edx
    inc dword [rbx+J_hitCount]
.chain:
    cmp dword [rbx+J_sourceType], 10
    jne .damage
    cmp dword [rbx+J_chainCount], 0
    jle .damage
    mov r13d, -1
    movss xmm5, [fp_150]
    lea r14, [game+G_enemies]
    mov r15d, 300
.chain_candidate:
    cmp byte [r14+E_active], 0
    je .chain_next
    mov edx, [r14+E_id]
    xor ecx, ecx
.chain_history:
    cmp ecx, [rbx+J_hitCount]
    jge .chain_distance
    cmp [rbx+rcx*4+J_hitHistory], edx
    je .chain_next
    inc ecx
    jmp .chain_history
.chain_distance:
    movq xmm0, [rbx+J_position]
    movq xmm1, [r14+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, xmm5
    jae .chain_next
    jp .chain_next
    movaps xmm5, xmm1
    mov r13d, edx
.chain_next:
    add r14, E_SIZE
    dec r15d
    jnz .chain_candidate
    cmp r13d, -1
    je .damage
    lea r14, [game+G_projectiles]
    mov ecx, 500
.chain_slot:
    cmp byte [r14+J_active], 0
    je .copy_chain
    add r14, J_SIZE
    dec ecx
    jnz .chain_slot
    jmp .damage
.copy_chain:
    mov rsi, rbx
    mov rdi, r14
    mov ecx, J_SIZE/8
    rep movsq
    mov byte [r14+J_active], 1
    mov edi, r13d
    call GetEnemyIndexById
    mov [r14+J_targetIndex], eax
    mov [r14+J_targetEnemyId], r13d
    movss xmm0, [r14+J_damage]
    mulss xmm0, [fp_07]
    movss [r14+J_damage], xmm0
    dec dword [r14+J_chainCount]
.damage:
    movss xmm0, [rbx+J_aoeRadius]
    ucomiss xmm0, [fp_zero]
    jbe .single
    mulss xmm0, xmm0
    movss [rsp], xmm0
    lea r14, [game+G_enemies]
    mov r15d, 300
.aoe:
    cmp byte [r14+E_active], 0
    je .aoe_next
    movq xmm0, [rbx+J_position]
    movq xmm1, [r14+E_position]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    ucomiss xmm0, [rsp]
    ja .aoe_next
    jp .aoe_next
    mov edi, 1
    mov esi, 100
    call GetRandomValue wrt ..plt
    cmp eax, 5
    setle dl
    movzx edx, dl
    mov rdi, rbx
    mov rsi, r14
    call ApplyDamageAndEffects
.aoe_next:
    add r14, E_SIZE
    dec r15d
    jnz .aoe
    jmp .done
.single:
    test r12, r12
    jz .done
    cmp byte [r12+E_active], 0
    je .done
    mov edi, 1
    mov esi, 100
    call GetRandomValue wrt ..plt
    cmp eax, 5
    setle dl
    movzx edx, dl
    mov rdi, rbx
    mov rsi, r12
    call ApplyDamageAndEffects
.done:
    RETURN 32

section .note.GNU-stack noalloc noexec nowrite progbits
