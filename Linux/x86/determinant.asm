# Matrix Assembly Library - Matrix operations library fully written in assembly
# Copyright (C) 2025  Chaturya Reddy (@Csral) <chaturyasral@gmail.com>
# 
# This project is licensed under the GNU Lesser General Public License v3.0 (LGPL-3.0).
# You should have received a copy of the GNU Lesser General Public License along
# with this program in the files COPYING and COPYING.LESSER. If not, see
# <https://www.gnu.org/licenses/>.
#
# ----------------- Determinant of a 2*2 matrix.

# Returns value in eax register
# Expects a pointer (reference) to the matrix
# Expect all registers to be over-written. Saving is the caller's job
# Restoring stack (removal of arguments) is also the caller's job

.type determinant,@function
determinant:

    # Store stack

    push %ebp
    mov %esp, %ebp

    # Allocate and store rows and columns
    sub $8, %esp

    mov 8(%ebp), %ebx
    mov (%ebx), %ecx
    mov %ecx, -4(%ebp)
    mov $1, %edi
    mov (%ebx, %edi, 4), %ecx
    mov %ecx, -8(%ebp)

    # While rows != 2 and columns != 2 -> Get sub matrix and its determinant
    # Support only 2x2 for num_rows

    mov -4(%ebp), %eax
    cmp $2, %eax
    jne _err_not_supported

    xor -8(%ebp), %eax
    cmp $0, %eax
    jne _err_not_supported

    # product of <1,1> <2,2> and <1,2> <2,1> sub them

    mov $2, %edi
    mov (%ebx, %edi, 4), %eax # <1,1>
    mov $5, %edi
    mov (%ebx, %edi, 4), %ecx # <2,2>

    # ecx * eax value is stored in eax register -> ecx is free!
    imul %ecx, %eax

    mov $3, %edi
    mov (%ebx, %edi, 4), %ecx # <1,2>
    mov $4, %edi
    mov (%ebx, %edi, 4), %edx # <2,1>

    # Thus, we use ecx again
    imul %edx, %ecx

    # Perform determinant
    sub %ecx, %eax

    mov %ebp, %esp
    pop %ebp
    ret

_err_not_supported:
    mov $1, %eax
    mov %ebp, %esp
    pop %ebp
    ret
