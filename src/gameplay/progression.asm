; gameplay/progression: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingText
extern AddFloatingTextFmt
extern ConfigureTowerStats
extern SpawnParticles
extern game
extern powf
hero equ game+G_hero

section .rodata align=16
align 16
fp_one: dd 1.0
align 16
fp_01: dd 0.1
align 16
fp_02: dd 0.2
align 16
fp_015: dd 0.15
align 16
fp_09: dd 0.9
align 16
fp_095: dd 0.95
align 16
fp_16: dd 1.6
align 16
fp_5: dd 5.0
align 16
fp_6: dd 6.0
align 16
fp_10: dd 10.0
align 16
fp_25: dd 25.0
align 16
fp_100: dd 100.0
align 16
fp_120: dd 120.0
align 16
fp_150: dd 150.0
align 16
fp_180: dd 180.0
align 16
txt_tower_level: db 'LEVEL UP!',0
align 16
txt_hero_level: db 'HERO LEVEL UP!',0
align 16
txt_xp: db '+%d XP',0

section .text
global ApplyHeroSkills
ApplyHeroSkills:
    FRAME 32
    mov ebx, [hero+H_level]
    dec ebx
    pxor xmm1, xmm1
    cvtsi2ss xmm1, ebx
    movss [rsp], xmm1
    movss xmm0, [fp_095]
    call powf wrt ..plt
    mulss xmm0, [fp_6]
    movss [rsp+4], xmm0
    imul eax, ebx, 10
    add eax, 35
    imul edx, dword [hero+H_skills], 15
    add eax, edx
    mov [hero+H_attackDamage], eax
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [hero+H_skills+4]
    mulss xmm0, [fp_01]
    addss xmm0, [fp_one]
    movss xmm1, [rsp]
    mulss xmm1, [fp_5]
    addss xmm1, [fp_180]
    mulss xmm0, xmm1
    movss [hero+H_speed], xmm0
    pxor xmm1, xmm1
    cvtsi2ss xmm1, dword [hero+H_skills+4]
    movss xmm0, [fp_09]
    call powf wrt ..plt
    mulss xmm0, [rsp+4]
    movss [hero+H_dashCooldown], xmm0
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [hero+H_skills+8]
    movaps xmm1, xmm0
    mulss xmm0, [fp_02]
    addss xmm0, [fp_one]
    movss xmm2, [rsp]
    mulss xmm2, [fp_25]
    addss xmm2, [fp_100]
    mulss xmm0, xmm2
    movss [hero+H_burstDamage], xmm0
    mulss xmm1, [fp_01]
    addss xmm1, [fp_one]
    movss xmm2, [rsp]
    mulss xmm2, [fp_5]
    addss xmm2, [fp_120]
    mulss xmm1, xmm2
    movss [hero+H_burstRange], xmm1
    RETURN 32

global GrantHeroXP
GrantHeroXP:
    FRAME 0
    add [hero+H_xp], edi
.check:
    mov eax, [hero+H_xp]
    cmp eax, [hero+H_xpToNextLevel]
    jl .done
    call LevelUpHero
    jmp .check
.done:
    RETURN 0

global LevelUpHero
LevelUpHero:
    FRAME 0
    mov eax, [hero+H_xpToNextLevel]
    sub [hero+H_xp], eax
    inc dword [hero+H_level]
    pxor xmm0, xmm0
    cvtsi2ss xmm0, eax
    mulss xmm0, [fp_16]
    cvttss2si eax, xmm0
    mov [hero+H_xpToNextLevel], eax
    inc dword [hero+H_skillPoints]
    call ApplyHeroSkills
    movq xmm0, [hero+H_position]
    lea rdi, [txt_hero_level]
    mov esi, 0xffff64b4
    mov edx, 1
    call AddFloatingText
    movq xmm0, [hero+H_position]
    mov edi, 70
    mov esi, 0xffff64b4
    mov edx, 0x00ff64b4
    xor ecx, ecx
    mov eax, __float32__(140.0)
    movd xmm1, eax
    mov eax, __float32__(12.0)
    movd xmm2, eax
    mov eax, __float32__(4.0)
    movd xmm3, eax
    call SpawnParticles wrt ..plt
    RETURN 0

global GrantXP
GrantXP:
    cmp edi, 100
    jae .ignore
    imul eax, edi, T_SIZE
    lea rdx, [game+G_towers]
    add rdx, rax
    cmp byte [rdx+T_active], 0
    je .ignore
    cmp dword [rdx+T_type], 3
    ja .ignore
    FRAME 16
    mov rbx, rdx
    mov r12d, edi
    mov r13d, esi
    cmp dword [hero+H_skills+12], 0
    jle .add
    movq xmm0, [rbx+T_position]
    movq xmm1, [hero+H_position]
    subps xmm0, xmm1
    mulps xmm0, xmm0
    movaps xmm1, xmm0
    shufps xmm1, xmm1, 0x55
    addss xmm0, xmm1
    sqrtss xmm0, xmm0
    ucomiss xmm0, [fp_150]
    ja .add
    jp .add
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    cvtsi2ss xmm0, dword [hero+H_skills+12]
    mulss xmm0, [fp_015]
    cvtsi2ss xmm1, r13d
    mulss xmm0, xmm1
    cvttss2si eax, xmm0
    add r13d, eax
.add:
    add [rbx+T_stats+S_xp], r13d
    movq xmm0, [rbx+T_position]
    mov edi, 0xff32ff32
    xor esi, esi
    lea rdx, [txt_xp]
    mov ecx, r13d
    mov eax, 1
    call AddFloatingTextFmt
.level_check:
    cmp dword [rbx+T_stats+S_level], 3
    jge .done
    mov eax, [rbx+T_stats+S_xp]
    cmp eax, [rbx+T_stats+S_xpToNextLevel]
    jl .done
    mov edi, r12d
    call LevelUpTower
    jmp .level_check
.done:
    RETURN 16
.ignore:
    ret

global LevelUpTower
LevelUpTower:
    FRAME 0
    imul eax, edi, T_SIZE
    lea rbx, [game+G_towers]
    add rbx, rax
    mov eax, [rbx+T_stats+S_xpToNextLevel]
    sub [rbx+T_stats+S_xp], eax
    inc dword [rbx+T_stats+S_level]
    mov rdi, rbx
    call ConfigureTowerStats
    movq xmm0, [rbx+T_position]
    lea rdi, [txt_tower_level]
    mov esi, 0xff00f9fd
    mov edx, 1
    call AddFloatingText
    movq xmm0, [rbx+T_position]
    mov edi, 60
    mov esi, 0xff00f9fd
    mov edx, 0x0000f9fd
    xor ecx, ecx
    movss xmm1, [fp_120]
    movss xmm2, [fp_10]
    mov eax, __float32__(3.0)
    movd xmm3, eax
    call SpawnParticles wrt ..plt
    RETURN 0

section .note.GNU-stack noalloc noexec nowrite progbits
