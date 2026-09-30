import 'dart:math';

import '../somatome/lesson_catalog.dart';

class StudyTerm {
  final String word, kana, meaning, exampleJa, exampleEs;
  const StudyTerm(this.word, this.kana, this.meaning, this.exampleJa, this.exampleEs);
}

class StudyVerb {
  final String dictionary, meaning, masu, nai, te;
  const StudyVerb(this.dictionary, this.meaning, this.masu, this.nai, this.te);
}

class StudyKanji {
  final String kanji, reading, meaning, word, wordReading, wordMeaning;
  const StudyKanji(this.kanji, this.reading, this.meaning, this.word, this.wordReading, this.wordMeaning);
}

abstract final class ExpandedContentService {
  static const _n4Terms = <StudyTerm>[
    StudyTerm('予定','よてい','plan; horario','来週の予定を確認します。','Reviso el plan de la próxima semana.'),
    StudyTerm('準備','じゅんび','preparación','旅行の準備をしています。','Estoy preparando el viaje.'),
    StudyTerm('約束','やくそく','promesa; cita','友達と駅で会う約束をしました。','Quedé con un amigo en la estación.'),
    StudyTerm('経験','けいけん','experiencia','日本で働いた経験があります。','Tengo experiencia trabajando en Japón.'),
    StudyTerm('習慣','しゅうかん','hábito','毎朝ニュースを見る習慣があります。','Tengo el hábito de mirar las noticias cada mañana.'),
    StudyTerm('連絡','れんらく','contacto; comunicación','着いたら連絡してください。','Avísame cuando llegues.'),
    StudyTerm('予約','よやく','reserva','ホテルを予約しておきました。','Dejé reservado el hotel.'),
    StudyTerm('必要','ひつよう','necesario','必要なものを準備します。','Preparo las cosas necesarias.'),
    StudyTerm('間に合う','まにあう','llegar a tiempo','急げば電車に間に合います。','Si me doy prisa, llego al tren a tiempo.'),
    StudyTerm('忘れる','わすれる','olvidar','忘れないようにメモします。','Tomo notas para no olvidarlo.'),
    StudyTerm('決める','きめる','decidir','旅行の日を決めました。','Decidí la fecha del viaje.'),
    StudyTerm('続ける','つづける','continuar','毎日少しずつ勉強を続けます。','Sigo estudiando un poco cada día.'),
    StudyTerm('調べる','しらべる','investigar; comprobar','分からない言葉を調べます。','Busco las palabras que no entiendo.'),
    StudyTerm('伝える','つたえる','comunicar','先生に予定を伝えました。','Le comuniqué el plan al profesor.'),
    StudyTerm('片付ける','かたづける','ordenar','部屋を片付けてから出かけます。','Ordeno la habitación antes de salir.'),
    StudyTerm('比べる','くらべる','comparar','二つの方法を比べます。','Comparo los dos métodos.'),
    StudyTerm('選ぶ','えらぶ','elegir','自分に合う本を選びます。','Elijo un libro adecuado para mí.'),
    StudyTerm('見つける','みつける','encontrar','駅の近くで店を見つけました。','Encontré una tienda cerca de la estación.'),
  ];

  static const _n3Terms = <StudyTerm>[
    StudyTerm('原因','げんいん','causa','問題の原因を調べています。','Estamos investigando la causa del problema.'),
    StudyTerm('結果','けっか','resultado','調査の結果を発表します。','Presentaremos los resultados de la investigación.'),
    StudyTerm('影響','えいきょう','influencia; efecto','天気は交通に影響します。','El clima afecta al transporte.'),
    StudyTerm('対策','たいさく','medida; contramedida','事故を防ぐ対策が必要です。','Se necesitan medidas para prevenir accidentes.'),
    StudyTerm('改善','かいぜん','mejora','サービスを改善する必要があります。','Es necesario mejorar el servicio.'),
    StudyTerm('状態','じょうたい','estado; condición','機械の状態を確認します。','Compruebo el estado de la máquina.'),
    StudyTerm('関係','かんけい','relación','二つの問題には関係があります。','Los dos problemas están relacionados.'),
    StudyTerm('目的','もくてき','propósito; objetivo','この調査の目的を説明します。','Explico el objetivo de esta investigación.'),
    StudyTerm('方法','ほうほう','método; manera','別の方法を考えてみましょう。','Pensemos en otro método.'),
    StudyTerm('場合','ばあい','caso; situación','雨の場合は中止します。','En caso de lluvia, se cancela.'),
    StudyTerm('判断','はんだん','juicio; decisión','状況を見て判断してください。','Decide después de observar la situación.'),
    StudyTerm('確認','かくにん','confirmación','内容をもう一度確認します。','Compruebo el contenido una vez más.'),
    StudyTerm('提案','ていあん','propuesta','新しい方法を提案しました。','Propuse un nuevo método.'),
    StudyTerm('解決','かいけつ','solución','問題を早く解決したいです。','Quiero resolver el problema pronto.'),
    StudyTerm('選択','せんたく','elección; selección','いくつかの選択肢があります。','Hay varias opciones.'),
    StudyTerm('変化','へんか','cambio','生活が大きく変化しました。','La vida cambió mucho.'),
    StudyTerm('維持','いじ','mantenimiento','健康を維持することが大切です。','Es importante mantener la salud.'),
    StudyTerm('期待','きたい','expectativa','新しい結果を期待しています。','Espero nuevos resultados.'),
  ];

  static const _n4Verbs = <StudyVerb>[
    StudyVerb('準備する','preparar','準備します','準備しない','準備して'),
    StudyVerb('予約する','reservar','予約します','予約しない','予約して'),
    StudyVerb('決める','decidir','決めます','決めない','決めて'),
    StudyVerb('続ける','continuar','続けます','続けない','続けて'),
    StudyVerb('調べる','investigar','調べます','調べない','調べて'),
    StudyVerb('伝える','comunicar','伝えます','伝えない','伝えて'),
    StudyVerb('選ぶ','elegir','選びます','選ばない','選んで'),
    StudyVerb('比べる','comparar','比べます','比べない','比べて'),
    StudyVerb('忘れる','olvidar','忘れます','忘れない','忘れて'),
    StudyVerb('間に合う','llegar a tiempo','間に合います','間に合わない','間に合って'),
    StudyVerb('手伝う','ayudar','手伝います','手伝わない','手伝って'),
    StudyVerb('戻る','volver','戻ります','戻らない','戻って'),
  ];

  static const _n3Verbs = <StudyVerb>[
    StudyVerb('改善する','mejorar','改善します','改善しない','改善して'),
    StudyVerb('確認する','comprobar','確認します','確認しない','確認して'),
    StudyVerb('判断する','juzgar; decidir','判断します','判断しない','判断して'),
    StudyVerb('取り組む','abordar; trabajar en','取り組みます','取り組まない','取り組んで'),
    StudyVerb('防ぐ','prevenir','防ぎます','防がない','防いで'),
    StudyVerb('達成する','lograr','達成します','達成しない','達成して'),
    StudyVerb('求める','buscar; exigir','求めます','求めない','求めて'),
    StudyVerb('認める','reconocer','認めます','認めない','認めて'),
    StudyVerb('支える','apoyar','支えます','支えない','支えて'),
    StudyVerb('避ける','evitar','避けます','避けない','避けて'),
    StudyVerb('変える','cambiar','変えます','変えない','変えて'),
    StudyVerb('比べる','comparar','比べます','比べない','比べて'),
  ];

  static const _n4Kanji = <StudyKanji>[
    StudyKanji('予','よ','de antemano','予定','よてい','plan'),
    StudyKanji('定','てい','determinar','決定','けってい','decisión'),
    StudyKanji('約','やく','promesa; aproximadamente','約束','やくそく','promesa'),
    StudyKanji('経','けい','pasar por; experiencia','経験','けいけん','experiencia'),
    StudyKanji('験','けん','examen; experiencia','試験','しけん','examen'),
    StudyKanji('習','しゅう','aprender','練習','れんしゅう','práctica'),
    StudyKanji('慣','かん','acostumbrarse','習慣','しゅうかん','hábito'),
    StudyKanji('連','れん','conectar','連絡','れんらく','contacto'),
    StudyKanji('調','ちょう','investigar; ajustar','調査','ちょうさ','investigación'),
    StudyKanji('必','ひつ','necesariamente','必要','ひつよう','necesario'),
    StudyKanji('要','よう','necesitar; esencial','必要','ひつよう','necesario'),
    StudyKanji('選','せん','elegir','選択','せんたく','selección'),
    StudyKanji('続','ぞく','continuar','続ける','つづける','continuar'),
    StudyKanji('比','ひ','comparar','比較','ひかく','comparación'),
  ];

  static const _n3Kanji = <StudyKanji>[
    StudyKanji('原','げん','origen','原因','げんいん','causa'),
    StudyKanji('因','いん','causa; factor','原因','げんいん','causa'),
    StudyKanji('結','けつ','resultado; unir','結果','けっか','resultado'),
    StudyKanji('果','か','resultado; fruto','結果','けっか','resultado'),
    StudyKanji('影','えい','influencia; sombra','影響','えいきょう','influencia'),
    StudyKanji('響','きょう','repercutir','影響','えいきょう','influencia'),
    StudyKanji('対','たい','opuesto; frente a','対策','たいさく','medida'),
    StudyKanji('策','さく','medida; plan','対策','たいさく','medida'),
    StudyKanji('改','かい','reformar; mejorar','改善','かいぜん','mejora'),
    StudyKanji('善','ぜん','bueno; virtud','改善','かいぜん','mejora'),
    StudyKanji('状','じょう','estado','状態','じょうたい','estado'),
    StudyKanji('態','たい','condición','状態','じょうたい','estado'),
    StudyKanji('関','かん','relación','関係','かんけい','relación'),
    StudyKanji('係','けい','relación; encargado','関係','かんけい','relación'),
  ];

  static const _notes = <String, String>{
    'しか～ない': 'Limita la cantidad o alcance y exige una forma negativa: la idea es “solo / nada más que”.',
    'までに': 'Marca un límite temporal: la acción debe completarse antes o, como máximo, en ese momento. Compáralo con まで, que expresa continuidad hasta un punto.',
    'たり～たり': 'Enumera acciones representativas sin afirmar que sean las únicas: “hacer cosas como A y B”.',
    '～し': 'Conecta razones o características que se acumulan: “además / y también”. Puede dejar implícita una conclusión.',
    'ところ': 'Con forma diccionario indica que la acción está por comenzar; ているところ indica que está ocurriendo; たところ indica que acaba de terminar.',
    '間に': '間 expresa un periodo; 間に suele presentar un acontecimiento que ocurre durante ese periodo.',
    '前に': 'Indica que una acción ocurre antes de otra. Con verbos se combina normalmente con la forma diccionario.',
    '後で': 'Indica que una acción ocurre después de otra; el contexto determina qué evento funciona como referencia temporal.',
    'たことがある': 'Expresa experiencia pasada: “haber hecho alguna vez”. No describe simplemente una acción terminada.',
    'ことにする': 'Presenta una decisión tomada por el sujeto: “decidir hacer / no hacer”.',
    'ことになる': 'Presenta una decisión, resultado o disposición que queda establecida; no necesariamente es una decisión personal del hablante.',
    'なければ': 'Las formas なければならない / なければいけない expresan obligación y parten de la forma negativa.',
    'なくてもいい': 'Expresa ausencia de obligación: no es necesario hacer algo.',
    'ておく': 'Expresa una acción realizada con anticipación para una necesidad futura.',
    'てしまう': 'Puede indicar finalización completa o una acción no deseada/accidental; el contexto decide el matiz.',
    'てくれる': 'Presenta una acción hecha para el beneficio del hablante o de alguien de su grupo.',
    'てもらう': 'Presenta al sujeto como receptor de un favor o como quien consigue que otra persona haga algo.',
    'てあげる': 'Presenta una acción que el sujeto realiza como beneficio para otra persona; la relación entre participantes importa.',
    'ようにする': 'Expresa esfuerzo o hábito para conseguir que algo ocurra: “procurar / asegurarse de”.',
    'ようになる': 'Describe un cambio de estado o capacidad: llegar a poder hacer algo o pasar a hacerlo.',
    'という': 'Puede introducir el nombre, contenido o caracterización de algo. El significado concreto depende de la construcción que sigue.',
    'そうだ': 'Puede expresar apariencia o información transmitida; la forma que precede ayuda a distinguir las funciones.',
    'らしい': 'Puede indicar información transmitida o una característica típica; conviene contrastarlo con ようだ y みたいだ.',
    'ほうがいい': 'Se usa para recomendar una opción. El contexto determina si se recomienda hacer algo o evitarlo.',
    'たら': 'Puede expresar condición, secuencia temporal o recomendación. El contexto decide la lectura.',
    'ば': 'Forma una condición y enfatiza la relación condicional entre dos hechos; no siempre es intercambiable con たら.',
    'なら': 'Presenta una condición o tema asumido a partir de la información disponible.',
    'のは': 'Nominaliza una acción para convertirla en tema o foco de una explicación, evaluación o razón.',
    'のが': 'Nominaliza una acción y permite tratarla como aquello que gusta, disgusta, resulta fácil, difícil, etc.',
    'のを': 'Nominaliza una acción para que pueda funcionar como objeto de otro verbo.',
    '見える': 'Expresa que algo se ve o resulta visible, normalmente como una percepción que ocurre sin control directo del sujeto.',
    '聞こえる': 'Expresa que un sonido se oye o llega al oído; no es lo mismo que “escuchar” intencionalmente.',
    'できる': 'Puede expresar capacidad o posibilidad, según el contexto y la construcción.',
    'しかたがない': 'Expresa que una situación no puede evitarse o que no hay otra solución: “no se puede evitar / no queda más remedio”.',
    '読み方': 'La forma 方 convierte la acción en una “manera de hacer algo”: 読み方 = manera de leer.',
    'てくださいませんか': 'Petición cortés que busca que otra persona realice una acción. Es más formal que una petición simple con てください.',
    'てもらいたい': 'Expresa el deseo de recibir una acción de otra persona; la persona que realiza la acción suele marcarse con に.',
    'てほしい': 'Expresa que el hablante desea que otra persona haga algo.',
    'と思う': 'Presenta una opinión, impresión o pensamiento del hablante.',
    'ようと思う': 'Expresa una intención o decisión que el hablante tiene en mente realizar.',
    'たら／ば／なら': 'Son condicionales relacionados pero no idénticos: たら es flexible y frecuente para condiciones/secuencia; ば enfatiza la relación condicional; なら parte de un supuesto o tema.',
    'ようだ': 'Expresa apariencia o una inferencia basada en indicios; se presenta como una interpretación del hablante.',
    'みたいだ': 'Expresa apariencia o comparación de forma más coloquial que ようだ.',
    'でしょう': 'Puede expresar una predicción, probabilidad o confirmación esperada según el contexto.',
    'すぎる': 'Indica exceso: “demasiado”. Se conecta con la raíz de adjetivos o verbos según la construcción.',
    'やすい': 'Indica facilidad para realizar una acción: Vます sin ます + やすい.',
    'にくい': 'Indica dificultad para realizar una acción: Vます sin ます + にくい.',
    '受身': 'La pasiva presenta al sujeto como receptor de la acción; に suele marcar al agente.',
    '使役': 'La causativa expresa que alguien hace o deja que otra persona realice una acción.',
    '使役受身': 'La causativa-pasiva presenta al sujeto como alguien obligado o llevado a realizar una acción por otra persona.',
    '自動詞': 'Un intransitivo describe un cambio o estado sin objeto directo; conviene estudiarlo junto a su pareja transitiva.',
    '他動詞': 'Un transitivo toma un objeto directo y describe una acción ejercida sobre algo.',
    'んです': 'Añade una función explicativa o de fondo: puede presentar una razón, aclaración o pedir una explicación según el contexto.',
    'かなあ': 'Expresa duda, reflexión o una pregunta que el hablante se hace a sí mismo.',
    'くらい': 'Indica aproximación o grado. En N3 también puede intensificar una comparación.',
    'ほど': 'Expresa grado, extensión o límite; ほど～ない y ば～ほど crean patrones comparativos importantes.',
    'とおり': 'Significa “tal como / de la manera que”. La forma que precede indica el modelo que se sigue.',
    'によって': 'Puede indicar medio, causa, criterio o agente, según la construcción. El contexto es imprescindible para elegir la lectura.',
    'たびに': 'Significa “cada vez que” y conecta una acción repetida con un resultado recurrente.',
    'ついでに': 'Expresa que una acción secundaria se realiza aprovechando la ocasión de hacer otra principal.',
    'に対して': 'Puede expresar “hacia / respecto de” o contraste entre dos elementos.',
    '反面': 'Presenta el otro lado o aspecto de una situación: “por otro lado / al mismo tiempo”.',
    '一方': 'Puede indicar contraste (“por otro lado”) o una tendencia que continúa en una dirección.',
    'というより': 'Corrige o ajusta una caracterización: “más que A, es B”.',
    'かわりに': 'Expresa sustitución, representación o intercambio: “en lugar de / a cambio de”.',
    'ためだ': 'Presenta una causa o finalidad según la construcción. En N3 es importante distinguir el valor causal del de propósito.',
    'おかげ': 'Presenta una causa con resultado positivo o beneficioso desde la perspectiva del hablante.',
    'せい': 'Presenta una causa asociada a un resultado negativo o no deseado.',
    'のだから': 'Refuerza una razón que el hablante considera evidente o relevante para la conclusión siguiente.',
    'さえ': 'Marca un elemento extremo para enfatizar que incluso ese caso está incluido.',
    'わけ': 'Organiza una interpretación lógica: わけだ puede expresar una conclusión, わけではない limita una interpretación y わけがない expresa imposibilidad.',
    'ばかり': 'Puede señalar cantidad, repetición o una situación que sigue avanzando; el patrón completo determina el significado.',
    'する・なる': 'する puede expresar que alguien produce un cambio; なる expresa que algo llega a ser o cambia de estado.',
    'といい': 'Expresa un deseo o esperanza: “ojalá / espero que”.',
    'べき': 'Expresa una obligación o norma desde la perspectiva del hablante; べきではない indica que algo no debería hacerse.',
    'ようとする': 'Combina la forma volitiva con とする para expresar intento o el momento en que alguien está a punto de hacer algo.',
    'ために': 'Puede expresar propósito (“para”) o causa (“debido a”); el contexto determina la interpretación.',
    'とは限らない': 'Niega una generalización absoluta: algo no es necesariamente cierto en todos los casos.',
    'わけではない': 'Niega una interpretación total: “no significa que / no es que”.',
    'ないことはない': 'Es una negación parcial: “no es que no pueda”; deja abierta la posibilidad, aunque puede haber dificultad.',
    'ないわけにはいかない': 'Expresa una obligación derivada de la situación: no se puede dejar de hacer algo.',
    'ていただきたい': 'Expresa una petición o deseo en registro muy cortés: se desea recibir la acción de otra persona.',
    '引用': 'Las construcciones de cita presentan palabras, pensamientos o información como contenido referido; el verbo y と ayudan a delimitar la cita.',
    '名詞の説明': 'Una oración puede modificar un sustantivo directamente. Para leerla, encuentra primero el sustantivo modificado y después reconstruye quién hace qué.',
    '決まった形': 'Los patrones fijos deben aprenderse como construcciones, pero conviene reconocer qué función cumple cada parte para no memorizarlos sin comprensión.',
  };
  static LessonPacket enrich(LessonPacket packet, {required String level, required String bookId}) {
    final terms = level == 'N3' ? _n3Terms : _n4Terms;
    final verbs = level == 'N3' ? _n3Verbs : _n4Verbs;
    final kanji = level == 'N3' ? _n3Kanji : _n4Kanji;
    final seed = _hash(packet.session.id);
    final t = List.generate(4, (i) => terms[(seed + i * 3) % terms.length]);
    final v = List.generate(2, (i) => verbs[(seed + i * 5) % verbs.length]);
    final k = List.generate(3, (i) => kanji[(seed + i * 2) % kanji.length]);
    final extra = <LessonStep>[];

    final note = _note(packet.session.focus);
    extra.add(TeachStep(
      label: note == null ? 'ESTRATEGIA' : 'EXPLICACIÓN EXTRA',
      title: note == null ? 'Cómo transferir lo aprendido' : 'Cómo pensar esta gramática',
      body: note ?? _strategy(bookId, packet.session.type, packet.session.focus),
      pattern: packet.session.focus,
      exampleJa: _example(packet.session.focus, v.first),
      exampleEs: 'Ejemplo original creado para practicar la idea en un contexto nuevo.',
      tip: 'Primero identifica la función comunicativa y después decide qué forma o estrategia encaja.',
    ));

    extra.add(TeachStep(
      label: 'VOCABULARIO',
      title: 'Palabras nuevas para esta sesión',
      body: t.map((x) => x.word + '（' + x.kana + '） — ' + x.meaning).join('\n') +
          '\n\nEstas palabras forman parte del banco activo del nivel y se reutilizan en distintas sesiones.',
      pattern: 'Palabra + lectura + uso',
      exampleJa: t.first.exampleJa,
      exampleEs: t.first.exampleEs,
      tip: 'Aprende cada palabra dentro de una oración y fíjate en las partículas que la acompañan.',
    ));

    extra.add(TeachStep(
      label: 'VERBO',
      title: 'Producción verbal',
      body: v.map((x) =>
          x.dictionary + ' — ' + x.meaning + '\n' +
          'ます: ' + x.masu + ' · ない: ' + x.nai + ' · て: ' + x.te
      ).join('\n\n'),
      pattern: 'Diccionario → ます → ない → て',
      exampleJa: v.first.te + 'ください。',
      exampleEs: 'Por favor, realiza esta acción.',
      tip: 'Reconocer las formas verbales te permite construir muchas expresiones gramaticales sin memorizarlas como bloques aislados.',
    ));

    extra.add(TeachStep(
      label: 'KANJI',
      title: 'Kanji dentro de palabras',
      body: k.map((x) =>
          x.kanji + '（' + x.reading + '） — ' + x.meaning +
          '\n' + x.word + '（' + x.wordReading + '） — ' + x.wordMeaning
      ).join('\n\n'),
      pattern: '漢字 → palabra → significado',
      exampleJa: k.first.word,
      exampleEs: k.first.wordMeaning,
      tip: 'La lectura puede cambiar según el compuesto; aprende el carácter dentro de una palabra real.',
    ));

    extra.add(QuestionStep(
      id: packet.session.id + '-extra-vocab',
      title: 'Vocabulario activo',
      question: '¿Qué significa 「' + t.first.word + '」 en esta oración?\n\n' + t.first.exampleJa,
      options: [t.first.meaning, t[1].meaning, t[2].meaning, t[3].meaning],
      answer: 0,
      explanation: '「' + t.first.word + '」 significa “' + t.first.meaning + '”.',
    ));

    extra.add(QuestionStep(
      id: packet.session.id + '-extra-verb',
      title: 'Forma verbal',
      question: '¿Cuál es la forma て de 「' + v.first.dictionary + '」?',
      options: [v.first.te, v.first.masu, v.first.nai, v[1].te],
      answer: 0,
      explanation: 'La forma て es 「' + v.first.te + '」.',
    ));

    extra.add(QuestionStep(
      id: packet.session.id + '-extra-kanji',
      title: 'Kanji en contexto',
      question: 'En 「' + k.first.word + '」, ¿qué idea aporta 「' + k.first.kanji + '」?',
      options: [k.first.meaning, k[1].meaning, k[2].meaning, 'No aporta significado'],
      answer: 0,
      explanation: 'En esta palabra, 「' + k.first.kanji + '」 se relaciona con “' + k.first.meaning + '”.',
    ));

    extra.add(QuestionStep(
      id: packet.session.id + '-extra-transfer',
      title: 'Transferencia',
      question: _transferQuestion(packet.session.type, t.first),
      options: _transferOptions(packet.session.type),
      answer: 0,
      explanation: 'La meta es aplicar el conocimiento a material nuevo, no depender de la misma oración del libro.',
    ));

    return LessonPacket(packet.session, [...packet.steps, ...extra]);
  }

  static LessonPacket randomize(LessonPacket packet) {
    final rng = Random();
    final steps = packet.steps.map<LessonStep>((s) {
      if (s is! QuestionStep || s.options.length < 2) return s;
      final order = List.generate(s.options.length, (i) => i)..shuffle(rng);
      return QuestionStep(
        id: s.id,
        title: s.title,
        question: s.question,
        options: order.map((i) => s.options[i]).toList(),
        answer: order.indexOf(s.answer),
        explanation: s.explanation,
      );
    }).toList();
    return LessonPacket(packet.session, steps);
  }

  static String? _note(String focus) {
    for (final e in _notes.entries) {
      if (focus.contains(e.key)) return e.value;
    }
    return null;
  }

  static String _example(String focus, StudyVerb v) {
    if (focus.contains('うちに')) return '忘れないうちに、' + v.te + 'メモしましょう。';
    if (focus.contains('までに')) return '明日までに' + v.te + 'ください。';
    if (focus.contains('たことがある')) return '日本で' + v.dictionary + 'たことがあります。';
    if (focus.contains('なければ')) return '今日中に' + v.nai + 'ければなりません。';
    if (focus.contains('ておく')) return '出かける前に' + v.te + 'おきます。';
    if (focus.contains('てしまう')) return '急いでいて、' + v.te + 'しまいました。';
    if (focus.contains('たら')) return '時間があったら、' + v.te + 'みましょう。';
    if (focus.contains('ようとする')) return v.dictionary + 'ようとしました。';
    if (focus.contains('ために')) return v.dictionary + 'ために、練習します。';
    if (focus.contains('たびに')) return v.dictionary + 'たびに、同じことを思い出します。';
    return '「' + focus.split('・').first + '」を新しい語彙と一緒に使ってみましょう。';
  }

  static String _strategy(String bookId, String type, String focus) {
    if (bookId == 'shinkanzen_n4_dokkai') {
      return (type == 'information' || type == 'multiple_questions')
          ? 'Convierte primero la pregunta en una búsqueda: identifica qué dato necesitas y localiza solo la información relevante. Después comprueba que el texto realmente responde a la pregunta.\n\nFoco: ' + focus
          : 'Para leer mejor, separa la oración en unidades, identifica quién hace qué y usa conectores y demostrativos para seguir las relaciones entre ideas. No traduzcas mentalmente cada palabra si la estructura ya te permite comprenderla.\n\nFoco: ' + focus;
    }
    if (type == 'sentence' || type == 'text') {
      return 'En esta parte conviene leer la relación entre oraciones: tiempo, referencia, causa, contraste, consecuencia y tono. El objetivo es comprender cómo una forma cambia la interpretación del texto.\n\nFoco: ' + focus;
    }
    return 'Amplía el punto en tres capas: significado, forma y contraste con expresiones parecidas. Después vuelve a practicarlo con vocabulario nuevo.\n\nFoco: ' + focus;
  }

  static String _transferQuestion(String type, StudyTerm term) {
    if (type == 'reading_skill' || type == 'short_text' || type == 'medium_text' || type == 'information' || type == 'multiple_questions') {
      return 'Aparece 「' + term.word + '」 en un texto nuevo. ¿Qué conviene hacer primero?';
    }
    return 'Quieres producir una oración nueva con 「' + term.word + '」. ¿Qué conviene comprobar primero?';
  }

  static List<String> _transferOptions(String type) {
    if (type == 'reading_skill' || type == 'short_text' || type == 'medium_text' || type == 'information' || type == 'multiple_questions') {
      return [
        'Usar el contexto y las palabras cercanas para confirmar su función',
        'Traducir solo el kanji e ignorar la oración',
        'Elegir el significado más parecido al español',
        'Suponer que siempre tiene un único uso',
      ];
    }
    return [
      'Comprobar qué forma y contexto necesita la palabra',
      'Cambiar el orden de las palabras al azar',
      'Traducir literalmente sin mirar la estructura',
      'Elegir una forma porque suena parecida',
    ];
  }

  static int _hash(String value) {
    var h = 0;
    for (final c in value.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}
