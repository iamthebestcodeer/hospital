; System V AMD64 stack frames and SSE2 vector operations.
%ifndef AETHERIUM_CALLING_CONVENTION
%define AETHERIUM_CALLING_CONVENTION
; Keep the stack 16-byte aligned before calls, with named scratch space.
%macro FRAME 1
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, %1+8
%endmacro
%macro RETURN 1
    add rsp, %1+8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
%endmacro
%macro FLOAT 2
    mov %1, __float32__(%2)
%endmacro
%macro CLAMP 3
    ucomiss %1, [%2]
    jp %%done
    jae %%upper
    movss %1, [%2]
%%upper:
    ucomiss %1, [%3]
    jbe %%done
    movss %1, [%3]
%%done:
%endmacro
; Input: packed XY in xmm0. Output: scalar length in xmm1; xmm2 is scratch.
%macro LENGTH 0
    movaps xmm1, xmm0
    mulps xmm1, xmm1
    movaps xmm2, xmm1
    shufps xmm2, xmm2, 0x55
    addss xmm1, xmm2
    sqrtss xmm1, xmm1
%endmacro
%macro NORMALIZE 0
    LENGTH
    movss xmm2, [fp_one]
    divss xmm2, xmm1
    shufps xmm2, xmm2, 0
    mulps xmm0, xmm2
%endmacro

%endif
