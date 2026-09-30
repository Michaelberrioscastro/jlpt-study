class SessionInfo {
  final String id, type, titleJa, titleEs, focus;
  final int week, day;
  final List<int> pages;
  final bool review;
  const SessionInfo({required this.id, required this.week, required this.day, required this.type, required this.titleJa, required this.titleEs, required this.focus, required this.pages, required this.review});
}

abstract final class LessonCatalog {
  static const sessions = <SessionInfo>[
    SessionInfo(id:"W01D01",week:1,day:1,type:"grammar",titleJa:"一日に二回、歯をみがきます。",titleEs:"Me cepillo los dientes dos veces al día.",focus:"Frecuencia/ratio y ほど",pages:[18,19],review:false),
    SessionInfo(id:"W01D02",week:1,day:2,type:"grammar",titleJa:"漢字は少ししか書けません。",titleEs:"Solo puedo escribir unos pocos kanji.",focus:"しか～ない / でも / で",pages:[20,21],review:false),
    SessionInfo(id:"W01D03",week:1,day:3,type:"grammar",titleJa:"9時までに来てください。",titleEs:"Ven antes de las 9.",focus:"まで / までに / たり～たり / し",pages:[22,23],review:false),
    SessionInfo(id:"W01D04",week:1,day:4,type:"grammar",titleJa:"今、勉強しているところです。",titleEs:"Ahora estoy estudiando.",focus:"ところ / 間に / とき / 前に / 後で",pages:[24,25],review:false),
    SessionInfo(id:"W01D05",week:1,day:5,type:"grammar",titleJa:"音楽を聞きながら勉強しています。",titleEs:"Estudio mientras escucho música.",focus:"て / なくて / ないで / ても",pages:[26,27],review:false),
    SessionInfo(id:"W01D06",week:1,day:6,type:"grammar",titleJa:"雪を見たことがありません。",titleEs:"Nunca he visto la nieve.",focus:"たことがある / ことにする / ことになる",pages:[28,29],review:false),
    SessionInfo(id:"W01D07",week:1,day:7,type:"grammar",titleJa:"まとめ問題",titleEs:"Problemas de repaso de la semana 1.",focus:"Review",pages:[30,31],review:true),
    SessionInfo(id:"W02D01",week:2,day:1,type:"grammar",titleJa:"宿題をしなければいけません。",titleEs:"Tengo que hacer la tarea.",focus:"なければならない / なくてもいい",pages:[34,35],review:false),
    SessionInfo(id:"W02D02",week:2,day:2,type:"grammar",titleJa:"習ったことを忘れてしまいました。",titleEs:"Olvidé lo que había aprendido.",focus:"ておく / てしまう",pages:[36,37],review:false),
    SessionInfo(id:"W02D03",week:2,day:3,type:"grammar",titleJa:"教えてくれてありがとう。",titleEs:"Gracias por enseñarme.",focus:"てくれる / てもらう / てあげる",pages:[38,39],review:false),
    SessionInfo(id:"W02D04",week:2,day:4,type:"grammar",titleJa:"日記を書くようにしましょう。",titleEs:"Procuremos escribir un diario.",focus:"ようにする / ようになる",pages:[40,41],review:false),
    SessionInfo(id:"W02D05",week:2,day:5,type:"grammar",titleJa:"日本語でどう言いますか。",titleEs:"¿Cómo se dice en japonés?",focus:"という / そうだ / らしい",pages:[42,43],review:false),
    SessionInfo(id:"W02D06",week:2,day:6,type:"grammar",titleJa:"もっと勉強したほうがいいですよ。",titleEs:"Deberías estudiar más.",focus:"ほうがいい / たらいい / なら",pages:[44,45],review:false),
    SessionInfo(id:"W02D07",week:2,day:7,type:"grammar",titleJa:"まとめ問題",titleEs:"Problemas de repaso de la semana 2.",focus:"Review",pages:[46,47],review:true),
    SessionInfo(id:"W03D01",week:3,day:1,type:"grammar",titleJa:"漢字を書くのは大変です。",titleEs:"Es difícil escribir kanji.",focus:"のは / のが / のを",pages:[50,51],review:false),
    SessionInfo(id:"W03D02",week:3,day:2,type:"grammar",titleJa:"このまどから富士山が見えます。",titleEs:"Desde esta ventana se puede ver el monte Fuji.",focus:"見える / 聞こえる / できる / 可能",pages:[52,53],review:false),
    SessionInfo(id:"W03D03",week:3,day:3,type:"grammar",titleJa:"雨でも行きましょう。",titleEs:"Vamos aunque llueva.",focus:"でも / ても / しかたがない",pages:[54,55],review:false),
    SessionInfo(id:"W03D04",week:3,day:4,type:"grammar",titleJa:"この漢字の読み方はむずかしいです。",titleEs:"La forma de leer este kanji es difícil.",focus:"読み方 / patrones relacionados",pages:[56,57],review:false),
    SessionInfo(id:"W03D05",week:3,day:5,type:"grammar",titleJa:"手伝ってくださいませんか。",titleEs:"¿Podría ayudarme?",focus:"てくださいませんか / てもらいたい / てほしい",pages:[58,59],review:false),
    SessionInfo(id:"W03D06",week:3,day:6,type:"grammar",titleJa:"今日はお酒を飲まないつもりです。",titleEs:"Hoy no tengo intención de beber alcohol.",focus:"って / と思う / ようと思う",pages:[60,61],review:false),
    SessionInfo(id:"W03D07",week:3,day:7,type:"grammar",titleJa:"まとめ問題",titleEs:"Problemas de repaso de la semana 3.",focus:"Review",pages:[62,63],review:true),
    SessionInfo(id:"W04D01",week:4,day:1,type:"grammar",titleJa:"夏休みになったら、国に帰ります。",titleEs:"Cuando lleguen las vacaciones de verano, volveré a mi país.",focus:"たら / ば / なら",pages:[66,67],review:false),
    SessionInfo(id:"W04D02",week:4,day:2,type:"grammar",titleJa:"明日は天気がよさそうです。",titleEs:"Parece que mañana hará buen tiempo.",focus:"ようだ / みたいだ / そうだ / でしょう",pages:[68,69],review:false),
    SessionInfo(id:"W04D03",week:4,day:3,type:"grammar",titleJa:"この本は使いやすいです。",titleEs:"Este libro es fácil de usar.",focus:"すぎる / やすい / にくい",pages:[70,71],review:false),
    SessionInfo(id:"W04D04",week:4,day:4,type:"grammar",titleJa:"会社をやめさせられました。",titleEs:"Me obligaron a dejar la empresa.",focus:"受身 / 使役 / 使役受身",pages:[72,73],review:false),
    SessionInfo(id:"W04D05",week:4,day:5,type:"grammar",titleJa:"かぎがかかっています。",titleEs:"La llave está puesta / la puerta está cerrada con llave.",focus:"自動詞 / 他動詞 / ている / てある",pages:[74,75],review:false),
    SessionInfo(id:"W04D06",week:4,day:6,type:"grammar",titleJa:"試験に受からないかなあ。",titleEs:"Ojalá pudiera aprobar el examen…",focus:"んです / なあ / かなあ",pages:[76,77],review:false),
    SessionInfo(id:"W04D07",week:4,day:7,type:"grammar",titleJa:"まとめ問題",titleEs:"Problemas de repaso de la semana 4.",focus:"Review",pages:[78,79],review:true),
    SessionInfo(id:"W05D01",week:5,day:1,type:"reading",titleJa:"メールやメモを読みましょう",titleEs:"Leamos correos y notas.",focus:"メール・メモ",pages:[82,83],review:false),
    SessionInfo(id:"W05D02",week:5,day:2,type:"reading",titleJa:"説明を読みましょう",titleEs:"Leamos explicaciones.",focus:"説明",pages:[84,85],review:false),
    SessionInfo(id:"W05D03",week:5,day:3,type:"reading",titleJa:"案内や注意書きを読みましょう",titleEs:"Leamos indicaciones y avisos.",focus:"案内・注意書き",pages:[86,87],review:false),
    SessionInfo(id:"W05D04",week:5,day:4,type:"reading",titleJa:"長めの文章を読みましょう①",titleEs:"Leamos un texto más largo ①.",focus:"文章①",pages:[88,89],review:false),
    SessionInfo(id:"W05D05",week:5,day:5,type:"reading",titleJa:"長めの文章を読みましょう②",titleEs:"Leamos un texto más largo ②.",focus:"文章②",pages:[90,91],review:false),
    SessionInfo(id:"W05D06",week:5,day:6,type:"reading",titleJa:"広告やお知らせを読みましょう",titleEs:"Leamos anuncios y avisos.",focus:"広告・お知らせ",pages:[92,93],review:false),
    SessionInfo(id:"W05D07",week:5,day:7,type:"reading",titleJa:"まとめ問題",titleEs:"Problemas de repaso de reading.",focus:"Review",pages:[94,95],review:true),
    SessionInfo(id:"W06D01",week:6,day:1,type:"listening",titleJa:"準備をしましょう①",titleEs:"Preparémonos ①.",focus:"準備①",pages:[98,99],review:false),
    SessionInfo(id:"W06D02",week:6,day:2,type:"listening",titleJa:"準備をしましょう②",titleEs:"Preparémonos ②.",focus:"準備②",pages:[100,101],review:false),
    SessionInfo(id:"W06D03",week:6,day:3,type:"listening",titleJa:"どれですか — 課題理解 —",titleEs:"¿Cuál es? — comprensión de la tarea —",focus:"どれですか",pages:[102,103],review:false),
    SessionInfo(id:"W06D04",week:6,day:4,type:"listening",titleJa:"どうしてですか — ポイント理解 —",titleEs:"¿Por qué? — comprensión de puntos clave —",focus:"どうしてですか",pages:[104,105],review:false),
    SessionInfo(id:"W06D05",week:6,day:5,type:"listening",titleJa:"何と言いますか — 発話表現 —",titleEs:"¿Qué dices? — expresiones al hablar —",focus:"何と言いますか",pages:[106,107],review:false),
    SessionInfo(id:"W06D06",week:6,day:6,type:"listening",titleJa:"どんな返事をしますか — 即時応答 —",titleEs:"¿Qué respuesta das? — respuesta inmediata —",focus:"どんな返事をしますか",pages:[108,109],review:false),
    SessionInfo(id:"W06D07",week:6,day:7,type:"listening",titleJa:"まとめ問題",titleEs:"Problemas de repaso de listening.",focus:"Review",pages:[110,111],review:true),
  ];

  static LessonPacket buildPacket(SessionInfo s) {
    if (s.review) {
      final p=sessions.where((x)=>x.week==s.week && !x.review).toList();
      final a=p[0],b=p[1],c=p[2];
      return LessonPacket(s,[
        TeachStep(label:'REPASO',title:'Semana '+s.week.toString()+': conecta las piezas',body:'Hoy recuperas lo estudiado durante la semana y compruebas qué estructuras reconoces con rapidez.',pattern:p.map((x)=>x.focus).join(' · '),exampleJa:a.titleJa,exampleEs:a.titleEs,tip:'Los errores de este repaso quedan registrados para volver a practicarlos.'),
        QuestionStep(id:s.id+'-q1',title:'Recuerda',question:'¿Qué foco corresponde a esta frase?\n\n'+a.titleJa,options:[a.focus,b.focus,c.focus],answer:0,explanation:'Corresponde a '+a.focus+'.'),
        QuestionStep(id:s.id+'-q2',title:'Relaciona',question:'¿Qué foco corresponde a esta frase?\n\n'+b.titleJa,options:[a.focus,b.focus,c.focus],answer:1,explanation:'Corresponde a '+b.focus+'.'),
        QuestionStep(id:s.id+'-q3',title:'Reto semanal',question:'¿Qué foco corresponde a esta frase?\n\n'+c.titleJa,options:[a.focus,b.focus,c.focus],answer:2,explanation:'Corresponde a '+c.focus+'.'),
      ]);
    }
    final d=sessions.where((x)=>x.id!=s.id && x.week==s.week && !x.review).map((x)=>x.focus).take(2).toList();
    final t=sessions.where((x)=>x.id!=s.id && !x.review).map((x)=>x.titleEs).skip(s.day-1).take(2).toList();
    return LessonPacket(s,[
      TeachStep(label:'APRENDE',title:'Objetivo de hoy',body:s.titleEs+'\n\nEsta sesión trabaja '+s.focus+'. La estructura sigue el programa del Somatome; esta explicación adicional está pensada para que empieces a reconocer el objetivo antes de practicarlo.',pattern:s.focus,exampleJa:s.titleJa,exampleEs:s.titleEs,tip:'Intenta reconocer la forma en contexto, no solo memorizar su traducción.'),
      QuestionStep(id:s.id+'-q1',title:'Comprensión rápida',question:'¿Qué significa esta frase?\n\n'+s.titleJa,options:[s.titleEs,...t],answer:0,explanation:'La frase de referencia significa: '+s.titleEs+'.'),
      TeachStep(label:'CLAVE',title:'Qué debes reconocer',body:'El foco de esta sesión es '+s.focus+'. En la siguiente etapa añadiremos ejercicios específicos de la página y sus respuestas.',pattern:s.focus,exampleJa:s.titleJa,exampleEs:s.titleEs,tip:'Cuando domines esta sesión, la siguiente quedará desbloqueada.'),
      QuestionStep(id:s.id+'-q2',title:'Identifica el objetivo',question:'¿Cuál es el foco principal de esta sesión?',options:[s.focus,...d],answer:0,explanation:'Según el mapa curricular, esta sesión trabaja principalmente '+s.focus+'.'),
      QuestionStep(id:s.id+'-q3',title:'Reto final',question:'¿Qué conviene reconocer antes de pasar al siguiente nivel?',options:['La estructura y su función en contexto','Solo la traducción palabra por palabra','Únicamente la pronunciación'],answer:0,explanation:'La meta es reconocer la estructura y su función en contexto.'),
    ]);
  }
}

abstract class LessonStep { const LessonStep(); }
class TeachStep extends LessonStep {
  final String label,title,body,pattern,exampleJa,exampleEs,tip;
  const TeachStep({required this.label,required this.title,required this.body,required this.pattern,required this.exampleJa,required this.exampleEs,required this.tip});
}
class QuestionStep extends LessonStep {
  final String id,title,question,explanation;
  final List<String> options;
  final int answer;
  const QuestionStep({required this.id,required this.title,required this.question,required this.options,required this.answer,required this.explanation});
}
class LessonPacket {
  final SessionInfo session;
  final List<LessonStep> steps;
  const LessonPacket(this.session,this.steps);
  factory LessonPacket.fromJson(Map<String,dynamic> map,SessionInfo session){
    final raw=map['steps'] as List<dynamic>;
    return LessonPacket(session,raw.asMap().entries.map<LessonStep>((e){
      final m=e.value as Map<String,dynamic>;
      if(m['type']=='teach') return TeachStep(label:'APRENDE',title:m['title'] as String,body:m['body'] as String,pattern:m['pattern'] as String,exampleJa:m['example_ja'] as String,exampleEs:m['example_es'] as String,tip:m['tip'] as String);
      return QuestionStep(id:session.id+'-'+e.key.toString(),title:m['title'] as String,question:m['question'] as String,options:(m['options'] as List<dynamic>).map((x)=>x.toString()).toList(),answer:m['answer'] as int,explanation:m['explanation'] as String);
    }).toList());
  }
}
