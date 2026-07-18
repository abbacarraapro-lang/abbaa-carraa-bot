import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ============================================================
/// Abba Carraa Pro - Telegram Bot (WEBHOOK version, Render free tier)
/// ============================================================
/// Kun bot-ichi seerabuu (polling) osoo hin taane, Telegram irraa
/// ergaa yeroo dhufu (webhook) qofa deebii kenna - Render Web
/// Service bilisaa waliin walsimu.

final String botToken = Platform.environment['BOT_TOKEN'] ?? '';
final String apiBase = 'https://api.telegram.org/bot$botToken';

// Cloud Function URL kee kan moo'aa dhumaa (latest winner) kennu
const String latestWinnerEndpoint =
    'https://REGION-PROJECT.cloudfunctions.net/getLatestWinner';

// Linkii app kee (Play Store ykn deep link)
const String appDownloadLink =
    'https://play.google.com/store/apps/details?id=com.yourpackage.abbaacarraapro';

Future<void> main() async {
  if (botToken.isEmpty) {
    print('⚠️  BOT_TOKEN environment variable hin argamne!');
  }

  final port = int.parse(Platform.environment['PORT'] ?? '10000');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🤖 Abba Carraa Pro Bot server port $port irratti jalqabame');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  try {
    if (request.method == 'POST' && request.uri.path == '/webhook') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);

      // Deebii dafaa Telegram-iif kenni, ergasii ergaa process godhi
      request.response
        ..statusCode = 200
        ..write('OK');
      await request.response.close();

      await _handleUpdate(data);
    } else if (request.uri.path == '/') {
      request.response
        ..statusCode = 200
        ..write('✅ Abba Carraa Pro Bot server ni jira');
      await request.response.close();
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  } catch (e) {
    print('Dogoggora request keessatti: $e');
    try {
      request.response.statusCode = 500;
      await request.response.close();
    } catch (_) {}
  }
}

Future<void> _handleUpdate(Map<String, dynamic> data) async {
  final message = data['message'];
  if (message == null) return;

  final chatId = message['chat']['id'];
  final text = (message['text'] ?? '').toString().trim();

  await _handleCommand(chatId, text);
}

Future<void> _handleCommand(int chatId, String text) async {
  if (text.startsWith('/start')) {
    await _sendMessage(
      chatId,
      '👋 Baga nagaan dhufte!\n\n'
      '🎡 *Abbaa Carraa Pro* - Spin Wheel App Itoophiyaa keessatti hojjetame.\n\n'
      'Ajajawwan (commands):\n'
      '/play - App download godhi\n'
      '/result - Moo\'aa dhumaa ilaali\n'
      '/help - Gargaarsa argadhu',
    );
  } else if (text.startsWith('/play')) {
    await _sendMessage(
      chatId,
      '📲 App kee asii download godhi:\n$appDownloadLink',
    );
  } else if (text.startsWith('/result')) {
    await _sendLatestWinner(chatId);
  } else if (text.startsWith('/help')) {
    await _sendMessage(
      chatId,
      'Gaaffii yoo qabaatte, admin @your_username tuqi.',
    );
  } else {
    await _sendMessage(chatId, "Ajaja hin beekamne. /help jedhii barbaadi.");
  }
}

Future<void> _sendLatestWinner(int chatId) async {
  try {
    final res = await http
        .get(Uri.parse(latestWinnerEndpoint))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final name = data['winnerName'] ?? 'Beekamu hin dandeenye';
      final prize = data['prize']?.toString() ?? '-';
      final time = data['timestamp'] ?? '';

      await _sendMessage(
        chatId,
        '🏆 *Moo\'aa Dhumaa*\n\n'
        'Maqaa: $name\n'
        'Badhaasa: $prize\n'
        'Yeroo: $time',
      );
    } else {
      await _sendMessage(
        chatId,
        'Amma odeeffannoo argachuu hin dandeenye, ammaan booda yaali.',
      );
    }
  } catch (e) {
    await _sendMessage(chatId, 'Dogoggora uumameera. Ammaan booda yaali.');
  }
}

Future<void> _sendMessage(int chatId, String text) async {
  final url = Uri.parse('$apiBase/sendMessage');
  await http.post(url, body: {
    'chat_id': chatId.toString(),
    'text': text,
    'parse_mode': 'Markdown',
  });
}
