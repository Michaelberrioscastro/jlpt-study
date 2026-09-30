import '../somatome/lesson_catalog.dart';

abstract final class ShinKanzenN4ReadingCatalog {
  static const totalSessions = 21;

  static const sessions = <SessionInfo>[
    SessionInfo(id:'SKN4P1U01',week:1,day:1,type:'reading_skill',titleJa:'文の切れ目',titleEs:'Cortes dentro de las oraciones',focus:'Reconocer dónde se separan las partes de una oración larga',pages:[4,4],review:false),
    SessionInfo(id:'SKN4P1U02',week:1,day:2,type:'reading_skill',titleJa:'説明する部分＋名詞',titleEs:'Partes que explican a un sustantivo',focus:'Identificar modificadores nominales',pages:[5,5],review:false),
    SessionInfo(id:'SKN4P1U03',week:1,day:3,type:'reading_skill',titleJa:'だれがしたか',titleEs:'Quién realizó la acción',focus:'Identificar agente, acción y objeto',pages:[6,6],review:false),
    SessionInfo(id:'SKN4P1U04',week:1,day:4,type:'reading_skill',titleJa:'書いた人の気持ち',titleEs:'La actitud o sentimiento del autor',focus:'Detectar expresiones de valoración positiva y negativa',pages:[7,7],review:false),
    SessionInfo(id:'SKN4P1U05',week:1,day:5,type:'reading_skill',titleJa:'前後関係からわかる意味',titleEs:'Significado a partir del contexto',focus:'Inferir significado mediante las oraciones anterior y posterior',pages:[8,8],review:false),
    SessionInfo(id:'SKN4P1U06',week:1,day:6,type:'reading_skill',titleJa:'「これ」「それ」など',titleEs:'Referencias como これ y それ',focus:'Identificar a qué se refiere una expresión demostrativa',pages:[9,9],review:false),
    SessionInfo(id:'SKN4P1U07',week:1,day:7,type:'reading_skill',titleJa:'接続の表現',titleEs:'Expresiones conectivas',focus:'Reconocer la relación anunciada por un conector',pages:[10,10],review:false),
    SessionInfo(id:'SKN4P1U08',week:1,day:8,type:'reading_skill',titleJa:'丁寧体と普通体',titleEs:'Estilo cortés y estilo informal',focus:'Reconocer diferencias entre 丁寧体 y 普通体',pages:[11,12],review:false),

    SessionInfo(id:'SKN4P2U01',week:2,day:1,type:'short_text',titleJa:'短文1（メモ）',titleEs:'Texto corto 1 · Nota',focus:'Comprensión de notas breves',pages:[16,17],review:false),
    SessionInfo(id:'SKN4P2U02',week:2,day:2,type:'short_text',titleJa:'短文2（メール）',titleEs:'Texto corto 2 · Correo electrónico',focus:'Comprensión de correos breves',pages:[18,19],review:false),
    SessionInfo(id:'SKN4P2U03',week:2,day:3,type:'short_text',titleJa:'短文3（注意書き）',titleEs:'Texto corto 3 · Aviso',focus:'Comprensión de instrucciones y advertencias',pages:[20,21],review:false),
    SessionInfo(id:'SKN4P2U04',week:2,day:4,type:'short_text',titleJa:'短文4（説明文）',titleEs:'Texto corto 4 · Texto explicativo',focus:'Localizar información explícita en una explicación breve',pages:[22,23],review:false),
    SessionInfo(id:'SKN4P2U05',week:2,day:5,type:'short_text',titleJa:'短文5（エッセイ）',titleEs:'Texto corto 5 · Ensayo breve',focus:'Comprender la idea principal de un texto breve',pages:[24,25],review:false),
    SessionInfo(id:'SKN4P2U06',week:2,day:6,type:'medium_text',titleJa:'中文1（エッセイ）',titleEs:'Texto medio 1 · Ensayo',focus:'Responder varias preguntas sobre un texto de longitud media',pages:[26,29],review:false),
    SessionInfo(id:'SKN4P2U07',week:2,day:7,type:'medium_text',titleJa:'中文2（説明文）',titleEs:'Texto medio 2 · Explicación',focus:'Seguir información y relaciones dentro de un texto medio',pages:[30,35],review:false),
    SessionInfo(id:'SKN4P2U08',week:2,day:8,type:'information',titleJa:'情報検索1（案内）',titleEs:'Búsqueda de información 1 · Guía',focus:'Buscar rápidamente información relevante en una guía',pages:[36,39],review:false),
    SessionInfo(id:'SKN4P2U09',week:2,day:9,type:'information',titleJa:'情報検索2（案内）',titleEs:'Búsqueda de información 2 · Guía',focus:'Localizar datos concretos sin leer todo el texto',pages:[40,43],review:false),

    SessionInfo(id:'SKN4P3U01',week:3,day:1,type:'multiple_questions',titleJa:'内容理解（短文）',titleEs:'Comprensión del contenido · textos cortos',focus:'Resolver cuatro preguntas sobre textos breves',pages:[46,63],review:false),
    SessionInfo(id:'SKN4P3U02',week:3,day:2,type:'multiple_questions',titleJa:'内容理解（中文）',titleEs:'Comprensión del contenido · texto medio',focus:'Resolver varias preguntas sobre un texto de aproximadamente 450 caracteres',pages:[64,83],review:false),
    SessionInfo(id:'SKN4P3U03',week:3,day:3,type:'multiple_questions',titleJa:'情報検索',titleEs:'Búsqueda de información',focus:'Resolver preguntas sobre guías, avisos y notificaciones',pages:[84,95],review:false),

    SessionInfo(id:'SKN4MOCK01',week:4,day:1,type:'mock',titleJa:'模擬試験',titleEs:'Simulacro de lectura N4',focus:'Simular el formato de lectura del JLPT N4 y gestionar el tiempo',pages:[96,103],review:true),
  ];

  static LessonPacket buildPacket(SessionInfo s) {
    final questionCount = s.type == 'short_text'
        ? 1
        : s.type == 'information'
            ? 2
            : s.type == 'medium_text' || s.type == 'multiple_questions'
                ? 4
                : s.type == 'mock'
                    ? 10
                    : 3;

    final steps = <LessonStep>[
      TeachStep(
        label: s.review ? 'SIMULACRO' : 'ENTRENAMIENTO',
        title: s.titleJa,
        body: s.titleEs + '.\n\nEsta sesión sigue la organización de 新完全マスター 読解 N4 y trabaja el objetivo indicado en las páginas de referencia.',
        pattern: s.focus,
        exampleJa: '読解 · pp. ' + s.pages[0].toString() + '–' + s.pages[1].toString(),
        exampleEs: 'Primero identifica qué información necesitas y después decide dónde buscarla.',
        tip: s.type == 'information'
            ? 'No necesitas leer cada palabra: identifica el propósito del texto y localiza el dato necesario.'
            : 'Busca relaciones, referentes y palabras clave antes de traducir mentalmente todo el texto.',
      ),
    ];

    for (var i = 1; i <= questionCount; i++) {
      steps.add(
        QuestionStep(
          id: s.id + '-q' + i.toString(),
          title: 'Práctica ' + i.toString(),
          question: _questionFor(s, i),
          options: const [
            'La información que responde directamente a la pregunta',
            'Un dato que aparece pero no responde a la pregunta',
            'Una interpretación basada solo en una palabra',
            'Una información que no aparece en el texto',
          ],
          answer: 0,
          explanation: 'La estrategia correcta es relacionar la pregunta con la información relevante del texto y evitar inferencias que el texto no permite.',
        ),
      );
    }

    return LessonPacket(s, steps);
  }

  static String _questionFor(SessionInfo s, int i) {
    if (s.type == 'reading_skill') {
      const prompts = [
        '¿Qué parte de la oración debes identificar primero para facilitar la lectura?',
        '¿Qué relación debes buscar entre una expresión y el sustantivo que explica?',
        '¿Qué conviene identificar para saber quién realizó una acción?',
        '¿Qué tipo de expresiones ayudan a reconocer la actitud del autor?',
        '¿Qué relación entre las oraciones puede ayudarte a inferir una palabra desconocida?',
        '¿Qué debes determinar cuando aparece これ o それ?',
        '¿Qué información anuncia normalmente un conector?',
        '¿Qué debes reconocer al pasar entre 丁寧体 y 普通体?',
      ];
      return prompts[(s.day - 1).clamp(0, prompts.length - 1)];
    }
    if (s.type == 'short_text') {
      return 'En un texto corto, ¿qué debes localizar para responder la pregunta ' + i.toString() + '?';
    }
    if (s.type == 'information') {
      return 'En una guía o aviso, ¿qué estrategia permite encontrar rápidamente el dato solicitado?';
    }
    if (s.type == 'medium_text') {
      return 'Al responder varias preguntas sobre un texto medio, ¿qué debes relacionar con cada pregunta?';
    }
    if (s.type == 'multiple_questions') {
      return 'Antes de responder la pregunta ' + i.toString() + ', ¿qué conviene localizar dentro del texto?';
    }
    return 'En el simulacro, ¿qué estrategia ayuda a administrar el tiempo de lectura?';
  }
}
