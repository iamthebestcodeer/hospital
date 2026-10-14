; The single compatibility state object shared with the original C ABI.
bits 64
%include "src/include/abi.inc"
section .bss align=32
global game
game: resb G_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
