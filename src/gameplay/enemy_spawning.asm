; gameplay/enemy_spawning: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingTextFmt
extern ClosestPointOnSegment
extern GetRandomValue
extern GrantHeroXP
extern GrantXP
extern SpawnParticles
extern game
extern powf
hero equ game+G_hero

section .rodata align=16
align 16
fp_one: dd 1.0
align 16
fp_two: dd 2.0
align 16
fp_01: dd 0.1
align 16
fp_04: dd 0.4
align 16
fp_001: dd 0.01
align 16
fp_018: dd 0.18
align 16
fp_11: dd 1.1
align 16
fp_20: dd 20.0
align 16
fp_100: dd 100.0
align 16
txt_gold: db '+%dG',0
align 16
txt_aether: db '+%dA',0
align 16
enemy_stats:
    dd 100.0,80.0,10.0,10.0,10,20,5,1,0
    dd 75.0,170.0,5.0,15.0,15,25,8,1,0
    dd 600.0,50.0,70.0,20.0,30,50,15,2,0
    dd 250.0,70.0,10.0,70.0,35,55,15,2,0
    dd 300.0,65.0,30.0,30.0,40,60,20,3,1
    dd 1500.0,60.0,50.0,50.0,150,250,-1,10,10
    dd 50.0,90.0,5.0,5.0,3,5,-1,0,0
    dd 5000.0,60.0,60.0,60.0,500,1000,-1,50,50

section .text
global SpawnEnemy
SpawnEnemy:
    lea rax, [game+G_enemies]
    mov ecx, 300
.slot:
    cmp byte [rax+E_active], 0
    je .create
    add rax, E_SIZE
    dec ecx
    jnz .slot
    ret
.create:
    FRAME 32
    mov rbx, rax
    mov r12d, edi
    movq [rsp], xmm0
    mov rdi, rbx
    xor eax, eax
    mov ecx, E_SIZE/4
    rep stosd
    mov byte [rbx+E_active], 1
    mov eax, [game+G_enemyIdCounter]
    mov [rbx+E_id], eax
    inc dword [game+G_enemyIdCounter]
    mov [rbx+E_type], r12d
    movq [rbx+E_position], xmm0
    movq xmm1, [game+G_map+M_waypoints]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    mov r13d, 1
    ucomiss xmm0, [fp_one]
    jb .path_ready
    mov eax, __float32__(10000000.0)
    mov [rsp+8], eax
    mov r14d, 1
    lea r15, [game+G_map+M_waypoints]
.path:
    cmp r14d, [game+G_map+M_waypointCount]
    jge .path_ready
    movq xmm0, [rsp]
    movq xmm1, [r15+r14*8-8]
    movq xmm2, [r15+r14*8]
    call ClosestPointOnSegment
    movq xmm1, [rsp]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    ucomiss xmm0, [rsp+8]
    jae .next_segment
    jp .next_segment
    movss [rsp+8], xmm0
    mov r13d, r14d
.next_segment:
    inc r14d
    jmp .path
.path_ready:
    mov [rbx+E_waypointIndex], r13d
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [game+G_currentWave]
    movss xmm1, [fp_11]
    call powf wrt ..plt
    mulss xmm0, [fp_001]
    mov eax, [game+G_currentWave]
    dec eax
    pxor xmm1, xmm1
    cvtsi2ss xmm1, eax
    movaps xmm2, xmm1
    mulss xmm1, [fp_018]
    addss xmm1, [fp_one]
    addss xmm0, xmm1
    mulss xmm2, [fp_01]
    addss xmm2, [fp_one]        ; armor scaling, also minion HP scaling
    cmp r12d, 8
    jae .finished
    imul eax, r12d, 36
    lea r13, [enemy_stats]
    add r13, rax
    cmp r12d, 6
    jne .normal_stats
    movaps xmm0, xmm2
    movss xmm2, [fp_one]
.normal_stats:
    mulss xmm0, [r13]
    movss [rbx+E_maxHp], xmm0
    movss xmm0, [r13+4]
    movss [rbx+E_baseSpeed], xmm0
    movss xmm0, [r13+8]
    mulss xmm0, xmm2
    movss [rbx+E_armor], xmm0
    movss xmm0, [r13+12]
    mulss xmm0, xmm2
    movss [rbx+E_energyResist], xmm0
    mov eax, [r13+16]
    mov [rbx+E_goldValue], eax
    mov eax, [r13+20]
    mov [rbx+E_xpValue], eax
    mov eax, [r13+32]
    cmp dword [r13+24], 0
    jl .aether_ready
    xor edi, edi
    mov esi, 100
    call GetRandomValue wrt ..plt
    cmp eax, [r13+24]
    mov eax, [r13+32]
    jge .aether_ready
    mov eax, [r13+28]
.aether_ready:
    mov [rbx+E_aetherValue], eax
.finished:
    mov eax, [rbx+E_maxHp]
    mov [rbx+E_hp], eax
    mov eax, [rbx+E_baseSpeed]
    mov [rbx+E_speed], eax
    RETURN 32

global HandleEnemyDeath
HandleEnemyDeath:
    cmp edi, 300
    jae .ignore
    imul eax, edi, E_SIZE
    lea rdx, [game+G_enemies]
    add rdx, rax
    cmp byte [rdx+E_active], 0
    je .ignore
    FRAME 16
    mov rbx, rdx
    mov r12d, esi
    mov byte [rbx+E_active], 0
    mov eax, [rbx+E_goldValue]
    add [game+G_gold], eax
    mov ecx, [rbx+E_aetherValue]
    add [game+G_aether], ecx
    movq xmm0, [rbx+E_position]
    mov edi, 0xff00d7ff
    xor esi, esi
    lea rdx, [txt_gold]
    mov ecx, eax
    mov eax, 1
    call AddFloatingTextFmt
    cmp dword [rbx+E_aetherValue], 0
    jle .particles
    movq xmm0, [rbx+E_position]
    movss xmm1, [rbx+E_position+4]
    addss xmm1, [fp_20]
    unpcklps xmm0, xmm1
    mov edi, 0xffff64b4
    xor esi, esi
    lea rdx, [txt_aether]
    mov ecx, [rbx+E_aetherValue]
    mov eax, 1
    call AddFloatingTextFmt
.particles:
    movq xmm0, [rbx+E_position]
    mov edi, 40
    mov esi, 0xff3729e6
    mov edx, 0x00828282
    mov ecx, 1
    movss xmm1, [fp_100]
    mov eax, __float32__(8.0)
    movd xmm2, eax
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    cmp dword [rbx+E_type], 5
    jne .xp
    mov r13d, 4
.minion:
    mov edi, -20
    mov esi, 20
    call GetRandomValue wrt ..plt
    mov [rsp], eax
    mov edi, -20
    mov esi, 20
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    cvtsi2ss xmm0, dword [rsp]
    cvtsi2ss xmm1, eax
    unpcklps xmm0, xmm1
    movq xmm1, [rbx+E_position]
    addps xmm0, xmm1
    mov edi, 6
    call SpawnEnemy
    dec r13d
    jnz .minion
.xp:
    cmp r12d, 100
    jae .hero_xp
    mov edi, r12d
    mov esi, [rbx+E_xpValue]
    call GrantXP
    imul eax, r12d, T_SIZE
    lea rdx, [game+G_towers]
    inc dword [rdx+rax+T_kills]
.hero_xp:
    mov edi, [rbx+E_xpValue]
    cmp r12d, -2
    je .grant
    pxor xmm0, xmm0
    cvtsi2ss xmm0, edi
    mulss xmm0, [fp_04]
    cvttss2si edi, xmm0
.grant:
    call GrantHeroXP
    RETURN 16
.ignore:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
