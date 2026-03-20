#!/bin/bash

# --- Configurare ---
CACHE_FILE="/tmp/vremea_cache.txt"
LAST_UPDATE="/tmp/vremea_last_update"
USER_NAME=$(whoami)
DATA_CURENTA=$(date +"%d %b | %H:%M")

# Coordonate Giroc/Timisoara (Modifică dacă te muți)
LAT="45.71"
LON="21.23"

# Inițializare fișiere (Previne eroarea "No such file")
touch "$CACHE_FILE" "$LAST_UPDATE"

update_weather() {
    # Folosim Open-Meteo (fără cheie API, stabil, răspuns JSON)
    RESPONSE=$(curl -s -m 5 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m")
    
    if [[ -n "$RESPONSE" && "$RESPONSE" != *"error"* ]]; then
        # Extragem datele folosind grep/sed (ca să nu depindem de jq)
        TEMP=$(echo "$RESPONSE" | grep -oP '"temperature_2m":\K-?[0-9.]+')
        HUMIDITY=$(echo "$RESPONSE" | grep -oP '"relative_humidity_2m":\K[0-9]+')
        PRECIP=$(echo "$RESPONSE" | grep -oP '"precipitation":\K[0-9.]+')
        WIND=$(echo "$RESPONSE" | grep -oP '"wind_speed_10m":\K[0-9.]+')
        
        # Formatăm rezultatul pentru afișare
        echo "+${TEMP}°C 󰖘 ${HUMIDITY}% 󰖝 ${WIND}km/h" > "$CACHE_FILE"
        date +%s > "$LAST_UPDATE"
    fi
}

# --- Logică Cache ---
if [ ! -s "$CACHE_FILE" ]; then
    update_weather
else
    ULTIMA=$(cat "$LAST_UPDATE" 2>/dev/null || echo 0)
    ACUM=$(date +%s)
    # Update la 30 min în fundal
    if [ $((ACUM - ULTIMA)) -gt 1800 ]; then
        update_weather > /dev/null 2>&1 &
    fi
fi

VREMEA_INFO=$(cat "$CACHE_FILE" 2>/dev/null)
[[ -z "$VREMEA_INFO" ]] && VREMEA_INFO="󰖐 Sincronizare..."

# --- Calcul Resurse ---
RAM_VAL=$(free -h | awk '/^Mem:/ {print $3}')
DISK_VAL=$(df -h / | awk 'NR==2 {print $4}')

# --- Afișare Dashboard ---
clear
echo -e "\e[38;5;208m╭────────────────────────────────────────────────────────────────╮\e[0m"
echo -e "\e[38;5;208m│\e[0m  \e[1;32m󱄅 Salut, $USER_NAME!\e[0m  \e[1;37m󰃭 $DATA_CURENTA\e[0m"
echo -e "\e[38;5;208m├────────────────────────────────────────────────────────────────┤\e[0m"
echo -e "\e[38;5;208m│\e[0m  \e[1;34m󰍛 RAM:\e[0m $RAM_VAL  \e[38;5;208m│\e[0m  \e[1;34m󰋊 Disc:\e[0m $DISK_VAL"
echo -e "\e[38;5;208m│\e[0m  \e[1;35m󰖐 Vremea:\e[0m $VREMEA_INFO"
echo -e "\e[38;5;208m╰────────────────────────────────────────────────────────────────╯\e[0m"
