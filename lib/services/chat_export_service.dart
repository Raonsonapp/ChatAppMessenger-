import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

/// Содироти сӯҳбат ба файли матнӣ.
///
/// Файл дар ҳофизаи барнома сохта мешавад ва баъд корбар онро мефиристад —
/// ҳамон тарзе ки WhatsApp мекунад.
class ChatExportService {
  /// Ҳадди паёмҳо: сӯҳбати хеле дароз набояд хотираро пур кунад.
  static const int _maxMessages = 5000;

  /// Сӯҳбатро ба файл менависад ва роҳи онро бармегардонад.
  static Future<File> export({
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required String chatTitle,
    required Map<String, String> nameByUid,
  }) async {
    final snapshot = await messagesRef
        .orderBy('createdAt', descending: false)
        .limit(_maxMessages)
        .get();

    final buffer = StringBuffer()
      ..writeln(chatTitle)
      ..writeln('─' * 40)
      ..writeln();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['deleted'] ?? false) == true) continue;

      final at = (data['createdAt'] as Timestamp?)?.toDate();
      final sender = nameByUid[data['senderId']] ?? tr('k002');
      buffer.writeln('[${_stamp(at)}] $sender: ${_body(data)}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Матни паём ё тавсифи медиа.
  ///
  /// Худи файлҳо содир намешаванд — танҳо қайд мешавад, ки чӣ буд.
  static String _body(Map<String, dynamic> data) {
    final text = (data['text'] as String?)?.trim() ?? '';
    final type = data['mediaType'] as String?;
    if (type == null) return text.isEmpty ? '—' : text;

    final label = switch (type) {
      'image' || 'gif' => tr('k436'),
      'video' => tr('k437'),
      'audio' => tr('k438'),
      'document' => data['mediaName'] as String? ?? tr('k439'),
      'location' => tr('k440'),
      'poll' => '${tr('k441')}: ${data['pollQuestion'] ?? ''}',
      'sticker' => tr('k442'),
      _ => tr('k443'),
    };
    return text.isEmpty ? '<$label>' : '<$label> $text';
  }

  static String _stamp(DateTime? at) {
    if (at == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.day)}.${two(at.month)}.${at.year} ${two(at.hour)}:${two(at.minute)}';
  }
}
