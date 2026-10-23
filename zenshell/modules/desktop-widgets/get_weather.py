import urllib.request
import json

def get_weather():
    try:
        req = urllib.request.Request("https://wttr.in/?format=j1", headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req, timeout=5).read().decode('utf-8')
        data = json.loads(response)
        
        current = data['current_condition'][0]
        weather = data['weather'][0]
        
        temp = current['temp_C']
        desc = current['weatherDesc'][0]['value']
        code = current['weatherCode']
        high = weather['maxtempC']
        low = weather['mintempC']
        
        icons = {
            '113': '󰖙', # Clear/Sunny
            '116': '󰖕', # Partly Cloudy
            '119': '󰖐', # Cloudy
            '122': '󰖐', # Overcast
            '143': '󰖑', # Mist
            '176': '󰖗', # Patchy rain
            '200': '󰖓', # Thundery outbreaks
            '248': '󰖑', # Fog
            '260': '󰖑', # Freezing fog
            '263': '󰖗', # Patchy light drizzle
            '266': '󰖗', # Light drizzle
            '281': '󰖗', # Freezing drizzle
            '284': '󰖗', # Heavy freezing drizzle
            '293': '󰖗', # Patchy light rain
            '296': '󰖗', # Light rain
            '299': '󰖖', # Moderate rain at times
            '302': '󰖖', # Moderate rain
            '305': '󰖖', # Heavy rain at times
            '308': '󰖖', # Heavy rain
            '311': '󰖗', # Light freezing rain
            '314': '󰖖', # Heavy freezing rain
            '317': '󰖗', # Light sleet
            '320': '󰖖', # Moderate or heavy sleet
            '323': '󰖘', # Patchy light snow
            '326': '󰖘', # Light snow
            '329': '󰖘', # Patchy moderate snow
            '332': '󰖘', # Moderate snow
            '335': '󰖘', # Patchy heavy snow
            '338': '󰖘', # Heavy snow
            '350': '󰖘', # Ice pellets
            '353': '󰖗', # Light rain shower
            '356': '󰖖', # Moderate or heavy rain shower
            '359': '󰖖', # Torrential rain shower
            '362': '󰖗', # Light sleet showers
            '365': '󰖖', # Moderate or heavy sleet showers
            '368': '󰖘', # Light snow showers
            '371': '󰖘', # Moderate or heavy snow showers
            '374': '󰖘', # Light showers of ice pellets
            '377': '󰖘', # Moderate or heavy showers of ice pellets
            '386': '󰖓', # Patchy light rain with thunder
            '389': '󰖓', # Moderate or heavy rain with thunder
            '392': '󰖓', # Patchy light snow with thunder
            '395': '󰖓', # Moderate or heavy snow with thunder
        }
        
        icon = icons.get(code, '󰖐')
        
        print(json.dumps({
            "temp": f"{temp}°",
            "desc": desc,
            "icon": icon,
            "high": f"{high}°",
            "low": f"{low}°"
        }))
    except Exception as e:
        print(json.dumps({
            "temp": "--°",
            "desc": "Offline",
            "icon": "󰖐",
            "high": "",
            "low": ""
        }))

if __name__ == "__main__":
    get_weather()
