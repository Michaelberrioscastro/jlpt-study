import 'dart:convert';

import 'package:http/http.dart' as http;

import '../study/study_catalog.dart';

class SenseiReply {
  final String text;
  final List<String> suggestions;

  const SenseiReply(this.text, {this.suggestions = const <String>[]});
}

class SenseiService {
  const SenseiService._();

  static const endpoint = String.fromEnvironment('SENSEI_API_URL');
  static const apiKey = String.fromEnvironment('SENSEI_API_KEY');
  static const model = String.fromEnvironment('SENSEI_MODEL', defaultValue: 'gpt-4o-mini');

  static bool get isOnlineConfigured => endpoint.isNotEmpty;

  static Future<SenseiReply> answerOnline({
    required List<Map<String, String>> history,
    required String level,
    String contextDescription = '',
  }) async {
    if (endpoint.isEmpty) {
      return answer(
        history.last['content'] ?? '',
        level: level,
        contextDescription: contextDescription,
      );
    }

    final sessions = StudyCatalog.sessions.take(60).map((session) =>
        '${session.id}: ${session.titleJa} | ${session.titleEs} | ${session.focus}').join('\n');
    final system = '''Eres Sensei, un tutor de japonés amable y preciso dentro de una app JLPT.
Responde principalmente en español, conserva el japonés original y añade lectura o traducción cuando ayude.
El estudiante está en nivel $level. Explica con ejemplos claros, compara patrones cercanos y corrige errores con tacto.
No inventes que una sesión pertenece a otro libro. Si una duda no está en el contexto, dilo y razona desde el japonés estándar.
Contexto de la pantalla actual:
${contextDescription.isEmpty ? 'No hay una pantalla de estudio especifica activa.' : contextDescription}
Contexto de sesiones disponibles:
$sessions''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      ...history,
    ];

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': .45,
              'max_tokens': 700,
            }),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _networkFallback('El Sensei online respondio con ${response.statusCode}.');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = payload['choices'] as List<dynamic>?;
      final content = choices?.isNotEmpty == true
          ? ((choices!.first as Map<String, dynamic>)['message'] as Map<String, dynamic>)['content']?.toString()
          : null;
      if (content == null || content.trim().isEmpty) {
        return _networkFallback('La respuesta online llego vacia.');
      }
      return SenseiReply(content.trim(), suggestions: const ['Dame un ejemplo', 'Corrige mi frase', 'Explicalo mas simple']);
    } catch (_) {
      return _networkFallback('No pude conectar con internet ahora.');
    }
  }

  static SenseiReply _networkFallback(String reason) => SenseiReply(
        '$reason\n\nPuedo seguir ayudandote con el conocimiento local de la app mientras vuelve la conexion.',
        suggestions: const ['Que significa ほど?', 'Explicame ている', 'Busca vocabulario'],
      );

  static SenseiReply answer(String raw, {required String level, String contextDescription = ''}) {
    final input = raw.trim();
    final query = _normalize(input);

    if (query.isEmpty) {
      return const SenseiReply(
        'Escribe una duda y la vemos juntos. Puedes preguntarme por una gramatica, una palabra, un kanji o una frase completa.',
        suggestions: ['Que significa ほど?', 'Explicame ている', 'Busca una palabra'],
      );
    }

    if (_matches(query, ['hola', 'buenas', 'hey', 'こんにちは', 'やあ'])) {
      return const SenseiReply(
        'こんにちは. Soy tu Sensei de estudio. Puedo explicarte gramatica, buscar contenido de tus cursos y ayudarte a construir frases.',
        suggestions: ['Que significa ほど?', 'Busca vocabulario', 'Dame un ejemplo'],
      );
    }

    if (_matches(query, ['esto', 'esta frase', 'este ejercicio', 'pista', 'ayuda con esto', 'this'])) {
      if (contextDescription.isNotEmpty) {
        return SenseiReply(
          'Pista sobre lo que tienes delante:\n\n$contextDescription\n\nFijate primero en la estructura y en la relacion entre la frase japonesa y su significado. No mires la respuesta completa todavia: intenta identificar que parte expresa la idea principal.',
          suggestions: const ['Explicamelo paso a paso', 'Dame otro ejemplo', 'Que debo recordar?'],
        );
      }
      return const SenseiReply(
        'Puedo darte una pista, pero necesito que estes dentro de una leccion o que pegues aqui la frase que quieres revisar.',
        suggestions: ['Que significa ほど?', 'Dame un ejemplo', 'Busca vocabulario'],
      );
    }

    final grammar = _grammarAnswer(query);
    if (grammar != null) return grammar;

    final content = _contentAnswer(query, level);
    if (content != null) return content;

    if (_matches(query, ['ejemplo', 'ejemplos', 'frase', 'oracion', '例文'])) {
      return const SenseiReply(
        'Ejemplo:\n\n毎日、日本語を勉強するようにしています。\nIntento estudiar japones todos los dias.\n\nようにする expresa el esfuerzo o la decision de mantener un habito.',
        suggestions: ['Explicame ようにする', 'Dame otro ejemplo', 'Que significa しか'],
      );
    }

    if (_matches(query, ['ayuda', 'puedes hacer', 'que sabes', 'help'])) {
      return const SenseiReply(
        'Puedo ayudarte con:\n\n• gramatica N4/N3\n• vocabulario y kanji de tus cursos\n• traduccion de frases\n• ejemplos en japones\n• diferencias entre patrones\n• busqueda de sesiones por tema\n\nPrueba: “diferencia entre まで y までに”.',
        suggestions: ['Diferencia entre まで y までに', 'Que significa ことになる?', 'Busca kanji'],
      );
    }

    return SenseiReply(
      'Todavia no encuentro una explicacion directa para esa duda. Prueba a escribir el patron japones, una palabra concreta o una frase completa.\n\nTambien puedo buscarla dentro de tus sesiones de $level.',
      suggestions: ['Que significa ほど?', 'Busca vocabulario', 'Dame un ejemplo'],
    );
  }

  static SenseiReply? _grammarAnswer(String query) {
    if (_containsAny(query, ['ほど', 'hodo'])) {
      return const SenseiReply(
        'ほど indica grado o comparacion. En la estructura AはBほど〜ない significa “A no es tan 〜 como B”.\n\n例: 東京は大阪ほど暑くない。\nTokio no es tan caluroso como Osaka.\n\nTambien aparece con cantidades: これほど難しくない = no es tan dificil como esto.',
        suggestions: ['Explicame しか〜ない', 'Dame un ejemplo con ほど', 'Busca sesiones de ほど'],
      );
    }
    if (_containsAny(query, ['ている', 'teiru', 'te iru'])) {
      return const SenseiReply(
        'ている tiene tres usos frecuentes:\n\n1. Accion en progreso: 今、勉強しています。Estoy estudiando ahora.\n2. Estado resultante: ドアが開いています。La puerta esta abierta.\n3. Habito o situacion continua: 東京に住んでいます。Vivo en Tokio.\n\nMira el contexto para decidir el significado.',
        suggestions: ['Diferencia entre ている y てある', 'Dame ejercicios de ている', 'Busca vocabulario'],
      );
    }
    if (_containsAny(query, ['しか', 'shika'])) {
      return const SenseiReply(
        'しか〜ない significa “solo / no mas que” y siempre necesita una forma negativa.\n\n漢字は少ししか書けません。\nSolo puedo escribir unos pocos kanji.\n\n少しだけ es neutral; 少ししか〜ない enfatiza que la cantidad es limitada.',
        suggestions: ['Que significa だけ?', 'Diferencia entre しか y だけ', 'Busca sesiones de しか'],
      );
    }
    if (_containsAny(query, ['までに', 'made ni'])) {
      return const SenseiReply(
        'までに marca una fecha limite: “antes de / para”.\n\n9時までに来てください。\nVen antes de las 9.\n\nまで marca el limite de una accion: 9時まで勉強します。Estudio hasta las 9.',
        suggestions: ['Diferencia entre まで y までに', 'Dame un ejemplo', 'Busca sesiones de までに'],
      );
    }
    if (_containsAny(query, ['ようにする', 'ようになる', 'youni'])) {
      return const SenseiReply(
        'ようにする expresa una decision o esfuerzo habitual: “procurar hacer”.\n\n毎日、漢字を書くようにしています。\nProcuro escribir kanji todos los dias.\n\nようになる expresa un cambio: 日本語が話せるようになりました。He llegado a poder hablar japones.',
        suggestions: ['Diferencia entre ようにする y ようになる', 'Dame un ejemplo', 'Busca sesiones'],
      );
    }
    if (_containsAny(query, ['ことになる', 'ことにする', 'koto'])) {
      return const SenseiReply(
        'ことにする = decidir hacer algo.\nことになる = quedar decidido o resultar que algo ocurre, normalmente por una circunstancia externa.\n\n日本へ行くことにしました。Decidi ir a Japon.\n日本へ行くことになりました. Se decidio que ire a Japon.',
        suggestions: ['Explicame たことがある', 'Dame otro ejemplo', 'Busca sesiones'],
      );
    }
    if (_containsAny(query, ['たことがある', 'takotogaaru'])) {
      return const SenseiReply(
        'たことがある habla de una experiencia pasada: “haber hecho alguna vez”.\n\n日本へ行ったことがあります。\nHe estado en Japon alguna vez.\n\nPara negar: 行ったことがありません = nunca he ido.',
        suggestions: ['Dame un ejercicio', 'Que significa ことになる?', 'Busca sesiones'],
      );
    }
    return null;
  }

  static SenseiReply? _contentAnswer(String query, String level) {
    final sessions = StudyCatalog.sessions;
    final matches = sessions.where((session) {
      final haystack = _normalize('${session.titleJa} ${session.titleEs} ${session.focus}');
      return haystack.contains(query) || query.split(' ').where((word) => word.length > 2).any(haystack.contains);
    }).take(3).toList();

    if (matches.isEmpty && _matches(query, ['vocabulario', 'palabra', 'palabras', '語彙', 'tango'])) {
      return SenseiReply(
        'Para estudiar vocabulario, abre uno de tus cursos de Vocabulario desde LIBRO. En este momento tu ruta activa contiene ${sessions.length} sesiones y puedo localizar temas concretos cuando escribes una palabra o foco.',
        suggestions: ['Busca una palabra concreta', 'Que significa ほど?', 'Dame un ejemplo'],
      );
    }

    if (matches.isEmpty && _matches(query, ['kanji', '漢字'])) {
      return SenseiReply(
        'Para estudiar kanji, abre el curso de Kanji asociado a tu libro desde LIBRO. Puedo ayudarte a relacionar un kanji con su lectura, significado y una frase cuando me lo escribas.',
        suggestions: ['Explicame este kanji: 学', 'Busca vocabulario', 'Dame un ejemplo'],
      );
    }

    if (matches.isEmpty) return null;

    final lines = matches.map((session) => '• Dia ${session.day}: ${session.titleJa} — ${session.focus}').join('\n');
    return SenseiReply(
      'He encontrado esto en tus sesiones de $level:\n\n$lines\n\nSi quieres, escribe la frase japonesa y te explico sus partes.',
      suggestions: ['Explicame la frase', 'Dame un ejemplo', 'Que diferencia hay?'],
    );
  }

  static bool _matches(String query, List<String> terms) => terms.any(query.contains);

  static bool _containsAny(String query, List<String> terms) => terms.any(query.contains);

  static String _normalize(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[。、！？!?.,:;]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
