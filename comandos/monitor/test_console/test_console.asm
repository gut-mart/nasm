%include "lib/constants.inc"
%include "lib/sys_macros.inc"

default rel

extern lib_cursor_hide, lib_cursor_show, lib_wait_key
extern print_string

section .data
    msg_antes  db "Cursor oculto. Pulsa cualquier tecla...", 10, 0
    msg_despues db "Tecla recibida. Cursor restaurado.", 10, 0

section .text
    global _start

_start:
    mov rbp, rsp
    and rsp, -16

    call lib_cursor_hide

    mov rdi, msg_antes
    call print_string

    call lib_wait_key       ; espera tecla

    call lib_cursor_show

    mov rdi, msg_despues
    call print_string

    sys_exit 0