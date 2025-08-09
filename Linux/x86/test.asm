.include "matrix.asm"

.section .data
arr:
.long 2, 2, 5, 1, 2, 4

.section .text
.global _start
_start:

mov $arr, %eax
push %eax
call determinant
add $4, %esp

mov %eax, %ebx
mov $1, %eax
int $0x80

