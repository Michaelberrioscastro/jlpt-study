import '../somatome/lesson_catalog.dart';

abstract final class N3Catalog {
  static const totalSessions = 50;
  static final sessions = <SessionInfo>[
    ..._module(1, 'P1L', 'grammar', [
      ['課1 · ～とき', 'Cuando / mientras: ～うちに・～間／～間に・～てからでないと・～ところ', 'Tiempo y estado de una acción', 16, 17],
      ['課2 · ～と関係して', '～とおり・～どおり・～によって・～によっては・～たびに', 'Correspondencia, relación y repetición', 18, 19],
      ['課3 · 比べれば…～がいちばん', '～くらい／～ぐらい／～ほど・～くらい…はない・～くらいなら・～に限る', 'Comparación, grado y preferencia', 22, 23],
      ['課4 · ～とは違って', '～に対して・～反面・～一方（で）・～というより・～かわりに', 'Contraste y sustitución', 24, 25],
      ['課5 · ～だから', '～ためだ／～ために・～によって／～による・～から／～ことから・～おかげ・～せい・～のだから', 'Causa, razón y consecuencia', 30, 31],
      ['課6 · もし…', '～（の）なら・～ては／～（の）では・～さえ～ば・たとえ～ても・～ば／～たら／～なら', 'Condición, hipótesis y concesión', 32, 33],
    ]),
    ..._module(2, 'P1L', 'grammar', [
      ['課7 · ～だそうだ', '～ということだ／～とのことだ・～と言われている・～とか・～って・～という', 'Información transmitida y cita', 36, 37],
      ['課8 · 絶対～ない・必ず～とは言えない', '～はずがない／～わけがない・～とは限らない・～わけではない・～ないことはない・～ことは～が', 'Negación, límite y matización', 38, 39],
      ['課9 · ～と望む', '～てもらいたい・～ていただきたい・～てほしい・～（さ）せてもらいたい・～といい／～ばいい／～たらいい', 'Deseo, petición y expectativa', 44, 45],
      ['課10 · ～したほうがいい・～なさい', '命令・禁止・～こと・～べきだ／～べきではない・～たらどうか', 'Consejo, obligación y prohibición', 46, 47],
      ['課11 · ～（よう）と思う', '～ことにする／～ことにしている・～ようにする／～ようにしている・～（よ）うとする・～つもりだ', 'Intención, decisión y propósito', 50, 51],
      ['課12 · 敬語', '尊敬語・謙譲語1・謙譲語2・丁寧語', 'Keigo: respeto, humildad y cortesía', 52, 53],
    ], offset: 6),    ..._module(3, 'P1A', 'consolidation', [
      ['A · いろいろな働きをする助詞', 'Partículas con distintas funciones; contraste de も・しか y ぐらい／くらい・まで', 'Partículas', 58, 60],
      ['B · 助詞のような働きをする言葉', '～について・～に対して／～に対する・～によって・～にとって・～として', 'Palabras con función semejante a partículas', 62, 64],
      ['C · 「こと・の」の使い方', 'Diferencias y usos de こと y の', 'こと / の', 66, 68],
      ['D · 「よう」のいろいろな使い方', '～（かの）ようだ・～のようだ・～ように・～のように; contraste con ～ために', 'よう', 70, 72],
      ['E · 「わけ」のいろいろな使い方', '～わけだ・～というわけだ・～わけにはいかない・～ないわけにはいかない', 'わけ', 74, 78],
    ]),
    ..._module(4, 'P1A', 'consolidation', [
      ['F · 「ばかり」のいろいろな使い方', '～ばかり・～てばかりいる・～ばかりでなく・～ばかりだ・～たばかりだ', 'ばかり', 80, 82],
      ['G · 「する・なる」の整理', 'Usos de する y なる; ～ようにしている y ～ようになっている', 'する / なる', 84, 86],
      ['H · 「たら・ば・と・なら」の特別な使い方', 'Usos especiales y precauciones de ～たら・～ば・～と・～なら', 'Condicionales', 88, 90],
      ['I · 後に決まった表現が来る副詞', 'Adverbios que requieren expresiones determinadas después', 'Adverbios y colocaciones', 92, 94],
      ['J · 動詞や名詞の意味を広げる文法形式', 'Formas que amplían el significado de verbos y sustantivos; ～らしい vs ～ようだ／～みたいだ', 'Extensión de significado', 96, 100],
    ]),
    ..._module(5, 'P2L', 'sentence', [
      ['第2部・課1 · 文の組み立て－1「引用」', 'Construcción de oraciones con citas', '引用 / cita', 104, 105],
      ['第2部・課2 · 文の組み立て－2「名詞の説明」', 'Construcción y explicación de sustantivos', 'Modificación nominal', 106, 107],
      ['第2部・課3 · 文の組み立て－3', '～という・～といった', 'Expresiones ～という / ～といった', 108, 109],
      ['第2部・課4 · 文の組み立て－4', '決まった形', 'Patrones fijos', 110, 111],
      ['第2部・まとめ問題', 'Resumen y evaluación de las lecciones 1–4', 'Repaso Part 2', 112, 112],
    ]),
    ..._module(6, 'P3L', 'text', [
      ['課1 · 文の始めと終わりの対応', 'Correspondencia entre el comienzo y el final de una oración', 'Cohesión de la oración', 116, 117],
      ['課2 · 時制・～ている', 'Tiempo verbal y usos de ～ている', 'Tiempo / ～ている', 118, 119],
      ['課3 · 話者が見る位置を動かさない－1', '他動詞・自動詞', 'Transitivos / intransitivos', 122, 123],
      ['課4 · 話者が見る位置を動かさない－2', '～てくる・～ていく', 'Movimiento temporal / perspectiva', 124, 125],
      ['課5 · 話者が見る位置を動かさない－3', '受身・使役・使役受身', 'Pasiva / causativa / causativa-pasiva', 128, 129],
    ]),
    ..._module(7, 'P3L', 'text', [
      ['課6 · 話者が見る位置を動かさない－4', '～てあげる・～てもらう・～てくれる', 'Dar / recibir acciones', 130, 131],
      ['課7 · こ・そ・あ', 'Referencia y deixis dentro del texto', 'こ・そ・あ', 134, 135],
      ['課8 · は・が', 'Diferenciación de は y が en la cohesión textual', 'は / が', 136, 137],
      ['課9 · 接続表現', 'Expresiones conectivas para enlazar el texto', 'Conectores', 140, 141],
      ['課10 · 文章の雰囲気の統一', 'Mantener un tono y estilo uniformes en el texto', 'Tono textual', 142, 144],
    ]),
    ..._reviewModule(8, [
      ['まとめ問題（1課～4課）', 'Repaso acumulativo de Part 1, lecciones 1–4', 28, 29],
      ['まとめ問題（1課～8課）', 'Repaso acumulativo de Part 1, lecciones 1–8', 42, 43],
      ['まとめ問題（1課～12課）', 'Repaso acumulativo de Part 1, lecciones 1–12', 56, 57],
      ['まとめ問題（A～E）', 'Repaso de la organización A–E', 78, 79],
      ['まとめ問題（A～J）', 'Repaso de la organización A–J', 100, 101],
      ['まとめ問題（第2部 1課～4課）', 'Repaso de Part 2', 112, 113],
      ['まとめ問題（第3部 1課・2課）', 'Repaso de Part 3, lecciones 1–2', 120, 121],
      ['まとめ問題（第3部 3課・4課）', 'Repaso de Part 3, lecciones 3–4', 126, 127],
      ['まとめ問題（第3部 5課・6課）', 'Repaso de Part 3, lecciones 5–6', 132, 133],
      ['まとめ問題（第3部 7課・8課）', 'Repaso de Part 3, lecciones 7–8', 138, 139],
      ['まとめ問題（第3部 9課・10課）', 'Repaso de Part 3, lecciones 9–10', 144, 145],
      ['模擬試験 第1回', 'Simulacro de examen 1', 148, 151],
      ['模擬試験 第2回', 'Simulacro de examen 2', 152, 155],
    ]),
  ];

  static List<SessionInfo> _module(int week, String prefix, String type, List<List<dynamic>> rows, {int offset = 0}) => List.generate(rows.length, (i) {
    final r = rows[i];
    return SessionInfo(id: prefix + (i + 1 + offset).toString().padLeft(2, '0'), week: week, day: i + 1, type: type,
      titleJa: r[0] as String, titleEs: r[1] as String, focus: r[2] as String,
      pages: [r[3] as int, r[4] as int], review: type == 'consolidation');
  });

  static List<SessionInfo> _reviewModule(int week, List<List<dynamic>> rows) => List.generate(rows.length, (i) {
    final r = rows[i]; final mock = (r[0] as String).startsWith('模擬');
    return SessionInfo(id: 'R' + (i + 1).toString().padLeft(2, '0'), week: week, day: i + 1, type: mock ? 'mock' : 'review',
      titleJa: r[0] as String, titleEs: r[1] as String, focus: mock ? 'Simulacro JLPT N3' : 'Repaso acumulativo',
      pages: [r[2] as int, r[3] as int], review: true);
  });

  static LessonPacket buildPacket(SessionInfo s) => LessonPacket(s, [
    TeachStep(label: s.review ? (s.type == 'mock' ? 'SIMULACRO' : 'REPASO') : 'APRENDE',
      title: s.titleJa,
      body: s.titleEs + '.\n\nEsta sesión sigue la organización del libro y trabaja el contenido indicado en sus páginas de referencia.',
      pattern: s.focus,
      exampleJa: 'Contenido de referencia: pp. ' + s.pages[0].toString() + '–' + s.pages[1].toString(),
      exampleEs: 'Reconoce primero la función y después practica la selección de la forma adecuada.',
      tip: 'La app separa aprendizaje, discriminación y repaso para que vuelvas a encontrar la misma forma en contextos diferentes.'),
    QuestionStep(id: s.id + '-q1', title: 'Reconoce el objetivo',
      question: '¿Qué contenido corresponde a esta sesión?', options: [s.focus, 'Contenido de otro nivel', 'Pronunciación aislada'], answer: 0,
      explanation: 'Esta sesión está organizada alrededor de: ' + s.focus + '.'),
    QuestionStep(id: s.id + '-q2', title: 'Piensa en contexto',
      question: 'Antes de elegir una forma gramatical, ¿qué conviene considerar?',
      options: ['La función y el contexto de la oración o texto', 'Solo la traducción literal', 'Solo la longitud de la palabra'], answer: 0,
      explanation: 'El libro trabaja la selección de formas según significado, función, composición y, en Part 3, cohesión textual.'),
  ]);
}

