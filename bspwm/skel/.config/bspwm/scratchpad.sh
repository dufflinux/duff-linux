#!/bin/bash

SCRATCHPAD_CLASS="scratchpad"
SCRATCHPAD_INSTANCE="scratchpad"

# Função para alternar o scratchpad
toggle_scratchpad() {
    if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
        if bspc query -N -n ".${SCRATCHPAD_CLASS}.hidden"; then
            # Se está escondido, mostra
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=off
            bspc node ".${SCRATCHPAD_CLASS}" -f
        else
            bspc node ".${SCRATCHPAD_CLASS}" -g hidden=on
        fi
    else
        create_scratchpad
    fi
}

create_scratchpad() {
    st -c "$SCRATCHPAD_CLASS" -n "$SCRATCHPAD_INSTANCE" -g 100x30+50+50 &
    
    sleep 0.2
    
    bspc node newest.local -t floating
    bspc node newest.local -g sticky=on
    bspc node newest.local -l above
    
    center_scratchpad
}

center_scratchpad() {
    eval $(xdotool getdisplaygeometry --shell)
    
    WINDOW_WIDTH=800
    WINDOW_HEIGHT=600
    POS_X=$(( (WIDTH - WINDOW_WIDTH) / 2 ))
    POS_Y=$(( (HEIGHT - WINDOW_HEIGHT) / 2 ))
    
    bspc node ".${SCRATCHPAD_CLASS}" -v ${POS_X} ${POS_Y}
    xdotool search --class "$SCRATCHPAD_CLASS" windowsize %1 $WINDOW_WIDTH $WINDOW_HEIGHT
}

close_scratchpad() {
    if bspc query -N -n ".${SCRATCHPAD_CLASS}"; then
        bspc node ".${SCRATCHPAD_CLASS}" -c
    fi
}

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
