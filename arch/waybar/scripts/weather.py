#!/usr/bin/env python3

import json
import urllib.request
import urllib.error
from datetime import datetime
import sys

WEATHER_CODES = {
    '113': '',
    '116': '',
    '119': '',
    '122': '',
    '143': '',
    '176': '󰼳',
    '179': '󰼴',
    '182': '󰼵',
    '185': '󰖗',
    '200': '',
    '227': '',
    '230': '',
    '248': '',
    '260': '',
    '263': '',
    '266': '',
    '281': '',
    '284': '',
    '293': '󰖗',
    '296': '󰖗',
    '299': '',
    '302': '',
    '305': '',
    '308': '',
    '311': '',
    '314': '',
    '317': '',
    '320': '',
    '323': '',
    '326': '',
    '329': '',
    '332': '',
    '335': '',
    '338': '',
    '350': '󰼩',
    '353': '',
    '356': '',
    '359': '',
    '362': '',
    '365': '',
    '368': '󰖘',
    '371': '',
    '374': '',
    '377': '',
    '386': '',
    '389': '',
    '392': '',
    '395': ''
}

data = {}

try:
    req = urllib.request.Request("https://wttr.in/Dhaka?format=j1")
    req.add_header('User-Agent', 'curl/7.68.0')
    with urllib.request.urlopen(req, timeout=10) as response:
        weather = json.loads(response.read().decode('utf-8'))
except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, KeyError, Exception) as e:
    data['text'] = "󰖓 ?°"
    data['tooltip'] = "Weather unavailable"
    print(json.dumps(data))
    sys.exit(0)


def format_time(time):
    time_str = time.replace("00", "")
    if not time_str:
        return "00"
    return time_str.zfill(2)


def format_temp(temp):
    return (str(temp)+"°").ljust(3)


def format_chances(hour):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind"
    }

    conditions = []
    for event in chances.keys():
        if int(hour[event]) > 0:
            conditions.append(chances[event]+" "+hour[event]+"%")
    return ", ".join(conditions)

tempint = int(weather['current_condition'][0]['FeelsLikeC'])
extrachar = ''
if tempint > 0 and tempint < 10:
    extrachar = '+'


data['text'] = WEATHER_CODES[weather['current_condition'][0]['weatherCode']] + \
    " "+extrachar+weather['current_condition'][0]['FeelsLikeC']+"°"

data['tooltip'] = f"<b>{weather['current_condition'][0]['weatherDesc'][0]['value']} {weather['current_condition'][0]['temp_F']}°</b>\n"
data['tooltip'] += f"Feels like: {weather['current_condition'][0]['FeelsLikeC']}°\n"
data['tooltip'] += f"Wind: {weather['current_condition'][0]['windspeedKmph']}Km/h\n"
data['tooltip'] += f"Humidity: {weather['current_condition'][0]['humidity']}%\n"
for i, day in enumerate(weather['weather']):
    data['tooltip'] += f"\n<b>"
    if i == 0:
        data['tooltip'] += "Today, "
    if i == 1:
        data['tooltip'] += "Tomorrow, "
    data['tooltip'] += f"{day['date']}</b>\n"
    data['tooltip'] += f" {day['maxtempC']}°  {day['mintempC']}° "
    data['tooltip'] += f" {day['astronomy'][0]['sunrise']}  {day['astronomy'][0]['sunset']}\n"
    for hour in day['hourly']:
        if i == 0:
            hour_time = int(format_time(hour['time']))
            current_hour = datetime.now().hour
            if hour_time < current_hour:
                continue
        data['tooltip'] += f"{format_time(hour['time'])} {WEATHER_CODES[hour['weatherCode']]} {format_temp(hour['FeelsLikeC'])} {hour['weatherDesc'][0]['value']}, {format_chances(hour)}\n"


print(json.dumps(data))