import 'dart:convert';

import 'package:http/http.dart' as http;

/// Роҳбари обу ҳаво аз телефони корбар ба Open-Meteo муроҷиат мекунад.
/// Ин роҳ Gemini ва Render-ро истифода намекунад.
class ChatAiWeatherService {
  static final RegExp _intent = RegExp(
    r'(обу\s*ҳаво|ҳавои|погода|прогноз\s*(?:погоды)?|weather|forecast)',
    caseSensitive: false,
  );

  static bool isWeatherQuestion(String prompt) => _intent.hasMatch(prompt);

  /// Агар дархост дар бораи обу ҳаво бошад, ҷавобро мустақим аз API мегирад.
  /// Барои дархостҳои дигар null бармегардонад.
  static Future<String?> answerIfWeather(String prompt) async {
    if (!isWeatherQuestion(prompt)) return null;

    final city = _extractCity(prompt);
    if (city == null || city.isEmpty) {
      return _isRussian(prompt)
          ? 'Чтобы проверить текущую погоду, напишите город, например: «Погода в Душанбе».'
          : _isTajik(prompt)
              ? 'Барои санҷидани обу ҳаво номи шаҳрро навис, масалан: «Обу ҳавои Душанбе».'
              : 'To check the current weather, include a city, for example: “Weather in Dushanbe”.';
    }

    try {
      final geoUri = Uri.https(
        'geocoding-api.open-meteo.com',
        '/v1/search',
        {'name': city, 'count': '1', 'language': 'en', 'format': 'json'},
      );
      final geoResponse = await http.get(geoUri).timeout(const Duration(seconds: 12));
      if (geoResponse.statusCode != 200) throw const _WeatherUnavailable();
      final geoData = jsonDecode(geoResponse.body);
      final results = geoData is Map<String, dynamic> ? geoData['results'] : null;
      if (results is! List || results.isEmpty || results.first is! Map<String, dynamic>) {
        return _noCity(city, prompt);
      }

      final place = results.first as Map<String, dynamic>;
      final latitude = place['latitude'];
      final longitude = place['longitude'];
      if (latitude is! num || longitude is! num) throw const _WeatherUnavailable();

      final forecastUri = Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
          'timezone': 'auto',
        },
      );
      final forecastResponse = await http.get(forecastUri).timeout(const Duration(seconds: 12));
      if (forecastResponse.statusCode != 200) throw const _WeatherUnavailable();
      final forecastData = jsonDecode(forecastResponse.body);
      if (forecastData is! Map<String, dynamic> ||
          forecastData['current'] is! Map<String, dynamic>) {
        throw const _WeatherUnavailable();
      }

      final current = forecastData['current'] as Map<String, dynamic>;
      final temp = current['temperature_2m'];
      final feels = current['apparent_temperature'];
      final humidity = current['relative_humidity_2m'];
      final wind = current['wind_speed_10m'];
      final rain = current['precipitation'];
      final code = current['weather_code'];
      if (temp is! num || feels is! num || humidity is! num || wind is! num || code is! num) {
        throw const _WeatherUnavailable();
      }

      final cityName = (place['name'] ?? city).toString();
      final country = (place['country'] ?? '').toString();
      final location = country.isEmpty ? cityName : '$cityName, $country';
      final condition = _condition(code.toInt(), prompt);
      final t = temp.round();
      final f = feels.round();
      final h = humidity.round();
      final w = wind.round();
      final precipitation = rain is num ? rain.toStringAsFixed(1) : '0.0';

      if (_isRussian(prompt)) {
        return 'Погода в $location: $condition. Температура: $t °C; ощущается как $f °C; влажность: $h%; ветер: $w км/ч; осадки: $precipitation мм.\nИсточник: Open-Meteo (текущие данные API).';
      }
      if (_isTajik(prompt)) {
        return 'Обу ҳавои $location: $condition. Ҳарорат: $t °C; ҳисшаванда: $f °C; намӣ: $h%; бод: $w км/соат; боришот: $precipitation мм.\nМанбаъ: Open-Meteo (маълумоти ҷории API).';
      }
      return 'Weather in $location: $condition. Temperature: $t °C; feels like: $f °C; humidity: $h%; wind: $w km/h; precipitation: $precipitation mm.\nSource: Open-Meteo (current API data).';
    } catch (_) {
      if (_isRussian(prompt)) {
        return 'Не удалось получить текущие данные о погоде из интернета. Попробуйте позже.';
      }
      if (_isTajik(prompt)) {
        return 'Маълумоти ҷории обу ҳаворо аз интернет гирифта натавонистам. Баъдтар боз кӯшиш кун.';
      }
      return 'I could not fetch live weather data. Please try again later.';
    }
  }

  static String? _extractCity(String prompt) {
    final patterns = [
      RegExp(
        r'.*(?:обу\s*ҳаво(?:и)?|ҳавои|погода(?:\s+(?:в|для))?|прогноз(?:\s+погоды)?(?:\s+(?:в|для))?|weather(?:\s+in)?|forecast(?:\s+for)?)\s*[:,-]?\s*(.+)$',
        caseSensitive: false,
      ),
      RegExp(r'.*\b(?:дар|в|in|for)\s+([\p{L} .\-]+)$', caseSensitive: false, unicode: true),
    ];

    String? city;
    for (var i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(prompt.trim());
      if (match != null) {
        city = (match.group(i == 0 ? 1 : 1) ?? '').trim();
        break;
      }
    }
    if (city == null || city.isEmpty) return null;

    city = city.replaceFirst(
      RegExp(r'^(?:дар|в|in|for|барои|сегодня|сейчас|имрӯз|ҳозир|today|now|tomorrow|пагоҳ)\s+', caseSensitive: false),
      '',
    );
    city = city.replaceAll(
      RegExp(r'\s+(?:сегодня|сейчас|имрӯз|ҳозир|today|now|tomorrow|пагоҳ|фардо)\b.*$', caseSensitive: false),
      '',
    );
    city = city.replaceAll(RegExp(r'[?!.,:;]+$'), '').trim();
    if (city.length > 80) city = city.substring(0, 80).trim();
    return city.isEmpty ? null : city;
  }

  static bool _isTajik(String text) =>
      RegExp(r'(обу\s*ҳаво|ҳавои|[ҒғҚқҲҳҶҷӢӣӮӯ])', caseSensitive: false).hasMatch(text);

  static bool _isRussian(String text) =>
      RegExp(r'(погода|прогноз|[А-Яа-яЁё])', caseSensitive: false).hasMatch(text) &&
      !_isTajik(text);

  static String _noCity(String city, String prompt) {
    if (_isRussian(prompt)) return 'Не нашёл город «$city». Проверьте написание или попробуйте название латиницей.';
    if (_isTajik(prompt)) return 'Шаҳри «$city» ёфт нашуд. Номашро санҷ ё бо ҳарфҳои лотинӣ навис.';
    return 'I could not find the city “$city”. Check the spelling or try its Latin spelling.';
  }

  static String _condition(int code, String prompt) {
    final tajik = _isTajik(prompt);
    final russian = _isRussian(prompt);
    if (code == 0) return tajik ? 'осмони соф' : russian ? 'ясно' : 'clear sky';
    if ([1, 2].contains(code)) return tajik ? 'абрҳои кам' : russian ? 'небольшая облачность' : 'mainly clear / partly cloudy';
    if (code == 3) return tajik ? 'абрнок' : russian ? 'облачно' : 'overcast';
    if ([45, 48].contains(code)) return tajik ? 'туман' : russian ? 'туман' : 'fog';
    if ([51, 53, 55, 56, 57].contains(code)) return tajik ? 'борони реза' : russian ? 'морось' : 'drizzle';
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return tajik ? 'борон' : russian ? 'дождь' : 'rain';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return tajik ? 'барф' : russian ? 'снег' : 'snow';
    if ([95, 96, 99].contains(code)) return tajik ? 'раъду барқ' : russian ? 'гроза' : 'thunderstorm';
    return tajik ? 'ҳолати номаълуми ҳаво' : russian ? 'неизвестное состояние погоды' : 'unknown weather conditions';
  }
}

class _WeatherUnavailable implements Exception {
  const _WeatherUnavailable();
}
