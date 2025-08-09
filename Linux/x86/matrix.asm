# Pass reference of array, i.e.,
# a void pointer otherwise said base address.
# The base address and its subsequent bytes is expected to follow the following structure:
# num_rows<m> num_columns<n> element<1,1> element<1,2> element<1,n> element<2,1> element<2,2> ... element<m,1> element<m,2> ... element<m,n>

# ---------------------------------- LIMITATIONS/FUTURE WORK -------------------
# * Add support for different data types, currently only long.

# ---------------------------------- MATRIX LIB -----------------------------

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

# ------------------------ Multiplication

# Returns a reference value in eax register
# Expects a pointer (reference) to the matrix 1 and matrix 2 (reverse order)
# Expect all registers to be over-written. Saving is the caller's job
# Restoring stack (removal of arguments) is also the caller's job

# *** Function signature.
# Expected parameter(s): A reference to the both the matrices, i.e., base memory address of matrix A and B.
#   
#   Stack:
#       Matrix B -> ebp + 12
#       Matrix A -> ebp + 8
#       Return Address
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
# ******* element (i,j) of a matrix where each element consumes 'size' bytes with 'nc' columns is: 
#  
#                                           size * (j + (nc * i))

.type multiplication, @function
multiplication:

    # Store stack

    push %ebp
    mov %esp, %ebp

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

    # Space to store size of matrices and loop index variables
    sub $24, %esp

    mov 8(%ebp), %ebx #1st matrix
    mov (%ebx), %ecx # num rows of 1st matrix
    mov %ecx, -4(%ebp) # r

    mov $1, %edi
    mov (%ebx, %edi, 4), %ecx # num columns of 1st matrix
    mov %ecx, -8(%ebp) # c

    mov 12(%ebp), %ebx #2nd matrix
    mov (%ebx, %edi, 4), %ecx # num columns of 2nd matrix
    mov %ecx, -12(%ebp) # s

    mov (%ebx), %ecx # num rows of 2nd matrix
    mov -8(%ebp), %ebx # num of columns of 1st matrix

    cmp %ebx, %ecx
    jne _cannot_multiply_matrix

    #* We are not saving the rows of 2nd matrix because this must be same as column size of 1st matrix.
    # Set all loop variables to 0.

    xor %ecx, %ecx # quick zero ecx
    mov %ecx, -16(%ebp) # i
    mov %ecx, -20(%ebp) # k
    mov %ecx, -24(%ebp) # j

_MATRIX_LIB_loop_internal_1st_matrix_rows:

    #* The outermost loop. Loops for every row within 1st matrix!
    # Loop variable: i

    mov -16(%ebp), %edi # load loop variable
    mov -4(%ebp), %ebx # r

    cmp %edi, %ebx
    je _MATRIX_LIB_internal_end_loop # matrix multiplication must have ended.

    # Go to middle loop.
    jmp _MATRIX_LIB_loop_internal_1st_matrix_columns

_MATRIX_LIB_loop_internal_1st_matrix_columns:
    
    #* The middle loop. Loops for every column within 1st matrix!
    # Loop variable: k

    mov -20(%ebp), %edi # load loop variable
    mov -8(%ebp), %ebx # c

    # Increase row if columns is maxed out and set column looper to 0.
    cmp %edi, %ebx
    je _MATRIX_LIB_loop_internal_1st_matrix_columns__INTERNAL_incr_row

    # Go to inner loop

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

    mov -24(%ebp), %edx     # load loop variable -> j
    mov -12(%ebp), %edi     # s
    mov -16(%ebp), %ecx     # i
    mov -20(%ebp), %esi     # k
    
    # load matrix A and B
    mov 8(%ebp), %eax
    mov 12(%ebp), %ebx

    # while j < s

    cmp %edx, %edi
    je _MATRIX_LIB_loop_internal_2nd_matrix_columns__end

    # Assume s to be unloaded here, used for any purpose and matrix ans can be loaded when needed.

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
    imul %edx, %edi     # edi = edi * edx
    add %esi, %edi      # esi = esi + edi
    imul $4, %edi       # edi = size * edi (4 for now, change later!)

    # restore edx register
    mov -24(%ebp), %edx     # j

    # edi now has element offset of matrix A
    # load element into eax
    mov (%eax, %edi), %eax

    # 2nd matrix elemental offset
    mov -12(%ebp), %edi # s
    imul %esi, %edi     # edi = edi * esi = s * k
    add %edx, %edi      # edi = edi + edx
    imul $4, %edi       # edi = size * edi (4 for now, change later!)

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

    mov -12(%ebp), %edi # s
    imul %ecx, %edi     # edi = edi * ecx = s * i
    add %edx, %edi      # edi = edi + edx
    imul $4, %edi       # edi = size * edi (4 for now, change later!)

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

        jmp _MATRIX_LIB_loop_internal_1st_matrix_columns        # unconditionally jump back to middle loop.

