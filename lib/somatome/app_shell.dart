import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'lesson_catalog.dart';
import 'progress_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  final progress = ProgressService.instance;

  @override
  void initState() {
    super.initState();
    progress.load();
  }

  void openSession(SessionInfo s) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LessonFlowPage(session: s, progress: progress))).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (_, __) {
      final content = IndexedStack(
        index: tab,
        children: [
          HomePage(progress: progress, onStart: () => openSession(progress.nextUnlockedSession())),
          CoursePage(progress: progress, onOpen: openSession),
          ReviewPage(progress: progress, onOpen: openSession),
          ProgressPage(progress: progress),
        ],
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;

          if (desktop) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  _DesktopRail(
                    selected: tab,
                    onChanged: (v) => setState(() => tab = v),
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: content,
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavItem(index: 0, selected: tab == 0, icon: Icons.home_rounded, label: 'Inicio', onTap: () => setState(() => tab = 0)),
                    _NavItem(index: 1, selected: tab == 1, icon: Icons.route_rounded, label: 'Curso', onTap: () => setState(() => tab = 1)),
                    _NavItem(index: 2, selected: tab == 2, icon: Icons.refresh_rounded, label: 'Repaso', onTap: () => setState(() => tab = 2)),
                    _NavItem(index: 3, selected: tab == 3, icon: Icons.insights_rounded, label: 'Progreso', onTap: () => setState(() => tab = 3)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _DesktopRail extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DesktopRail({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Inicio'),
      (Icons.route_rounded, 'Curso'),
      (Icons.refresh_rounded, 'Repaso'),
      (Icons.insights_rounded, 'Progreso'),
    ];

    return Container(
      width: 235,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.07),
            blurRadius: 30,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 26),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF735BC1), Color(0xFF4E3A91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Text(
                      'N4',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JLPT Study',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Somatome N4',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected == i ? AppColors.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i].$1,
                        size: 21,
                        color: selected == i ? AppColors.primary : AppColors.muted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          color: selected == i ? AppColors.primaryDeep : AppColors.text,
                          fontWeight: selected == i ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0EBFC), Color(0xFFFFF0F1)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Aprende un poco cada día.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21, color: selected ? AppColors.primary : AppColors.muted),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final ProgressService progress;
  final VoidCallback onStart;

  const HomePage({super.key, required this.progress, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final s = progress.stats;
    final next = progress.nextUnlockedSession();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JLPT N4',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'おかえりなさい',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(s.streak.toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const Text('racha', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Un paso a la vez.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.9,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aprende japonés con sesiones cortas y progresivas.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, Color(0xFF343A59)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(.14),
                  blurRadius: 28,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        next.review ? 'RETO SEMANAL' : 'CONTINÚA AQUÍ',
                        style: const TextStyle(
                          color: AppColors.coral,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'S' + next.week.toString() + ' · D' + next.day.toString(),
                      style: const TextStyle(color: Color(0xFFB9BDCF), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.titleJa,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            next.titleEs,
                            style: const TextStyle(color: Color(0xFFB9BDCF), height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            next.focus,
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress.sessionProgress,
                            strokeWidth: 7,
                            color: AppColors.primary,
                            backgroundColor: Colors.white.withOpacity(.55),
                          ),
                          Text(
                            (progress.sessionProgress * 100).round().toString() + '%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(next.review ? 'COMENZAR RETO' : 'CONTINUAR'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Metric(icon: Icons.bolt_rounded, value: s.xp.toString(), label: 'XP')),
              const SizedBox(width: 8),
              Expanded(child: _Metric(icon: Icons.check_circle_rounded, value: s.correct.toString(), label: 'Buenas')),
              const SizedBox(width: 8),
              Expanded(child: _Metric(icon: Icons.percent_rounded, value: s.accuracy.round().toString() + '%', label: 'Precisión')),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tu recorrido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                (progress.sessionProgress * 100).round().toString() + '%',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 8),
              child: Column(
                children: [
                  for (var w = 1; w <= 6; w++)
                    _HomeWeekRow(week: w, progress: progress),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    s.corrected > 0
                        ? 'Has recuperado ' + s.corrected.toString() + ' errores. Sigue así.'
                        : 'Cada error queda registrado para que puedas recuperarlo.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeWeekRow extends StatelessWidget {
  final int week;
  final ProgressService progress;

  const _HomeWeekRow({required this.week, required this.progress});

  @override
  Widget build(BuildContext context) {
    final sessions = LessonCatalog.sessions.where((s) => s.week == week).toList();
    final done = sessions.where((s) => progress.isCompleted(s.id)).length;
    final unlocked = progress.weekUnlocked(week);
    final complete = progress.weekCompleted(week);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: complete
                  ? AppColors.sageSoft
                  : unlocked
                      ? AppColors.primarySoft
                      : const Color(0xFFEDEAE7),
            ),
            child: Icon(
              complete
                  ? Icons.check_rounded
                  : unlocked
                      ? Icons.play_arrow_rounded
                      : Icons.lock_rounded,
              size: 17,
              color: complete
                  ? const Color(0xFF4B8A5A)
                  : unlocked
                      ? AppColors.primary
                      : AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semana ' + week.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: done / 7,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFECE7E2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            done.toString() + '/7',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ProgressService progress; final SessionInfo session; final VoidCallback onStart;
  const _Hero({required this.progress, required this.session, required this.onStart});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft,end: Alignment.bottomRight,colors:[Color(0xFFECE7FA),Color(0xFFF9E9EA)]),
      borderRadius: BorderRadius.circular(28),
      boxShadow:[BoxShadow(color:AppColors.primary.withOpacity(.10),blurRadius:24,offset:const Offset(0,10))],
    ),
    child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text('SIGUIENTE SESIÓN',style:Theme.of(context).textTheme.labelMedium?.copyWith(color:AppColors.primary,fontWeight:FontWeight.w900,letterSpacing:1.2))),_Pill(icon:Icons.lock_open_rounded,text:'Desbloqueada')]),
      const SizedBox(height:12),
      Text('Semana '+session.week.toString()+' · Día '+session.day.toString(),style:const TextStyle(fontWeight:FontWeight.w900)),
      const SizedBox(height:5),
      Text(session.titleJa,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),
      const SizedBox(height:4),
      Text(session.focus,style:const TextStyle(color:AppColors.muted)),
      const SizedBox(height:16),
      Row(children:[Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:progress.sessionProgress,minHeight:8))),const SizedBox(width:10),Text(progress.completedCount.toString()+'/42',style:const TextStyle(fontWeight:FontWeight.w900))]),
      const SizedBox(height:16),
      SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onStart,icon:const Icon(Icons.play_arrow_rounded),label:const Text('CONTINUAR'))),
    ]),
  );
}

class CoursePage extends StatelessWidget {
  final ProgressService progress; final void Function(SessionInfo) onOpen;
  const CoursePage({super.key,required this.progress,required this.onOpen});
  @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[
    Text('Curso',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:5),const Text('Cada sesión se desbloquea al superar la anterior con 80% o más.'),
    const SizedBox(height:18),
    _CourseSummary(progress:progress),
    const SizedBox(height:18),
    for(var w=1;w<=6;w++) _WeekCard(week:w,progress:progress,onOpen:onOpen),
  ]));
}

class _CourseSummary extends StatelessWidget {
  final ProgressService progress; const _CourseSummary({required this.progress});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(17),child:Row(children:[
    SizedBox(width:72,height:72,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:progress.sessionProgress,strokeWidth:8),Text((progress.sessionProgress*100).round().toString()+'%',style:const TextStyle(fontWeight:FontWeight.w900))])),
    const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(progress.completedCount.toString()+' / 42 sesiones',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text('Nivel '+progress.stats.level.toString()+' · '+progress.stats.xp.toString()+' XP',style:const TextStyle(color:AppColors.muted))])),
  ])));
}

class _WeekCard extends StatelessWidget {
  final int week; final ProgressService progress; final void Function(SessionInfo) onOpen;
  const _WeekCard({required this.week,required this.progress,required this.onOpen});
  @override Widget build(BuildContext context){
    final sessions=LessonCatalog.sessions.where((s)=>s.week==week).toList();
    final done=sessions.where((s)=>progress.isCompleted(s.id)).length;
    final unlocked=sessions.any((s)=>progress.isUnlocked(s.id));
    final type=week<=4?'Gramática':week==5?'Reading':'Listening';
    return Card(margin:const EdgeInsets.only(bottom:12),child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[
      Row(children:[
        CircleAvatar(backgroundColor:unlocked?AppColors.primarySoft:const Color(0xFFEDEAE7),child:Text(week.toString(),style:TextStyle(fontWeight:FontWeight.w900,color:unlocked?AppColors.primary:AppColors.muted))),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Semana '+week.toString(),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text(type+' · '+done.toString()+'/7',style:const TextStyle(color:AppColors.muted))])),
        Text((done/7*100).round().toString()+'%',style:const TextStyle(fontWeight:FontWeight.w900)),
      ]),
      const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:done/7,minHeight:7)),
      const SizedBox(height:8),
      for(final s in sessions) _SessionTile(session:s,progress:progress,onOpen:onOpen),
    ])));
  }
}

class _SessionTile extends StatelessWidget {
  final SessionInfo session; final ProgressService progress; final void Function(SessionInfo) onOpen;
  const _SessionTile({required this.session,required this.progress,required this.onOpen});
  @override Widget build(BuildContext context){
    final done=progress.isCompleted(session.id), unlocked=progress.isUnlocked(session.id);
    return ListTile(
      dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:2),
      leading:CircleAvatar(radius:16,backgroundColor:done?AppColors.sageSoft:unlocked?AppColors.primarySoft:const Color(0xFFEDEAE7),child:Icon(done?Icons.check_rounded:unlocked?Icons.play_arrow_rounded:Icons.lock_rounded,size:17,color:done?const Color(0xFF4B8A5A):unlocked?AppColors.primary:AppColors.muted)),
      title:Text('Día '+session.day.toString()+' · '+session.titleJa,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700)),
      subtitle:Text(session.focus,maxLines:1,overflow:TextOverflow.ellipsis),
      trailing:done?const Icon(Icons.verified_rounded,color:Color(0xFF4B8A5A)):unlocked?const Icon(Icons.chevron_right_rounded):null,
      onTap:unlocked?()=>onOpen(session):null,
    );
  }
}

class LessonFlowPage extends StatefulWidget {
  final SessionInfo session; final ProgressService progress;
  const LessonFlowPage({super.key,required this.session,required this.progress});
  @override State<LessonFlowPage> createState()=>_LessonFlowPageState();
}

class _LessonFlowPageState extends State<LessonFlowPage> {
  late Future<LessonPacket> future;
  LessonPacket? packet;
  int step=0,correct=0,wrong=0;
  int? selected; bool checked=false;

  @override void initState(){super.initState();future=_load();}
  Future<LessonPacket> _load() async {
    if(widget.session.id=='W01D01'){
      final raw=await rootBundle.loadString('assets/content/somatome_n4/lessons/W01D01.json');
      packet=LessonPacket.fromJson(jsonDecode(raw) as Map<String,dynamic>,widget.session);
    }else{
      packet=LessonCatalog.buildPacket(widget.session);
    }
    return packet!;
  }

  Future<void> answer(int value,QuestionStep q) async {
    if(checked)return;
    final ok=value==q.answer;
    setState(() { selected=value; checked=true; });
    if(ok) correct++; else wrong++;
    await widget.progress.recordAnswer(sessionId:widget.session.id,questionId:q.id,prompt:q.question,correct:ok);
    setState((){});
  }

  Future<void> next() async {
    if(step<packet!.steps.length-1){setState(() { step++; selected=null; checked=false; });return;}
    final total=correct+wrong;
    final passed=total>0 && correct/total>=.80;
    if(passed) await widget.progress.completeSession(widget.session.id,correct,wrong);
    if(!mounted)return;
    showDialog(context:context,barrierDismissible:false,builder:(_)=>_ResultDialog(passed:passed,correct:correct,wrong:wrong,onClose:(){Navigator.pop(context);if(passed){Navigator.pop(context);}else{setState((){step=0;correct=0;wrong=0;selected=null;checked=false;});}}));
  }

  @override Widget build(BuildContext context)=>FutureBuilder<LessonPacket>(future:future,builder:(_,snap){
    if(!snap.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final item=packet!.steps[step];
    return Scaffold(
      appBar:AppBar(title:Text('Día '+widget.session.day.toString()),actions:[Padding(padding:const EdgeInsets.only(right:16),child:Text('+'+widget.progress.stats.xp.toString()+' XP'))]),
      body:Column(children:[
        LinearProgressIndicator(value:(step+1)/packet!.steps.length,minHeight:6),
        Expanded(child:AnimatedSwitcher(duration:const Duration(milliseconds:220),child:item is TeachStep?_TeachCard(key:ValueKey(step),step:item,onNext:()=>setState(() { step++; })):_QuestionCard(key:ValueKey(step),step:item as QuestionStep,selected:selected,checked:checked,onAnswer:answer,onNext:next))),
      ]),
    );
  });
}

class _TeachCard extends StatelessWidget {
  final TeachStep step; final VoidCallback onNext;
  const _TeachCard({super.key,required this.step,required this.onNext});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(22,26,22,30),children:[
    _Label(text:step.label),const SizedBox(height:12),
    Text(step.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:12),Text(step.body,style:const TextStyle(fontSize:17,height:1.45)),
    const SizedBox(height:18),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:AppColors.primarySoft,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(step.pattern,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:13),Text(step.exampleJa,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(step.exampleEs),
    ])),
    const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(15),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.lightbulb_rounded,color:AppColors.primary),const SizedBox(width:10),Expanded(child:Text(step.tip))]))),
    const SizedBox(height:24),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onNext,icon:const Icon(Icons.arrow_forward_rounded),label:const Text('CONTINUAR'))),
  ]);
}

class _QuestionCard extends StatelessWidget {
  final QuestionStep step;
  final int? selected;
  final bool checked;
  final Future<void> Function(int, QuestionStep) onAnswer;
  final VoidCallback onNext;

  const _QuestionCard({
    super.key,
    required this.step,
    required this.selected,
    required this.checked,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ok = checked && selected == step.answer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
      children: [
        _Label(text: 'TU TURNO'),
        const SizedBox(height: 12),
        Text(
          step.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Text(
          step.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        for (var i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                side: BorderSide(
                  color: checked && i == step.answer
                      ? const Color(0xFF4B8A5A)
                      : checked && i == selected
                          ? const Color(0xFFC85A5A)
                          : AppColors.border,
                  width: checked && (i == step.answer || i == selected)
                      ? 2
                      : 1,
                ),
              ),
              onPressed: checked ? null : () => onAnswer(i, step),
              child: Text(
                step.options[i],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

        if (checked) ...[
          const SizedBox(height: 4),
          Card(
            color: ok ? AppColors.sageSoft : AppColors.roseSoft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: ok
                        ? const Color(0xFF4B8A5A)
                        : const Color(0xFFC85A5A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step.explanation)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('SIGUIENTE'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final bool passed; final int correct,wrong; final VoidCallback onClose;
  const _ResultDialog({required this.passed,required this.correct,required this.wrong,required this.onClose});
  @override Widget build(BuildContext context)=>Dialog(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Icon(passed?Icons.emoji_events_rounded:Icons.refresh_rounded,size:64,color:AppColors.primary),const SizedBox(height:12),
    Text(passed?'¡Nivel superado!':'Casi lo tienes',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:7),
    Text(correct.toString()+' buenas · '+wrong.toString()+' malas',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:5),
    Text(passed?'Siguiente sesión desbloqueada.':'Necesitas 80% para desbloquear la siguiente sesión.',textAlign:TextAlign.center),const SizedBox(height:20),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:onClose,child:Text(passed?'CONTINUAR':'REINTENTAR'))),
  ])));
}

class ReviewPage extends StatelessWidget {
  final ProgressService progress; final void Function(SessionInfo) onOpen;
  const ReviewPage({super.key,required this.progress,required this.onOpen});
  @override Widget build(BuildContext context){final s=progress.stats;return SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[
    Text('Repaso inteligente',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Convierte tus errores en puntos fuertes.'),const SizedBox(height:18),
    Card(color:AppColors.primarySoft,child:Padding(padding:const EdgeInsets.all(19),child:Row(children:[const Icon(Icons.auto_awesome_rounded,size:34,color:AppColors.primary),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.openMistakes.toString()+' errores pendientes',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),Text(s.corrected.toString()+' errores ya corregidos',style:const TextStyle(color:AppColors.muted))]))] ))),
    const SizedBox(height:14),_StatsRow(stats:s),const SizedBox(height:18),
    if(s.openMistakes>0) for(final m in progress.mistakePrompts.take(8)) Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:const Icon(Icons.replay_rounded),title:Text(m,maxLines:2,overflow:TextOverflow.ellipsis),subtitle:const Text('Pendiente de reforzar')))
    else Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(children:const[Icon(Icons.celebration_rounded,size:48,color:AppColors.primary),SizedBox(height:10),Text('No tienes errores pendientes',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),SizedBox(height:5),Text('Sigue avanzando y vuelve aquí para reforzar lo difícil.',textAlign:TextAlign.center)]))),
    const SizedBox(height:18),Text('Próxima sesión',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    _SessionTile(session:progress.nextUnlockedSession(),progress:progress,onOpen:onOpen),
  ]));}
}

class ProgressPage extends StatelessWidget {
  final ProgressService progress; const ProgressPage({super.key,required this.progress});
  @override Widget build(BuildContext context){final s=progress.stats;return SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,30),children:[
    Text('Tu progreso',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Buenas, malas y lo que ya lograste corregir.'),const SizedBox(height:18),
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[SizedBox(width:82,height:82,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:progress.sessionProgress,strokeWidth:9),Text((progress.sessionProgress*100).round().toString()+'%',style:const TextStyle(fontWeight:FontWeight.w900))])),const SizedBox(width:17),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(progress.completedCount.toString()+' / 42 sesiones',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),Text('Nivel '+s.level.toString()+' · '+s.xp.toString()+' XP',style:const TextStyle(color:AppColors.muted))]))]))),
    const SizedBox(height:14),_StatsRow(stats:s),const SizedBox(height:22),
    Text('Recuperación',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      _Bar(label:'Buenas respuestas',value:s.correct,max:s.totalAnswers==0?1:s.totalAnswers),_Bar(label:'Malas respuestas',value:s.wrong,max:s.totalAnswers==0?1:s.totalAnswers),_Bar(label:'Errores corregidos',value:s.corrected,max:s.wrong==0?1:s.wrong),
    ]))),
    const SizedBox(height:22),Text('Por semana',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    for(var w=1;w<=6;w++) _WeekRow(week:w,progress:progress),
  ]));}
}

class _StatsRow extends StatelessWidget {
  final StudyStats stats; const _StatsRow({required this.stats});
  @override Widget build(BuildContext context)=>Row(children:[
    Expanded(child:_Metric(icon:Icons.check_circle_rounded,value:stats.correct.toString(),label:'Buenas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.close_rounded,value:stats.wrong.toString(),label:'Malas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.healing_rounded,value:stats.corrected.toString(),label:'Corregidas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.percent_rounded,value:stats.accuracy.round().toString()+'%',label:'Precisión')),
  ]);
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  final String label; final int value,max; const _Bar({required this.label,required this.value,required this.max});
  @override Widget build(BuildContext context){final v=(value/max).clamp(0.0,1.0);return Padding(padding:const EdgeInsets.only(bottom:14),child:Column(children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w700))),Text(value.toString(),style:const TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:v,minHeight:7))]));}
}

class _WeekRow extends StatelessWidget {
  final int week; final ProgressService progress; const _WeekRow({required this.week,required this.progress});
  @override Widget build(BuildContext context){final done=LessonCatalog.sessions.where((s)=>s.week==week&&progress.isCompleted(s.id)).length;return Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[SizedBox(width:82,child:Text('Semana '+week.toString(),style:const TextStyle(fontWeight:FontWeight.w800))),Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:done/7,minHeight:8))),const SizedBox(width:10),Text(done.toString()+'/7',style:const TextStyle(fontWeight:FontWeight.w900))]));}
}

class _Path extends StatelessWidget {
  final ProgressService progress;

  const _Path({required this.progress});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 1; i <= 6; i++) {
      children.add(
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: progress.weekCompleted(i)
                  ? AppColors.sageSoft
                  : progress.weekUnlocked(i)
                      ? AppColors.primarySoft
                      : const Color(0xFFEDEAE7),
              child: Icon(
                progress.weekCompleted(i)
                    ? Icons.check_rounded
                    : progress.weekUnlocked(i)
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                size: 17,
                color: progress.weekCompleted(i)
                    ? const Color(0xFF4B8A5A)
                    : progress.weekUnlocked(i)
                        ? AppColors.primary
                        : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'S' + i.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

      if (i < 6) {
        children.add(const Expanded(child: Divider()));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: children),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon; final String text; const _Pill({required this.icon,required this.text});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withOpacity(.72),borderRadius:BorderRadius.circular(20)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:AppColors.primary),const SizedBox(width:4),Text(text,style:const TextStyle(fontWeight:FontWeight.w800))]));
}

class _Label extends StatelessWidget {
  final String text; const _Label({required this.text});
  @override Widget build(BuildContext context)=>Text(text,style:Theme.of(context).textTheme.labelLarge?.copyWith(color:AppColors.primary,fontWeight:FontWeight.w900,letterSpacing:1.3));
}
