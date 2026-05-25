; ==============================================================================
; RUTA: ./lib/math/int32/lib_math_int32.inc
; DESCRIPCIÓN: Constantes para las librerías lib/math/int32.
;              Incluir en cualquier .asm que use operaciones sobre int32
;              o que necesite los límites de rango.
; ==============================================================================

%ifndef LIB_MATH_INT32_INC
%define LIB_MATH_INT32_INC

%define INT32_MIN   0x80000000      ; -2147483648
%define INT32_MAX   0x7FFFFFFF      ;  2147483647

%endif
