; NASM x86-64, System V ABI. See tools/generate.py.
bits 64
default rel
extern game
extern powf
; Handwritten SSE2 visual-effects update. Same operations and libm calls;
; packed XY math reduces scalar instructions, and empty blocks skip 8 slots.
%include "src/include/layout.inc"
section .rodata
align 4
__gas_Lthree:
dd 0x40400000
__gas_Lsixty:
dd 0x42700000
__gas_Ltwohundred:
dd 0x43480000
__gas_Ldtmax:
dd 0x3dcccccd
__gas_Lgravitybase:
dd 0x3f7d70a4
__gas_Lnormalbase:
dd 0x3f733333
section .text
global UpdateVFX
UpdateVFX:
    sub rsp,24
    movss dword [rsp],xmm0
    movaps xmm2,xmm0
    movaps xmm5,xmm0
    mulss xmm5,dword [rel __gas_Lthree]
    pxor xmm4,xmm4
    lea rax,[rel GAME_TEXTS+game]
    lea rdx,[rax+TEXT_SIZE*100]
__gas_Ltext:
    cmp byte [rax+FT_ACTIVE],0
    je __gas_Ltext_next
    movss xmm1,dword [rax+FT_VY]
    movaps xmm3,xmm1
    mulss xmm3,xmm2
    addss xmm3,dword [rax+FT_Y]
    movss dword [rax+FT_Y],xmm3
    movaps xmm3,xmm4
    subss xmm3,xmm1
    mulss xmm3,xmm5
    addss xmm1,xmm3
    movss dword [rax+FT_VY],xmm1
    movss xmm1,dword [rax+FT_LIFE]
    subss xmm1,xmm2
    movss dword [rax+FT_LIFE],xmm1
    comiss xmm4,xmm1
    jb __gas_Ltext_next
    mov byte [rax+FT_ACTIVE],0
__gas_Ltext_next:
    add rax,TEXT_SIZE
    cmp rax,rdx
    jne __gas_Ltext
; Clamp(dt,0,.1), including the original unordered comparison behavior.
    movaps xmm3,xmm2
    pxor xmm0,xmm0
    pxor xmm1,xmm1
    cmpnltss xmm3,xmm0
    movaps xmm0,xmm2
    andps xmm0,xmm3
    andnps xmm3,xmm1
    movss xmm1,dword [rel __gas_Ldtmax]
    orps xmm3,xmm0
    movaps xmm0,xmm1
    movaps xmm4,xmm1
    cmpltss xmm0,xmm3
    andps xmm4,xmm0
    andnps xmm0,xmm3
    movaps xmm1,xmm0
    movss xmm0,dword [rel __gas_Lgravitybase]
    orps xmm1,xmm4
    mulss xmm1,dword [rel __gas_Lsixty]
    movss dword [rsp+4],xmm1
    call powf wrt ..plt
    movss dword [rsp+8],xmm0
    movss xmm0,dword [rel __gas_Lnormalbase]
    movss xmm1,dword [rsp+4]
    call powf wrt ..plt
    shufps xmm0,xmm0,0
    movss xmm6,dword [rsp+8]
    shufps xmm6,xmm6,0
    movss xmm2,dword [rsp]
    movaps xmm5,xmm2
    mulss xmm5,dword [rel __gas_Ltwohundred]
    shufps xmm2,xmm2,0
    lea rax,[rel GAME_PARTICLES+game]
    lea rdx,[rax+PARTICLE_COUNT*PARTICLE_SIZE]
__gas_Lblock:
    movzx ecx,byte [rax+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*2+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*3+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*4+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*5+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*6+P_ACTIVE]
    or cl,byte [rax+PARTICLE_SIZE*7+P_ACTIVE]
    lea r8,[rax+PARTICLE_SIZE*8]
    test cl,cl
    jnz __gas_Lparticle
    mov rax,r8
    jmp __gas_Lblock_end
__gas_Lparticle:
    cmp byte [rax+P_ACTIVE],0
    je __gas_Lparticle_next
    movss xmm1,dword [rax+P_LIFE]
    addss xmm1,xmm2
    movss dword [rax+P_LIFE],xmm1
    comiss xmm1,dword [rax+P_MAX_LIFE]
    jae __gas_Lexpire
    cmp byte [rax+P_GRAVITY],0
    movaps xmm4,xmm0
    je __gas_Lmove
    movss xmm1,dword [rax+P_VELOCITY+4]
    addss xmm1,xmm5
    movss dword [rax+P_VELOCITY+4],xmm1
    movaps xmm4,xmm6
__gas_Lmove:
    movq xmm1,qword [rax+P_VELOCITY]
    movaps xmm3,xmm1
    mulps xmm3,xmm2
    movq xmm7,qword [rax+P_POSITION]
    addps xmm3,xmm7
    movlps qword [rax+P_POSITION],xmm3
    mulps xmm1,xmm4
    movlps qword [rax+P_VELOCITY],xmm1
    jmp __gas_Lparticle_next
__gas_Lexpire:
    mov byte [rax+P_ACTIVE],0
__gas_Lparticle_next:
    add rax,PARTICLE_SIZE
    cmp rax,r8
    jne __gas_Lparticle
__gas_Lblock_end:
    cmp rax,rdx
    jb __gas_Lblock
    add rsp,24
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
