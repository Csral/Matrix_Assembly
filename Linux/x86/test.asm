.include "matrix.asm"

.section .data
arr:
.long 2, 2, 5, 1, 2, 4
arrB:
.long 2, 2, 1, 0, 0, 1
arrAns:
.long 2, 2, 0, 0, 0, 0

.section .text
.global _start
_start:

mov $arr, %eax                                          # Move arr to eax
push %eax                                               # push into stack
call determinant                                        # Call determinant function
add $4, %esp                                            # Restore stack

#mov %eax, %ebx                                         # Exit now to check determinant
#mov $1, %eax
#int $0x80

# Prepare and push arguments in reverse order for multiplication

mov $arrAns, %eax                                       # Move matrix ans into eax
push %eax                                               # push into stack

mov $arrB, %eax                                         # Move 2nd matrix to eax
push %eax                                               # push into stack

mov $arr, %eax                                          # Move 1st matrix to eax
push %eax                                               # push into stack

call multiplication                                     # Call the multiplication function -> eax has ans
push %eax                                               # push matrix ans into stack

call determinant                                        # Since 2nd matrix is I, product should be same as first matrix.
mov %eax, %ebx                                          # And so should the determinant.

mov $1, %eax
int $0x80                                               # exit and confirm
