#!/bin/bash

# scratchpad.sh - Script para gerenciar scratchpad no bspwm com st

SCRATCHPAD_CLASS="scratchpad"
SCRATCHPAD_INSTANCE="scratchpad"

# Função para alternar o scratchpad
toggle_scratchpad() {
    # Verifica se o scratchpad já existe
    if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
        # Se existe, alterna entre mostrar/esconder
        if bspc query -N -n ".${SCRATCHPAD_CLASS}.hidden"; then
            # Se está escondido, mostra
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=off
            bspc node ".${SCRATCHPAD_CLASS}" -f
        else
            # Se está visível, esconde
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=on
        fi
    else
        # Se não existe, cria um novo scratchpad
        create_scratchpad
    fi
}

# Função para criar o scratchpad
create_scratchpad() {
    # Lança st com classe específica para o scratchpad
    st -c "$SCRATCHPAD_CLASS" -n "$SCRATCHPAD_INSTANCE" -g 100x30+50+50 &
    
    # Aguarda a janela aparecer e configura suas propriedades
    sleep 0.2
    
    # Define como flutuante e aplica regras
    bspc node newest.local -t floating
    bspc node newest.local -g sticky=on
    bspc node newest.local -l above
    
    # Centraliza a janela
    center_scratchpad
}

# Função para centralizar o scratchpad
center_scratchpad() {
    # Obtém dimensões da tela
    eval $(xdotool getdisplaygeometry --shell)
    
    # Calcula posição central (ajuste os valores conforme necessário)
    WINDOW_WIDTH=800
    WINDOW_HEIGHT=600
    POS_X=$(( (WIDTH - WINDOW_WIDTH) / 2 ))
    POS_Y=$(( (HEIGHT - WINDOW_HEIGHT) / 2 ))
    
    # Move e redimensiona a janela
    bspc node ".${SCRATCHPAD_CLASS}" -v ${POS_X} ${POS_Y}
    xdotool search --class "$SCRATCHPAD_CLASS" windowsize %1 $WINDOW_WIDTH $WINDOW_HEIGHT
}

# Função para fechar o scratchpad
close_scratchpad() {
    if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
        bspc node ".${SCRATCHPAD_CLASS}" -c
    fi
}

# Processa argumentos
case "$1" in
    "toggle")
        toggle_scratchpad
        ;;
    "show")
        if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=off
            bspc node ".${SCRATCHPAD_CLASS}" -f
        else
            create_scratchpad
        fi
        ;;
    "hide")
        if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=on
        fi
        ;;
    "close")
        close_scratchpad
        ;;
    "center")
        center_scratchpad
        ;;
    *)
        echo "Uso: $0 {toggle|show|hide|close|center}"
        echo "  toggle - Alterna entre mostrar/esconder o scratchpad"
        echo "  show   - Mostra o scratchpad (cria se não existir)"
        echo "  hide   - Esconde o scratchpad"
        echo "  close  - Fecha o scratchpad"
        echo "  center - Centraliza o scratchpad na tela"
        exit 1
        ;;
esac
