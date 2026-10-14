; application/session: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern ApplyHeroSkills
extern BuildStaticMapRT
extern HandleInput
extern InitMap
extern IsKeyPressed
extern IsMouseButtonPressed
extern ManageWaves
extern ScreenShake
extern UpdateEnemies
extern UpdateEnvironment
extern UpdateHero
extern UpdateProjectiles
extern UpdateTowers
extern UpdateVFX
extern game
hero equ game+G_hero

section .rodata align=16
align 16
fp_two: dd 2.0
align 16
fp_20: dd 20.0
align 16
title: db 'Aetherium Vanguard - PRESTIGE EDITION v3.1.0 (Physics, Movement & Pathfinding Fixed)',0

section .text
global InitGame
InitGame:
    FRAME 0
    call InitMap
    call ResetGame
    mov dword [game+G_state], 0
    pxor xmm0, xmm0
    movups [game+G_camera], xmm0
    movq [game+G_camera+16], xmm0
    FLOAT dword [game+G_camera+20], 1.0
    call BuildStaticMapRT wrt ..plt
    RETURN 0

global ResetGame
ResetGame:
    FRAME 0
    xor eax, eax
    lea rdi, [game+G_towers]
    mov ecx, (G_lives-G_towers)/8
    rep stosq
    lea rdi, [game+G_occupied]
    mov ecx, 480/8
    rep stosq
    lea rdi, [hero]
    mov ecx, H_SIZE/4
    rep stosd
    mov dword [game+G_lives], 20
    mov dword [game+G_gold], 350
    mov dword [game+G_aether], 0
    mov dword [game+G_currentWave], 0
    FLOAT dword [game+G_waveTimer], 10.0
    mov byte [game+G_waveActive], 0
    mov dword [game+G_placingTower], -1
    mov dword [game+G_selectedTowerIndex], -1
    mov byte [game+G_showGrid], 0
    mov dword [game+G_enemyIdCounter], 1
    mov dword [game+G_dayNightCycle], 0
    mov dword [game+G_screenShakeDuration], 0
    FLOAT dword [hero+H_position], 100.0
    FLOAT dword [hero+H_position+4], 100.0
    mov dword [hero+H_level], 1
    mov dword [hero+H_xpToNextLevel], 250
    FLOAT dword [hero+H_attackRange], 65.0
    FLOAT dword [hero+H_attackCooldown], 0.6
    FLOAT dword [hero+H_dashCooldown], 6.0
    FLOAT dword [hero+H_burstCooldown], 20.0
    FLOAT dword [hero+H_lastMovementDirection], 1.0
    call ApplyHeroSkills
    RETURN 0

global UpdateGame
UpdateGame:
    FRAME 16
    movss [rsp], xmm0
    call UpdateEnvironment
    movss xmm0, [rsp]
    call UpdateVFX wrt ..plt
    mov byte [game+G_tooltip], 0
    mov eax, [game+G_state]
    cmp eax, 0
    je .title
    cmp eax, 1
    je .playing
    cmp eax, 2
    je .paused
    cmp eax, 3
    je .over
    cmp eax, 4
    jne .done
    call UpdateHeroLevelUp
    jmp .done
.title:
    mov edi, 257
    call IsKeyPressed wrt ..plt
    test al, al
    jnz .start
    xor edi, edi
    call IsMouseButtonPressed wrt ..plt
    test al, al
    jz .done
    jmp .start
.over:
    mov edi, 82
    call IsKeyPressed wrt ..plt
    test al, al
    jz .done
.start:
    call ResetGame
    mov dword [game+G_state], 1
    jmp .done
.playing:
    movss xmm0, [rsp]
    call UpdatePlaying
    jmp .done
.paused:
    mov edi, 80
    call IsKeyPressed wrt ..plt
    test al, al
    jnz .resume
    mov edi, 256
    call IsKeyPressed wrt ..plt
    test al, al
    jz .inspect
.resume:
    mov dword [game+G_state], 1
.inspect:
    call HandleInput
.done:
    RETURN 16

global UpdatePlaying
UpdatePlaying:
    FRAME 16
    movss [rsp], xmm0
    mov edi, 80
    call IsKeyPressed wrt ..plt
    test al, al
    jz .skills
    mov dword [game+G_state], 2
    jmp .done
.skills:
    cmp dword [hero+H_skillPoints], 0
    jle .simulate
    mov dword [game+G_state], 4
    jmp .done
.simulate:
    call HandleInput
    movss xmm0, [rsp]
    call ManageWaves
    movss xmm0, [rsp]
    call UpdateHero
    movss xmm0, [rsp]
    call UpdateTowers
    movss xmm0, [rsp]
    call UpdateEnemies
    movss xmm0, [rsp]
    call UpdateProjectiles
    cmp dword [game+G_lives], 0
    jg .done
    mov dword [game+G_lives], 0
    cmp dword [game+G_state], 3
    je .done
    mov dword [game+G_state], 3
    movss xmm0, [fp_20]
    movss xmm1, [fp_two]
    call ScreenShake
.done:
    RETURN 16

global UpdateHeroLevelUp
UpdateHeroLevelUp:
    ; The draw-time skill buttons spend points; resume on the following update.
    cmp dword [hero+H_skillPoints], 0
    jne .done
    mov dword [game+G_state], 1
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
