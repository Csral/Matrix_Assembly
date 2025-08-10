# Matrix Assembly Library - Matrix operations library fully written in assembly
# Copyright (C) 2025  Chaturya Reddy (@Csral) <chaturyasral@gmail.com>
# 
# This project is licensed under the GNU Lesser General Public License v3.0 (LGPL-3.0).
# You should have received a copy of the GNU Lesser General Public License along
# with this program in the files COPYING and COPYING.LESSER. If not, see
# <https://www.gnu.org/licenses/>.
#
# ------------------------ Multiplication
# *** Function signature:
#                           multiplication(Matrix* A, Matrix* B, Matrix* ans)
#
#   Following GNU-C (cdecl) calling convention on x86 (32-bit)
#   -> Expected parameters are pushed on the stack in reverse order
#   -> Caller-saved registers (eax, ecx, edx) will be overwritten by the callee.
#   -> Callee must preserve callee-saved registers (ebx, esi, edi, ebp).
#   -> Restoring stack (popping arguments) is caller's job
#   -> Return value will be given in eax register
#   -> Return value is the base memory address for an array
#
# Expected parameter(s): A reference to the both the matrices, i.e., base memory address of matrix A and B.
# Push matrix B followed by matrix A
# This function returns a new matrix which is the product of A and B.
# Register ecx will have error code.
#   
#   Stack:
#       Matrix ans -> ebp + 28
#       Matrix B -> ebp + 24
#       Matrix A -> ebp + 20
#       Return Address
#       Callee saved registers
#
# *** Register architecture:
# For all cross verification etc, we use ebx, ecx and edi registers.
#
# For loop bodies:
#   edi -> loop index value.
#
# *** Local variables required:
#
#   Size of 1st matrix -> r,c
#   Columns of 2nd matrix -> s
#   outermost loop index to be held -> i
#   middle loop index to be held -> k
#   innermost loop index to be held -> j
#
#   r = ebp -4
#   c = ebp - 8
#   s = ebp - 12
#   i = ebp - 16
#   k = ebp - 20
#   j = ebp - 24
#   matrix ans = ebp - 28
#       
#       Matrix ans would be of size: (r*s)
#
# for i in range(num_rows_of_1st_matrix)
#     for k in range(num_columns_of_1st_matrix)
#         for j in range(num_columns_of_2nd_matrix)
#               print(f"<{i+1},{j+1}> = ({i+1},{k+1}) * [{k+1},{j+1}]")

# Allocate required space and fill the matrix.
# Check:
# >>> for r in range(3):
# ...     for c in range(3):
# ...         print(f"({r+1},{c+1}) -> {4*c + (4 * 3 * r)}")
# ...
# (1,1) -> 0
# (1,2) -> 4
# (1,3) -> 8
# (2,1) -> 12
# (2,2) -> 16
# (2,3) -> 20
# (3,1) -> 24
# (3,2) -> 28
# (3,3) -> 32
# ******* element (i,j) of a matrix where each element consumes 'size' bytes with 'nc' columns is: 
#  
#                                           size * (j + (nc * i))
#
# When we calculate the elemental offset, we must add 8 bytes as the first 2 long integers (8 bytes) of every matrix
# should contain their row, column information. This doesn't depend on datatype and is always 8.
#
# -----------------------------------
# There are labels ending with __RETURN__ in this function used to return control
# from a lower-level loop back to a higher-level loop.
#
# When a lower-level loop finishes, it needs to jump back to a higher-level loop
# to either terminate or continue further cycles.
#
# Thus, the inner loop needs to transfer its instruction pointer to the address of first byte under these "__RETURN__" labels
# (Simply to say, perform an unconditional jump).
#
# A separate label is required because the main label should not update the looping variable
# until the inner loop is completed.
# -----------------------------------

.type multiplication, @function
multiplication:

    # Store stack

    push %ebx
    push %esi
    push %edi
    push %ebp
    mov %esp, %ebp

    # Space to store size of matrices and loop index variables
    sub $28, %esp

    mov 20(%ebp), %ebx                      #1st matrix
    mov (%ebx), %ecx                        # num rows of 1st matrix
    mov %ecx, -4(%ebp)                      # r

    mov $1, %edi                            # 1st index of matrix A
    mov (%ebx, %edi, 4), %ecx               # num columns of 1st matrix
    mov %ecx, -8(%ebp)                      # c

    mov 24(%ebp), %ebx                      #2nd matrix
    mov (%ebx, %edi, 4), %ecx               # num columns of 2nd matrix
    mov %ecx, -12(%ebp)                     # s

    mov (%ebx), %ecx                        # num rows of 2nd matrix
    mov -8(%ebp), %ebx                      # num of columns of 1st matrix

    cmp %ebx, %ecx                          # if columns of matrix A != rows of matrix B
    jne _cannot_multiply_matrix             # then exit

    mov 28(%ebp), %ecx                      # Move matrix ans into ecx
    mov %ecx, -28(%ebp)                     # Store matrix ans into its expected location

    #* We are not saving the rows of 2nd matrix because this must be same as column size of 1st matrix.
    # Set all loop variables to 0.

    xor %ecx, %ecx                          # quick zero ecx
    mov %ecx, -16(%ebp)                     # i
    mov %ecx, -20(%ebp)                     # k
    mov %ecx, -24(%ebp)                     # j

    jmp _MATRIX_LIB_loop_internal_1st_matrix_rows       # unconditionally jump and start the loop

_MATRIX_LIB_loop_internal_1st_matrix_rows:

    #* The outermost loop. Loops for every row within 1st matrix!
    # Loop variable: i
    # Load variable: i, r
    # if i == r then matrix multiplication must have ended. Return the answer
    # else go into the middle loop
    #
    # Register architecture:
    #   i -> edi
    #   r -> edx

    mov -16(%ebp), %edi     # load loop variable -> i
    mov -4(%ebp), %edx      # r

    cmp %edx, %edi                                  # if i == r
    je _MATRIX_LIB_internal_end_loop_and_return     # matrix multiplication must have ended.

    # Go to middle loop.
    jmp _MATRIX_LIB_loop_internal_1st_matrix_columns

    _MATRIX_LIB_loop_internal_1st_matrix_rows_RETURN__:

        # The middle loop has ended.
        # Update looping conditions (outer loop) and jump back (unconditionally)
        # The label checks if the looping has ended as a whole

        mov -16(%ebp), %edi                                 # load loop variable
        inc %edi                                            # update looping variable
        mov %edi, -16(%ebp)                                 # Store back the looping variable

        jmp _MATRIX_LIB_loop_internal_1st_matrix_rows       # unconditionally jump back to outer loop.

_MATRIX_LIB_loop_internal_1st_matrix_columns:
    
    #* The middle loop. Loops for every column within 1st matrix!
    # Loop variable: k
    # Load variable: k, c
    # if k < c then go into inner loop
    # else go to outer loop
    # Register architecture:
    #   k -> edi
    #   c -> edx

    mov -20(%ebp), %edi                                         # load loop variable -> k
    mov -8(%ebp), %edx                                          # c

    cmp %edx, %edi                                              # if k < c
    jl _MATRIX_LIB_loop_internal_2nd_matrix_columns             # then go into the inner loop

    # if not, then middle loop has fulfilled its purpose!
    # reset the loop variable
    # unconditionally jump to outer loop.

    mov -20(%ebp), %edi                                         # load k
    xor %edi, %edi                                              # k = 0
    mov %edi, -20(%ebp)                                         # store back the variable

    jmp _MATRIX_LIB_loop_internal_1st_matrix_rows_RETURN__      # unconditionally jump to outer loop

    _MATRIX_LIB_loop_internal_1st_matrix_columns_RETURN__:

        # The inner loop has ended.
        # Update looping conditions (middle loop) and jump back (unconditionally)
        # As the label checks if the loop is completed or not.

        mov -20(%ebp), %edi                                     # load the looping variable
        inc %edi                                                # increase the looping variable
        mov %edi, -20(%ebp)                                     # store back the looping variable

        jmp _MATRIX_LIB_loop_internal_1st_matrix_columns        # unconditionally jump back to middle loop.
    
_MATRIX_LIB_loop_internal_2nd_matrix_columns:

    #* The inner loop. Loops for every column within 2st matrix!
    # Loop variable: j
    # Load variables: i, k, j, matrix B, matrix A, s
    # Register architecture:
    #   i -> ecx
    #   j -> edx
    #   k -> esi
    #   s -> edi
    #   matrix ANS (and elements) -> edi (after unloading s)
    #   matrix B (and elements) -> ebx
    #   matrix A (and elements) -> eax
    #
    # Save and restore registers that are needed to be used.

    mov -24(%ebp), %edx                 # load loop variable -> j
    mov -12(%ebp), %edi                 # s
    mov -16(%ebp), %ecx                 # i
    mov -20(%ebp), %esi                 # k
    
    # load matrix A and B
    mov 20(%ebp), %eax                  # Matrix A
    mov 24(%ebp), %ebx                  # Matrix B

    cmp %edi, %edx
    je _MATRIX_LIB_loop_internal_2nd_matrix_columns__end        # if j == s then end inner loop

    # Assume s to be unloaded here, used for any purpose and matrix ans can be loaded when needed.
    #
    # 4 * ( j + ( s * i) ) -> the element being computed!
    # 4 * ( k + ( c * i) ) -> 1st matrix : fetch and store value in eax
    # 4 * ( j + ( s * k) ) -> 2nd matrix : fetch and store value in ebx
    #
    # Thus,
    #        4 * ( j + ( s * i) ) = 4 * ( k + ( c * i) ) * 4 * ( j + ( s * k) )

    # 1st matrix elemental offset
        # overwrite j with c and load i into edi
    mov -8(%ebp), %edx
    mov %ecx, %edi
    imul %edx, %edi                     # edi = edi * edx
    add %esi, %edi                      # esi = esi + edi
    imul $4, %edi                       # edi = size * edi (4 for now, change later!)
    add $8, %edi                        # add 8 bytes for row and column

    # restore edx register
    mov -24(%ebp), %edx                 # j

    # edi now has element offset of matrix A
    # load element into eax
    mov (%eax, %edi), %eax

    # 2nd matrix elemental offset
    mov -12(%ebp), %edi                 # s
    imul %esi, %edi                     # edi = edi * esi = s * k
    add %edx, %edi                      # edi = edi + edx
    imul $4, %edi                       # edi = size * edi (4 for now, change later!)
    add $8, %edi                        # add 8 bytes for row and column

    # edi now has element offset of matrix B
    # load element into ebx
    mov (%ebx, %edi), %ebx

    # Multiply both of these and store in ebx.
    # imul for now, add other datatype support later
    imul %eax, %ebx     # ebx = ebx * eax

    # ebx now has product needed.
    # use eax for loading matrix ans
    # use edx to load current value in matrix ans at elemental offset
    #
    # Idea: To store the immediate product into the matrix ans
    # and add them over in iterations to save memory space.

    # Elemental offset for matrix ans

    mov -12(%ebp), %edi                     # s
    imul %ecx, %edi                         # edi = edi * ecx = s * i
    add %edx, %edi                          # edi = edi + edx
    imul $4, %edi                           # edi = size * edi (4 for now, change later!)
    add $8, %edi                            # add 8 bytes.

    # edi now has element offset for matrix ans
    # load matrix ans

    mov -28(%ebp), %eax
    mov (%eax, %edi), %edx      # sum of all iterations for this element.
    add %ebx, %edx              # edx = edx + ebx -> previous sum of all iterations + current iteration result
    mov %edx, (%eax, %edi)      # store back the result

    # computations completed. Update looping conditions and jump back
    # No need to restore registers as the unconditional jump will do it automatically

    mov -24(%ebp), %edx         # loop variable
    inc %edx                    # add 1 to loop variable
    mov %edx, -24(%ebp)         # Store back the loop variable

    jmp _MATRIX_LIB_loop_internal_2nd_matrix_columns        # unconditionally jump back to loop.

    _MATRIX_LIB_loop_internal_2nd_matrix_columns__end:

        # The inner loop has ended.
        # Reset local inner loop variable
        # unconditionally jump to middle loop

        mov -24(%ebp), %edx         # loop variable
        xor %edx, %edx              # reset loop variable
        mov %edx, -24(%ebp)         # Store back the loop variable

        jmp _MATRIX_LIB_loop_internal_1st_matrix_columns_RETURN__       # unconditionally jump back to middle loop.

_MATRIX_LIB_internal_end_loop_and_return:

    # The matrix multiplication has finished.
    # Load the base memory address of matrix ans into eax
    # restore the stack pointer
    # return

    xor %ecx, %ecx          # No errors.

    mov -28(%ebp), %eax     # load return value into eax
    
    mov %ebp, %esp          # restore the stack pointer
    pop %ebp                # remove base pointer from stack            (Callee saved register)
    pop %edi                # remove index pointer from stack           (Callee saved register)
    pop %esi                # remove string index pointer from stack    (Callee saved register)
    pop %ebx                # remove ebx from stack                     (Callee saved register)
    ret                     # transfer control to callee

_cannot_multiply_matrix:

    mov $1, %ecx            # Error code: 1 -> Different sizes
    mov -28(%ebp), %eax     # load return value into eax

    mov %ebp, %esp          # restore the stack pointer
    pop %ebp                # remove base pointer from stack            (Callee saved register)
    pop %edi                # remove index pointer from stack           (Callee saved register)
    pop %esi                # remove string index pointer from stack    (Callee saved register)
    pop %ebx                # remove ebx from stack                     (Callee saved register)
    ret                     # transfer control to callee
