#!/bin/bash

# ==============================================================================
# RUTA: ./setup.sh
# DESCRIPCIÓN: Script universal de setup que detecta la distribución Linux
#              e instala las dependencias correspondientes.
# ==============================================================================

set -e

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Función de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Detectar distribución
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID,,}"
        DISTRO_VERSION="$VERSION_ID"
    else
        log_error "No se pudo detectar la distribución"
        exit 1
    fi
}

# Función de instalación genérica
install_packages() {
    local package_manager="$1"
    shift
    local packages=("$@")
    
    case "$package_manager" in
        apt)
            log_info "Actualizando repositorios..."
            sudo apt-get update
            log_info "Instalando dependencias..."
            sudo apt-get install -y "${packages[@]}"
            ;;
        pacman)
            log_info "Instalando dependencias..."
            sudo pacman -Sy --noconfirm "${packages[@]}"
            ;;
        dnf)
            log_info "Instalando dependencias..."
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            log_info "Instalando dependencias..."
            sudo yum install -y "${packages[@]}"
            ;;
        *)
            log_error "Gestor de paquetes desconocido: $package_manager"
            exit 1
            ;;
    esac
}

# Instalar VS Code extensions
install_extensions() {
    log_info "Instalando extensiones de VS Code..."
    
    local extensions=(
        "ryuta46.multi-command"
        "ms-vscode.cpptools"
        "13xforever.language-x86-64-assembly"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension "$ext" || log_warning "No se pudo instalar $ext"
    done
}

# Crear y activar servicio systemd
setup_systemd_service() {
    log_info "Configurando servicio systemd para monitoreo de archivos..."
    
    local service_file="/etc/systemd/system/monitor_asm.service"
    
    if ! sudo test -f "$service_file"; then
        sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=Monitor NASM Assembly Files
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=/bin/bash $SCRIPT_DIR/monitor_comandos.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        sudo systemctl enable monitor_asm.service
        sudo systemctl start monitor_asm.service
        log_success "Servicio systemd creado y activado"
    else
        log_info "Servicio systemd ya existe"
    fi
}

# Configurar atajos de teclado en VS Code
setup_vscode_keybindings() {
    log_info "Configurando atajos de teclado en VS Code..."
    
    local keybindings_file="$SCRIPT_DIR/.vscode/keybindings.json"
    
    # Este archivo debe ser configurado manualmente en VS Code
    log_warning "Los atajos de teclado deben configurarse manualmente en:"
    echo "  File > Preferences > Keyboard Shortcuts > keybindings.json"
    echo "  Referencia: $keybindings_file"
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Setup NASM - Entorno de Desarrollo   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
    
    detect_distro
    log_info "Distribución detectada: $DISTRO ($DISTRO_VERSION)"
    echo
    
    # Seleccionar paquetes según la distro
    case "$DISTRO" in
        ubuntu|debian)
            log_info "Detectado: Debian/Ubuntu"
            install_packages "apt" \
                "build-essential" \
                "nasm" \
                "gdb" \
                "gcc" \
                "make" \
                "inotify-tools" \
                "curl"
            ;;
        fedora)
            log_info "Detectado: Fedora"
            install_packages "dnf" \
                "gcc" \
                "make" \
                "nasm" \
                "gdb" \
                "inotify-tools" \
                "curl"
            ;;
        rhel|centos)
            log_info "Detectado: RHEL/CentOS"
            install_packages "yum" \
                "gcc" \
                "make" \
                "nasm" \
                "gdb" \
                "inotify-tools" \
                "curl"
            ;;
        arch|manjaro)
            log_info "Detectado: Arch/Manjaro"
            install_packages "pacman" \
                "base-devel" \
                "nasm" \
                "gdb" \
                "gcc" \
                "make" \
                "inotify-tools" \
                "curl"
            ;;
        *)
            log_error "Distribución no soportada: $DISTRO"
            log_info "Instalación manual requerida. Dependencias necesarias:"
            echo "  - nasm >= 2.14"
            echo "  - gcc"
            echo "  - make"
            echo "  - gdb"
            echo "  - inotify-tools"
            exit 1
            ;;
    esac
    
    log_success "Dependencias del sistema instaladas"
    echo
    
    # Configurar servicio de monitoreo
    setup_systemd_service
    echo
    
    # Instalar extensiones de VS Code
    if command -v code &> /dev/null; then
        install_extensions
    else
        log_warning "VS Code no encontrado. Instálalo manualmente."
    fi
    echo
    
    # Información adicional
    setup_vscode_keybindings
    echo
    
    log_success "Setup completado exitosamente!"
    echo
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo "  1. Verifica que inotifywait está instalado:"
    echo "     which inotifywait"
    echo "  2. Crea un archivo .asm en comandos/"
    echo "  3. El sistema compilará automáticamente"
    echo
}

main "$@"
