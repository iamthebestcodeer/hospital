; Rendering/UI translated from corrected reference/linux.c.
; Gameplay is handwritten in src/domain, src/gameplay, src/application and src/platform.
; NASM x86-64, System V ABI. See tools/generate.py.
bits 64
default rel
extern AddFloatingText
extern ApplyHeroSkills
extern BeginBlendMode
extern BeginDrawing
extern BeginMode2D
extern BeginTextureMode
extern CheckCollisionPointRec
extern ClearBackground
extern ColorAlphaBlend
extern ColorBrightness
extern ColorLerp
extern ColorTint
extern ConfigureTowerStats
extern DrawCircleLines
extern DrawCircleV
extern DrawLine
extern DrawLineEx
extern DrawPoly
extern DrawRectangle
extern DrawRectangleGradientV
extern DrawRectangleLinesEx
extern DrawRectanglePro
extern DrawRectangleRec
extern DrawRectangleRounded
extern DrawRectangleRoundedLines
extern DrawText
extern DrawTextPro
extern DrawTexturePro
extern EndBlendMode
extern EndDrawing
extern EndMode2D
extern EndTextureMode
extern Fade
extern GetAimToleranceDegrees
extern GetFontDefault
extern GetMousePosition
extern GetRandomValue
extern GetScreenToWorld2D
extern GetTowerAetherCost
extern GetTowerCost
extern IsMouseButtonPressed
extern IsTileBuildable
extern LoadRenderTexture
extern MeasureText
extern ScreenShake
extern SellTower
extern TileToWorldCenter
extern UpgradeTower
extern WorldToTile
extern atan2f
extern fmodf
extern game
extern sincosf
extern sinf
extern snprintf
section .text
align 16
BuildStaticMapRT.part.0:
    push r15
    mov edx, 800
    mov esi, 960
    push r14
    lea r14, [rel game]
    push r13
    xor r13d, r13d
    push r12
    mov r12, -4294967296
    push rbp
    push rbx
    sub rsp, 88
    lea rdi, [rsp+32]
    call LoadRenderTexture wrt ..plt
    movdqu xmm0, oword [rsp+48]
    movdqu xmm1, oword [rsp+32]
    sub rsp, 48
    movups oword [rel 253388+game], xmm0
    movdqu xmm0, oword [rsp+108]
    movups oword [rel 253372+game], xmm1
    movups oword [rel 253400+game], xmm0
    movups oword [rsp], xmm1
    movdqu xmm1, oword [rel 253388+game]
    movups oword [rsp+16], xmm1
    movups oword [rsp+28], xmm0
    call BeginTextureMode wrt ..plt
    add rsp, 48
    mov edi, -15463926
    movss xmm0, dword [rel __gas_LC1]
    call ColorBrightness wrt ..plt
    mov r8d, -15463926
    xor esi, esi
    xor edi, edi
    mov r9d, eax
    mov ecx, 800
    mov edx, 960
    call DrawRectangleGradientV wrt ..plt
    jmp __gas_L2
align 16
align 8
__gas_L43:
    test r13b, 1
    jne __gas_L32
    mov ecx, 15
    mov edx, 30
    mov eax, 25
__gas_L17:
    mov bl, cl
    sal eax, 16
    movq xmm1, rdi
    mov bh, dl
    movd edx, xmm0
    and ebx, -16711681
    or ebx, eax
    mov rax, rsi
    and rax, r12
    or ebx, -16777216
    or rax, rdx
    mov edi, ebx
    mov eax, eax
    movq xmm0, rax
    call DrawRectangleRec wrt ..plt
    cmp dword [r14+4], 1
    je __gas_L42
    add r13d, 1
    add r14, 4
    cmp r13d, 24
    je __gas_L28
__gas_L2:
    pxor xmm0, xmm0
    xor esi, esi
    cmp dword [r14+4], 1
    mov ebp, r13d
    cvtsi2ss xmm0, r13d
    mulss xmm0, dword [rel __gas_LC0]
    mov rdi, qword [rel __gas_LC2]
    movss dword [rsp], xmm0
    jne __gas_L43
    mov ecx, 45
    mov edx, 30
    mov eax, 60
    jmp __gas_L17
__gas_L32:
    mov ecx, 20
    mov edx, 35
    mov eax, 30
    jmp __gas_L17
__gas_L42:
    movss xmm0, dword [rel __gas_LC3]
    mov edi, -39756
    call Fade wrt ..plt
    mov edi, dword [r14+100]
    test edi, edi
    je __gas_L19
__gas_L27:
    test ebp, ebp
    je __gas_L44
    mov ecx, dword [r14]
    test ecx, ecx
    je __gas_L24
__gas_L26:
    cmp ebp, 23
    je __gas_L28
    mov edx, dword [r14+8]
    test edx, edx
    je __gas_L21
    add r13d, 1
    add r14, 4
    jmp __gas_L2
__gas_L28:
    mov r13, -96
    mov r12d, 1
align 16
align 8
__gas_L15:
    pxor xmm0, xmm0
    lea r15, [rel game]
    mov r14, -96
    xor ebp, ebp
    cvtsi2ss xmm0, r12d
    mulss xmm0, dword [rel __gas_LC0]
    sub r15, r13
    sub r14, r13
    movss dword [rsp+12], xmm0
align 16
align 8
__gas_L14:
    pxor xmm0, xmm0
    movss xmm6, dword [rsp+12]
    movss xmm4, dword [rel __gas_LC0]
    cvtsi2ss xmm0, ebp
    cmp dword [r15+4], 1
    mov rdi, qword [rel __gas_LC2]
    mulss xmm4, xmm0
    movaps xmm5, xmm4
    movss dword [rsp+16], xmm4
    unpcklps xmm5, xmm6
    movlps qword [rsp], xmm5
    je __gas_L29
    lea eax, [rbp+r12+0]
    test al, 1
    jne __gas_L30
    mov r9d, 15
    mov edx, 30
    mov eax, 25
    movq rsi, xmm5
__gas_L3:
    mov bl, r9b
    sal eax, 16
    movq xmm1, rdi
    movq xmm0, rsi
    mov bh, dl
    and ebx, -16711681
    or ebx, eax
    or ebx, -16777216
    mov edi, ebx
    call DrawRectangleRec wrt ..plt
    cmp dword [r15+4], 1
    je __gas_L4
    add ebp, 1
    add r15, 4
    cmp ebp, 24
    jne __gas_L14
__gas_L6:
    add r12d, 1
    sub r13, 96
    cmp r12d, 20
    jne __gas_L15
    call EndTextureMode wrt ..plt
    mov byte [rel 253416+game], 1
    add rsp, 88
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L29:
    mov r9d, 45
    mov edx, 30
    mov eax, 60
    movq rsi, xmm5
    jmp __gas_L3
align 16
align 8
__gas_L30:
    mov r9d, 20
    mov edx, 35
    mov eax, 30
    movq rsi, xmm5
    jmp __gas_L3
align 16
align 8
__gas_L4:
    movss xmm0, dword [rel __gas_LC3]
    mov edi, -39756
    call Fade wrt ..plt
    lea rsi, [r15+r13]
    mov edx, dword [rsi+r14+4]
    test edx, edx
    je __gas_L7
__gas_L13:
    cmp r12d, 19
    je __gas_L8
    sub rsi, r13
    mov r11d, dword [rsi+100]
    test r11d, r11d
    je __gas_L45
__gas_L8:
    test ebp, ebp
    je __gas_L46
    mov r9d, dword [r15]
    test r9d, r9d
    je __gas_L47
__gas_L11:
    cmp ebp, 23
    je __gas_L6
    mov r8d, dword [r15+8]
    test r8d, r8d
    je __gas_L10
__gas_L40:
    add ebp, 1
    add r15, 4
    jmp __gas_L14
align 16
align 8
__gas_L46:
    mov r10d, dword [r15+8]
    test r10d, r10d
    je __gas_L10
    add r15, 4
    mov ebp, 1
    jmp __gas_L14
align 16
align 8
__gas_L45:
    movss xmm2, dword [rel __gas_LC0]
    addss xmm2, dword [rsp+12]
    mov edi, eax
    mov dword [rsp+20], eax
    movss xmm7, dword [rsp+16]
    movq xmm1, qword [rsp]
    addps xmm1, oword [rel __gas_LC5]
    unpcklps xmm7, xmm2
    movss xmm2, dword [rel __gas_LC4]
    movaps xmm0, xmm7
    call DrawLineEx wrt ..plt
    mov eax, dword [rsp+20]
    jmp __gas_L8
align 16
align 8
__gas_L10:
    movss xmm0, dword [rel __gas_LC0]
    addss xmm0, dword [rsp+16]
    mov edi, eax
    movq xmm1, qword [rsp]
    movss xmm7, dword [rsp+12]
    addps xmm1, oword [rel __gas_LC5]
    movss xmm2, dword [rel __gas_LC4]
    unpcklps xmm0, xmm7
    call DrawLineEx wrt ..plt
    jmp __gas_L40
__gas_L47:
    movss xmm0, dword [rel __gas_LC0]
    addss xmm0, dword [rsp+12]
    mov edi, eax
    mov dword [rsp+20], eax
    movq xmm3, qword [rsp]
    movss xmm1, dword [rsp+16]
    movss xmm2, dword [rel __gas_LC4]
    unpcklps xmm1, xmm0
    movdqa xmm0, xmm3
    call DrawLineEx wrt ..plt
    mov eax, dword [rsp+20]
    jmp __gas_L11
align 16
align 8
__gas_L7:
    movss xmm1, dword [rel __gas_LC0]
    addss xmm1, dword [rsp+16]
    mov edi, eax
    mov qword [rsp+24], rsi
    movss xmm3, dword [rsp+12]
    movss xmm2, dword [rel __gas_LC4]
    mov dword [rsp+20], eax
    movq xmm0, qword [rsp]
    unpcklps xmm1, xmm3
    call DrawLineEx wrt ..plt
    mov eax, dword [rsp+20]
    mov rsi, qword [rsp+24]
    jmp __gas_L13
__gas_L44:
    mov esi, dword [r14+8]
    test esi, esi
    je __gas_L21
    add r14, 4
    mov rdi, qword [rel __gas_LC2]
    cmp dword [r14+4], 1
    je __gas_L33
    mov ecx, 20
    mov edx, 35
    mov eax, 30
__gas_L22:
    mov dword [rsp], 0x42200000
    mov ebp, 1
    movss xmm0, dword [rsp]
    mov r13d, 1
    jmp __gas_L17
__gas_L21:
    movss xmm0, dword [rel __gas_LC0]
    addss xmm0, dword [rsp]
    mov edi, eax
    add r13d, 1
    mov rdx, 4764808405757984768
    movss xmm2, dword [rel __gas_LC4]
    add r14, 4
    movd ecx, xmm0
    or rdx, rcx
    movd ecx, xmm0
    movd xmm0, ecx
    movq xmm1, rdx
    call DrawLineEx wrt ..plt
    jmp __gas_L2
__gas_L19:
    movss xmm7, dword [rsp]
    movss xmm2, dword [rel __gas_LC0]
    mov edi, eax
    mov dword [rsp+12], eax
    mov rcx, 4764808405757984768
    addss xmm2, xmm7
    movd esi, xmm7
    or rsi, rcx
    movq xmm0, rsi
    movd edx, xmm2
    movss xmm2, dword [rel __gas_LC4]
    or rdx, rcx
    movq xmm1, rdx
    call DrawLineEx wrt ..plt
    mov eax, dword [rsp+12]
    jmp __gas_L27
__gas_L24:
    movss xmm2, dword [rsp]
    mov edi, eax
    mov dword [rsp+12], eax
    mov rdx, 4764808405757984768
    movd ecx, xmm2
    or rdx, rcx
    movd ecx, xmm2
    movss xmm2, dword [rel __gas_LC4]
    movd xmm3, ecx
    movq xmm1, rdx
    movdqa xmm0, xmm3
    call DrawLineEx wrt ..plt
    mov eax, dword [rsp+12]
    jmp __gas_L26
__gas_L33:
    mov ecx, 45
    mov edx, 30
    mov eax, 60
    jmp __gas_L22
align 16
DrawTooltip.part.0:
    push r13
    push r12
    push rbp
    push rbx
    sub rsp, 40
    call GetMousePosition wrt ..plt
    mov rdx, qword [rel 253328+game]
    movq r12, xmm0
    mov rax, r12
    shr rax, 32
    mov rbx, rax
    movzx eax, byte [rdx]
    test al, al
    je __gas_L56
    mov ecx, 1
align 32
align 16
align 8
__gas_L51:
    cmp al, 10
    sete al
    add rdx, 1
    movzx eax, al
    add ecx, eax
    movzx eax, byte [rdx]
    test al, al
    jne __gas_L51
    lea eax, [rcx+rcx*4]
    lea r13d, [rcx+rax*4]
__gas_L49:
    mov rdi, qword [rel 253320+game]
    mov esi, 20
    call MeasureText wrt ..plt
    mov rdi, qword [rel 253328+game]
    mov esi, 16
    mov ebp, eax
    call MeasureText wrt ..plt
    mov edx, 300
    pxor xmm4, xmm4
    movss xmm0, dword [rel __gas_LC6]
    movd xmm3, r12d
    movd xmm5, ebx
    pxor xmm2, xmm2
    cmp ebp, eax
    cmovge eax, ebp
    addss xmm3, xmm0
    addss xmm5, xmm0
    movss xmm1, dword [rel __gas_LC7]
    cvtsi2ss xmm2, r13d
    addss xmm2, dword [rel __gas_LC8]
    cmp eax, edx
    addss xmm2, dword [rel __gas_LC9]
    cmovg eax, edx
    movaps xmm6, xmm3
    cvtsi2ss xmm4, eax
    addss xmm1, xmm4
    addss xmm6, xmm1
    comiss xmm6, dword [rel __gas_LC10]
    ja __gas_L57
    movss xmm6, dword [rel __gas_LC11]
__gas_L52:
    movaps xmm7, xmm5
    addss xmm7, xmm2
    comiss xmm7, dword [rel __gas_LC12]
    jbe __gas_L54
    movd xmm5, ebx
    subss xmm5, xmm2
    subss xmm5, xmm0
__gas_L54:
    movaps xmm7, xmm1
    movss xmm0, dword [rel __gas_LC13]
    mov edi, -15463926
    movss dword [rsp+28], xmm6
    unpcklps xmm7, xmm2
    movss dword [rsp+24], xmm4
    movq rbx, xmm7
    movaps xmm7, xmm3
    movss dword [rsp+20], xmm3
    unpcklps xmm7, xmm5
    movss dword [rsp+12], xmm5
    movq rbp, xmm7
    call Fade wrt ..plt
    movq xmm0, rbp
    movq xmm1, rbx
    mov qword [rsp], rbp
    mov edi, eax
    call DrawRectangleRec wrt ..plt
    movq xmm0, qword [rsp]
    movq xmm1, rbx
    movss xmm2, dword [rel __gas_LC14]
    mov edi, -12836061
    call DrawRectangleLinesEx wrt ..plt
    movss xmm3, dword [rsp+20]
    movss xmm0, dword [rel __gas_LC15]
    mov r8d, -9216
    movss xmm5, dword [rsp+12]
    movss xmm1, dword [rel __gas_LC15]
    mov ecx, 20
    addss xmm0, xmm3
    mov rdi, qword [rel 253320+game]
    movss dword [rsp+12], xmm3
    addss xmm1, xmm5
    movss dword [rsp+16], xmm5
    cvttss2si ebx, xmm0
    cvttss2si edx, xmm1
    movss dword [rsp], xmm1
    mov esi, ebx
    call DrawText wrt ..plt
    movss xmm1, dword [rsp]
    mov edi, ebx
    addss xmm1, dword [rel __gas_LC8]
    movss xmm6, dword [rsp+28]
    movss xmm3, dword [rsp+12]
    mov r8d, -12836061
    movss xmm4, dword [rsp+24]
    addss xmm1, xmm6
    addss xmm4, xmm3
    addss xmm4, dword [rel __gas_LC15]
    cvttss2si esi, xmm1
    cvttss2si edx, xmm4
    mov ecx, esi
    call DrawLine wrt ..plt
    movss xmm0, dword [rel __gas_LC7]
    movss xmm5, dword [rsp+16]
    mov esi, ebx
    mov rdi, qword [rel 253328+game]
    mov r8d, -2571
    mov ecx, 16
    addss xmm0, xmm5
    addss xmm0, dword [rel __gas_LC8]
    add rsp, 40
    pop rbx
    pop rbp
    pop r12
    pop r13
    cvttss2si edx, xmm0
    jmp DrawText wrt ..plt
align 16
align 8
__gas_L57:
    movss xmm3, dword [rel __gas_LC10]
    movss xmm6, dword [rel __gas_LC11]
    subss xmm3, xmm1
    subss xmm3, xmm6
    jmp __gas_L52
align 16
align 8
__gas_L56:
    mov r13d, 21
    jmp __gas_L49
align 16
global BuildStaticMapRT
BuildStaticMapRT:
    cmp byte [rel 253416+game], 0
    je __gas_L63
    ret
align 16
align 8
__gas_L63:
    jmp BuildStaticMapRT.part.0
align 16
global AVDrawRectangleRoundedLinesEx
AVDrawRectangleRoundedLinesEx:
    push r13
    movdqa xmm6, xmm0
    push r12
    push rbp
    mov ebp, esi
    push rbx
    mov ebx, edi
    sub rsp, 56
    movss xmm5, dword [rel __gas_LC14]
    comiss xmm5, xmm3
    jnb __gas_L77
    movss xmm4, dword [rel __gas_LC19]
    movss xmm7, dword [rel __gas_LC16]
    movaps xmm0, xmm3
    andps xmm0, xmm4
    ucomiss xmm7, xmm0
    ja __gas_L78
__gas_L67:
    cvttss2si r12d, xmm3
    test r12d, r12d
    jle __gas_L64
    movq xmm5, xmm6
    movq xmm7, xmm1
    pxor xmm4, xmm4
    xor r13d, r13d
    movaps oword [rsp+16], xmm5
    movaps oword [rsp+32], xmm7
    jmp __gas_L71
align 16
align 8
__gas_L79:
    comiss xmm4, xmm6
    jnb __gas_L64
    mov esi, ebp
    mov edi, ebx
    add r13d, 1
    movss dword [rsp+12], xmm2
    call DrawRectangleRoundedLines wrt ..plt
    cmp r12d, r13d
    movss xmm2, dword [rsp+12]
    pxor xmm4, xmm4
    je __gas_L64
__gas_L71:
    lea eax, [r13+r13]
    pxor xmm1, xmm1
    movaps xmm3, oword [rsp+32]
    pxor xmm0, xmm0
    cvtsi2ss xmm1, eax
    cvtsi2ss xmm0, r13d
    shufps xmm1, xmm1, 0xe0
    movq xmm1, xmm1
    subps xmm3, xmm1
    shufps xmm0, xmm0, 0xe0
    movq xmm0, xmm0
    addps xmm0, oword [rsp+16]
    comiss xmm4, xmm3
    movaps xmm6, xmm3
    movaps xmm1, xmm3
    shufps xmm6, xmm6, 0xe5
    jb __gas_L79
__gas_L64:
    add rsp, 56
    pop rbx
    pop rbp
    pop r12
    pop r13
    ret
align 16
align 8
__gas_L78:
    cvttss2si eax, xmm3
    pxor xmm0, xmm0
    andnps xmm4, xmm3
    cvtsi2ss xmm0, eax
    movaps xmm7, xmm0
    cmpnless xmm7, xmm3
    andps xmm7, xmm5
    subss xmm0, xmm7
    movaps xmm3, xmm0
    orps xmm3, xmm4
    jmp __gas_L67
align 16
align 8
__gas_L77:
    add rsp, 56
    pop rbx
    pop rbp
    pop r12
    pop r13
    jmp DrawRectangleRoundedLines wrt ..plt
align 16
global DrawMap
DrawMap:
    cmp byte [rel 253416+game], 0
    push r12
    push rbp
    push rbx
    je __gas_L91
__gas_L81:
    pxor xmm1, xmm1
    pxor xmm6, xmm6
    sub rsp, 32
    xor r12d, r12d
    cvtsi2ss xmm1, dword [rel 253380+game]
    pxor xmm5, xmm5
    pxor xmm4, xmm4
    mov eax, dword [rel 253392+game]
    pxor xmm2, xmm2
    movdqu xmm0, oword [rel 253376+game]
    cvtsi2ss xmm6, dword [rel 253384+game]
    xorps xmm6, oword [rel __gas_LC20]
    mov dword [rsp+16], eax
    mov edi, -1
    lea rbp, [rel game]
    mov rax, 4920182594050457600
    movq xmm3, rax
    movups oword [rsp], xmm0
    pxor xmm0, xmm0
    unpcklps xmm1, xmm6
    call DrawTexturePro wrt ..plt
    add rsp, 32
    mov edi, 2
    call BeginBlendMode wrt ..plt
    mov r8d, dword [rel 253368+game]
    xor esi, esi
    xor edi, edi
    mov ecx, 800
    mov edx, 960
    call DrawRectangle wrt ..plt
    call EndBlendMode wrt ..plt
    cmp byte [rel 253296+game], 0
    jne __gas_L83
__gas_L82:
    pop rbx
    pop rbp
    pop r12
    ret
align 16
align 8
__gas_L92:
    add r12d, 1
    add rbp, 96
    cmp r12d, 20
    je __gas_L82
__gas_L83:
    xor ebx, ebx
    jmp __gas_L85
align 32
align 16
align 8
__gas_L84:
    add rbx, 1
    cmp rbx, 24
    je __gas_L92
__gas_L85:
    mov eax, dword [rbp+rbx*4+4]
    test eax, eax
    jne __gas_L84
    movd xmm0, ebx
    movd xmm7, r12d
    mov rax, 4764808406867378176
    movss xmm2, dword [rel __gas_LC14]
    punpckldq xmm0, xmm7
    mov edi, 1682319400
    movq xmm1, rax
    movq xmm0, xmm0
    cvtdq2ps xmm0, xmm0
    movq xmm0, xmm0
    mulps xmm0, oword [rel __gas_LC5]
    call DrawRectangleLinesEx wrt ..plt
    jmp __gas_L84
__gas_L91:
    call BuildStaticMapRT.part.0
    jmp __gas_L81
section .rodata
__gas_LC31:
db 42, 83, 84, 85, 78, 42, 0
section .text
__gas_LCOLDB38:
section .text
__gas_LHOTB38:
align 16
global DrawEnemies
DrawEnemies:
    push r15
    lea r15, [rel 10456+game]
    push r14
    push r13
    push r12
    push rbp
    push rbx
    sub rsp, 88
align 16
align 8
__gas_L131:
    movzx ebp, byte [r15+56]
    test bpl, bpl
    je __gas_L94
    cmp dword [r15+8], 7
    ja __gas_L132
    mov eax, dword [r15+8]
    lea rdx, [rel __gas_L97]
    movsx rax, dword [rdx+rax*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L97:
dd __gas_L104-__gas_L97
dd __gas_L103-__gas_L97
dd __gas_L102-__gas_L97
dd __gas_L101-__gas_L97
dd __gas_L100-__gas_L97
dd __gas_L99-__gas_L97
dd __gas_L98-__gas_L97
dd __gas_L96-__gas_L97
section .text
align 16
align 8
__gas_L98:
    movss xmm7, dword [rel __gas_LC24]
    mov ebx, -11513776
    movss dword [rsp+8], xmm7
align 16
align 8
__gas_L95:
    mov esi, dword [rel 253368+game]
    mov edi, ebx
    call ColorTint wrt ..plt
    mov ebx, eax
    mov eax, dword [r15+160]
    test eax, eax
    jg __gas_L153
__gas_L107:
    mov eax, dword [r15+8]
    cmp eax, 4
    je __gas_L154
__gas_L118:
    cmp eax, 5
    je __gas_L155
    movss xmm1, dword [rsp+8]
    movq xmm0, qword [r15]
    mov edi, ebx
    call DrawCircleV wrt ..plt
__gas_L119:
    movss xmm1, dword [r15+20]
    pxor xmm2, xmm2
    comiss xmm1, xmm2
    jbe __gas_L94
    movss xmm0, dword [r15+16]
    comiss xmm1, xmm0
    jbe __gas_L94
    divss xmm0, xmm1
    movss xmm7, dword [rsp+8]
    comiss xmm7, dword [rel __gas_LC7]
    movaps xmm1, xmm0
    cmpnltss xmm1, xmm2
    pxor xmm2, xmm2
    andps xmm0, xmm1
    andnps xmm1, xmm2
    movss xmm2, dword [rel __gas_LC14]
    orps xmm0, xmm1
    movss xmm1, dword [rel __gas_LC14]
    cmpltss xmm2, xmm0
    andps xmm1, xmm2
    andnps xmm2, xmm0
    orps xmm2, xmm1
    ja __gas_L134
    movss xmm0, dword [rel __gas_LC7]
    movss xmm5, dword [rel __gas_LC0]
__gas_L126:
    movss xmm4, dword [r15]
    mov rax, r13
    movd edx, xmm5
    mov edi, -14478316
    mov rcx, -4294967296
    movss xmm3, dword [r15+4]
    subss xmm3, dword [rsp+8]
    movss dword [rsp+20], xmm2
    subss xmm4, xmm0
    and rax, rcx
    subss xmm3, dword [rel __gas_LC15]
    movss dword [rsp+8], xmm5
    or rax, rdx
    mov rdx, 4665729213955833856
    mov eax, eax
    movaps xmm6, xmm4
    or rax, rdx
    movss dword [rsp+16], xmm4
    unpcklps xmm6, xmm3
    movq xmm1, rax
    movss dword [rsp+12], xmm3
    mov r13, rax
    movdqa xmm0, xmm6
    movq r12, xmm6
    call DrawRectangleRec wrt ..plt
    movss xmm0, dword [rel __gas_LC35]
    movss xmm2, dword [rsp+20]
    mov r8d, -13573120
    movss xmm5, dword [rsp+8]
    movss xmm3, dword [rsp+12]
    comiss xmm0, xmm2
    movss xmm4, dword [rsp+16]
    jbe __gas_L151
    and r8d, -16777216
    or r8d, 3615206
__gas_L129:
    mulss xmm2, xmm5
    cvttss2si edi, xmm4
    mov ecx, 6
    cvttss2si esi, xmm3
    cvttss2si edx, xmm2
    call DrawRectangle wrt ..plt
    mov edi, -16777216
    movq xmm0, r12
    movss xmm2, dword [rel __gas_LC14]
    movq xmm1, r13
    call DrawRectangleLinesEx wrt ..plt
align 16
align 8
__gas_L94:
    add r15, 164
    lea rax, [rel 59656+game]
    cmp rax, r15
    jne __gas_L131
    add rsp, 88
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L99:
    movss xmm6, dword [rel __gas_LC7]
    mov ebx, -34104
    movss dword [rsp+8], xmm6
    jmp __gas_L95
align 16
align 8
__gas_L103:
    movss xmm7, dword [rel __gas_LC15]
    mov ebx, -16735745
    movss dword [rsp+8], xmm7
    jmp __gas_L95
align 16
align 8
__gas_L96:
    movss xmm5, dword [rel __gas_LC25]
    mov ebx, -13162010
    movss dword [rsp+8], xmm5
    jmp __gas_L95
align 16
align 8
__gas_L104:
    movss xmm7, dword [rel __gas_LC21]
    mov ebx, -13164098
    movss dword [rsp+8], xmm7
    jmp __gas_L95
align 16
align 8
__gas_L101:
    movss xmm0, dword [rel __gas_LC27]
    mov edi, -9216
    call Fade wrt ..plt
    movss xmm7, dword [rel __gas_LC23]
    mov ebx, eax
    movss dword [rsp+8], xmm7
    jmp __gas_L95
align 16
align 8
__gas_L102:
    movss xmm5, dword [rel __gas_LC22]
    mov ebx, -13680820
    movss dword [rsp+8], xmm5
    jmp __gas_L95
align 16
align 8
__gas_L100:
    movss xmm5, dword [rel __gas_LC6]
    mov ebx, -13656576
    movss dword [rsp+8], xmm5
    jmp __gas_L95
align 16
align 8
__gas_L153:
    mov byte [rsp+16], 0
    lea rcx, [r15+-10456]
    xor r8d, r8d
    lea r14, [rel __gas_L110]
    mov byte [rsp+12], 0
align 16
align 8
__gas_L115:
    cmp dword [rcx+10520], 32
    ja __gas_L113
    mov edx, dword [rcx+10520]
    movsx rdx, dword [r14+rdx*4]
    add rdx, r14
    jmp rdx
section .rodata
align 4
align 4
__gas_L110:
dd __gas_L113-__gas_L110
dd __gas_L111-__gas_L110
dd __gas_L114-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L133-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L112-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L111-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L113-__gas_L110
dd __gas_L109-__gas_L110
section .text
align 16
align 8
__gas_L111:
    movss xmm0, dword [rel __gas_LC28]
    mov edi, -1
    mov qword [rsp+24], rcx
    mov dword [rsp+20], r8d
    call Fade wrt ..plt
    mov edi, ebx
    mov esi, -340345
    mov edx, eax
    call ColorAlphaBlend wrt ..plt
    mov r8d, dword [rsp+20]
    mov rcx, qword [rsp+24]
    mov ebx, eax
    mov eax, dword [r15+160]
align 16
align 8
__gas_L113:
    add r8d, 1
    add rcx, 16
    cmp r8d, eax
    jl __gas_L115
__gas_L157:
    cmp byte [rsp+16], 0
    je __gas_L116
    movss xmm0, dword [rel __gas_LC6]
    mulss xmm0, dword [rel 253304+game]
    cvttss2si eax, xmm0
    test al, 1
    je __gas_L156
__gas_L116:
    cmp byte [rsp+12], 0
    je __gas_L107
    mov esi, dword [rel 253368+game]
    mov edi, -16538
    call ColorTint wrt ..plt
    lea rdi, [rsp+32]
    mov ebx, eax
    call GetFontDefault wrt ..plt
    movss xmm0, dword [r15+4]
    sub rsp, 48
    movss xmm4, dword [rel __gas_LC14]
    mov esi, -16713219
    movss xmm3, dword [rel __gas_LC32]
    pxor xmm2, xmm2
    lea rdi, [rel __gas_LC31]
    movaps xmm1, xmm0
    subss xmm1, dword [rsp+56]
    movss xmm0, dword [r15]
    unpcklps xmm0, xmm1
    movdqa xmm1, oword [rsp+80]
    movq xmm0, xmm0
    addps xmm0, oword [rel __gas_LC37]
    movups oword [rsp], xmm1
    movdqa xmm1, oword [rsp+96]
    movups oword [rsp+16], xmm1
    movdqa xmm1, oword [rsp+112]
    movups oword [rsp+32], xmm1
    pxor xmm1, xmm1
    call DrawTextPro wrt ..plt
    mov eax, dword [r15+8]
    add rsp, 48
    cmp eax, 4
    jne __gas_L118
__gas_L154:
    movss xmm0, dword [rel __gas_LC1]
    mov edi, -13656576
    call Fade wrt ..plt
    movss xmm1, dword [rel __gas_LC33]
    movq xmm0, qword [r15]
    mov edi, eax
    call DrawCircleV wrt ..plt
    mov eax, dword [r15+8]
    cmp eax, 4
    jne __gas_L118
    movss xmm2, dword [rel __gas_LC34]
    movss xmm1, dword [rsp+8]
    mov esi, ebx
    mov edi, 4
    movq xmm0, qword [r15]
    call DrawPoly wrt ..plt
    jmp __gas_L119
align 16
align 8
__gas_L109:
    mov esi, dword [rel 253368+game]
    mov edi, -16741121
    mov qword [rsp+24], rcx
    mov dword [rsp+20], r8d
    call ColorTint wrt ..plt
    cvttss2si edi, dword [r15]
    movss xmm0, dword [rsp+8]
    cvttss2si esi, dword [r15+4]
    addss xmm0, dword [rel __gas_LC11]
    mov edx, eax
    call DrawCircleLines wrt ..plt
    mov r8d, dword [rsp+20]
    mov rcx, qword [rsp+24]
    mov eax, dword [r15+160]
    add r8d, 1
    add rcx, 16
    cmp r8d, eax
    jl __gas_L115
    jmp __gas_L157
align 16
align 8
__gas_L112:
    mov esi, dword [rel 253368+game]
    mov edi, -9216
    mov qword [rsp+24], rcx
    mov dword [rsp+20], r8d
    call ColorTint wrt ..plt
    cvttss2si edi, dword [r15]
    movss xmm0, dword [rsp+8]
    cvttss2si esi, dword [r15+4]
    addss xmm0, dword [rel __gas_LC29]
    mov edx, eax
    call DrawCircleLines wrt ..plt
    mov r8d, dword [rsp+20]
    mov rcx, qword [rsp+24]
    mov eax, dword [r15+160]
    add r8d, 1
    add rcx, 16
    cmp r8d, eax
    jl __gas_L115
    jmp __gas_L157
align 16
align 8
__gas_L133:
    add r8d, 1
    mov byte [rsp+12], bpl
    add rcx, 16
    cmp r8d, eax
    jl __gas_L115
    jmp __gas_L157
align 16
align 8
__gas_L114:
    add r8d, 1
    mov byte [rsp+16], bpl
    add rcx, 16
    cmp r8d, eax
    jl __gas_L115
    jmp __gas_L157
align 16
align 8
__gas_L155:
    movq xmm0, qword [r15]
    mov esi, ebx
    pxor xmm2, xmm2
    mov edi, 5
    movss xmm1, dword [rsp+8]
    call DrawPoly wrt ..plt
    jmp __gas_L119
align 16
align 8
__gas_L151:
    movss xmm0, dword [rel __gas_LC36]
    comiss xmm0, xmm2
    jbe __gas_L129
    mov r8w, -1539
    and r8d, -16711681
    jmp __gas_L129
align 16
align 8
__gas_L134:
    movss xmm0, dword [rel __gas_LC9]
    movss xmm5, dword [rel __gas_LC26]
    jmp __gas_L126
align 16
align 8
__gas_L156:
    mov esi, dword [rel 253368+game]
    mov edi, -16735745
    call ColorTint wrt ..plt
    mov ebx, eax
    jmp __gas_L116
section .text
DrawEnemies.cold:
__gas_L132:
    mov dword [rsp+8], 0x00000000
    jmp __gas_L95
section .text
section .text
__gas_LCOLDE38:
section .text
__gas_LHOTE38:
align 16
global GetTowerColor
GetTowerColor:
    cmp edi, 11
    ja __gas_L159
    lea rdx, [rel __gas_L161]
    mov edi, edi
    movsx rax, dword [rdx+rdi*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L161:
dd __gas_L165-__gas_L161
dd __gas_L163-__gas_L161
dd __gas_L162-__gas_L161
dd __gas_L160-__gas_L161
dd __gas_L165-__gas_L161
dd __gas_L165-__gas_L161
dd __gas_L163-__gas_L161
dd __gas_L163-__gas_L161
dd __gas_L162-__gas_L161
dd __gas_L162-__gas_L161
dd __gas_L160-__gas_L161
dd __gas_L160-__gas_L161
section .text
align 16
align 8
__gas_L163:
    mov esi, -1
    mov ecx, -116
    xor eax, eax
__gas_L164:
    movzx edx, sil
    mov dh, cl
    movzx ecx, al
    mov eax, edx
    sal ecx, 16
    and eax, -16711681
    or eax, ecx
    or eax, -16777216
    ret
align 16
align 8
__gas_L165:
    xor esi, esi
    mov ecx, -36
    mov eax, -1
    jmp __gas_L164
align 16
align 8
__gas_L160:
    mov esi, -1
    xor ecx, ecx
    mov eax, -1
    jmp __gas_L164
align 16
align 8
__gas_L162:
    mov esi, -121
    mov ecx, -50
    mov eax, -6
    jmp __gas_L164
__gas_L159:
    mov esi, -126
    mov ecx, -126
    mov eax, -126
    jmp __gas_L164
section .rodata
__gas_LC51:
db 76, 37, 100, 0
section .text
align 16
global DrawTowers
DrawTowers:
    push r15
    push r14
    push r13
    push r12
    push rbp
    push rbx
    lea rbx, [rel 2456+game]
    lea r12, [rbx+8000]
    sub rsp, 104
    jmp __gas_L189
align 16
align 16
align 8
__gas_L167:
    add rbx, 80
    cmp rbx, r12
    je __gas_L209
__gas_L189:
    cmp byte [rbx+64], 0
    je __gas_L167
    mov edi, dword [rbx+8]
    call GetTowerColor
    movss xmm0, dword [rel __gas_LC41]
    mov edi, eax
    mov r13d, eax
    call ColorBrightness wrt ..plt
    mov esi, dword [rel 253368+game]
    mov edi, eax
    call ColorTint wrt ..plt
    mov esi, dword [rel 253368+game]
    mov edi, r13d
    mov r15d, eax
    call ColorTint wrt ..plt
    movss xmm0, dword [rbx+4]
    mov r8d, r15d
    subss xmm0, dword [rel __gas_LC7]
    movss xmm1, dword [rel __gas_LC42]
    mov ecx, 32
    mov edx, 32
    mov r13d, eax
    addss xmm0, xmm1
    cvttss2si esi, xmm0
    movss xmm0, dword [rbx]
    subss xmm0, dword [rel __gas_LC7]
    addss xmm0, xmm1
    cvttss2si edi, xmm0
    call DrawRectangle wrt ..plt
    mov r15d, dword [rbx+8]
    lea eax, [r15+1]
    cmp eax, 12
    ja __gas_L168
    lea rdx, [rel __gas_L170]
    movsx rax, dword [rdx+rax*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L170:
dd __gas_L208-__gas_L170
dd __gas_L168-__gas_L170
dd __gas_L168-__gas_L170
dd __gas_L171-__gas_L170
dd __gas_L169-__gas_L170
dd __gas_L168-__gas_L170
dd __gas_L190-__gas_L170
dd __gas_L168-__gas_L170
dd __gas_L168-__gas_L170
dd __gas_L172-__gas_L170
dd __gas_L171-__gas_L170
dd __gas_L169-__gas_L170
dd __gas_L169-__gas_L170
section .text
align 16
align 8
__gas_L169:
    movq xmm0, qword [rbx]
    movss xmm1, dword [rel __gas_LC23]
    mov edi, r13d
    call DrawCircleV wrt ..plt
    movss xmm0, dword [rbx+40]
    comiss xmm0, dword [rel __gas_LC1]
    ja __gas_L184
    xor edi, edi
    mov esi, 15
    call GetRandomValue wrt ..plt
    test eax, eax
    jne __gas_L208
__gas_L184:
    mov esi, 360
    xor edi, edi
    call GetRandomValue wrt ..plt
    pxor xmm0, xmm0
    lea rsi, [rsp+24]
    lea rdi, [rsp+28]
    cvtsi2ss xmm0, eax
    mulss xmm0, dword [rel __gas_LC47]
    call sincosf wrt ..plt
    movss xmm0, dword [rsp+28]
    movss xmm1, dword [rsp+24]
    mov edi, r13d
    unpcklps xmm1, xmm0
    movq xmm0, qword [rbx]
    movq xmm1, xmm1
    mulps xmm1, oword [rel __gas_LC55]
    movq xmm1, xmm1
    addps xmm1, xmm0
    movss xmm0, dword [rel __gas_LC27]
    movlps qword [rsp], xmm1
    call Fade wrt ..plt
    movq xmm1, qword [rsp]
    movq xmm0, qword [rbx]
    movss xmm2, dword [rel __gas_LC4]
    mov edi, eax
    call DrawLineEx wrt ..plt
    mov rax, qword [rel __gas_LC49]
    mov qword [rsp], rax
align 16
align 8
__gas_L174:
    mov ecx, dword [rbx+12]
    lea r13, [rsp+40]
    xor eax, eax
    mov esi, 8
    lea rdx, [rel __gas_LC51]
    mov rdi, r13
    call snprintf wrt ..plt
    cmp dword [rbx+12], 2
    jle __gas_L195
    cmp dword [rbx+8], 3
    jg __gas_L195
    mov ecx, -3
    mov edx, -7
    xor eax, eax
__gas_L188:
    mov bpl, cl
    sal eax, 16
    lea rdi, [rsp+48]
    add rbx, 80
    mov ecx, ebp
    mov ch, dl
    mov ebp, ecx
    and ebp, -16711681
    or ebp, eax
    call GetFontDefault wrt ..plt
    sub rsp, 48
    pxor xmm2, xmm2
    mov rdi, r13
    movq xmm0, qword [rbx+-80]
    addps xmm0, oword [rel __gas_LC54]
    or ebp, -16777216
    movq xmm1, qword [rsp+48]
    movss xmm4, dword [rel __gas_LC14]
    mov esi, ebp
    movss xmm3, dword [rel __gas_LC32]
    movq xmm0, xmm0
    addps xmm0, xmm1
    movdqa xmm1, oword [rsp+96]
    movups oword [rsp], xmm1
    movdqa xmm1, oword [rsp+112]
    movups oword [rsp+16], xmm1
    movdqa xmm1, oword [rsp+128]
    movups oword [rsp+32], xmm1
    pxor xmm1, xmm1
    call DrawTextPro wrt ..plt
    add rsp, 48
    cmp rbx, r12
    jne __gas_L189
__gas_L209:
    add rsp, 104
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L168:
    mov rax, qword [rbx]
    movss xmm2, dword [rbx+60]
    movss xmm3, dword [rbx+52]
    mov qword [rsp+8], rax
    cmp r15d, 1
    jne __gas_L210
    movss xmm0, dword [rel __gas_LC39]
    movss xmm2, dword [rel __gas_LC24]
    movss xmm4, dword [rel __gas_LC22]
    movss xmm1, dword [rel __gas_LC40]
__gas_L173:
    movd eax, xmm0
    addss xmm2, dword [rbx+60]
    mov r14d, r14d
    sal rax, 32
    or r14, rax
__gas_L185:
    movss xmm5, dword [rbx+4]
    movss xmm7, dword [rbx]
    movd eax, xmm2
    mov edi, r13d
    mov rdx, -4294967296
    unpcklps xmm1, xmm4
    and rdx, r14
    unpcklps xmm7, xmm5
    or rdx, rax
    movaps xmm0, xmm7
    movq xmm2, rdx
    mov r14, rdx
    call DrawRectanglePro wrt ..plt
__gas_L208:
    mov rax, qword [rel __gas_LC49]
    mov qword [rsp], rax
    jmp __gas_L174
align 16
align 8
__gas_L171:
    movsx rdx, dword [rbx+44]
    cmp edx, 299
    ja __gas_L176
    lea rax, [rdx+rdx*4]
    lea rcx, [rel game]
    lea rax, [rdx+rax*8]
    lea rax, [rcx+rax*4]
    cmp byte [rax+10512], 0
    je __gas_L176
    mov esi, dword [rax+10468]
    cmp dword [rbx+48], esi
    je __gas_L211
__gas_L176:
    movss xmm2, dword [rbx+52]
    movq xmm0, qword [rbx]
    mov esi, r13d
    mov edi, 6
    movss xmm1, dword [rel __gas_LC6]
    call DrawPoly wrt ..plt
    mov rax, qword [rel __gas_LC49]
    mov qword [rsp], rax
    jmp __gas_L174
align 16
align 8
__gas_L172:
    movss xmm0, dword [rel __gas_LC29]
    mulss xmm0, dword [rel 253304+game]
    call sinf wrt ..plt
    addss xmm0, dword [rel __gas_LC14]
    mov edi, r13d
    mulss xmm0, dword [rel __gas_LC46]
    addss xmm0, dword [rel __gas_LC1]
    call Fade wrt ..plt
    movss xmm1, dword [rbx+28]
    movq xmm0, qword [rbx]
    mov edi, eax
    call DrawCircleV wrt ..plt
    movss xmm1, dword [rel __gas_LC22]
    movq xmm0, qword [rbx]
    mov edi, r13d
    call DrawCircleV wrt ..plt
    mov rax, qword [rel __gas_LC49]
    mov qword [rsp], rax
    jmp __gas_L174
align 16
align 8
__gas_L190:
    movss xmm2, dword [rel __gas_LC24]
    movss xmm0, dword [rel __gas_LC39]
    movss xmm1, dword [rel __gas_LC0]
    movss xmm3, dword [rbx+52]
    movaps xmm4, xmm2
    jmp __gas_L173
align 16
align 8
__gas_L195:
    mov ecx, -1
    mov edx, -1
    mov eax, 255
    jmp __gas_L188
align 16
align 8
__gas_L210:
    cmp r15d, 6
    jne __gas_L212
    movss xmm0, dword [rel __gas_LC15]
    movss xmm2, dword [rel __gas_LC21]
    movss xmm4, dword [rel __gas_LC7]
    movss xmm1, dword [rel __gas_LC8]
    jmp __gas_L173
__gas_L212:
    movaps xmm0, xmm3
    lea rdi, [rsp+28]
    lea rsi, [rsp+24]
    movss dword [rsp], xmm3
    mulss xmm0, dword [rel __gas_LC47]
    addss xmm2, dword [rel __gas_LC24]
    mov r14, 4665729215046352896
    movss dword [rsp+20], xmm2
    call sincosf wrt ..plt
    movss xmm4, dword [rsp+28]
    movss xmm0, dword [rsp+24]
    cmp r15d, 4
    xorps xmm4, oword [rel __gas_LC20]
    movss xmm3, dword [rsp]
    movss xmm2, dword [rsp+20]
    unpcklps xmm4, xmm0
    je __gas_L198
    cmp r15d, 7
    jne __gas_L194
__gas_L198:
    mov rax, qword [rel __gas_LC49]
    movq xmm4, xmm4
    mov edi, r13d
    movq xmm5, qword [rsp+8]
    mov r14, 4665729213955833856
    movq xmm1, qword [rel __gas_LC50]
    mov qword [rsp], rax
    movq xmm0, qword [rsp]
    movd eax, xmm2
    or r14, rax
    movq qword [rsp+8], xmm1
    mulps xmm4, xmm0
    movq xmm2, r14
    movq xmm4, xmm4
    movaps xmm0, xmm4
    addps xmm0, xmm5
    subps xmm5, xmm4
    movq r15, xmm5
    call DrawRectanglePro wrt ..plt
    movss xmm3, dword [rbx+52]
    mov edi, r13d
    movq xmm1, qword [rsp+8]
    movq xmm2, r14
    movq xmm0, r15
    call DrawRectanglePro wrt ..plt
    jmp __gas_L174
align 16
align 8
__gas_L211:
    movss xmm1, dword [rax+10456]
    subss xmm1, dword [rbx]
    mov qword [rsp+8], rdx
    movss xmm0, dword [rax+10460]
    subss xmm0, dword [rbx+4]
    call atan2f wrt ..plt
    movss xmm1, dword [rbx+52]
    fld dword [rel __gas_LC45]
    mulss xmm0, dword [rel __gas_LC43]
    mov rdx, qword [rsp+8]
    subss xmm1, xmm0
    addss xmm1, dword [rel __gas_LC44]
    movss dword [rsp], xmm1
    fld dword [rsp]
__gas_L178:
    fprem
    fnstsw ax
    test ah, 4
    jne __gas_L178
    fstp st1
    fstp dword [rsp+8]
    movss xmm7, dword [rsp+8]
    ucomiss xmm7, xmm7
    jp __gas_L213
    mov edi, r15d
    mov qword [rsp], rdx
    call GetAimToleranceDegrees wrt ..plt
    movaps xmm1, xmm0
    movss xmm0, dword [rsp+8]
    subss xmm0, dword [rel __gas_LC44]
    andps xmm0, oword [rel __gas_LC17]
    comiss xmm1, xmm0
    jb __gas_L176
    cmp dword [rbx+8], 2
    movss xmm2, dword [rel __gas_LC11]
    lea rcx, [rel game]
    mov rdx, qword [rsp]
    je __gas_L214
__gas_L181:
    lea rax, [rdx+rdx*4]
    movss xmm0, dword [rel __gas_LC13]
    mov edi, r13d
    movss dword [rsp], xmm2
    lea rax, [rdx+rax*8]
    lea r15, [rcx+rax*4+10456]
    call Fade wrt ..plt
    movss xmm2, dword [rsp]
    movq xmm1, qword [r15]
    movq xmm0, qword [rbx]
    mov edi, eax
    call DrawLineEx wrt ..plt
    movss xmm0, dword [rel __gas_LC3]
    mov edi, r13d
    call Fade wrt ..plt
    movss xmm2, dword [rsp]
    movq xmm1, qword [r15]
    addss xmm2, dword [rel __gas_LC39]
    movq xmm0, qword [rbx]
    mov edi, eax
    call DrawLineEx wrt ..plt
    jmp __gas_L176
__gas_L214:
    movss xmm2, dword [rel __gas_LC29]
    jmp __gas_L181
__gas_L194:
    movss xmm4, dword [rel __gas_LC21]
    movss xmm1, dword [rel __gas_LC25]
    jmp __gas_L185
__gas_L213:
    movss xmm1, dword [rel __gas_LC45]
    movss xmm0, dword [rsp]
    call fmodf wrt ..plt
    mov edi, r15d
    call GetAimToleranceDegrees wrt ..plt
    jmp __gas_L176
section .rodata
__gas_LC60:
db 72, 37, 100, 0
section .text
align 16
global DrawHero
DrawHero:
    push rbp
    push rbx
    sub rsp, 72
    mov eax, dword [rel 2428+game]
    test eax, eax
    jle __gas_L216
    movss xmm0, dword [rel __gas_LC58]
    mov edi, -13435086
    call Fade wrt ..plt
    movss xmm1, dword [rel __gas_LC59]
    movq xmm0, qword [rel 2328+game]
    mov edi, eax
    call DrawCircleV wrt ..plt
__gas_L216:
    mov esi, dword [rel 253368+game]
    mov edi, -39756
    call ColorTint wrt ..plt
    mov esi, dword [rel 253368+game]
    mov edi, -34104
    mov ebp, eax
    call ColorTint wrt ..plt
    movss xmm1, dword [rel __gas_LC6]
    mov edi, ebp
    movq xmm0, qword [rel 2328+game]
    mov ebx, eax
    call DrawCircleV wrt ..plt
    cvttss2si esi, dword [rel 2332+game]
    movss xmm0, dword [rel __gas_LC6]
    mov edx, ebx
    cvttss2si edi, dword [rel 2328+game]
    lea rbx, [rsp+8]
    call DrawCircleLines wrt ..plt
    mov ecx, dword [rel 2336+game]
    mov rdi, rbx
    xor eax, eax
    lea rdx, [rel __gas_LC60]
    mov esi, 8
    call snprintf wrt ..plt
    lea rdi, [rsp+16]
    call GetFontDefault wrt ..plt
    sub rsp, 48
    mov rdi, rbx
    pxor xmm2, xmm2
    movdqa xmm1, oword [rsp+64]
    movq xmm0, qword [rel 2328+game]
    mov esi, -1
    addps xmm0, oword [rel __gas_LC62]
    movss xmm4, dword [rel __gas_LC14]
    movups oword [rsp], xmm1
    movdqa xmm1, oword [rsp+80]
    movss xmm3, dword [rel __gas_LC23]
    movups oword [rsp+16], xmm1
    movdqa xmm1, oword [rsp+96]
    movups oword [rsp+32], xmm1
    pxor xmm1, xmm1
    call DrawTextPro wrt ..plt
    add rsp, 120
    pop rbx
    pop rbp
    ret
align 16
global DrawProjectiles
DrawProjectiles:
    push r13
    lea r13, [rel CSWTCH.94]
    push r12
    push rbp
    push rbx
    lea rbx, [rel 59656+game]
    lea r12, [rbx+56000]
    sub rsp, 24
    jmp __gas_L228
align 16
align 16
align 8
__gas_L219:
    add rbx, 112
    cmp r12, rbx
    je __gas_L233
__gas_L228:
    cmp byte [rbx+48], 0
    je __gas_L219
    cmp dword [rbx+24], 11
    ja __gas_L220
    mov eax, dword [rbx+24]
    lea rdx, [rel __gas_L222]
    movsx rax, dword [rdx+rax*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L222:
dd __gas_L229-__gas_L222
dd __gas_L224-__gas_L222
dd __gas_L223-__gas_L222
dd __gas_L221-__gas_L222
dd __gas_L229-__gas_L222
dd __gas_L229-__gas_L222
dd __gas_L224-__gas_L222
dd __gas_L224-__gas_L222
dd __gas_L223-__gas_L222
dd __gas_L223-__gas_L222
dd __gas_L221-__gas_L222
dd __gas_L221-__gas_L222
section .text
align 16
align 8
__gas_L224:
    xor edi, edi
    mov eax, -116
    mov edx, -1
__gas_L225:
    mov bpl, dl
    sal edi, 16
    mov esi, dword [rel 253368+game]
    mov ecx, ebp
    mov ch, al
    mov ebp, ecx
    and ebp, -16711681
    or edi, ebp
    or edi, -16777216
    call ColorTint wrt ..plt
    movss xmm1, dword [rel __gas_LC42]
    mov ebp, eax
    mov eax, dword [rbx+24]
    sub eax, 1
    cmp eax, 9
    ja __gas_L226
    movss xmm1, dword [r13+rax*4+0]
__gas_L226:
    movq xmm0, qword [rbx]
    mov edi, ebp
    movss dword [rsp+12], xmm1
    call DrawCircleV wrt ..plt
    cmp dword [rbx+16], 1
    jne __gas_L219
    movss xmm0, dword [rel __gas_LC3]
    mov edi, ebp
    add rbx, 112
    call Fade wrt ..plt
    movss xmm1, dword [rsp+12]
    addss xmm1, dword [rel __gas_LC11]
    movq xmm0, qword [rbx+-112]
    mov edi, eax
    call DrawCircleV wrt ..plt
    cmp r12, rbx
    jne __gas_L228
__gas_L233:
    add rsp, 24
    pop rbx
    pop rbp
    pop r12
    pop r13
    ret
align 16
align 8
__gas_L229:
    mov edi, 255
    mov eax, -36
    xor edx, edx
    jmp __gas_L225
align 16
align 8
__gas_L221:
    mov edi, 255
    xor eax, eax
    mov edx, -1
    jmp __gas_L225
align 16
align 8
__gas_L223:
    mov edi, 250
    mov eax, -50
    mov edx, -121
    jmp __gas_L225
__gas_L220:
    mov edi, 130
    mov eax, -126
    mov edx, -126
    jmp __gas_L225
align 16
global DrawEntities
DrawEntities:
    sub rsp, 8
    call DrawEnemies
    call DrawTowers
    call DrawHero
    add rsp, 8
    jmp DrawProjectiles
align 16
global DrawVFX
DrawVFX:
    push r14
    push r13
    push r12
    push rbp
    push rbx
    lea rbx, [rel 115656+game]
    lea rbp, [rbx+132000]
    sub rsp, 64
    jmp __gas_L238
align 16
align 16
align 8
__gas_L237:
    add rbx, 44
    cmp rbx, rbp
    je __gas_L249
__gas_L238:
    cmp byte [rbx+40], 0
    je __gas_L237
    mov esi, dword [rbx+20]
    mov edi, dword [rbx+16]
    add rbx, 44
    movss xmm0, dword [rbx+-20]
    divss xmm0, dword [rbx+-16]
    movss dword [rsp+4], xmm0
    call ColorLerp wrt ..plt
    movss xmm2, dword [rbx+-12]
    movss xmm1, dword [rbx+-8]
    movss xmm0, dword [rsp+4]
    mov esi, dword [rel 253368+game]
    mov edi, eax
    subss xmm1, xmm2
    mulss xmm1, xmm0
    addss xmm1, xmm2
    movss dword [rsp+4], xmm1
    call ColorTint wrt ..plt
    movq xmm0, qword [rbx+-44]
    movss xmm1, dword [rsp+4]
    mov edi, eax
    call DrawCircleV wrt ..plt
    cmp rbx, rbp
    jne __gas_L238
__gas_L249:
    lea rbx, [rel 247656+game]
    lea rbp, [rbx+5600]
align 16
align 8
__gas_L243:
    cmp byte [rbx+52], 0
    je __gas_L239
    movss xmm1, dword [rbx+44]
    pxor xmm2, xmm2
    cmp byte [rbx+53], 0
    mov r13d, 20
    addss xmm1, xmm1
    movaps xmm0, xmm1
    cmpnltss xmm0, xmm2
    pxor xmm2, xmm2
    andps xmm1, xmm0
    andnps xmm0, xmm2
    movss xmm2, dword [rel __gas_LC14]
    orps xmm0, xmm1
    movss xmm1, dword [rel __gas_LC14]
    cmpltss xmm1, xmm0
    andps xmm2, xmm1
    andnps xmm1, xmm0
    orps xmm1, xmm2
    movd r14d, xmm1
    je __gas_L242
    mov r13d, 24
__gas_L242:
    lea rdi, [rsp+16]
    call GetFontDefault wrt ..plt
    movq xmm5, qword [rbx]
    movd xmm0, r14d
    mov edi, -16777216
    movq xmm1, xmm5
    addps xmm1, oword [rel __gas_LC64]
    movlps qword [rsp+8], xmm5
    movq r12, xmm1
    call Fade wrt ..plt
    sub rsp, 48
    pxor xmm3, xmm3
    movss xmm4, dword [rel __gas_LC14]
    cvtsi2ss xmm3, r13d
    lea r13, [rbx+8]
    pxor xmm2, xmm2
    mov esi, eax
    movdqa xmm1, oword [rsp+64]
    movq xmm0, r12
    mov rdi, r13
    movups oword [rsp], xmm1
    movdqa xmm1, oword [rsp+80]
    movss dword [rsp+52], xmm3
    movups oword [rsp+16], xmm1
    movdqa xmm1, oword [rsp+96]
    movups oword [rsp+32], xmm1
    pxor xmm1, xmm1
    call DrawTextPro wrt ..plt
    mov edi, dword [rbx+40]
    add rsp, 48
    movd xmm0, r14d
    call Fade wrt ..plt
    movq xmm5, qword [rsp+8]
    sub rsp, 48
    pxor xmm2, xmm2
    movdqa xmm1, oword [rsp+64]
    movss xmm3, dword [rsp+52]
    mov esi, eax
    mov rdi, r13
    movss xmm4, dword [rel __gas_LC14]
    movdqa xmm0, xmm5
    movups oword [rsp], xmm1
    movdqa xmm1, oword [rsp+80]
    movups oword [rsp+16], xmm1
    movdqa xmm1, oword [rsp+96]
    movups oword [rsp+32], xmm1
    pxor xmm1, xmm1
    call DrawTextPro wrt ..plt
    add rsp, 48
__gas_L239:
    add rbx, 56
    cmp rbp, rbx
    jne __gas_L243
    add rsp, 64
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    ret
section .rodata
__gas_LC65:
db 72, 69, 82, 79, 32, 83, 84, 65, 84, 85, 83, 0
__gas_LC66:
db 76, 101, 118, 101, 108, 58, 32, 37, 100, 0
__gas_LC67:
db 65, 116, 116, 97, 99, 107, 58, 32, 37, 100, 32, 40, 80, 104, 121, 115, 41, 0
__gas_LC68:
db 83, 75, 73, 76, 76, 32, 80, 79, 73, 78, 84, 32, 65, 86, 65, 73, 76, 65, 66, 76, 69, 33, 0
__gas_LC70:
db 88, 80, 58, 32, 37, 100, 32, 47, 32, 37, 100, 0
__gas_LC72:
db 68, 97, 115, 104, 32, 40, 81, 41, 0
__gas_LC73:
db 82, 97, 112, 105, 100, 32, 109, 111, 118, 101, 109, 101, 110, 116, 32, 98, 117, 114, 115, 116, 46, 0
__gas_LC75:
db 66, 117, 114, 115, 116, 32, 40, 69, 41, 0
__gas_LC76:
db 65, 101, 116, 104, 101, 114, 32, 66, 117, 114, 115, 116, 32, 40, 69, 41, 0
section .rodata
align 8
__gas_LC77:
db 65, 111, 69, 32, 100, 97, 109, 97, 103, 101, 32, 97, 110, 100, 32, 101, 110, 101, 114, 103, 121, 32, 119, 101, 97, 107, 110, 101, 115, 115, 32, 100, 101, 98, 117, 102, 102, 46, 0
section .text
align 16
global DrawHeroStatus
DrawHeroStatus:
    push r14
    mov r8d, -39756
    mov ecx, 20
    mov edx, 135
    push rbp
    mov esi, 970
    lea rdi, [rel __gas_LC65]
    push rbx
    sub rsp, 176
    call DrawText wrt ..plt
    lea rbx, [rsp+16]
    mov ecx, dword [rel 2336+game]
    xor eax, eax
    mov rdi, rbx
    lea rdx, [rel __gas_LC66]
    mov esi, 32
    call snprintf wrt ..plt
    mov r8d, -2571
    mov rdi, rbx
    mov ecx, 18
    mov edx, 160
    mov esi, 970
    lea rbx, [rsp+48]
    call DrawText wrt ..plt
    mov ecx, dword [rel 2356+game]
    mov rdi, rbx
    xor eax, eax
    lea rdx, [rel __gas_LC67]
    mov esi, 64
    call snprintf wrt ..plt
    mov r8d, -2571
    mov ecx, 18
    mov rdi, rbx
    mov edx, 160
    mov esi, 1090
    call DrawText wrt ..plt
    mov eax, dword [rel 2348+game]
    test eax, eax
    jle __gas_L251
    mov r8d, -16713219
    mov ecx, 18
    mov edx, 180
    mov esi, 970
    lea rdi, [rel __gas_LC68]
    call DrawText wrt ..plt
__gas_L251:
    mov eax, dword [rel 2344+game]
    pxor xmm2, xmm2
    test eax, eax
    jle __gas_L252
    pxor xmm2, xmm2
    pxor xmm0, xmm0
    cvtsi2ss xmm2, dword [rel 2340+game]
    cvtsi2ss xmm0, eax
    divss xmm2, xmm0
__gas_L252:
    mov rbx, 4848125000012693504
    mov edi, -12836061
    mov rbp, 4728779609872924672
    movss dword [rsp+8], xmm2
    movq xmm0, rbx
    movq xmm1, rbp
    call DrawRectangleRec wrt ..plt
    movss xmm2, dword [rsp+8]
    mov r8d, -39756
    mov ecx, 20
    mulss xmm2, dword [rel __gas_LC69]
    mov esi, 200
    mov edi, 970
    cvttss2si edx, xmm2
    call DrawRectangle wrt ..plt
    movq xmm0, rbx
    movq xmm1, rbp
    movss xmm2, dword [rel __gas_LC14]
    mov edi, -16777216
    lea rbx, [rsp+112]
    call DrawRectangleLinesEx wrt ..plt
    mov ecx, dword [rel 2340+game]
    mov rdi, rbx
    xor eax, eax
    mov r8d, dword [rel 2344+game]
    lea rdx, [rel __gas_LC70]
    mov esi, 64
    call snprintf wrt ..plt
    mov r8d, -2571
    mov ecx, 16
    mov rdi, rbx
    mov edx, 202
    mov esi, 980
    call DrawText wrt ..plt
    movss xmm0, dword [rel 2372+game]
    pxor xmm2, xmm2
    comiss xmm0, xmm2
    jbe __gas_L276
    movss xmm1, dword [rel 2376+game]
    movss xmm3, dword [rel __gas_LC14]
    divss xmm1, xmm0
    movaps xmm0, xmm1
    cmpnltss xmm0, xmm2
    pxor xmm2, xmm2
    andps xmm1, xmm0
    andnps xmm0, xmm2
    movaps xmm2, xmm3
    orps xmm0, xmm1
    movaps xmm1, xmm3
    cmpltss xmm1, xmm0
    andps xmm2, xmm1
    andnps xmm1, xmm0
    orps xmm1, xmm2
    movaps xmm2, xmm3
    subss xmm2, xmm1
__gas_L253:
    mov rbp, 4856569249314013184
    mov edi, -12836061
    mov r14, 4728779609864208384
    movss dword [rsp+12], xmm3
    movq xmm1, r14
    movq xmm0, rbp
    movss dword [rsp+8], xmm2
    lea rbx, [rel __gas_LC72]
    call DrawRectangleRec wrt ..plt
    movss xmm2, dword [rsp+8]
    mov r8d, -39756
    mov ecx, 20
    mulss xmm2, dword [rel __gas_LC71]
    mov esi, 230
    mov edi, 970
    cvttss2si edx, xmm2
    call DrawRectangle wrt ..plt
    mov r8d, -2571
    mov ecx, 14
    mov rdi, rbx
    mov edx, 233
    mov esi, 975
    call DrawText wrt ..plt
    call GetMousePosition wrt ..plt
    movq xmm1, rbp
    movq xmm2, r14
    call CheckCollisionPointRec wrt ..plt
    movss xmm3, dword [rsp+12]
    test al, al
    je __gas_L257
    lea rax, [rel __gas_LC73]
    movq xmm0, rbx
    mov byte [rel 253312+game], 1
    movq xmm5, rax
    punpcklqdq xmm0, xmm5
    movups oword [rel 253320+game], xmm0
    movaps xmm0, oword [rel __gas_LC74]
    movups oword [rel 253336+game], xmm0
__gas_L257:
    movss xmm0, dword [rel 2400+game]
    pxor xmm2, xmm2
    comiss xmm0, xmm2
    jbe __gas_L277
    movss xmm1, dword [rel 2404+game]
    divss xmm1, xmm0
    movaps xmm0, xmm1
    cmpnltss xmm0, xmm2
    pxor xmm2, xmm2
    andps xmm1, xmm0
    andnps xmm0, xmm2
    movaps xmm2, xmm3
    orps xmm0, xmm1
    movaps xmm1, xmm3
    cmpltss xmm1, xmm0
    andps xmm2, xmm1
    andnps xmm1, xmm0
    orps xmm1, xmm2
    subss xmm3, xmm1
    movss dword [rsp+8], xmm3
__gas_L258:
    mov rbx, 4856569249315725312
    mov edi, -12836061
    mov r14, 4728779609864208384
    movq xmm1, r14
    movq xmm0, rbx
    call DrawRectangleRec wrt ..plt
    mov r8d, -9216
    mov ecx, 20
    movss xmm0, dword [rel __gas_LC71]
    mulss xmm0, dword [rsp+8]
    mov esi, 230
    mov edi, 1125
    cvttss2si edx, xmm0
    call DrawRectangle wrt ..plt
    mov r8d, -2571
    mov ecx, 14
    mov edx, 233
    mov esi, 1130
    lea rdi, [rel __gas_LC75]
    call DrawText wrt ..plt
    call GetMousePosition wrt ..plt
    movq xmm1, rbx
    movq xmm2, r14
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L250
    movq xmm0, qword [rel __gas_LC79]
    lea rax, [rel __gas_LC77]
    mov byte [rel 253312+game], 1
    movq xmm6, rax
    punpcklqdq xmm0, xmm6
    movups oword [rel 253320+game], xmm0
    movaps xmm0, oword [rel __gas_LC78]
    movups oword [rel 253336+game], xmm0
__gas_L250:
    add rsp, 176
    pop rbx
    pop rbp
    pop r14
    ret
align 16
align 8
__gas_L276:
    movss xmm3, dword [rel __gas_LC14]
    movaps xmm2, xmm3
    jmp __gas_L253
align 16
align 8
__gas_L277:
    movss dword [rsp+8], xmm3
    jmp __gas_L258
align 16
global DrawTooltip
DrawTooltip:
    cmp byte [rel 253312+game], 0
    jne __gas_L281
    ret
align 16
align 8
__gas_L281:
    jmp DrawTooltip.part.0
section .rodata
__gas_LC80:
db 80, 117, 108, 115, 101, 32, 69, 109, 105, 116, 116, 101, 114, 32, 91, 49, 93, 0
__gas_LC81:
db 65, 101, 116, 104, 101, 114, 32, 67, 97, 110, 110, 111, 110, 32, 91, 50, 93, 0
__gas_LC82:
db 67, 114, 121, 111, 32, 66, 101, 97, 109, 32, 91, 51, 93, 0
__gas_LC83:
db 84, 101, 115, 108, 97, 32, 67, 111, 105, 108, 32, 91, 52, 93, 0
__gas_LC84:
db 84, 52, 58, 32, 80, 117, 108, 115, 101, 32, 82, 101, 112, 101, 97, 116, 101, 114, 0
__gas_LC85:
db 84, 52, 58, 32, 77, 97, 114, 107, 115, 109, 97, 110, 32, 76, 97, 115, 101, 114, 0
__gas_LC86:
db 84, 52, 58, 32, 79, 114, 98, 105, 116, 97, 108, 32, 77, 111, 114, 116, 97, 114, 0
__gas_LC87:
db 84, 52, 58, 32, 86, 117, 108, 99, 97, 110, 32, 71, 97, 116, 108, 105, 110, 103, 0
__gas_LC88:
db 84, 52, 58, 32, 66, 108, 105, 122, 122, 97, 114, 100, 32, 70, 105, 101, 108, 100, 0
__gas_LC89:
db 84, 52, 58, 32, 68, 101, 101, 112, 32, 70, 114, 101, 101, 122, 101, 114, 0
__gas_LC90:
db 84, 52, 58, 32, 67, 104, 97, 105, 110, 32, 76, 105, 103, 104, 116, 110, 105, 110, 103, 0
__gas_LC91:
db 84, 52, 58, 32, 83, 116, 111, 114, 109, 32, 67, 97, 108, 108, 101, 114, 0
__gas_LC92:
db 85, 110, 107, 110, 111, 119, 110, 0
section .text
align 16
global GetTowerName
GetTowerName:
    cmp edi, 11
    ja __gas_L283
    lea rdx, [rel __gas_L285]
    mov edi, edi
    movsx rax, dword [rdx+rdi*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L285:
dd __gas_L296-__gas_L285
dd __gas_L297-__gas_L285
dd __gas_L294-__gas_L285
dd __gas_L293-__gas_L285
dd __gas_L292-__gas_L285
dd __gas_L291-__gas_L285
dd __gas_L290-__gas_L285
dd __gas_L289-__gas_L285
dd __gas_L288-__gas_L285
dd __gas_L287-__gas_L285
dd __gas_L286-__gas_L285
dd __gas_L284-__gas_L285
section .text
align 16
align 8
__gas_L297:
    lea rax, [rel __gas_LC81]
    ret
align 16
align 8
__gas_L296:
    lea rax, [rel __gas_LC80]
    ret
align 16
align 8
__gas_L284:
    lea rax, [rel __gas_LC91]
    ret
align 16
align 8
__gas_L287:
    lea rax, [rel __gas_LC89]
    ret
align 16
align 8
__gas_L286:
    lea rax, [rel __gas_LC90]
    ret
align 16
align 8
__gas_L294:
    lea rax, [rel __gas_LC82]
    ret
align 16
align 8
__gas_L293:
    lea rax, [rel __gas_LC83]
    ret
align 16
align 8
__gas_L292:
    lea rax, [rel __gas_LC84]
    ret
align 16
align 8
__gas_L291:
    lea rax, [rel __gas_LC85]
    ret
align 16
align 8
__gas_L290:
    lea rax, [rel __gas_LC86]
    ret
align 16
align 8
__gas_L289:
    lea rax, [rel __gas_LC87]
    ret
align 16
align 8
__gas_L288:
    lea rax, [rel __gas_LC88]
    ret
__gas_L283:
    lea rax, [rel __gas_LC92]
    ret
section .rodata
align 8
__gas_LC93:
db 82, 97, 112, 105, 100, 45, 102, 105, 114, 101, 32, 101, 110, 101, 114, 103, 121, 32, 119, 101, 97, 112, 111, 110, 46, 32, 69, 102, 102, 101, 99, 116, 105, 118, 101, 32, 97, 103, 97, 105, 110, 115, 116, 32, 109, 111, 115, 116, 32, 116, 97, 114, 103, 101, 116, 115, 46, 0
align 8
__gas_LC94:
db 70, 105, 114, 101, 115, 32, 101, 120, 112, 108, 111, 115, 105, 118, 101, 32, 112, 104, 121, 115, 105, 99, 97, 108, 32, 115, 104, 101, 108, 108, 115, 46, 32, 68, 101, 97, 108, 115, 32, 65, 111, 69, 32, 100, 97, 109, 97, 103, 101, 46, 10, 83, 89, 78, 69, 82, 71, 89, 58, 32, 65, 112, 112, 108, 105, 101, 115, 32, 66, 117, 114, 110, 32, 97, 110, 100, 32, 77, 101, 108, 116, 101, 100, 32, 65, 114, 109, 111, 114, 46, 0
align 8
__gas_LC95:
db 67, 111, 110, 116, 105, 110, 117, 111, 117, 115, 32, 101, 110, 101, 114, 103, 121, 32, 98, 101, 97, 109, 32, 116, 104, 97, 116, 32, 115, 108, 111, 119, 115, 32, 97, 32, 116, 97, 114, 103, 101, 116, 46, 10, 83, 89, 78, 69, 82, 71, 89, 58, 32, 65, 112, 112, 108, 105, 101, 115, 32, 66, 114, 105, 116, 116, 108, 101, 32, 40, 73, 110, 99, 114, 101, 97, 115, 101, 100, 32, 80, 104, 121, 115, 105, 99, 97, 108, 32, 68, 109, 103, 32, 84, 97, 107, 101, 110, 41, 46, 0
align 8
__gas_LC96:
db 72, 105, 103, 104, 45, 100, 97, 109, 97, 103, 101, 32, 101, 110, 101, 114, 103, 121, 32, 97, 116, 116, 97, 99, 107, 115, 32, 119, 105, 116, 104, 32, 97, 32, 99, 104, 97, 110, 99, 101, 32, 116, 111, 32, 115, 116, 117, 110, 32, 116, 104, 101, 32, 116, 97, 114, 103, 101, 116, 46, 0
align 8
__gas_LC97:
db 85, 112, 103, 114, 97, 100, 101, 100, 32, 80, 117, 108, 115, 101, 32, 69, 109, 105, 116, 116, 101, 114, 32, 119, 105, 116, 104, 32, 101, 120, 116, 114, 101, 109, 101, 32, 102, 105, 114, 101, 32, 114, 97, 116, 101, 46, 32, 79, 118, 101, 114, 119, 104, 101, 108, 109, 115, 32, 116, 97, 114, 103, 101, 116, 115, 32, 119, 105, 116, 104, 32, 101, 110, 101, 114, 103, 121, 46, 0
align 8
__gas_LC98:
db 76, 111, 110, 103, 45, 114, 97, 110, 103, 101, 44, 32, 115, 108, 111, 119, 45, 102, 105, 114, 105, 110, 103, 32, 108, 97, 115, 101, 114, 32, 116, 104, 97, 116, 32, 100, 101, 97, 108, 115, 32, 109, 97, 115, 115, 105, 118, 101, 32, 101, 110, 101, 114, 103, 121, 32, 100, 97, 109, 97, 103, 101, 46, 0
align 8
__gas_LC99:
db 71, 108, 111, 98, 97, 108, 32, 114, 97, 110, 103, 101, 32, 97, 114, 116, 105, 108, 108, 101, 114, 121, 46, 32, 70, 105, 114, 101, 115, 32, 115, 108, 111, 119, 45, 109, 111, 118, 105, 110, 103, 32, 115, 104, 101, 108, 108, 115, 32, 119, 105, 116, 104, 32, 97, 32, 109, 97, 115, 115, 105, 118, 101, 32, 101, 120, 112, 108, 111, 115, 105, 111, 110, 32, 114, 97, 100, 105, 117, 115, 46, 10, 85, 115, 101, 115, 32, 112, 114, 101, 100, 105, 99, 116, 105, 118, 101, 32, 98, 97, 108, 108, 105, 115, 116, 105, 99, 32, 116, 97, 114, 103, 101, 116, 105, 110, 103, 46, 0
align 8
__gas_LC100:
db 72, 105, 103, 104, 45, 115, 112, 101, 101, 100, 32, 112, 104, 121, 115, 105, 99, 97, 108, 32, 71, 97, 116, 108, 105, 110, 103, 32, 103, 117, 110, 46, 32, 83, 104, 114, 101, 100, 115, 32, 97, 114, 109, 111, 114, 32, 97, 110, 100, 32, 97, 112, 112, 108, 105, 101, 115, 32, 66, 117, 114, 110, 32, 114, 97, 112, 105, 100, 108, 121, 46, 0
align 8
__gas_LC101:
db 67, 114, 101, 97, 116, 101, 115, 32, 97, 32, 112, 101, 114, 115, 105, 115, 116, 101, 110, 116, 32, 115, 108, 111, 119, 105, 110, 103, 32, 102, 105, 101, 108, 100, 32, 97, 114, 111, 117, 110, 100, 32, 116, 104, 101, 32, 116, 111, 119, 101, 114, 44, 32, 97, 102, 102, 101, 99, 116, 105, 110, 103, 32, 97, 108, 108, 32, 101, 110, 101, 109, 105, 101, 115, 32, 119, 105, 116, 104, 105, 110, 46, 0
align 8
__gas_LC102:
db 85, 112, 103, 114, 97, 100, 101, 100, 32, 67, 114, 121, 111, 32, 66, 101, 97, 109, 32, 116, 104, 97, 116, 32, 99, 111, 109, 112, 108, 101, 116, 101, 108, 121, 32, 102, 114, 101, 101, 122, 101, 115, 32, 40, 115, 116, 117, 110, 115, 41, 32, 116, 104, 101, 32, 116, 97, 114, 103, 101, 116, 32, 102, 111, 114, 32, 97, 32, 100, 117, 114, 97, 116, 105, 111, 110, 46, 0
align 8
__gas_LC103:
db 76, 105, 103, 104, 116, 110, 105, 110, 103, 32, 97, 116, 116, 97, 99, 107, 32, 116, 104, 97, 116, 32, 99, 104, 97, 105, 110, 115, 32, 116, 111, 32, 109, 117, 108, 116, 105, 112, 108, 101, 32, 110, 101, 97, 114, 98, 121, 32, 101, 110, 101, 109, 105, 101, 115, 46, 0
align 8
__gas_LC104:
db 72, 105, 103, 104, 32, 100, 97, 109, 97, 103, 101, 32, 84, 101, 115, 108, 97, 32, 67, 111, 105, 108, 32, 119, 105, 116, 104, 32, 105, 110, 99, 114, 101, 97, 115, 101, 100, 32, 115, 116, 117, 110, 32, 99, 104, 97, 110, 99, 101, 32, 97, 110, 100, 32, 100, 97, 109, 97, 103, 101, 46, 0
section .rodata
__gas_LC105:
db 78, 111, 32, 100, 101, 115, 99, 114, 105, 112, 116, 105, 111, 110, 32, 97, 118, 97, 105, 108, 97, 98, 108, 101, 46, 0
section .text
align 16
global GetTowerDescription
GetTowerDescription:
    cmp edi, 11
    ja __gas_L299
    lea rdx, [rel __gas_L301]
    mov edi, edi
    movsx rax, dword [rdx+rdi*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L301:
dd __gas_L312-__gas_L301
dd __gas_L313-__gas_L301
dd __gas_L310-__gas_L301
dd __gas_L309-__gas_L301
dd __gas_L308-__gas_L301
dd __gas_L307-__gas_L301
dd __gas_L306-__gas_L301
dd __gas_L305-__gas_L301
dd __gas_L304-__gas_L301
dd __gas_L303-__gas_L301
dd __gas_L302-__gas_L301
dd __gas_L300-__gas_L301
section .text
align 16
align 8
__gas_L313:
    lea rax, [rel __gas_LC94]
    ret
align 16
align 8
__gas_L312:
    lea rax, [rel __gas_LC93]
    ret
align 16
align 8
__gas_L300:
    lea rax, [rel __gas_LC104]
    ret
align 16
align 8
__gas_L303:
    lea rax, [rel __gas_LC102]
    ret
align 16
align 8
__gas_L302:
    lea rax, [rel __gas_LC103]
    ret
align 16
align 8
__gas_L310:
    lea rax, [rel __gas_LC95]
    ret
align 16
align 8
__gas_L309:
    lea rax, [rel __gas_LC96]
    ret
align 16
align 8
__gas_L308:
    lea rax, [rel __gas_LC97]
    ret
align 16
align 8
__gas_L307:
    lea rax, [rel __gas_LC98]
    ret
align 16
align 8
__gas_L306:
    lea rax, [rel __gas_LC99]
    ret
align 16
align 8
__gas_L305:
    lea rax, [rel __gas_LC100]
    ret
align 16
align 8
__gas_L304:
    lea rax, [rel __gas_LC101]
    ret
__gas_L299:
    lea rax, [rel __gas_LC105]
    ret
align 16
global GuiButton
GuiButton:
    push r15
    movaps xmm5, xmm1
    movaps xmm7, xmm0
    push r14
    shufps xmm7, xmm7, 0xe5
    shufps xmm5, xmm5, 0xe5
    push r13
    mov r13d, esi
    push r12
    mov r12d, -2571
    push rbp
    mov rbp, rdi
    push rbx
    mov ebx, edx
    sub rsp, 72
    movq qword [rsp], xmm1
    movss dword [rsp+44], xmm7
    movq qword [rsp+16], xmm0
    movq xmm7, qword [rsp+16]
    movss dword [rsp+40], xmm5
    movq xmm5, qword [rsp]
    movss dword [rsp+48], xmm7
    movss dword [rsp+36], xmm5
    call GetMousePosition wrt ..plt
    movq xmm1, qword [rsp+16]
    movq xmm2, qword [rsp]
    call CheckCollisionPointRec wrt ..plt
    test bl, bl
    je __gas_L325
    mov esi, -12836061
    test r13b, r13b
    jne __gas_L326
    test al, al
    jne __gas_L327
__gas_L318:
    mov byte [rsp+59], 0
    mov r13d, 100
    mov ebx, 70
    mov r15d, 40
    mov byte [rsp+52], 40
__gas_L316:
    movq xmm7, qword [rsp+16]
    pxor xmm0, xmm0
    mov edi, 8
    movss xmm2, dword [rel __gas_LC1]
    movq xmm1, qword [rsp]
    sal ebx, 16
    sal r13d, 24
    movq xmm4, xmm7
    addps xmm0, xmm4
    movaps oword [rsp+16], xmm4
    movq r14, xmm0
    movdqa xmm0, xmm7
    call DrawRectangleRounded wrt ..plt
    movzx eax, r15b
    mov ah, byte [rsp+52]
    pxor xmm5, xmm5
    movq xmm0, r14
    movzx eax, ax
    or eax, ebx
    or r13d, eax
    comiss xmm5, dword [rsp+36]
    jnb __gas_L320
    comiss xmm5, dword [rsp+40]
    jnb __gas_L320
    movq xmm1, qword [rsp]
    movaps xmm4, oword [rsp+16]
    mov esi, r13d
    mov edi, 8
    addps xmm4, oword [rel __gas_LC64]
    movss xmm2, dword [rel __gas_LC1]
    movq xmm3, xmm1
    addps xmm3, oword [rel __gas_LC110]
    movq rbx, xmm4
    movaps xmm7, xmm3
    movq r14, xmm3
    movaps oword [rsp], xmm3
    shufps xmm7, xmm7, 0xe5
    movss dword [rsp+52], xmm7
    call DrawRectangleRoundedLines wrt ..plt
    movaps xmm3, oword [rsp]
    pxor xmm5, xmm5
    movq xmm0, rbx
    comiss xmm5, xmm3
    jnb __gas_L320
    comiss xmm5, dword [rsp+52]
    jnb __gas_L320
    movss xmm2, dword [rel __gas_LC1]
    mov esi, r13d
    mov edi, 8
    movq xmm1, r14
    call DrawRectangleRoundedLines wrt ..plt
__gas_L320:
    mov rdi, rbp
    mov esi, 18
    call MeasureText wrt ..plt
    movss xmm1, dword [rel __gas_LC28]
    mov r8d, r12d
    mov rdi, rbp
    movss xmm0, dword [rsp+40]
    mov ecx, eax
    shr ecx, 31
    mulss xmm0, xmm1
    add eax, ecx
    mov ecx, 18
    addss xmm0, dword [rsp+44]
    subss xmm0, dword [rel __gas_LC109]
    sar eax, 1
    cvttss2si edx, xmm0
    movss xmm0, dword [rsp+36]
    mulss xmm0, xmm1
    pxor xmm1, xmm1
    cvtsi2ss xmm1, eax
    addss xmm0, dword [rsp+48]
    subss xmm0, xmm1
    cvttss2si esi, xmm0
    call DrawText wrt ..plt
    movzx eax, byte [rsp+59]
    add rsp, 72
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L326:
    mov si, -9216
    mov byte [rsp+59], 0
    xor ebx, ebx
    and r12d, -16777216
    mov byte [rsp+52], -7
    or esi, 16711680
    mov r13d, -1
    mov r15d, -3
    jmp __gas_L316
align 16
align 8
__gas_L325:
    movss xmm0, dword [rel __gas_LC106]
    mov edi, -12836061
    and r12d, -16777216
    or r12d, 11835030
    call ColorBrightness wrt ..plt
    mov esi, eax
    jmp __gas_L318
align 16
align 8
__gas_L327:
    movss xmm0, dword [rel __gas_LC107]
    mov edi, -12836061
    mov r13d, -1
    xor ebx, ebx
    mov r15d, -3
    call ColorBrightness wrt ..plt
    xor edi, edi
    mov dword [rsp+60], eax
    call IsMouseButtonPressed wrt ..plt
    mov byte [rsp+52], -7
    mov esi, dword [rsp+60]
    mov byte [rsp+59], al
    jmp __gas_L316
section .rodata
__gas_LC111:
db 66, 85, 73, 76, 68, 32, 77, 69, 78, 85, 32, 40, 49, 45, 52, 41, 0
__gas_LC112:
db 37, 115, 32, 40, 37, 100, 71, 41, 0
__gas_LC113:
db 78, 111, 116, 32, 101, 110, 111, 117, 103, 104, 32, 71, 111, 108, 100, 33, 0
section .text
__gas_LCOLDB115:
section .text
__gas_LHOTB115:
align 16
global DrawBuildMenu
DrawBuildMenu:
    push r15
    mov r8d, -9216
    mov ecx, 20
    mov edx, 270
    push r14
    mov esi, 970
    lea rdi, [rel __gas_LC111]
    push r13
    push r12
    push rbp
    push rbx
    xor ebx, ebx
    sub rsp, 200
    call DrawText wrt ..plt
    mov rax, 4294967296
    mov qword [rsp+48], rax
    mov rax, 12884901890
    mov qword [rsp+56], rax
    lea rax, [rsp+48]
    mov qword [rsp+24], rax
    lea rax, [rsp+64]
    mov qword [rsp+8], rax
__gas_L348:
    mov rax, qword [rsp+24]
    pxor xmm0, xmm0
    cvtsi2ss xmm0, ebx
    addss xmm0, dword [rel __gas_LC69]
    mov ebp, dword [rax]
    mov edi, ebp
    movss dword [rsp+16], xmm0
    call GetTowerCost wrt ..plt
    mov r10d, dword [rel 253260+game]
    mov r8d, eax
    cmp r10d, eax
    setge byte [rsp+22]
    cmp dword [rel 253288+game], ebp
    sete byte [rsp+23]
    cmp ebp, 11
    ja __gas_L349
    lea rcx, [rel __gas_L331]
    mov eax, ebp
    movsx rax, dword [rcx+rax*4]
    add rax, rcx
    jmp rax
section .rodata
align 4
align 4
__gas_L331:
dd __gas_L342-__gas_L331
dd __gas_L341-__gas_L331
dd __gas_L340-__gas_L331
dd __gas_L339-__gas_L331
dd __gas_L338-__gas_L331
dd __gas_L337-__gas_L331
dd __gas_L336-__gas_L331
dd __gas_L335-__gas_L331
dd __gas_L334-__gas_L331
dd __gas_L333-__gas_L331
dd __gas_L332-__gas_L331
dd __gas_L330-__gas_L331
section .text
align 16
align 8
__gas_L342:
    lea rax, [rel __gas_LC80]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC93]
    mov qword [rsp+40], rax
align 16
align 8
__gas_L329:
    mov rdi, qword [rsp+8]
    mov rcx, qword [rsp]
    mov esi, 128
    xor eax, eax
    lea rdx, [rel __gas_LC112]
    mov dword [rsp+36], r10d
    mov r13, 4792392954609532928
    mov dword [rsp+32], r8d
    call snprintf wrt ..plt
    mov rax, r12
    mov edx, dword [rsp+16]
    mov rsi, -4294967296
    and rax, rsi
    mov rdi, qword [rsp+8]
    movzx esi, byte [rsp+23]
    movq xmm1, r13
    or rax, 1148354560
    sal rdx, 32
    mov eax, eax
    or rax, rdx
    movzx edx, byte [rsp+22]
    movq xmm0, rax
    mov r12, rax
    call GuiButton
    test al, al
    je __gas_L343
    mov r8d, dword [rsp+32]
    mov r10d, dword [rsp+36]
    cmp r10d, r8d
    jl __gas_L344
    mov dword [rel 253288+game], ebp
    mov dword [rel 253292+game], -1
__gas_L343:
    call GetMousePosition wrt ..plt
    mov rax, r14
    mov rdi, -4294967296
    mov edx, dword [rsp+16]
    mov r15, 4792392954609532928
    and rax, rdi
    or rax, 1148354560
    sal rdx, 32
    movq xmm2, r15
    mov eax, eax
    or rax, rdx
    movq xmm1, rax
    mov r14, rax
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L345
    mov rax, qword [rsp]
    movss xmm3, dword [rsp+16]
    add ebx, 80
    mov dword [rel 253336+game], 0x44728000
    mov qword [rel 253344+game], r15
    mov qword [rel 253320+game], rax
    mov rax, qword [rsp+40]
    mov byte [rel 253312+game], 1
    mov qword [rel 253328+game], rax
    movss dword [rel 253340+game], xmm3
    cmp ebx, 320
    je __gas_L328
__gas_L360:
    add qword [rsp+24], 4
    jmp __gas_L348
align 16
align 8
__gas_L330:
    lea rax, [rel __gas_LC91]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC104]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L332:
    lea rax, [rel __gas_LC90]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC103]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L333:
    lea rax, [rel __gas_LC89]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC102]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L334:
    lea rax, [rel __gas_LC88]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC101]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L335:
    lea rax, [rel __gas_LC87]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC100]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L336:
    lea rax, [rel __gas_LC86]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC99]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L337:
    lea rax, [rel __gas_LC85]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC98]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L338:
    lea rax, [rel __gas_LC84]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC97]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L339:
    lea rax, [rel __gas_LC83]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC96]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L340:
    lea rax, [rel __gas_LC82]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC95]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L341:
    lea rax, [rel __gas_LC81]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC94]
    mov qword [rsp+40], rax
    jmp __gas_L329
align 16
align 8
__gas_L345:
    add ebx, 80
    cmp ebx, 320
    jne __gas_L360
__gas_L328:
    add rsp, 200
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L344:
    mov eax, dword [rsp+16]
    xor edx, edx
    mov esi, -13487361
    lea rdi, [rel __gas_LC113]
    sal rax, 32
    or rax, 1149009920
    movq xmm0, rax
    call AddFloatingText wrt ..plt
    jmp __gas_L343
section .text
DrawBuildMenu.cold:
__gas_L349:
    lea rax, [rel __gas_LC92]
    mov qword [rsp], rax
    lea rax, [rel __gas_LC105]
    mov qword [rsp+40], rax
    jmp __gas_L329
section .text
section .text
__gas_LCOLDE115:
section .text
__gas_LHOTE115:
section .rodata
align 8
__gas_LC116:
db 84, 52, 32, 85, 80, 71, 82, 65, 68, 69, 32, 80, 65, 84, 72, 83, 32, 40, 82, 101, 113, 117, 105, 114, 101, 115, 32, 65, 101, 116, 104, 101, 114, 41, 0
section .rodata
__gas_LC118:
db 37, 115, 32, 40, 37, 100, 71, 44, 32, 37, 100, 65, 41, 0
__gas_LC119:
db 85, 80, 71, 82, 65, 68, 69, 68, 33, 0
__gas_LC120:
db 67, 97, 110, 110, 111, 116, 32, 65, 102, 102, 111, 114, 100, 33, 0
section .text
__gas_LCOLDB121:
section .text
__gas_LHOTB121:
align 16
global DrawTowerUpgradePaths
DrawTowerUpgradePaths:
    push r15
    mov r8d, -39756
    mov ecx, 20
    mov edx, 600
    push r14
    mov esi, 970
    push r13
    push r12
    push rbp
    push rbx
    mov rbx, rdi
    sub rsp, 216
    mov qword [rsp+48], rdi
    lea rdi, [rel __gas_LC116]
    call DrawText wrt ..plt
    mov eax, dword [rbx+8]
    cmp eax, 3
    ja __gas_L361
    mov qword [rsp+8], 0
    add eax, eax
    lea edx, [rax+4]
    add eax, 5
    mov dword [rsp+76], eax
    lea rax, [rsp+72]
    mov qword [rsp+32], rax
    lea rax, [rsp+80]
    mov dword [rsp+72], edx
    mov qword [rsp+16], rax
__gas_L384:
    mov rcx, qword [rsp+8]
    pxor xmm0, xmm0
    mov eax, ecx
    neg eax
    and eax, 65
    cvtsi2ss xmm0, eax
    mov rax, qword [rsp+32]
    addss xmm0, dword [rel __gas_LC117]
    mov ebp, dword [rax+rcx*4]
    movss dword [rsp+56], xmm0
    mov edi, ebp
    call GetTowerCost wrt ..plt
    mov edi, ebp
    mov ebx, eax
    call GetTowerAetherCost wrt ..plt
    cmp dword [rel 253260+game], ebx
    mov dword [rsp], 0
    mov r9d, eax
    jl __gas_L363
    xor eax, eax
    cmp dword [rel 253264+game], r9d
    setge al
    mov dword [rsp], eax
__gas_L363:
    cmp ebp, 11
    ja __gas_L386
    lea rsi, [rel __gas_L366]
    mov eax, ebp
    movsx rax, dword [rsi+rax*4]
    add rax, rsi
    jmp rax
section .rodata
align 4
align 4
__gas_L366:
dd __gas_L377-__gas_L366
dd __gas_L376-__gas_L366
dd __gas_L375-__gas_L366
dd __gas_L374-__gas_L366
dd __gas_L373-__gas_L366
dd __gas_L372-__gas_L366
dd __gas_L371-__gas_L366
dd __gas_L370-__gas_L366
dd __gas_L369-__gas_L366
dd __gas_L368-__gas_L366
dd __gas_L367-__gas_L366
dd __gas_L365-__gas_L366
section .text
align 16
align 8
__gas_L382:
    cmp qword [rsp+8], 1
    jne __gas_L383
__gas_L361:
    add rsp, 216
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L377:
    lea rax, [rel __gas_LC80]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC93]
    mov qword [rsp+40], rax
align 16
align 8
__gas_L364:
    mov rcx, qword [rsp+24]
    mov rdi, qword [rsp+16]
    xor eax, eax
    mov r8d, ebx
    lea rdx, [rel __gas_LC118]
    mov esi, 128
    mov dword [rsp+60], r9d
    mov r15, 4776067405960314880
    call snprintf wrt ..plt
    mov rax, r14
    mov edx, dword [rsp+56]
    xor esi, esi
    mov rcx, -4294967296
    mov rdi, qword [rsp+16]
    movq xmm1, r15
    and rax, rcx
    sal rdx, 32
    or rax, 1148354560
    mov eax, eax
    or rax, rdx
    mov edx, dword [rsp]
    movq xmm0, rax
    mov r14, rax
    call GuiButton
    test al, al
    je __gas_L379
    mov eax, dword [rsp]
    test eax, eax
    je __gas_L380
    mov r9d, dword [rsp+60]
    movd xmm1, ebx
    mov rdi, qword [rsp+48]
    mov esi, ebp
    movq xmm0, qword [rel 253260+game]
    movd xmm4, r9d
    punpckldq xmm1, xmm4
    psubd xmm0, xmm1
    movq qword [rel 253260+game], xmm0
    call UpgradeTower wrt ..plt
    test al, al
    jne __gas_L394
align 16
align 8
__gas_L379:
    call GetMousePosition wrt ..plt
    mov rax, r12
    mov rsi, -4294967296
    mov edx, dword [rsp+56]
    mov r13, 4776067405960314880
    and rax, rsi
    or rax, 1148354560
    sal rdx, 32
    movq xmm2, r13
    mov eax, eax
    or rax, rdx
    movq xmm1, rax
    mov r12, rax
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L382
    mov rax, qword [rsp+24]
    movss xmm3, dword [rsp+56]
    mov dword [rel 253336+game], 0x44728000
    cmp qword [rsp+8], 1
    mov qword [rel 253344+game], r13
    mov qword [rel 253320+game], rax
    mov rax, qword [rsp+40]
    mov byte [rel 253312+game], 1
    mov qword [rel 253328+game], rax
    movss dword [rel 253340+game], xmm3
    je __gas_L361
__gas_L383:
    mov qword [rsp+8], 1
    jmp __gas_L384
align 16
align 8
__gas_L376:
    lea rax, [rel __gas_LC81]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC94]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L375:
    lea rax, [rel __gas_LC82]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC95]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L374:
    lea rax, [rel __gas_LC83]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC96]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L373:
    lea rax, [rel __gas_LC84]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC97]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L372:
    lea rax, [rel __gas_LC85]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC98]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L371:
    lea rax, [rel __gas_LC86]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC99]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L370:
    lea rax, [rel __gas_LC87]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC100]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L369:
    lea rax, [rel __gas_LC88]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC101]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L368:
    lea rax, [rel __gas_LC89]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC102]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L367:
    lea rax, [rel __gas_LC90]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC103]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L365:
    lea rax, [rel __gas_LC91]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC104]
    mov qword [rsp+40], rax
    jmp __gas_L364
align 16
align 8
__gas_L380:
    mov eax, dword [rsp+56]
    xor edx, edx
    mov esi, -13487361
    lea rdi, [rel __gas_LC120]
    sal rax, 32
    or rax, 1149009920
    movq xmm0, rax
    call AddFloatingText wrt ..plt
    jmp __gas_L379
align 16
align 8
__gas_L394:
    mov rax, qword [rsp+48]
    mov edx, 1
    mov esi, -39756
    lea rdi, [rel __gas_LC119]
    add dword [rax+76], ebx
    mov rax, qword [rax]
    movq xmm0, rax
    mov qword [rsp], rax
    call AddFloatingText wrt ..plt
    movss xmm1, dword [rel __gas_LC35]
    movss xmm0, dword [rel __gas_LC29]
    call ScreenShake wrt ..plt
    jmp __gas_L379
section .text
DrawTowerUpgradePaths.cold:
__gas_L386:
    lea rax, [rel __gas_LC92]
    mov qword [rsp+24], rax
    lea rax, [rel __gas_LC105]
    mov qword [rsp+40], rax
    jmp __gas_L364
section .text
section .text
__gas_LCOLDE121:
section .text
__gas_LHOTE121:
section .rodata
__gas_LC122:
db 84, 114, 117, 101, 0
__gas_LC123:
db 69, 110, 101, 114, 103, 121, 0
__gas_LC124:
db 80, 104, 121, 115, 105, 99, 97, 108, 0
__gas_LC125:
db 71, 108, 111, 98, 97, 108, 0
__gas_LC126:
db 67, 108, 111, 115, 101, 115, 116, 0
__gas_LC127:
db 70, 105, 114, 115, 116, 32, 40, 68, 101, 102, 97, 117, 108, 116, 41, 0
__gas_LC128:
db 83, 116, 114, 111, 110, 103, 101, 115, 116, 32, 40, 72, 80, 41, 0
__gas_LC129:
db 87, 101, 97, 107, 101, 115, 116, 32, 40, 72, 80, 41, 0
__gas_LC130:
db 84, 79, 87, 69, 82, 32, 73, 78, 83, 80, 69, 67, 84, 73, 79, 78, 0
__gas_LC131:
db 37, 115, 32, 40, 76, 37, 100, 41, 0
__gas_LC132:
db 75, 105, 108, 108, 115, 58, 32, 37, 100, 0
__gas_LC133:
db 69, 120, 112, 101, 114, 105, 101, 110, 99, 101, 58, 0
__gas_LC134:
db 37, 100, 32, 47, 32, 37, 100, 0
__gas_LC135:
db 77, 65, 88, 32, 76, 69, 86, 69, 76, 32, 45, 32, 82, 69, 65, 68, 89, 32, 70, 79, 82, 32, 85, 80, 71, 82, 65, 68, 69, 0
__gas_LC136:
db 83, 112, 101, 99, 105, 97, 108, 105, 122, 101, 100, 32, 84, 111, 119, 101, 114, 32, 40, 77, 97, 120, 32, 84, 105, 101, 114, 41, 0
__gas_LC137:
db 83, 116, 97, 116, 115, 58, 0
__gas_LC138:
db 68, 97, 109, 97, 103, 101, 58, 32, 37, 46, 49, 102, 32, 40, 37, 115, 41, 0
__gas_LC140:
db 37, 46, 48, 102, 0
__gas_LC141:
db 82, 97, 110, 103, 101, 58, 32, 37, 115, 0
__gas_LC142:
db 70, 105, 114, 101, 32, 82, 97, 116, 101, 58, 32, 67, 111, 110, 116, 105, 110, 117, 111, 117, 115, 32, 40, 68, 80, 83, 41, 0
__gas_LC143:
db 83, 108, 111, 119, 32, 65, 117, 114, 97, 58, 32, 37, 46, 48, 102, 37, 37, 0
__gas_LC144:
db 70, 105, 114, 101, 32, 82, 97, 116, 101, 58, 32, 37, 46, 50, 102, 47, 115, 0
__gas_LC145:
db 84, 97, 114, 103, 101, 116, 105, 110, 103, 32, 77, 111, 100, 101, 58, 0
__gas_LC146:
db 84, 97, 114, 103, 101, 116, 105, 110, 103, 32, 77, 111, 100, 101, 0
section .rodata
align 8
__gas_LC147:
db 67, 104, 97, 110, 103, 101, 32, 104, 111, 119, 32, 116, 104, 101, 32, 116, 111, 119, 101, 114, 32, 112, 114, 105, 111, 114, 105, 116, 105, 122, 101, 115, 32, 101, 110, 101, 109, 105, 101, 115, 46, 0
section .rodata
__gas_LC148:
db 83, 101, 108, 108, 32, 84, 111, 119, 101, 114, 32, 40, 37, 100, 71, 41, 0
__gas_LC149:
db 83, 101, 108, 108, 0
section .rodata
align 8
__gas_LC150:
db 83, 101, 108, 108, 32, 116, 104, 101, 32, 116, 111, 119, 101, 114, 32, 102, 111, 114, 32, 97, 32, 112, 97, 114, 116, 105, 97, 108, 32, 114, 101, 102, 117, 110, 100, 46, 0
section .text
align 16
global DrawTowerInspector
DrawTowerInspector:
    push r15
    push r14
    push r13
    push r12
    push rbp
    push rbx
    sub rsp, 424
    movsx rbx, dword [rel 253292+game]
    cmp ebx, -1
    je __gas_L396
    lea r12, [rbx+rbx*4]
    lea rbp, [rel game]
    sal r12, 4
    add r12, rbp
    cmp byte [r12+2520], 0
    jne __gas_L397
__gas_L396:
    mov dword [rel 253292+game], -1
__gas_L395:
    add rsp, 424
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L397:
    mov r8d, -16713219
    mov ecx, 20
    mov edx, 270
    mov esi, 970
    lea rdi, [rel __gas_LC130]
    call DrawText wrt ..plt
    mov r8d, dword [r12+2468]
    cmp dword [r12+2464], 11
    ja __gas_L399
    mov eax, dword [r12+2464]
    lea rdx, [rel __gas_L401]
    movsx rax, dword [rdx+rax*4]
    add rax, rdx
    jmp rax
section .rodata
align 4
align 4
__gas_L401:
dd __gas_L412-__gas_L401
dd __gas_L431-__gas_L401
dd __gas_L410-__gas_L401
dd __gas_L409-__gas_L401
dd __gas_L408-__gas_L401
dd __gas_L407-__gas_L401
dd __gas_L406-__gas_L401
dd __gas_L405-__gas_L401
dd __gas_L404-__gas_L401
dd __gas_L403-__gas_L401
dd __gas_L402-__gas_L401
dd __gas_L400-__gas_L401
section .text
align 16
align 8
__gas_L431:
    lea rcx, [rel __gas_LC81]
align 16
align 8
__gas_L411:
    lea r12, [rbx+rbx*4]
    lea r13, [rsp+288]
    mov esi, 128
    xor eax, eax
    sal r12, 4
    lea rdx, [rel __gas_LC131]
    mov rdi, r13
    call snprintf wrt ..plt
    add r12, rbp
    mov edi, dword [r12+2464]
    call GetTowerColor
    mov rdi, r13
    mov ecx, 22
    mov edx, 300
    mov r8d, eax
    mov esi, 970
    lea r13, [rsp+32]
    call DrawText wrt ..plt
    mov esi, 32
    mov rdi, r13
    xor eax, eax
    mov ecx, dword [r12+2528]
    lea rdx, [rel __gas_LC132]
    call snprintf wrt ..plt
    mov r8d, -2571
    mov ecx, 18
    mov rdi, r13
    mov edx, 305
    mov esi, 1160
    call DrawText wrt ..plt
    mov r8d, -13435086
    mov ecx, 18
    cmp dword [r12+2464], 3
    mov edx, 340
    mov esi, 970
    ja __gas_L413
    lea rdi, [rel __gas_LC133]
    call DrawText wrt ..plt
    cmp dword [r12+2468], 2
    jg __gas_L414
    mov eax, dword [r12+2476]
    pxor xmm2, xmm2
    test eax, eax
    jle __gas_L415
    pxor xmm2, xmm2
    pxor xmm0, xmm0
    cvtsi2ss xmm2, dword [r12+2472]
    cvtsi2ss xmm0, eax
    divss xmm2, xmm0
__gas_L415:
    mov rax, 4878524297497444352
    mov edi, -12836061
    mov r14, 4728779609872924672
    movss dword [rsp+8], xmm2
    movq xmm0, rax
    movq xmm1, r14
    mov qword [rsp], rax
    lea r12, [rsp+224]
    call DrawRectangleRec wrt ..plt
    movss xmm2, dword [rsp+8]
    mov r8d, -13435086
    mov ecx, 20
    mulss xmm2, dword [rel __gas_LC69]
    mov esi, 360
    mov edi, 970
    cvttss2si edx, xmm2
    call DrawRectangle wrt ..plt
    movq xmm0, qword [rsp]
    mov edi, -16777216
    movss xmm2, dword [rel __gas_LC14]
    movq xmm1, r14
    call DrawRectangleLinesEx wrt ..plt
    lea rax, [rbx+rbx*4]
    mov esi, 64
    mov rdi, r12
    sal rax, 4
    lea rdx, [rel __gas_LC134]
    add rax, rbp
    mov ecx, dword [rax+2472]
    mov r8d, dword [rax+2476]
    xor eax, eax
    call snprintf wrt ..plt
    mov r8d, -2571
    mov ecx, 16
    mov rdi, r12
    mov edx, 362
    mov esi, 980
    call DrawText wrt ..plt
__gas_L416:
    mov dword [rsp+24], 520
    mov r13d, 510
    mov r15d, 425
    mov edx, 400
    mov dword [rsp+20], 475
    mov dword [rsp], 450
    mov dword [rsp+28], 390
__gas_L417:
    mov r8d, -16713219
    mov ecx, 20
    mov esi, 970
    lea rdi, [rel __gas_LC137]
    call DrawText wrt ..plt
    lea rax, [rbx+rbx*4]
    lea r10, [rel __gas_LC123]
    sal rax, 4
    mov eax, dword [rbp+rax+2492]
    cmp eax, 1
    je __gas_L418
    test eax, eax
    lea r10, [rel __gas_LC122]
    lea rax, [rel __gas_LC124]
    cmove r10, rax
__gas_L418:
    lea rax, [rbx+rbx*4]
    pxor xmm0, xmm0
    sal rax, 4
    lea r14, [rbp+rax+0]
    mov edi, dword [r14+2464]
    call GetTowerColor
    lea rdi, [rsp+96]
    mov rcx, r10
    lea rdx, [rel __gas_LC138]
    mov dword [rsp+16], eax
    mov esi, 64
    mov eax, 1
    cvtss2sd xmm0, dword [r14+2480]
    mov qword [rsp+8], rdi
    call snprintf wrt ..plt
    mov r8d, dword [rsp+16]
    mov rdi, qword [rsp+8]
    mov edx, r15d
    mov ecx, 18
    mov esi, 970
    call DrawText wrt ..plt
    lea rcx, [rel __gas_LC125]
    movss xmm0, dword [r14+2484]
    comiss xmm0, dword [rel __gas_LC139]
    jbe __gas_L459
__gas_L419:
    lea r15, [rsp+160]
    lea rdx, [rel __gas_LC141]
    mov esi, 64
    xor eax, eax
    mov rdi, r15
    call snprintf wrt ..plt
    mov edx, dword [rsp]
    mov ecx, 18
    mov rdi, r15
    mov r8d, -2571
    mov esi, 970
    call DrawText wrt ..plt
    lea rax, [rbx+rbx*4]
    sal rax, 4
    add rax, rbp
    mov edx, dword [rax+2464]
    cmp edx, 2
    je __gas_L439
    cmp edx, 9
    je __gas_L439
    movss xmm0, dword [rax+2488]
    cmp edx, 8
    je __gas_L460
    lea rdx, [rel __gas_LC144]
    cvtss2sd xmm0, xmm0
__gas_L458:
    mov esi, 64
    mov rdi, r12
    mov eax, 1
    call snprintf wrt ..plt
    mov edx, dword [rsp+20]
    mov r8d, -2571
    mov rdi, r12
    mov ecx, 18
    mov esi, 970
    call DrawText wrt ..plt
__gas_L422:
    mov ecx, r13d
    mov esi, r13d
    lea r13, [rbx+rbx*4]
    mov r8d, -12836061
    sal r13, 4
    mov edx, 1280
    mov edi, 960
    call DrawLine wrt ..plt
    add r13, rbp
    cmp dword [r13+2464], 8
    je __gas_L424
    mov edx, dword [rsp+24]
    mov r8d, -16713219
    mov ecx, 20
    lea rdi, [rel __gas_LC145]
    mov esi, 970
    call DrawText wrt ..plt
    mov eax, dword [rsp+28]
    pxor xmm4, xmm4
    lea rdi, [rel __gas_LC128]
    add eax, 155
    cvtsi2ss xmm4, eax
    mov eax, dword [r13+2524]
    movd r14d, xmm4
    cmp eax, 2
    je __gas_L425
    ja __gas_L426
    test eax, eax
    lea rdi, [rel __gas_LC127]
    lea rax, [rel __gas_LC126]
    cmovne rdi, rax
__gas_L425:
    xor ecx, ecx
    mov edx, 1
    mov rsi, -4294967296
    mov rax, 4764808406891888640
    and rcx, rsi
    mov esi, r14d
    or rcx, 1148354560
    sal rsi, 32
    movq xmm1, rax
    mov ecx, ecx
    or rcx, rsi
    xor esi, esi
    movq xmm0, rcx
    call GuiButton
    test al, al
    je __gas_L427
    lea rax, [rbx+rbx*4]
    sal rax, 4
    add rax, rbp
    mov esi, dword [rax+2524]
    lea edx, [rsi+1]
    and edx, 3
    mov dword [rax+2524], edx
__gas_L427:
    call GetMousePosition wrt ..plt
    xor ecx, ecx
    mov rsi, -4294967296
    mov r15, 4764808406891888640
    and rcx, rsi
    mov esi, r14d
    movq xmm2, r15
    or rcx, 1148354560
    sal rsi, 32
    mov ecx, ecx
    or rcx, rsi
    movq xmm1, rcx
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L428
    movq xmm0, qword [rel __gas_LC152]
    lea rax, [rel __gas_LC147]
    mov dword [rel 253336+game], 0x44728000
    movq xmm5, rax
    mov dword [rel 253340+game], r14d
    mov qword [rel 253344+game], r15
    punpcklqdq xmm0, xmm5
    mov byte [rel 253312+game], 1
    movups oword [rel 253320+game], xmm0
__gas_L428:
    lea rax, [rbx+rbx*4]
    sal rax, 4
    lea rdx, [rbp+rax+0]
    cmp dword [rdx+2468], 2
    jle __gas_L424
    cmp dword [rdx+2464], 3
    ja __gas_L424
    lea rdi, [rbp+rax+2456]
    call DrawTowerUpgradePaths
align 16
align 8
__gas_L424:
    lea rax, [rbx+rbx*4]
    pxor xmm0, xmm0
    mov esi, 64
    mov rdi, r12
    sal rax, 4
    lea rdx, [rel __gas_LC148]
    cvtsi2ss xmm0, dword [rbp+rax+2532]
    xor eax, eax
    mulss xmm0, dword [rel __gas_LC36]
    cvttss2si ecx, xmm0
    call snprintf wrt ..plt
    xor esi, esi
    mov edx, 1
    mov rdi, r12
    mov rax, 4916664156841738240
    movq xmm0, rax
    mov rax, 4764808406891888640
    movq xmm1, rax
    call GuiButton
    test al, al
    jne __gas_L461
__gas_L429:
    call GetMousePosition wrt ..plt
    mov rax, 4916664156841738240
    movq xmm1, rax
    mov rax, 4764808406891888640
    movq xmm2, rax
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L395
    movq xmm0, qword [rel __gas_LC153]
    lea rax, [rel __gas_LC150]
    mov byte [rel 253312+game], 1
    movq xmm3, rax
    punpcklqdq xmm0, xmm3
    movups oword [rel 253320+game], xmm0
    movaps xmm0, oword [rel __gas_LC151]
    movups oword [rel 253336+game], xmm0
    jmp __gas_L395
align 16
align 8
__gas_L412:
    lea rcx, [rel __gas_LC80]
    jmp __gas_L411
align 16
align 8
__gas_L410:
    lea rcx, [rel __gas_LC82]
    jmp __gas_L411
align 16
align 8
__gas_L409:
    lea rcx, [rel __gas_LC83]
    jmp __gas_L411
align 16
align 8
__gas_L408:
    lea rcx, [rel __gas_LC84]
    jmp __gas_L411
align 16
align 8
__gas_L407:
    lea rcx, [rel __gas_LC85]
    jmp __gas_L411
align 16
align 8
__gas_L406:
    lea rcx, [rel __gas_LC86]
    jmp __gas_L411
align 16
align 8
__gas_L405:
    lea rcx, [rel __gas_LC87]
    jmp __gas_L411
align 16
align 8
__gas_L404:
    lea rcx, [rel __gas_LC88]
    jmp __gas_L411
align 16
align 8
__gas_L403:
    lea rcx, [rel __gas_LC89]
    jmp __gas_L411
align 16
align 8
__gas_L402:
    lea rcx, [rel __gas_LC90]
    jmp __gas_L411
align 16
align 8
__gas_L400:
    lea rcx, [rel __gas_LC91]
    jmp __gas_L411
align 16
align 8
__gas_L413:
    lea rdi, [rel __gas_LC136]
    mov r13d, 490
    mov r15d, 405
    call DrawText wrt ..plt
    lea r12, [rsp+224]
    mov dword [rsp+24], 500
    mov edx, 380
    mov dword [rsp+20], 455
    mov dword [rsp], 430
    mov dword [rsp+28], 370
    jmp __gas_L417
align 16
align 8
__gas_L459:
    lea r15, [rsp+64]
    lea rdx, [rel __gas_LC140]
    mov esi, 32
    mov eax, 1
    mov rdi, r15
    cvtss2sd xmm0, xmm0
    call snprintf wrt ..plt
    mov rcx, r15
    jmp __gas_L419
align 16
align 8
__gas_L461:
    mov edi, dword [rel 253292+game]
    call SellTower wrt ..plt
    jmp __gas_L429
align 16
align 8
__gas_L439:
    mov edx, dword [rsp+20]
    mov r8d, -2571
    mov ecx, 18
    mov esi, 970
    lea rdi, [rel __gas_LC142]
    call DrawText wrt ..plt
    jmp __gas_L422
align 16
align 8
__gas_L460:
    mulss xmm0, dword [rel __gas_LC33]
    lea rdx, [rel __gas_LC143]
    cvtss2sd xmm0, xmm0
    jmp __gas_L458
align 16
align 8
__gas_L414:
    mov rax, 4878524297497444352
    mov edi, -13435086
    lea r12, [rsp+224]
    movq xmm0, rax
    mov rax, 4728779609872924672
    movq xmm1, rax
    call DrawRectangleRec wrt ..plt
    mov r8d, -16777216
    mov ecx, 16
    mov edx, 362
    mov esi, 980
    lea rdi, [rel __gas_LC135]
    call DrawText wrt ..plt
    jmp __gas_L416
align 16
align 8
__gas_L426:
    cmp eax, 3
    lea rdi, [rel __gas_LC129]
    lea rax, [rel __gas_LC92]
    cmovne rdi, rax
    jmp __gas_L425
__gas_L399:
    lea rcx, [rel __gas_LC92]
    jmp __gas_L411
section .rodata
__gas_LC156:
db 71, 76, 79, 66, 65, 76, 32, 82, 65, 78, 71, 69, 0
__gas_LC157:
db 65, 69, 84, 72, 69, 82, 73, 85, 77, 32, 86, 65, 78, 71, 85, 65, 82, 68, 0
__gas_LC158:
db 76, 73, 86, 69, 83, 58, 32, 37, 100, 0
__gas_LC159:
db 71, 79, 76, 68, 58, 32, 37, 100, 0
__gas_LC160:
db 65, 69, 84, 72, 69, 82, 58, 32, 37, 100, 0
__gas_LC161:
db 87, 65, 86, 69, 32, 37, 100, 32, 40, 82, 101, 109, 97, 105, 110, 105, 110, 103, 58, 32, 37, 100, 41, 0
__gas_LC162:
db 78, 101, 120, 116, 32, 87, 97, 118, 101, 58, 32, 37, 46, 49, 102, 115, 32, 40, 78, 41, 0
section .text
align 16
global DrawUI
DrawUI:
    push r15
    push r14
    push r13
    push r12
    push rbp
    mov ebp, -1
    push rbx
    sub rsp, 216
    call GetMousePosition wrt ..plt
    sub rsp, 32
    mov rax, qword [rel 2448+game]
    movdqa xmm5, xmm0
    movdqu xmm0, oword [rel 2432+game]
    mov qword [rsp+16], rax
    movups oword [rsp], xmm0
    movdqa xmm0, xmm5
    movq qword [rsp+40], xmm5
    call GetScreenToWorld2D wrt ..plt
    mov rax, qword [rel 2448+game]
    movq rbx, xmm0
    movdqu xmm0, oword [rel 2432+game]
    mov qword [rsp+16], rax
    movups oword [rsp], xmm0
    call BeginMode2D wrt ..plt
    add rsp, 32
    cmp dword [rel 253288+game], -1
    je __gas_L463
    movd xmm0, dword [rsp+8]
    movss xmm1, dword [rel __gas_LC154]
    comiss xmm1, xmm0
    ja __gas_L485
__gas_L463:
    movsx rax, dword [rel 253292+game]
    lea rbx, [rsp+128]
    cmp eax, -1
    je __gas_L467
    lea rax, [rax+rax*4]
    lea rdx, [rel 8+game]
    mov bp, -1539
    sal rax, 4
    and ebp, -16711681
    movq xmm3, qword [rdx+rax+2448]
    movss xmm1, dword [rdx+rax+2476]
__gas_L466:
    comiss xmm1, dword [rel __gas_LC139]
    movaps xmm6, xmm3
    movaps xmm4, xmm3
    shufps xmm6, xmm6, 0xe5
    movaps xmm2, xmm6
    jbe __gas_L482
    addss xmm2, dword [rel __gas_LC7]
    subss xmm4, dword [rel __gas_LC155]
    mov r8d, ebp
    mov ecx, 20
    addss xmm2, dword [rel __gas_LC11]
    lea rdi, [rel __gas_LC156]
    cvttss2si esi, xmm4
    cvttss2si edx, xmm2
    call DrawText wrt ..plt
__gas_L467:
    call EndMode2D wrt ..plt
    xor esi, esi
    mov r8d, -14478316
    mov ecx, 800
    mov edx, 320
    mov edi, 960
    lea rbp, [rsp+32]
    call DrawRectangle wrt ..plt
    xor esi, esi
    mov r8d, -12836061
    mov ecx, 800
    mov edx, 960
    mov edi, 960
    call DrawLine wrt ..plt
    mov r8d, -9216
    mov ecx, 24
    mov edx, 10
    mov esi, 970
    lea rdi, [rel __gas_LC157]
    call DrawText wrt ..plt
    mov ecx, dword [rel 253256+game]
    xor eax, eax
    mov rdi, rbp
    lea rdx, [rel __gas_LC158]
    mov esi, 32
    call snprintf wrt ..plt
    cmp dword [rel 253256+game], 5
    jg __gas_L476
    mov esi, -1
    mov ecx, 50
    mov edx, 50
__gas_L470:
    movzx eax, sil
    sal edx, 16
    mov rdi, rbp
    mov esi, 970
    mov ah, cl
    mov ecx, 20
    lea rbp, [rsp+64]
    and eax, -16711681
    mov r8d, eax
    or r8d, edx
    mov edx, 40
    or r8d, -16777216
    call DrawText wrt ..plt
    mov ecx, dword [rel 253260+game]
    mov rdi, rbp
    xor eax, eax
    lea rdx, [rel __gas_LC159]
    mov esi, 32
    call snprintf wrt ..plt
    mov r8d, -16721921
    mov rdi, rbp
    mov ecx, 20
    mov edx, 40
    mov esi, 1110
    lea rbp, [rsp+96]
    call DrawText wrt ..plt
    mov ecx, dword [rel 253264+game]
    mov rdi, rbp
    xor eax, eax
    lea rdx, [rel __gas_LC160]
    mov esi, 32
    call snprintf wrt ..plt
    mov r8d, -39756
    mov ecx, 20
    mov rdi, rbp
    mov edx, 65
    mov esi, 1110
    call DrawText wrt ..plt
    cmp byte [rel 253284+game], 0
    je __gas_L471
    mov ecx, dword [rel 253268+game]
    mov esi, 64
    mov rdi, rbx
    xor eax, eax
    mov r8d, dword [rel 253276+game]
    lea rdx, [rel __gas_LC161]
    call snprintf wrt ..plt
__gas_L484:
    mov r8d, -2571
    mov ecx, 20
    mov edx, 95
    mov rdi, rbx
    mov esi, 970
    call DrawText wrt ..plt
    mov r8d, -12836061
    mov ecx, 125
    mov edx, 1280
    mov esi, 125
    mov edi, 960
    call DrawLine wrt ..plt
    call DrawHeroStatus
    mov r8d, -12836061
    mov ecx, 260
    mov edx, 1280
    mov esi, 260
    mov edi, 960
    call DrawLine wrt ..plt
    cmp dword [rel 253292+game], -1
    je __gas_L473
    call DrawTowerInspector
__gas_L462:
    add rsp, 216
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    ret
align 16
align 8
__gas_L476:
    mov esi, -11
    mov ecx, -11
    mov edx, 255
    jmp __gas_L470
align 16
align 8
__gas_L471:
    pxor xmm0, xmm0
    mov esi, 64
    mov rdi, rbx
    mov eax, 1
    lea rdx, [rel __gas_LC162]
    cvtss2sd xmm0, dword [rel 253272+game]
    call snprintf wrt ..plt
    jmp __gas_L484
align 16
align 8
__gas_L482:
    movss xmm0, dword [rel __gas_LC58]
    mov edi, ebp
    movss dword [rsp+28], xmm6
    movss dword [rsp+24], xmm1
    movss dword [rsp+16], xmm3
    movlps qword [rsp+8], xmm3
    call Fade wrt ..plt
    movq xmm3, qword [rsp+8]
    movss xmm1, dword [rsp+24]
    mov edi, eax
    movdqa xmm0, xmm3
    movss dword [rsp+8], xmm1
    call DrawCircleV wrt ..plt
    movss xmm2, dword [rsp+28]
    movss xmm4, dword [rsp+16]
    mov edx, ebp
    movss xmm1, dword [rsp+8]
    cvttss2si esi, xmm2
    cvttss2si edi, xmm4
    movaps xmm0, xmm1
    call DrawCircleLines wrt ..plt
    jmp __gas_L467
align 16
align 8
__gas_L485:
    movq xmm0, rbx
    call WorldToTile wrt ..plt
    movq rax, xmm0
    cvttss2si r12d, xmm0
    mov rbx, rax
    shr rbx, 32
    movd xmm7, ebx
    lea rbx, [rsp+128]
    cvttss2si r13d, xmm7
    mov edi, r12d
    mov esi, r13d
    call TileToWorldCenter wrt ..plt
    mov eax, dword [rel 253288+game]
    mov rdi, rbx
    movlps qword [rsp+16], xmm0
    movaps xmm7, xmm0
    movd r14d, xmm0
    pxor xmm0, xmm0
    movaps oword [rsp+128], xmm0
    shufps xmm7, xmm7, 0xe5
    movd r15d, xmm7
    mov dword [rsp+136], eax
    movaps oword [rsp+144], xmm0
    movaps oword [rsp+160], xmm0
    movaps oword [rsp+176], xmm0
    movaps oword [rsp+192], xmm0
    mov dword [rsp+140], 1
    call ConfigureTowerStats wrt ..plt
    mov esi, r13d
    mov edi, r12d
    movss xmm1, dword [rsp+156]
    movss dword [rsp+8], xmm1
    call IsTileBuildable wrt ..plt
    movss xmm1, dword [rsp+8]
    movq xmm3, qword [rsp+16]
    test al, al
    jne __gas_L475
    mov ecx, -26
    mov edx, 41
    mov eax, 55
__gas_L465:
    mov bpl, cl
    sal eax, 16
    movlps qword [rsp+8], xmm3
    movss xmm0, dword [rel __gas_LC28]
    mov ecx, ebp
    movss dword [rsp+16], xmm1
    mov ch, dl
    mov ebp, ecx
    and ebp, -16711681
    or ebp, eax
    mov edi, ebp
    call Fade wrt ..plt
    movd xmm0, r15d
    mov ecx, 40
    movss xmm2, dword [rel __gas_LC7]
    mov r8d, eax
    mov edx, 40
    subss xmm0, xmm2
    cvttss2si esi, xmm0
    movd xmm0, r14d
    subss xmm0, xmm2
    cvttss2si edi, xmm0
    call DrawRectangle wrt ..plt
    movq xmm3, qword [rsp+8]
    movss xmm1, dword [rsp+16]
    jmp __gas_L466
align 16
align 8
__gas_L473:
    call DrawBuildMenu
    jmp __gas_L462
align 16
align 8
__gas_L475:
    xor ecx, ecx
    mov edx, -28
    mov eax, 48
    jmp __gas_L465
section .rodata
__gas_LC164:
db 80, 82, 69, 83, 84, 73, 71, 69, 32, 69, 68, 73, 84, 73, 79, 78, 0
__gas_LC165:
db 67, 108, 105, 99, 107, 32, 111, 114, 32, 80, 114, 101, 115, 115, 32, 69, 78, 84, 69, 82, 32, 116, 111, 32, 83, 116, 97, 114, 116, 0
section .rodata
align 8
__gas_LC166:
db 67, 111, 110, 116, 114, 111, 108, 115, 58, 32, 87, 65, 83, 68, 32, 40, 77, 111, 118, 101, 41, 44, 32, 81, 32, 40, 68, 97, 115, 104, 41, 44, 32, 69, 32, 40, 66, 117, 114, 115, 116, 41, 44, 32, 83, 112, 97, 99, 101, 32, 40, 65, 116, 116, 97, 99, 107, 41, 44, 32, 49, 45, 52, 47, 67, 108, 105, 99, 107, 32, 40, 66, 117, 105, 108, 100, 41, 44, 32, 78, 32, 40, 78, 101, 120, 116, 32, 87, 97, 118, 101, 41, 44, 32, 71, 32, 40, 71, 114, 105, 100, 41, 0
section .rodata
__gas_LC168:
db 80, 65, 85, 83, 69, 68, 32, 40, 80, 114, 101, 115, 115, 32, 80, 41, 0
section .rodata
align 8
__gas_LC170:
db 83, 101, 108, 101, 99, 116, 32, 97, 32, 83, 107, 105, 108, 108, 32, 40, 83, 107, 105, 108, 108, 32, 80, 111, 105, 110, 116, 115, 58, 32, 37, 100, 41, 0
section .rodata
__gas_LC171:
db 72, 69, 82, 79, 32, 76, 69, 86, 69, 76, 32, 85, 80, 33, 0
__gas_LC172:
db 86, 105, 103, 111, 114, 32, 40, 65, 116, 116, 97, 99, 107, 43, 41, 0
__gas_LC173:
db 65, 103, 105, 108, 105, 116, 121, 32, 40, 83, 112, 101, 101, 100, 47, 68, 97, 115, 104, 32, 67, 68, 41, 0
__gas_LC174:
db 66, 117, 114, 115, 116, 32, 77, 97, 115, 116, 101, 114, 121, 32, 40, 65, 111, 69, 43, 41, 0
__gas_LC175:
db 76, 101, 97, 100, 101, 114, 115, 104, 105, 112, 32, 40, 84, 111, 119, 101, 114, 32, 88, 80, 32, 65, 117, 114, 97, 41, 0
section .rodata
align 8
__gas_LC176:
db 73, 110, 99, 114, 101, 97, 115, 101, 115, 32, 98, 97, 115, 105, 99, 32, 97, 116, 116, 97, 99, 107, 32, 100, 97, 109, 97, 103, 101, 46, 0
align 8
__gas_LC177:
db 73, 110, 99, 114, 101, 97, 115, 101, 115, 32, 109, 111, 118, 101, 109, 101, 110, 116, 32, 115, 112, 101, 101, 100, 32, 97, 110, 100, 32, 114, 101, 100, 117, 99, 101, 115, 32, 68, 97, 115, 104, 32, 99, 111, 111, 108, 100, 111, 119, 110, 46, 0
align 8
__gas_LC178:
db 73, 110, 99, 114, 101, 97, 115, 101, 115, 32, 65, 101, 116, 104, 101, 114, 32, 66, 117, 114, 115, 116, 32, 100, 97, 109, 97, 103, 101, 32, 97, 110, 100, 32, 114, 97, 100, 105, 117, 115, 46, 0
align 8
__gas_LC179:
db 84, 111, 119, 101, 114, 115, 32, 110, 101, 97, 114, 32, 116, 104, 101, 32, 104, 101, 114, 111, 32, 103, 97, 105, 110, 32, 98, 111, 110, 117, 115, 32, 88, 80, 46, 0
section .rodata
__gas_LC180:
db 37, 115, 32, 40, 76, 101, 118, 101, 108, 32, 37, 100, 41, 0
__gas_LC182:
db 71, 65, 77, 69, 32, 79, 86, 69, 82, 0
__gas_LC183:
db 89, 111, 117, 32, 115, 117, 114, 118, 105, 118, 101, 100, 32, 37, 100, 32, 119, 97, 118, 101, 115, 46, 0
__gas_LC184:
db 80, 114, 101, 115, 115, 32, 82, 32, 116, 111, 32, 82, 101, 115, 116, 97, 114, 116, 0
section .text
align 16
global DrawGame
DrawGame:
    push r15
    push r14
    push r13
    push r12
    push rbp
    push rbx
    sub rsp, 312
    call BeginDrawing wrt ..plt
    mov edi, -15463926
    call ClearBackground wrt ..plt
    mov eax, dword [rel game]
    test eax, eax
    jne __gas_L487
    lea rbx, [rel __gas_LC157]
    mov esi, 60
    lea rbp, [rel __gas_LC165]
    mov rdi, rbx
    call MeasureText wrt ..plt
    mov r8d, -9216
    mov ecx, 60
    mov rdi, rbx
    mov edx, eax
    lea rbx, [rel __gas_LC164]
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 236
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    mov rdi, rbx
    mov esi, 40
    call MeasureText wrt ..plt
    mov r8d, -39756
    mov ecx, 40
    mov rdi, rbx
    mov edx, eax
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 306
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    movss xmm0, dword [rel 253304+game]
    addss xmm0, xmm0
    call sinf wrt ..plt
    addss xmm0, dword [rel __gas_LC14]
    mov edi, -2571
    mulss xmm0, dword [rel __gas_LC28]
    call Fade wrt ..plt
    mov esi, 30
    mov rdi, rbp
    mov ebx, eax
    call MeasureText wrt ..plt
    mov r8d, ebx
    mov ecx, 30
    mov rdi, rbp
    mov edx, eax
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 400
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    mov r8d, -4942186
    mov ecx, 18
    mov edx, 770
    mov esi, 20
    lea rdi, [rel __gas_LC166]
    call DrawText wrt ..plt
__gas_L488:
    add rsp, 312
    pop rbx
    pop rbp
    pop r12
    pop r13
    pop r14
    pop r15
    jmp EndDrawing wrt ..plt
align 16
align 8
__gas_L487:
    mov rax, qword [rel 2448+game]
    movdqu xmm0, oword [rel 2432+game]
    sub rsp, 32
    mov qword [rsp+16], rax
    movups oword [rsp], xmm0
    call BeginMode2D wrt ..plt
    add rsp, 32
    call DrawMap
    call DrawEnemies
    call DrawTowers
    call DrawHero
    call DrawProjectiles
    call DrawVFX
    call EndMode2D wrt ..plt
    call DrawUI
    mov eax, dword [rel game]
    cmp eax, 2
    je __gas_L508
    cmp eax, 4
    je __gas_L509
__gas_L490:
    cmp eax, 3
    je __gas_L510
__gas_L496:
    cmp byte [rel 253312+game], 0
    je __gas_L488
__gas_L511:
    call DrawTooltip.part.0
    jmp __gas_L488
align 16
align 8
__gas_L508:
    movss xmm0, dword [rel __gas_LC167]
    mov edi, -16777216
    lea rbx, [rel __gas_LC168]
    call Fade wrt ..plt
    mov ecx, 800
    xor esi, esi
    xor edi, edi
    mov r8d, eax
    mov edx, 1280
    call DrawRectangle wrt ..plt
    mov esi, 40
    mov rdi, rbx
    call MeasureText wrt ..plt
    mov r8d, -1
    mov ecx, 40
    mov rdi, rbx
    mov edx, eax
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 380
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    mov eax, dword [rel game]
    cmp eax, 4
    jne __gas_L490
__gas_L509:
    movss xmm0, dword [rel __gas_LC169]
    mov edi, -15463926
    mov rbx, 4848124999998898176
    call Fade wrt ..plt
    mov ecx, 800
    xor esi, esi
    xor edi, edi
    mov r8d, eax
    mov edx, 1280
    call DrawRectangle wrt ..plt
    movq xmm0, rbx
    mov esi, -14478316
    mov rax, 4884153797026250752
    movss xmm2, dword [rel __gas_LC46]
    movq xmm1, rax
    mov edi, 16
    mov rbp, rax
    call DrawRectangleRounded wrt ..plt
    movq xmm0, rbx
    movq xmm1, rbp
    movss xmm2, dword [rel __gas_LC46]
    mov esi, -39756
    mov edi, 16
    lea rbx, [rsp+112]
    call DrawRectangleRoundedLines wrt ..plt
    mov esi, -39756
    mov rax, 4848406474975641600
    movss xmm2, dword [rel __gas_LC46]
    movq xmm0, rax
    mov edi, 16
    mov rax, 4883872322049507328
    movq xmm1, rax
    lea rbp, [rel game]
    call DrawRectangleRoundedLines wrt ..plt
    mov ecx, dword [rel 2348+game]
    mov rdi, rbx
    xor eax, eax
    lea rdx, [rel __gas_LC170]
    mov esi, 64
    call snprintf wrt ..plt
    mov r8d, -39756
    mov ecx, 30
    mov edx, 220
    mov esi, 340
    lea rdi, [rel __gas_LC171]
    call DrawText wrt ..plt
    mov rdi, rbx
    mov r8d, -2571
    mov ecx, 20
    mov edx, 260
    mov esi, 340
    xor ebx, ebx
    call DrawText wrt ..plt
    lea rax, [rel __gas_LC173]
    movq xmm0, qword [rel __gas_LC185]
    movq xmm4, rax
    lea rax, [rel __gas_LC175]
    punpcklqdq xmm0, xmm4
    movq xmm5, rax
    lea rax, [rel __gas_LC177]
    movaps oword [rsp+48], xmm0
    movq xmm6, rax
    movq xmm0, qword [rel __gas_LC186]
    lea rax, [rel __gas_LC179]
    movq xmm7, rax
    lea rax, [rsp+48]
    punpcklqdq xmm0, xmm5
    mov qword [rsp+32], rax
    lea rax, [rsp+176]
    movaps oword [rsp+64], xmm0
    movq xmm0, qword [rel __gas_LC187]
    mov qword [rsp+8], rax
    lea rax, [rsp+80]
    punpcklqdq xmm0, xmm6
    mov qword [rsp+40], rax
    movaps oword [rsp+80], xmm0
    movq xmm0, qword [rel __gas_LC188]
    punpcklqdq xmm0, xmm7
    movaps oword [rsp+96], xmm0
__gas_L495:
    mov eax, ebx
    pxor xmm0, xmm0
    mov rdi, qword [rsp+8]
    mov esi, 128
    sal eax, 6
    mov r8d, dword [rbp+2416]
    lea rdx, [rel __gas_LC180]
    mov r13, 4776067405968703488
    add eax, ebx
    cvtsi2ss xmm0, eax
    mov rax, qword [rsp+32]
    addss xmm0, dword [rel __gas_LC69]
    mov rax, qword [rax+rbx*8]
    movss dword [rsp+4], xmm0
    mov rcx, rax
    mov qword [rsp+16], rax
    xor eax, eax
    call snprintf wrt ..plt
    mov rax, r12
    mov edx, dword [rsp+4]
    xor esi, esi
    mov rcx, -4294967296
    mov rdi, qword [rsp+8]
    movq xmm1, r13
    and rax, rcx
    sal rdx, 32
    or rax, 1135214592
    mov eax, eax
    or rax, rdx
    mov edx, 1
    movq xmm0, rax
    mov r12, rax
    call GuiButton
    test al, al
    je __gas_L491
    mov eax, dword [rel 2348+game]
    test eax, eax
    jle __gas_L491
    add dword [rbp+2416], 1
    sub eax, 1
    mov dword [rel 2348+game], eax
    call ApplyHeroSkills wrt ..plt
__gas_L491:
    mov r15, 4776067405968703488
    mov rax, qword [rsp+40]
    mov rax, qword [rax+rbx*8]
    mov qword [rsp+24], rax
    call GetMousePosition wrt ..plt
    mov rax, r14
    mov edx, dword [rsp+4]
    mov rcx, -4294967296
    and rax, rcx
    movq xmm2, r15
    or rax, 1135214592
    sal rdx, 32
    mov eax, eax
    or rax, rdx
    movq xmm1, rax
    mov r14, rax
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L492
    movq xmm0, qword [rsp+16]
    movss xmm3, dword [rsp+4]
    add rbx, 1
    mov dword [rel 253336+game], 0x43aa0000
    mov qword [rel 253344+game], r15
    movhps xmm0, qword [rsp+24]
    mov byte [rel 253312+game], 1
    movups oword [rel 253320+game], xmm0
    movss dword [rel 253340+game], xmm3
    cmp rbx, 4
    je __gas_L493
__gas_L507:
    add rbp, 4
    jmp __gas_L495
align 16
align 8
__gas_L510:
    movss xmm0, dword [rel __gas_LC35]
    mov edi, -13487361
    lea rbx, [rel __gas_LC182]
    call Fade wrt ..plt
    mov ecx, 800
    xor esi, esi
    xor edi, edi
    mov r8d, eax
    mov edx, 1280
    call DrawRectangle wrt ..plt
    mov rdi, rbx
    mov esi, 60
    call MeasureText wrt ..plt
    mov r8d, -1
    mov rdi, rbx
    mov ecx, 60
    mov edx, eax
    lea rbx, [rsp+176]
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 350
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    mov ecx, dword [rel 253268+game]
    mov rdi, rbx
    xor eax, eax
    lea rdx, [rel __gas_LC183]
    mov esi, 64
    call snprintf wrt ..plt
    mov rdi, rbx
    mov esi, 30
    call MeasureText wrt ..plt
    mov r8d, -1
    mov ecx, 30
    mov rdi, rbx
    mov edx, eax
    lea rbx, [rel __gas_LC184]
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 420
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    mov esi, 20
    mov rdi, rbx
    call MeasureText wrt ..plt
    mov r8d, -1
    mov ecx, 20
    mov rdi, rbx
    mov edx, eax
    shr edx, 31
    lea esi, [rdx+rax]
    mov edx, 460
    sar esi, 1
    neg esi
    add esi, 640
    call DrawText wrt ..plt
    cmp byte [rel 253312+game], 0
    je __gas_L488
    jmp __gas_L511
align 16
align 8
__gas_L492:
    add rbx, 1
    cmp rbx, 4
    jne __gas_L507
__gas_L493:
    mov eax, dword [rel game]
    cmp eax, 3
    jne __gas_L496
    jmp __gas_L510
align 16
global SetTooltip
SetTooltip:
    push rbp
    mov rbp, rdi
    push rbx
    mov rbx, rsi
    sub rsp, 24
    movq qword [rsp+8], xmm1
    movq qword [rsp], xmm0
    call GetMousePosition wrt ..plt
    movq xmm1, qword [rsp]
    movq xmm2, qword [rsp+8]
    call CheckCollisionPointRec wrt ..plt
    test al, al
    je __gas_L512
    mov rax, qword [rsp]
    mov qword [rel 253320+game], rbp
    mov qword [rel 253328+game], rbx
    mov qword [rel 253336+game], rax
    mov rax, qword [rsp+8]
    mov byte [rel 253312+game], 1
    mov qword [rel 253344+game], rax
__gas_L512:
    add rsp, 24
    pop rbx
    pop rbp
    ret
section .rodata
align 32
CSWTCH.94:
dd 1090519040
dd 1082130432
dd 1084227584
dd 1082130432
dd 1086324736
dd 1094713344
dd 1082130432
dd 1082130432
dd 1082130432
dd 1084227584
__gas_LC0 equ __gas_LC5
section .rodata
align 4
__gas_LC1:
dd 1036831949
__gas_LC2 equ __gas_LC5
align 4
__gas_LC3:
dd 1053609165
align 4
__gas_LC4:
dd 1073741824
section .rodata
align 16
__gas_LC5:
dd 1109393408
dd 1109393408
dd 0
dd 0
section .rodata
align 4
__gas_LC6:
dd 1097859072
__gas_LC7 equ __gas_LC74+12
align 4
__gas_LC8:
dd 1103626240
align 4
__gas_LC9:
dd 1106247680
align 4
__gas_LC10:
dd 1151336448
align 4
__gas_LC11:
dd 1084227584
align 4
__gas_LC12:
dd 1145569280
align 4
__gas_LC13:
dd 1063675494
__gas_LC14 equ __gas_LC64
align 4
__gas_LC15:
dd 1092616192
align 4
__gas_LC16:
dd 1258291200
section .rodata
align 16
__gas_LC17:
dd 2147483647
dd 0
dd 0
dd 0
__gas_LC19 equ __gas_LC17
align 16
__gas_LC20:
dd -2147483648
dd 0
dd 0
dd 0
__gas_LC21 equ __gas_LC50+4
section .rodata
align 4
__gas_LC22:
dd 1099956224
align 4
__gas_LC23:
dd 1096810496
align 4
__gas_LC24:
dd 1090519040
__gas_LC25 equ __gas_LC50
align 4
__gas_LC26:
dd 1114636288
align 4
__gas_LC27:
dd 1061997773
align 4
__gas_LC28:
dd 1056964608
align 4
__gas_LC29:
dd 1077936128
align 4
__gas_LC32:
dd 1098907648
align 4
__gas_LC33:
dd 1120403456
align 4
__gas_LC34:
dd 1110704128
align 4
__gas_LC35:
dd 1050253722
align 4
__gas_LC36:
dd 1058642330
section .rodata
align 16
__gas_LC37:
dd -1046478848
dd -1043857408
dd 0
dd 0
section .rodata
align 4
__gas_LC39:
dd 1086324736
__gas_LC40 equ __gas_LC55
align 4
__gas_LC41:
dd -1088841318
__gas_LC42 equ __gas_LC49
align 4
__gas_LC43:
dd 1113927392
align 4
__gas_LC44:
dd 1127481344
align 4
__gas_LC45:
dd 1135869952
align 4
__gas_LC46:
dd 1028443341
align 4
__gas_LC47:
dd 1016003125
section .rodata
align 8
__gas_LC49:
dd 1082130432
dd 1082130432
align 8
__gas_LC50:
dd 1105199104
dd 1094713344
section .rodata
align 16
__gas_LC54:
dd -1046478848
dd -1046478848
dd 0
dd 0
align 16
__gas_LC55:
dd 1102053376
dd 1102053376
dd 0
dd 0
section .rodata
align 4
__gas_LC58:
dd 1041865114
align 4
__gas_LC59:
dd 1125515264
section .rodata
align 16
__gas_LC62:
dd -1054867456
dd -1056964608
dd 0
dd 0
align 16
__gas_LC64:
dd 1065353216
dd 1065353216
dd 0
dd 0
__gas_LC69 equ __gas_LC151+8
__gas_LC71 equ __gas_LC74+8
align 16
__gas_LC74:
dd 1148354560
dd 1130758144
dd 1125187584
dd 1101004800
align 16
__gas_LC78:
dd 1150066688
dd 1130758144
dd 1125187584
dd 1101004800
section .data.rel.ro.local alloc noexec write progbits align=8
align 8
__gas_LC79:
dq __gas_LC76
section .rodata
align 4
__gas_LC106:
dd -1093874483
align 4
__gas_LC107:
dd 1045220557
align 4
__gas_LC109:
dd 1091567616
section .rodata
align 16
__gas_LC110:
dd -1073741824
dd -1073741824
dd 0
dd 0
section .rodata
align 4
__gas_LC117:
dd 1142784000
align 4
__gas_LC139:
dd 1159725056
section .rodata
align 16
__gas_LC151:
dd 1148354560
dd 1144750080
dd 1133903872
dd 1109393408
section .data.rel.ro.local alloc noexec write progbits align=8
align 8
__gas_LC152:
dq __gas_LC146
align 8
__gas_LC153:
dq __gas_LC149
section .rodata
align 4
__gas_LC154:
dd 1148190720
align 4
__gas_LC155:
dd 1112014848
align 4
__gas_LC167:
dd 1060320051
align 4
__gas_LC169:
dd 1062836634
section .data.rel.ro.local alloc noexec write progbits align=8
align 8
__gas_LC185:
dq __gas_LC172
align 8
__gas_LC186:
dq __gas_LC174
align 8
__gas_LC187:
dq __gas_LC176
align 8
__gas_LC188:
dq __gas_LC178
section .note.GNU-stack noalloc noexec nowrite progbits
