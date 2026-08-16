/// Minimal Server-Sent Events parser for a UTF-8 decoded byte stream.
///
/// It dispatches only complete events (blank-line framed), joins multiple
/// `data:` fields with a newline as required by SSE, ignores comments, and
/// preserves `[DONE]` as an application-level sentinel.
final class SseParser {
  const SseParser._();

  static Stream<String> parse(Stream<String> chunks) async* {
    var buffer = '';
    final data = <String>[];

    Future<String?> dispatch() async {
      if (data.isEmpty) return null;
      final value = data.join('\n');
      data.clear();
      return value;
    }

    Future<String?> consumeLine(String line) async {
      if (line.isEmpty) return dispatch();
      if (line.startsWith(':')) return null;

      final separator = line.indexOf(':');
      final field = separator == -1 ? line : line.substring(0, separator);
      var value = separator == -1 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'data') data.add(value);
      return null;
    }

    await for (final chunk in chunks) {
      buffer += chunk;
      while (true) {
        final lineEnd = buffer.indexOf('\n');
        if (lineEnd == -1) break;
        var line = buffer.substring(0, lineEnd);
        buffer = buffer.substring(lineEnd + 1);
        if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
        final event = await consumeLine(line);
        if (event != null) yield event;
      }
    }

    if (buffer.isNotEmpty) {
      final event = await consumeLine(
        buffer.endsWith('\r') ? buffer.substring(0, buffer.length - 1) : buffer,
      );
      if (event != null) yield event;
    }
    final finalEvent = await dispatch();
    if (finalEvent != null) yield finalEvent;
  }
}
