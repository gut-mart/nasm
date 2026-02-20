📘 Librería: lib_graph_get_info_screen
Archivo: lib/graph/lib_graph_get_info_screen.asm
Dependencia: lib/graph/lib_graph_get_info_screen.inc

Esta librería interactúa con el Kernel de Linux a través del dispositivo /dev/fb0. Su función es obtener la configuración de pantalla actual (resolución y profundidad de color) y las dimensiones físicas del monitor (en milímetros), calculando además el LineLength (Pitch) necesario para dibujar píxeles correctamente.

⚙️ Especificación de Interfaz (API)
📥 Registros de Entrada (Inputs)
Antes de llamar a la función, debes configurar el siguiente registro:

Registro	Dato Esperado	Descripción
RDI	Puntero a Estructura	Dirección de memoria donde se guardarán los datos. Debe apuntar a un espacio reservado de al menos 24 bytes (ScreenInfo_size).
📤 Registros de Salida (Outputs)
Tras la ejecución (ret), el estado será:

Registro	Valor	Significado
RAX	0	Éxito. Los datos se han escrito en la estructura apuntada por RDI.
RAX	-1	Error. No se pudo abrir /dev/fb0 o falló la lectura (ioctl).
Nota: La memoria apuntada por RDI habrá sido rellenada con los datos de la pantalla.

💾 Estructura de Datos (ScreenInfo)
La librería rellena la estructura definida en el archivo .inc. El tamaño total es de 24 bytes.

Offset	Campo (.inc)	Tamaño	Descripción	Ejemplo
+0	.width	4 bytes	Ancho de resolución (píxeles)	1920
+4	.height	4 bytes	Alto de resolución (píxeles)	1080
+8	.bpp	4 bytes	Bits por Píxel (profundidad)	32
+12	.pitch	4 bytes	Bytes por línea (Calculado)	7680
+16	.phy_width	4 bytes	Ancho físico del monitor (mm)	476
+20	.phy_height	4 bytes	Alto físico del monitor (mm)	268
🛡️ Gestión de Registros
Preservados (Seguros): RBX, RBP, R12, R13, RSP. La función se encarga de guardarlos y restaurarlos.

Volátiles (Destruidos): RAX, RCX, RDX, RSI, RDI, R8-R11.

Stack: La función utiliza temporalmente 160 bytes de la pila para comunicarse con el Kernel.

📝 Ejemplo de Uso
A continuación, un ejemplo de cómo integrar esta librería en un programa principal (main.asm).

Fragmento de código
; ==============================================================================
; Ejemplo de uso de lib_graph_get_info_screen
; ==============================================================================
default rel

; 1. Incluir la definición de la estructura (el "plano")
%include "lib/graph/lib_graph_get_info_screen.inc"

; 2. Declarar la función externa
extern lib_graph_get_info_screen

section .bss
    ; 3. Reservar memoria para la estructura (24 bytes)
    mi_pantalla resb ScreenInfo_size

section .text
    global _start

_start:
    ; --- LLAMADA A LA LIBRERÍA ---
    
    ; 4. Cargar la dirección de la estructura en RDI
    lea rdi, [mi_pantalla]
    
    ; 5. Llamar a la función
    call lib_graph_get_info_screen
    
    ; 6. Comprobar errores
    cmp rax, 0
    jl .error_detectado

    ; --- ACCESO A LOS DATOS ---
    
    ; Ejemplo: Cargar el Ancho (Width) en EAX
    mov eax, [mi_pantalla + ScreenInfo.width]
    
    ; Ejemplo: Cargar el Ancho Físico (mm) en EBX
    mov ebx, [mi_pantalla + ScreenInfo.phy_width]

    ; (Aquí iría el resto de tu lógica...)

    ; Salir bien
    mov rax, 60
    xor rdi, rdi
    syscall

.error_detectado:
    ; Salir con código de error 1
    mov rax, 60
    mov rdi, 1
    syscall
⚠️ Requisitos del Sistema
Para que esta función tenga éxito (retorno 0), el programa debe tener permisos de lectura sobre el dispositivo de framebuffer. Generalmente requiere ejecutar con sudo o que el usuario pertenezca al grupo video.