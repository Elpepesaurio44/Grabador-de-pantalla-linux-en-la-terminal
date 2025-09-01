#!/bin/bash

# ===================================================================
#  ██████╗  █████╗ ████████╗████████╗██╗     ███████╗███████╗
#  ██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║     ██╔════╝██╔════╝
#  ██████╔╝███████║   ██║      ██║   ██║     █████╗  ███████╗
#  ██╔══██╗██╔══██║   ██║      ██║   ██║     ██╔══╝  ╚════██║
#  ██████╔╝██║  ██║   ██║      ██║   ███████╗███████╗███████║
#  ╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚══════╝╚══════╝
#      🎥 Grabador de Pantalla + Webcam para Terminal Linux
# ===================================================================

# Colores
ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
MAGENTA="\033[1;35m"
CIAN="\033[1;36m"
BLANCO="\033[1;37m"
NC="\033[0m" # No Color

# Variables
OUTPUT="grabacion.mp4"
FPS=30
RESOLUTION=""
WEBCAM_DEVICE="/dev/video0"
USE_MIC="n"
MIC_SOURCE=""
PRESET="ultrafast"
CRF=23
MODE=""

# Detectar resolución del escritorio
detectar_resolucion() {
    RESOLUTION=$(xrandr | grep "\*" | head -1 | awk '{print $1}')
    if [ -z "$RESOLUTION" ]; then
        echo -e "${ROJO}❌ No se pudo detectar la resolución. ¿Estás en X11?${NC}"
        exit 1
    fi
}

# Mostrar título gigante
mostrar_titulo() {
    clear
    echo -e "${CIAN}"
    echo -e "  ██████╗  █████╗ ████████╗████████╗██╗     ███████╗███████╗"
    echo -e "  ██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║     ██╔════╝██╔════╝"
    echo -e "  ██████╔╝███████║   ██║      ██║   ██║     █████╗  ███████╗"
    echo -e "  ██╔══██╗██╔══██║   ██║      ██║   ██║     ██╔══╝  ╚════██║"
    echo -e "  ██████╔╝██║  ██║   ██║      ██║   ███████╗███████╗███████║"
    echo -e "  ╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚══════╝╚══════╝${NC}"
    echo -e "${AMARILLO}         🎥 Grabador de Pantalla para Terminal Linux${NC}"
    echo -e "${BLANCO}========================================================${NC}"
    echo
}

# Listar micrófonos disponibles
listar_micrófonos() {
    echo -e "${BLANCO}🔍 Micrófonos disponibles:${NC}"
    local mics=()
    local i=1
    pactl list sources short | grep -i "input" | while read line; do
        NAME=$(echo "$line" | awk '{print $2}')
        DESC=$(pactl list sources | grep -A5 "Name: $NAME" | grep "Description" | cut -d: -f2 | xargs)
        echo -e "  ${AZUL}[$i]${NC} $NAME → ${MAGENTA}$DESC${NC}"
        mics+=("$NAME")
        ((i++))
    done
}

# Preguntar nombre del archivo
preguntar_salida() {
    echo -ne "${BLANCO}📁 Nombre del archivo de salida [grabacion.mp4]: ${NC}"
    read -r nombre
    OUTPUT="${nombre:-grabacion.mp4}"
    [[ "$OUTPUT" != *.mp4 ]] && OUTPUT="$OUTPUT.mp4"
}

# Menú principal
menu_principal() {
    echo -e "${BLANCO}🎥 Selecciona el modo de grabación:${NC}"
    echo -e " ${AZUL}1${NC}) Solo pantalla"
    echo -e " ${AZUL}2${NC}) Solo webcam"
    echo -e " ${AZUL}3${NC}) Pantalla + webcam (webcam en esquina)"
    echo

    while true; do
        echo -ne "${BLANCO}Elige una opción [1-3]: ${NC}"
        read -r opcion
        case $opcion in
            1) MODE="pantalla"; break ;;
            2) MODE="webcam"; break ;;
            3) MODE="pantalla_webcam"; break ;;
            *) echo -e "${ROJO}❌ Opción inválida. Elige 1, 2 o 3.${NC}" ;;
        esac
    done
}

# Preguntar micrófono
configurar_mic() {
    echo
    echo -ne "${BLANCO}🎙️  ¿Usar micrófono? (s/n) [n]: ${NC}"
    read -r USE_MIC
    USE_MIC=${USE_MIC:-n}

    if [[ $USE_MIC =~ ^[Ss]$ ]]; then
        if ! pactl list sources short | grep -iq "input"; then
            echo -e "${AMARILLO}⚠️  No se detectó ningún micrófono.${NC}"
            return
        fi

        listar_micrófonos
        echo
        echo -ne "${BLANCO}Elige el número del micrófono: ${NC}"
        read -r num
        local sources=($(pactl list sources short | grep -i "input" | awk '{print $2}'))
        if [ $num -ge 1 ] && [ $num -le ${#sources[@]} ]; then
            MIC_SOURCE="${sources[$((num-1))]}"
            echo -e "${VERDE}✔️  Micrófono seleccionado: $MIC_SOURCE${NC}"
        else
            echo -e "${ROJO}❌ Número inválido. Sin micrófono.${NC}"
            USE_MIC="n"
        fi
    else
        echo -e "${AMARILLO}🔇 Micrófono desactivado.${NC}"
    fi
}

# Iniciar grabación
iniciar_grabacion() {
    local inputs=()
    local filters=""
    local audio_map=()

    echo -e "\n${VERDE}🚀 Iniciando grabación... (Presiona ${BLANCO}Ctrl+C${VERDE} para detener)${NC}"

    # Entradas según modo
    case $MODE in
        "pantalla")
            inputs+=(-f x11grab -s "$RESOLUTION" -framerate "$FPS" -i :0.0)
            filters="scale=trunc(iw/2)*2:trunc(ih/2)*2"
            ;;

        "webcam")
            if ! v4l2-ctl --list-devices >/dev/null 2>&1; then
                echo -e "${ROJO}❌ No se puede acceder a v4l2. ¿Webcam conectada?${NC}"
                exit 1
            fi
            inputs+=(-f v4l2 -framerate "$FPS" -video_size 640x480 -i "$WEBCAM_DEVICE")
            filters="scale=640:480"
            ;;

        "pantalla_webcam")
            inputs+=(
                -f x11grab -s "$RESOLUTION" -framerate "$FPS" -i :0.0
                -f v4l2 -framerate "$FPS" -video_size 640x480 -i "$WEBCAM_DEVICE"
            )
            filters="[1]scale=240:180[v]; [0][v]overlay=main_w-250:main_h-190"
            ;;
    esac

    # Audio del sistema (siempre activo)
    inputs+=(-f pulse -i default)
    audio_map+=("[${#inputs[@]}/2:a]")

    # Micrófono (si se eligió)
    if [[ $USE_MIC =~ ^[Ss]$ ]] && [ -n "$MIC_SOURCE" ]; then
        inputs+=(-f pulse -i "$MIC_SOURCE")
        audio_map+=("[${#inputs[@]}/2:a]")
    fi

    # Mezclar audio si hay más de uno
    local audio_filter=""
    if [ ${#audio_map[@]} -gt 1 ]; then
        audio_filter=$(printf '%s;' "${audio_map[@]}")"amix=inputs=${#audio_map[@]}"
    else
        audio_filter="${audio_map[0]}"
    fi

    # Comando final
    ffmpeg -y "${inputs[@]}" \
        -vf "$filters" \
        -filter_complex "$audio_filter" \
        -c:a aac -b:a 128k \
        -c:v libx264 -preset "$PRESET" -crf "$CRF" \
        "$OUTPUT" || {
        echo -e "\n${ROJO}❌ Error al grabar. Verifica permisos o dispositivos.${NC}"
        exit 1
    }

    echo -e "\n${VERDE}✅ ¡Grabación finalizada! Guardado en: ${BLANCO}$OUTPUT${NC}"
}

# ===============
#   MAIN
# ===============
mostrar_titulo
detectar_resolucion
menu_principal
preguntar_salida
configurar_mic
iniciar_grabacion
