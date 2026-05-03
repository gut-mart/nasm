#!/bin/bash
# ==============================================================================
# RUTA: ./setup.sh
# DESCRIPCIÓN: Instalador del entorno de desarrollo NASM.
#
# Por defecto instala SOLO lo mínimo necesario para compilar y depurar el
# proyecto. Funcionalidad opcional (watcher de Makefiles, extensiones de
# VS Code) se activa con flags explícitos.
#
# MODOS DE USO:
#   ./setup.sh             Solo dependencias mínimas (nasm, make, gdb, gcc)
#   ./setup.sh --watcher   + inotify-tools + servicio systemd como --user
#   ./setup.sh --vscode    + extensiones recomendadas de VS Code
#   ./setup.sh --all       Todo lo anterior
#   ./setup.sh --yes       No pedir confirmación interactiva
#   ./setup.sh --help      Mostrar esta ayuda
#
# Los flags se pueden combinar: ./setup.sh --watcher --vscode --yes
# ==============================================================================

set -e

# --- Códigos de color para mensajes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok()      { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }

# --- Resolver el directorio del proyecto ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Flags por defecto ---
INSTALL_WATCHER=0
INSTALL_VSCODE=0
SKIP_CONFIRMATION=0

# ==============================================================================
# FUNCIÓN: mostrar_ayuda
# ==============================================================================
mostrar_ayuda() {
    cat << 'EOF'
Uso: ./setup.sh [OPCIONES]

Instala el entorno de desarrollo del proyecto NASM. Por defecto solo
instala las dependencias mínimas para compilar y depurar.

OPCIONES:
  --watcher      Instala inotify-tools y un servicio systemd (modo --user)
                 que regenera Makefiles delegadores automáticamente cuando
                 añades nuevos comandos.
  --vscode       Instala las extensiones recomendadas de VS Code.
  --all          Equivalente a --watcher --vscode.
  --yes, -y      No pedir confirmación antes de instalar.
  --help, -h     Mostrar esta ayuda.

EJEMPLOS:
  # Setup mínimo (solo compilar y depurar)
  ./setup.sh

  # Setup completo para desarrollo intensivo
  ./setup.sh --all

  # Para scripts de CI/CD que no pueden interactuar
  ./setup.sh --yes

EOF
}

# ==============================================================================
# FUNCIÓN: parsear_argumentos
# ==============================================================================
parsear_argumentos() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --watcher)
                INSTALL_WATCHER=1
                ;;
            --vscode)
                INSTALL_VSCODE=1
                ;;
            --all)
                INSTALL_WATCHER=1
                INSTALL_VSCODE=1
                ;;
            --yes|-y)
                SKIP_CONFIRMATION=1
                ;;
            --help|-h)
                mostrar_ayuda
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                echo ""
                mostrar_ayuda
                exit 1
                ;;
        esac
        shift
    done
}

# ==============================================================================
# FUNCIÓN: verificar_sistema
# Comprueba que estamos en Linux x86_64 y con sudo configurado.
# ==============================================================================
verificar_sistema() {
    log_info "Verificando sistema..."

    if [ "$(uname -s)" != "Linux" ]; then
        log_error "Este proyecto solo funciona en Linux. Detectado: $(uname -s)"
        exit 1
    fi

    if [ "$(uname -m)" != "x86_64" ]; then
        log_error "Se requiere arquitectura x86_64. Detectada: $(uname -m)"
        exit 1
    fi

    if ! command -v sudo > /dev/null 2>&1; then
        log_error "sudo no está instalado. Instálalo o ejecuta este script como root."
        exit 1
    fi

    if ! sudo -v; then
        log_error "No se pudo validar sudo. ¿Estás en sudoers?"
        exit 1
    fi

    log_ok "Sistema compatible: Linux x86_64 con sudo configurado."
}

# ==============================================================================
# FUNCIÓN: detectar_distro
# Detecta la distribución usando /etc/os-release. Considera ID e ID_LIKE
# para soportar distribuciones derivadas.
# Define las variables: DISTRO_FAMILY (apt/dnf/pacman), PKG_MANAGER
# ==============================================================================
detectar_distro() {
    log_info "Detectando distribución..."

    if [ ! -f /etc/os-release ]; then
        log_error "No se encontró /etc/os-release. Distro no soportada."
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    local ID_LOWER="${ID,,}"
    local ID_LIKE_LOWER="${ID_LIKE,,}"

    case "$ID_LOWER" in
        ubuntu|debian|pop|linuxmint)
            DISTRO_FAMILY="apt"
            PKG_MANAGER="apt-get"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO_FAMILY="dnf"
            PKG_MANAGER="dnf"
            ;;
        arch|manjaro|endeavouros|cachyos)
            DISTRO_FAMILY="pacman"
            PKG_MANAGER="pacman"
            ;;
        *)
            # Fallback: usar ID_LIKE
            case "$ID_LIKE_LOWER" in
                *arch*)
                    DISTRO_FAMILY="pacman"
                    PKG_MANAGER="pacman"
                    ;;
                *debian*|*ubuntu*)
                    DISTRO_FAMILY="apt"
                    PKG_MANAGER="apt-get"
                    ;;
                *rhel*|*fedora*)
                    DISTRO_FAMILY="dnf"
                    PKG_MANAGER="dnf"
                    ;;
                *)
                    log_error "Distribución no soportada: $ID (ID_LIKE: $ID_LIKE)"
                    log_error "Familias soportadas: Debian/Ubuntu, Fedora/RHEL, Arch."
                    exit 1
                    ;;
            esac
            ;;
    esac

    log_ok "Distribución detectada: $ID (familia: $DISTRO_FAMILY)"
}

# ==============================================================================
# FUNCIÓN: mostrar_resumen_y_confirmar
# ==============================================================================
mostrar_resumen_y_confirmar() {
    echo ""
    echo "================================================================"
    echo " RESUMEN DE LA INSTALACIÓN"
    echo "================================================================"
    echo ""
    echo " Dependencias mínimas (siempre):"
    echo "   - nasm, make, gdb, gcc"
    echo ""

    if [ $INSTALL_WATCHER -eq 1 ]; then
        echo " Watcher de Makefiles (--watcher):"
        echo "   - inotify-tools"
        echo "   - servicio systemd (modo --user, no requiere root permanente)"
        echo ""
    fi

    if [ $INSTALL_VSCODE -eq 1 ]; then
        echo " Extensiones de VS Code (--vscode):"
        echo "   - ms-vscode.cpptools"
        echo "   - 13xforever.language-x86-64-assembly"
        echo "   - ryuta46.multi-command"
        echo ""
    fi

    echo " Bootstrap de Makefiles delegadores (siempre):"
    echo "   - Genera Makefiles en cada carpeta de comandos/"
    echo ""
    echo "================================================================"
    echo ""

    if [ $SKIP_CONFIRMATION -eq 1 ]; then
        log_info "Omitiendo confirmación (--yes)."
        return
    fi

    read -r -p "¿Continuar con la instalación? [y/N]: " RESPUESTA
    case "$RESPUESTA" in
        [yY]|[yY][eE][sS]|[sS]|[sS][iI])
            log_info "Continuando..."
            ;;
        *)
            log_warn "Instalación cancelada por el usuario."
            exit 0
            ;;
    esac
}

# ==============================================================================
# FUNCIÓN: instalar_paquetes
# Instala una lista de paquetes según la familia de distro detectada.
# ==============================================================================
instalar_paquetes() {
    local PAQUETES=("$@")

    log_info "Instalando: ${PAQUETES[*]}"

    case "$DISTRO_FAMILY" in
        apt)
            sudo "$PKG_MANAGER" update
            sudo "$PKG_MANAGER" install -y "${PAQUETES[@]}"
            ;;
        dnf)
            sudo "$PKG_MANAGER" install -y "${PAQUETES[@]}"
            ;;
        pacman)
            sudo "$PKG_MANAGER" -S --noconfirm --needed "${PAQUETES[@]}"
            ;;
    esac
}

# ==============================================================================
# FUNCIÓN: instalar_dependencias_minimas
# ==============================================================================
instalar_dependencias_minimas() {
    log_info "Instalando dependencias mínimas..."
    instalar_paquetes nasm make gdb gcc
    log_ok "Dependencias mínimas instaladas."
}

# ==============================================================================
# FUNCIÓN: instalar_watcher
# Instala inotify-tools y configura el servicio systemd como --user.
# ==============================================================================
instalar_watcher() {
    log_info "Instalando soporte de watcher (inotify-tools)..."

    case "$DISTRO_FAMILY" in
        apt)    instalar_paquetes inotify-tools ;;
        dnf)    instalar_paquetes inotify-tools ;;
        pacman) instalar_paquetes inotify-tools ;;
    esac

    log_info "Configurando servicio systemd como --user..."

    local SERVICE_DIR="$HOME/.config/systemd/user"
    local SERVICE_FILE="$SERVICE_DIR/monitor_asm.service"

    mkdir -p "$SERVICE_DIR"

    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Monitor de archivos NASM (regenera Makefiles delegadores)
After=default.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $SCRIPT_DIR/monitor_comandos.sh --watch
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable monitor_asm.service
    systemctl --user start monitor_asm.service

    log_ok "Servicio monitor_asm.service instalado y activo (modo --user)."
    log_info "Para ver estado:    systemctl --user status monitor_asm.service"
    log_info "Para detener:       systemctl --user stop monitor_asm.service"
    log_info "Para desinstalar:   systemctl --user disable monitor_asm.service"
}

# ==============================================================================
# FUNCIÓN: instalar_extensiones_vscode
# ==============================================================================
instalar_extensiones_vscode() {
    log_info "Instalando extensiones de VS Code..."

    if ! command -v code > /dev/null 2>&1; then
        log_warn "VS Code no está instalado o 'code' no está en el PATH."
        log_warn "Salta la instalación de extensiones. Instala VS Code y"
        log_warn "vuelve a ejecutar ./setup.sh --vscode si quieres las extensiones."
        return
    fi

    local EXTENSIONES=(
        "ms-vscode.cpptools"
        "13xforever.language-x86-64-assembly"
        "ryuta46.multi-command"
    )

    for EXT in "${EXTENSIONES[@]}"; do
        log_info "  - $EXT"
        code --install-extension "$EXT" --force > /dev/null 2>&1 || \
            log_warn "    No se pudo instalar $EXT (puede que ya esté instalada)."
    done

    log_ok "Extensiones de VS Code procesadas."
}

# ==============================================================================
# FUNCIÓN: bootstrap_makefiles
# Llama al script monitor_comandos.sh en modo --bootstrap para generar
# Makefiles delegadores en cada carpeta de comandos.
# ==============================================================================
bootstrap_makefiles() {
    log_info "Generando Makefiles delegadores en comandos/..."

    if [ ! -x "$SCRIPT_DIR/monitor_comandos.sh" ]; then
        log_warn "No se encuentra monitor_comandos.sh ejecutable. Saltando bootstrap."
        return
    fi

    "$SCRIPT_DIR/monitor_comandos.sh" --bootstrap

    log_ok "Bootstrap de Makefiles completado."
}

# ==============================================================================
# FUNCIÓN: mostrar_siguientes_pasos
# ==============================================================================
mostrar_siguientes_pasos() {
    echo ""
    echo "================================================================"
    echo " ✨ INSTALACIÓN COMPLETADA"
    echo "================================================================"
    echo ""
    echo " Siguientes pasos:"
    echo ""
    echo "   1. Compila un comando de ejemplo:"
    echo "      make SRC=comandos/monitor/draw_pixel/draw_pixel.asm"
    echo ""
    echo "   2. Ejecuta el binario (requiere /dev/fb0 accesible):"
    echo "      sudo ./bin/draw_pixel 100 100 0xFF0000"
    echo ""

    if [ $INSTALL_WATCHER -eq 1 ]; then
        echo "   3. El watcher de Makefiles está activo en background."
        echo ""
    fi

    echo "   Para desarrollo remoto vía SSH, copia y edita la config:"
    echo "      cp config.example.mk config.local.mk"
    echo "      \$EDITOR config.local.mk"
    echo ""
    echo "   Más información:  cat README.md"
    echo ""
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
    parsear_argumentos "$@"

    echo ""
    echo "🔧 Instalador del entorno NASM"
    echo ""

    verificar_sistema
    detectar_distro
    mostrar_resumen_y_confirmar

    instalar_dependencias_minimas

    if [ $INSTALL_WATCHER -eq 1 ]; then
        instalar_watcher
    fi

    if [ $INSTALL_VSCODE -eq 1 ]; then
        instalar_extensiones_vscode
    fi

    bootstrap_makefiles
    mostrar_siguientes_pasos
}

main "$@"
