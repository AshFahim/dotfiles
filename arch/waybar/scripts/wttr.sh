#!/usr/bin/env bash

# Helper function to extract JSON values using Python
json_get() {
    local json="$1"
    local path="$2"
    python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data$path) if '$path' != '' else json.dumps(data))" <<< "$json" | sed 's/^"//;s/"$//'
}

json_get_raw() {
    local json="$1"
    local path="$2"
    python3 -c "import json, sys; data = json.load(sys.stdin); result = data$path; print(result if isinstance(result, (int, float)) else json.dumps(result))" <<< "$json" | sed 's/^"//;s/"$//'
}

# Weather codes mapping (matching original Python script)
declare -A WEATHER_CODES=(
    ['113']=''
    ['116']=''
    ['119']=''
    ['122']=''
    ['143']=''
    ['176']='󰼳'
    ['179']='󰼴'
    ['182']='󰼵'
    ['185']='󰖗'
    ['200']=''
    ['227']=''
    ['230']=''
    ['248']=''
    ['260']=''
    ['263']=''
    ['266']=''
    ['281']=''
    ['284']=''
    ['293']='󰖗'
    ['296']='󰖗'
    ['299']=''
    ['302']=''
    ['305']=''
    ['308']=''
    ['311']=''
    ['314']=''
    ['317']=''
    ['320']=''
    ['323']=''
    ['326']=''
    ['329']=''
    ['332']=''
    ['335']=''
    ['338']=''
    ['350']='󰼩'
    ['353']=''
    ['356']=''
    ['359']=''
    ['362']=''
    ['365']=''
    ['368']='󰖘'
    ['371']=''
    ['374']=''
    ['377']=''
    ['386']=''
    ['389']=''
    ['392']=''
    ['395']=''
)

# Function to format time
format_time() {
    local time_str="${1//00/}"
    if [ -z "$time_str" ]; then
        echo "00"
    else
        printf "%02d" "$time_str"
    fi
}

# Function to format temperature
format_temp() {
    local temp="$1"
    printf "%-3s" "${temp}°"
}

# Function to format chances
format_chances() {
    local hour_json="$1"
    local conditions=""
    
    declare -A chance_map=(
        ['chanceoffog']='Fog'
        ['chanceoffrost']='Frost'
        ['chanceofovercast']='Overcast'
        ['chanceofrain']='Rain'
        ['chanceofsnow']='Snow'
        ['chanceofsunshine']='Sunshine'
        ['chanceofthunder']='Thunder'
        ['chanceofwindy']='Wind'
    )
    
    for key in "${!chance_map[@]}"; do
        local value=$(json_get_raw "$hour_json" "['$key']")
        if [ -n "$value" ] && [ "$value" != "null" ] && [ "$value" -gt 0 ] 2>/dev/null; then
            if [ -n "$conditions" ]; then
                conditions="${conditions}, "
            fi
            conditions="${conditions}${chance_map[$key]} ${value}%"
        fi
    done
    
    echo "$conditions"
}

# Fetch weather data
WEATHER_DATA=$(curl -s --max-time 10 -H "User-Agent: curl/7.68.0" "https://wttr.in/Dhaka?format=j1" 2>/dev/null)

# Check if fetch was successful
if [ $? -ne 0 ] || [ -z "$WEATHER_DATA" ]; then
    echo '{"text":"󰖓 ?°","tooltip":"Weather unavailable"}'
    exit 0
fi

# Parse current condition
CURRENT=$(python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data['current_condition'][0]))" <<< "$WEATHER_DATA")
if [ -z "$CURRENT" ] || [ "$CURRENT" = "null" ]; then
    echo '{"text":"󰖓 ?°","tooltip":"Weather unavailable"}'
    exit 0
fi

WEATHER_CODE=$(json_get_raw "$CURRENT" "['weatherCode']")
FEELS_LIKE_C=$(json_get_raw "$CURRENT" "['FeelsLikeC']")
TEMP_F=$(json_get_raw "$CURRENT" "['temp_F']")
WEATHER_DESC=$(json_get_raw "$CURRENT" "['weatherDesc'][0]['value']")
WINDSPEED=$(json_get_raw "$CURRENT" "['windspeedKmph']")
HUMIDITY=$(json_get_raw "$CURRENT" "['humidity']")

# Get weather icon
ICON="${WEATHER_CODES[$WEATHER_CODE]:-?}"

# Format temperature with + prefix if needed
TEMPINT=$((FEELS_LIKE_C))
EXTRA_CHAR=""
if [ "$TEMPINT" -gt 0 ] && [ "$TEMPINT" -lt 10 ]; then
    EXTRA_CHAR="+"
fi

# Build text
TEXT="${ICON} ${EXTRA_CHAR}${FEELS_LIKE_C}°"

# Build tooltip
TOOLTIP="<b>${WEATHER_DESC} ${TEMP_F}°</b>\n"
TOOLTIP="${TOOLTIP}Feels like: ${FEELS_LIKE_C}°\n"
TOOLTIP="${TOOLTIP}Wind: ${WINDSPEED}Km/h\n"
TOOLTIP="${TOOLTIP}Humidity: ${HUMIDITY}%\n"

# Process weather days
CURRENT_HOUR=$(date +%H | sed 's/^0//')
CURRENT_HOUR=${CURRENT_HOUR:-0}

DAYS=$(python3 -c "import json, sys; data = json.load(sys.stdin); print(len(data['weather']))" <<< "$WEATHER_DATA")
for ((i=0; i<DAYS; i++)); do
    DAY=$(python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data['weather'][$i]))" <<< "$WEATHER_DATA")
    DATE=$(json_get_raw "$DAY" "['date']")
    MAX_TEMP=$(json_get_raw "$DAY" "['maxtempC']")
    MIN_TEMP=$(json_get_raw "$DAY" "['mintempC']")
    SUNRISE=$(json_get_raw "$DAY" "['astronomy'][0]['sunrise']")
    SUNSET=$(json_get_raw "$DAY" "['astronomy'][0]['sunset']")
    
    TOOLTIP="${TOOLTIP}\n<b>"
    if [ "$i" -eq 0 ]; then
        TOOLTIP="${TOOLTIP}Today, "
    elif [ "$i" -eq 1 ]; then
        TOOLTIP="${TOOLTIP}Tomorrow, "
    fi
    TOOLTIP="${TOOLTIP}${DATE}</b>\n"
    TOOLTIP="${TOOLTIP} ${MAX_TEMP}°  ${MIN_TEMP}° "
    TOOLTIP="${TOOLTIP} ${SUNRISE}   ${SUNSET}\n"
    
    # Process hourly data
    HOURS=$(python3 -c "import json, sys; data = json.load(sys.stdin); print(len(data['hourly']))" <<< "$DAY")
    for ((h=0; h<HOURS; h++)); do
        HOUR=$(python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data['hourly'][$h]))" <<< "$DAY")
        HOUR_TIME=$(json_get_raw "$HOUR" "['time']")
        HOUR_TIME_FORMATTED=$(format_time "$HOUR_TIME")
        HOUR_CODE=$(json_get_raw "$HOUR" "['weatherCode']")
        HOUR_FEELS_LIKE=$(json_get_raw "$HOUR" "['FeelsLikeC']")
        HOUR_DESC=$(json_get_raw "$HOUR" "['weatherDesc'][0]['value']")
        
        # Skip past hours for today
        if [ "$i" -eq 0 ]; then
            HOUR_INT=$((HOUR_TIME_FORMATTED))
            if [ "$HOUR_INT" -lt "$CURRENT_HOUR" ]; then
                continue
            fi
        fi
        
        HOUR_ICON="${WEATHER_CODES[$HOUR_CODE]:-?}"
        HOUR_TEMP_FORMATTED=$(format_temp "$HOUR_FEELS_LIKE")
        HOUR_CHANCES=$(format_chances "$HOUR")
        
        TOOLTIP="${TOOLTIP}${HOUR_TIME_FORMATTED} ${HOUR_ICON} ${HOUR_TEMP_FORMATTED} ${HOUR_DESC}, ${HOUR_CHANCES}\n"
    done
done

# Output JSON using Python
# Pass tooltip via stdin to avoid shell escaping issues with newlines
printf '%s' "$TOOLTIP" | python3 -c "
import json
import sys

text = sys.argv[1]
tooltip = sys.stdin.read()

# Replace literal backslash-n (the two characters: backslash and n) with actual newlines
# In Python string literal: '\\\\n' represents the two-character sequence backslash-n
tooltip = tooltip.replace(r'\\n', '\n')

output = {
    'text': text,
    'tooltip': tooltip
}

print(json.dumps(output))
" "$TEXT"
