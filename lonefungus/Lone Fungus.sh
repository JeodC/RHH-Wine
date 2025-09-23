#!/bin/bash

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR=/$directory/ports/lone_fungus
EXEC="Lone Fungus.exe"

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Display loading splash
$ESUDO $GAMEDIR/splash "$GAMEDIR/splash.png" 30000 &

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export WINEDEBUG=-all

export DXVK_HUD=1

# Determine architecture
if file "$GAMEDIR/data/$EXEC" | grep -q "PE32" && ! file "$GAMEDIR/data/$EXEC" | grep -q "PE32+"; then
    export WINEARCH=win32
    export WINEPREFIX=~/.wine32
elif file "$GAMEDIR/data/$EXEC" | grep -q "PE32+"; then
    export WINEPREFIX=~/.wine64
else
    echo "Unknown file format"
fi

# Install dependencies
if ! winetricks list-installed | grep -q "^dxvk$"; then
    pm_message "Installing dependencies."
    winetricks dxvk
fi

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories "$WINEPREFIX/drive_c/users/root/AppData/LocalLow/Andrew Shouldice/Secret Legend" "$GAMEDIR/config"

# Config Setup
mkdir -p $GAMEDIR/config
bind_directories ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1674780/pfx/drive_c/users/steamuser/AppData/Local/LoneFungus "$GAMEDIR/config"

# Run the game
#$GPTOKEYB "$EXEC" -c "$GAMEDIR/mouse.gptk" &
$GPTOKEYB "$EXEC" -c "$GAMEDIR/lonefungus.gptk" &
box64 wine "$GAMEDIR/data/$EXEC"

