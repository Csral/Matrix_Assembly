# Matrix Assembly Library - Matrix operations library fully written in assembly
# Copyright (C) 2025  Chaturya Reddy (@Csral) <chaturyasral@gmail.com>
# 
# This project is licensed under the GNU Lesser General Public License v3.0 (LGPL-3.0).
# You should have received a copy of the GNU Lesser General Public License along
# with this program in the files COPYING and COPYING.LESSER. If not, see
# <https://www.gnu.org/licenses/>.
#
# Pass reference of array, i.e.,
# a void pointer otherwise said base address.
# The base address and its subsequent bytes is expected to follow the following structure:
# num_rows<m> num_columns<n> element<1,1> element<1,2> element<1,n> element<2,1> element<2,2> ... element<m,1> element<m,2> ... element<m,n>

# ---------------------------------- LIMITATIONS/FUTURE WORK -------------------
# * Add support for different data types, currently only long.

# ---------------------------------- MATRIX LIB -----------------------------

# separate files for a clean environment + easy to maintain.

.include "multiplication.asm"
.include "determinant.asm"
