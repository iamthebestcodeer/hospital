; gameplay/hero: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingText
extern AddFloatingTextFmt
extern ApplyStatusEffect
extern CalculateDamage
extern HandleEnemyDeath
extern IsKeyDown
extern IsKeyPressed
extern ScreenShake
extern SpawnParticles
extern game
hero equ game+G_hero

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
fp_45: dd 4.5
align 16
fp_5: dd 5.0
align 16
fp_6: dd 6.0
align 16
fp_10: dd 10.0
align 16
fp_100: dd 100.0
align 16
fp_150: dd 150.0
align 16
fp_950: dd 950.0
align 16
fp_790: dd 790.0
align 16
txt_damage: db '%.0f',0
align 16
txt_burst: db 'AETHER BURST!',0
; HP, speed, armor, resistance, gold, XP, aether chance, success, failure.

section .text
global UpdateHero
UpdateHero:
    FRAME 32
    movss [rsp], xmm0
    xor r12d, r12d
    xor r13d, r13d
    mov edi, 87
    call IsKeyDown wrt ..plt
    test al, al
    jz .south
    dec r13d
.south:
    mov edi, 83
    call IsKeyDown wrt ..plt
    test al, al
    jz .west
    inc r13d
.west:
    mov edi, 65
    call IsKeyDown wrt ..plt
    test al, al
    jz .east
    dec r12d
.east:
    mov edi, 68
    call IsKeyDown wrt ..plt
    test al, al
    jz .input_ready
    inc r12d
.input_ready:
    pxor xmm0, xmm0
    pxor xmm1, xmm1
    cvtsi2ss xmm0, r12d
    cvtsi2ss xmm1, r13d
    unpcklps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [fp_zero]
    jbe .movement_ready
    movss xmm2, [fp_one]
    divss xmm2, xmm1
    shufps xmm2, xmm2, 0
    mulps xmm0, xmm2
    movq [hero+H_lastMovementDirection], xmm0
.movement_ready:
    movq [rsp+8], xmm0
    movq [rsp+24], xmm0
    movss xmm1, [hero+H_currentDashCooldown]
    subss xmm1, [rsp]
    movss [hero+H_currentDashCooldown], xmm1
    movss xmm1, [hero+H_dashTimer]
    subss xmm1, [rsp]
    movss [hero+H_dashTimer], xmm1
    movss xmm0, [hero+H_speed]
    movss [rsp+16], xmm0
    ucomiss xmm1, [fp_zero]
    ja .dashing
    mov edi, 81
    call IsKeyPressed wrt ..plt
    test al, al
    jz .move
    movss xmm0, [hero+H_currentDashCooldown]
    ucomiss xmm0, [fp_zero]
    jp .move
    ja .move
    FLOAT dword [hero+H_dashTimer], 0.2
    mov eax, [hero+H_dashCooldown]
    mov [hero+H_currentDashCooldown], eax
    movq xmm0, [rsp+8]
    LENGTH
    ucomiss xmm1, [fp_zero]
    ja .dash_direction
    movq xmm0, [hero+H_lastMovementDirection]
.dash_direction:
    movq [hero+H_dashDirection], xmm0
    movq [rsp+24], xmm0
    movss xmm0, [rsp+16]
    mulss xmm0, [fp_45]
    movss [rsp+16], xmm0
    movq xmm0, [hero+H_position]
    mov edi, 30
    mov esi, 0xffff64b4
    mov edx, 0x00ff64b4
    xor ecx, ecx
    mov eax, __float32__(80.0)
    movd xmm1, eax
    mov eax, __float32__(8.0)
    movd xmm2, eax
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    jmp .move
.dashing:
    movq xmm0, [hero+H_dashDirection]
    movq [rsp+24], xmm0
    movss xmm0, [rsp+16]
    mulss xmm0, [fp_45]
    movss [rsp+16], xmm0
.move:
    movq xmm0, [rsp+24]
    LENGTH
    ucomiss xmm1, [fp_zero]
    jbe .constrain
    movss xmm1, [rsp+16]
    mulss xmm1, [rsp]
    shufps xmm1, xmm1, 0
    mulps xmm0, xmm1
    movq xmm1, [hero+H_position]
    addps xmm0, xmm1
    movq [hero+H_position], xmm0
.constrain:
    movss xmm0, [hero+H_position]
    CLAMP xmm0, fp_10, fp_950
    movss [hero+H_position], xmm0
    movss xmm0, [hero+H_position+4]
    CLAMP xmm0, fp_10, fp_790
    movss [hero+H_position+4], xmm0
    movss xmm0, [hero+H_currentCooldown]
    subss xmm0, [rsp]
    movss [hero+H_currentCooldown], xmm0
    mov edi, 32
    call IsKeyDown wrt ..plt
    test al, al
    jz .burst_timer
    movss xmm0, [hero+H_currentCooldown]
    ucomiss xmm0, [fp_zero]
    jp .burst_timer
    ja .burst_timer
    call HeroAttack
    mov eax, [hero+H_attackCooldown]
    mov [hero+H_currentCooldown], eax
.burst_timer:
    movss xmm0, [hero+H_currentBurstCooldown]
    subss xmm0, [rsp]
    movss [hero+H_currentBurstCooldown], xmm0
    mov edi, 69
    call IsKeyPressed wrt ..plt
    test al, al
    jz .done
    movss xmm0, [hero+H_currentBurstCooldown]
    ucomiss xmm0, [fp_zero]
    jp .done
    ja .done
    movq xmm0, [hero+H_position]
    lea rdi, [txt_burst]
    mov esi, 0xffffdc00
    mov edx, 1
    call AddFloatingText
    movss xmm0, [fp_5]
    movss xmm1, [fp_03]
    call ScreenShake
    movq xmm0, [hero+H_position]
    mov edi, 200
    mov esi, 0xffffdc00
    mov edx, 0x7fffffff
    xor ecx, ecx
    movss xmm1, [fp_150]
    movss xmm2, [fp_10]
    movss xmm3, [fp_two]
    call SpawnParticles wrt ..plt
    movq xmm0, [hero+H_position]
    mov edi, 50
    mov esi, 0xffff64b4
    mov edx, 0x00ff64b4
    xor ecx, ecx
    mov eax, __float32__(50.0)
    movd xmm1, eax
    mov eax, __float32__(15.0)
    movd xmm2, eax
    movss xmm3, [fp_5]
    call SpawnParticles wrt ..plt
    lea rbx, [game+G_enemies]
    xor r12d, r12d
.burst_enemy:
    cmp byte [rbx+E_active], 0
    je .burst_next
    movq xmm0, [hero+H_position]
    movq xmm1, [rbx+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [hero+H_burstRange]
    ja .burst_next
    jp .burst_next
    movss xmm0, [hero+H_burstDamage]
    mov edi, 2
    mov rsi, rbx
    call CalculateDamage
    movss xmm1, [rbx+E_hp]
    subss xmm1, xmm0
    movss [rbx+E_hp], xmm1
    cvtss2sd xmm1, xmm0
    movq xmm0, [rbx+E_position]
    mov edi, 0xffffdc00
    mov esi, 1
    lea rdx, [txt_damage]
    mov eax, 2
    call AddFloatingTextFmt
    mov rdi, rbx
    mov esi, 8
    movss xmm0, [fp_6]
    mov eax, __float32__(1.25)
    movd xmm1, eax
    call ApplyStatusEffect
    movss xmm0, [rbx+E_hp]
    ucomiss xmm0, [fp_zero]
    jp .burst_next
    ja .burst_next
    mov edi, r12d
    mov esi, -2
    call HandleEnemyDeath
.burst_next:
    add rbx, E_SIZE
    inc r12d
    cmp r12d, 300
    jb .burst_enemy
    mov eax, [hero+H_burstCooldown]
    mov [hero+H_currentBurstCooldown], eax
.done:
    RETURN 32

global HeroAttack
HeroAttack:
    FRAME 0
    lea rbx, [game+G_enemies]
    xor r12d, r12d
.enemy:
    cmp byte [rbx+E_active], 0
    je .next
    movq xmm0, [hero+H_position]
    movq xmm1, [rbx+E_position]
    subps xmm0, xmm1
    LENGTH
    ucomiss xmm1, [hero+H_attackRange]
    jae .next
    jp .next
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [hero+H_attackDamage]
    xor edi, edi
    mov rsi, rbx
    call CalculateDamage
    movss xmm1, [rbx+E_hp]
    subss xmm1, xmm0
    movss [rbx+E_hp], xmm1
    cvtss2sd xmm1, xmm0
    movq xmm0, [rbx+E_position]
    mov edi, 0xffff64b4
    xor esi, esi
    lea rdx, [txt_damage]
    mov eax, 2
    call AddFloatingTextFmt
    movq xmm0, [rbx+E_position]
    mov edi, 8
    mov esi, 0xffff64b4
    mov edx, 0x00ffffff
    xor ecx, ecx
    movss xmm1, [fp_100]
    movss xmm2, [fp_5]
    movss xmm3, [fp_one]
    call SpawnParticles wrt ..plt
    movss xmm0, [rbx+E_hp]
    ucomiss xmm0, [fp_zero]
    jp .next
    ja .next
    mov edi, r12d
    mov esi, -2
    call HandleEnemyDeath
.next:
    add rbx, E_SIZE
    inc r12d
    cmp r12d, 300
    jb .enemy
    RETURN 0

section .note.GNU-stack noalloc noexec nowrite progbits
