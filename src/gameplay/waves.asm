; gameplay/waves: handwritten NASM, System V AMD64 ABI.
bits 64
default rel
%include "src/include/abi.inc"
%include "src/include/calling_convention.inc"

extern AddFloatingText
extern AddFloatingTextFmt
extern GetRandomValue
extern IsKeyPressed
extern ScreenShake
extern SpawnEnemy
extern game

section .rodata align=16
align 16
fp_zero: dd 0.0
align 16
fp_one: dd 1.0
align 16
fp_half: dd 0.5
align 16
fp_03: dd 0.3
align 16
fp_004: dd 0.04
align 16
fp_14: dd 1.4
align 16
fp_35: dd 3.5
align 16
fp_10: dd 10.0
align 16
fp_100: dd 100.0
align 16
txt_wave: db 'WAVE %d INCOMING!',0
align 16
txt_wave_done: db 'Wave Complete! Bonus Resources!',0

section .text
global ManageWaves
ManageWaves:
    FRAME 16
    cmp byte [game+G_waveActive], 0
    jne .active
    movss xmm1, [game+G_waveTimer]
    subss xmm1, xmm0
    movss [game+G_waveTimer], xmm1
    ucomiss xmm1, [fp_zero]
    jp .next_key
    jbe .start
.next_key:
    mov edi, 78
    call IsKeyPressed wrt ..plt
    test al, al
    jz .done
    cmp dword [game+G_state], 1
    jne .done
.start:
    inc dword [game+G_currentWave]
    mov byte [game+G_waveActive], 1
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [game+G_currentWave]
    mulss xmm0, [fp_35]
    cvttss2si eax, xmm0
    add eax, 10
    mov [game+G_enemiesToSpawn], eax
    FLOAT dword [game+G_spawnTimer], 1.0
    mov eax, __float32__(480.0)
    movd xmm0, eax
    mov eax, __float32__(50.0)
    movd xmm1, eax
    unpcklps xmm0, xmm1
    mov edi, 0xffffdc00
    mov esi, 1
    lea rdx, [txt_wave]
    mov ecx, [game+G_currentWave]
    mov eax, 1
    call AddFloatingTextFmt
    mov eax, __float32__(3.0)
    movd xmm0, eax
    movss xmm1, [fp_half]
    call ScreenShake
    jmp .done
.active:
    cmp dword [game+G_enemiesToSpawn], 0
    jle .check_clear
    movss xmm1, [game+G_spawnTimer]
    subss xmm1, xmm0
    movss [game+G_spawnTimer], xmm1
    ucomiss xmm1, [fp_zero]
    jp .done
    ja .done
    xor edi, edi
    mov esi, 100
    call GetRandomValue wrt ..plt
    mov r12d, [game+G_currentWave]
    xor ebx, ebx
    cmp r12d, 2
    jl .composition_done
    cmp eax, 30
    jge .tank
    mov ebx, 1
.tank:
    cmp r12d, 4
    jl .composition_done
    cmp eax, 70
    jl .ethereal
    cmp eax, 85
    jge .ethereal
    mov ebx, 2
.ethereal:
    cmp r12d, 6
    jl .composition_done
    cmp eax, 50
    jl .healer
    cmp eax, 65
    jge .healer
    mov ebx, 3
.healer:
    cmp r12d, 8
    jl .composition_done
    cmp eax, 85
    jl .spawner
    cmp eax, 95
    jge .spawner
    mov ebx, 4
.spawner:
    cmp r12d, 10
    jl .composition_done
    cmp eax, 40
    jl .composition_done
    cmp eax, 50
    jge .composition_done
    mov ebx, 5
.composition_done:
    mov eax, r12d
    cdq
    mov ecx, 5
    idiv ecx
    test edx, edx
    jnz .boss
    mov eax, [game+G_enemiesToSpawn]
    cdq
    mov ecx, 10
    idiv ecx
    test edx, edx
    jnz .boss
    mov edi, 5
    movq xmm0, [game+G_map+M_waypoints]
    call SpawnEnemy
.boss:
    mov eax, r12d
    cdq
    mov ecx, 10
    idiv ecx
    test edx, edx
    jnz .spawn
    cmp dword [game+G_enemiesToSpawn], 1
    jne .spawn
    mov ebx, 7
    movss xmm0, [fp_10]
    movss xmm1, [fp_one]
    call ScreenShake
.spawn:
    mov edi, ebx
    movq xmm0, [game+G_map+M_waypoints]
    call SpawnEnemy
    dec dword [game+G_enemiesToSpawn]
    pxor xmm0, xmm0
    cvtsi2ss xmm0, dword [game+G_currentWave]
    mulss xmm0, [fp_004]
    movss xmm1, [fp_14]
    subss xmm1, xmm0
    maxss xmm1, [fp_03]
    movss [game+G_spawnTimer], xmm1
    jmp .done
.check_clear:
    lea rax, [game+G_enemies]
    mov ecx, 300
.scan:
    cmp byte [rax+E_active], 0
    jne .done
    add rax, E_SIZE
    dec ecx
    jnz .scan
    mov byte [game+G_waveActive], 0
    FLOAT dword [game+G_waveTimer], 25.0
    mov eax, [game+G_currentWave]
    imul edx, eax, 20
    add edx, 50
    add [game+G_gold], edx
    cdq
    mov ecx, 3
    idiv ecx
    add eax, 5
    add [game+G_aether], eax
    mov eax, __float32__(480.0)
    movd xmm0, eax
    movss xmm1, [fp_100]
    unpcklps xmm0, xmm1
    lea rdi, [txt_wave_done]
    mov esi, 0xff00d7ff
    xor edx, edx
    call AddFloatingText
.done:
    RETURN 16

section .note.GNU-stack noalloc noexec nowrite progbits
