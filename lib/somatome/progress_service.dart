import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lesson_catalog.dart';

class StudyStats {
  final int totalAnswers, correct, wrong, corrected, xp, streak, openMistakes, level;
  const StudyStats({this.totalAnswers=0,this.correct=0,this.wrong=0,this.corrected=0,this.xp=0,this.streak=1,this.openMistakes=0,this.level=1});
  double get accuracy => totalAnswers == 0 ? 0 : correct / totalAnswers * 100;
}

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final instance = ProgressService._();
  SharedPreferences? _prefs;
  final Set<String> _completed = {};
  final Map<String, Map<String, dynamic>> _mistakes = {};
  int _total=0,_correct=0,_wrong=0,_corrected=0,_xp=0,_streak=1;
  bool _loaded=false;

  Future<void> load() async {
    if (_loaded) return;
    _prefs=await SharedPreferences.getInstance();
    _completed.addAll(_prefs!.getStringList('completed_sessions') ?? const []);
    final raw=_prefs!.getString('mistakes');
    if(raw!=null){final decoded=jsonDecode(raw) as Map<String,dynamic>;for(final e in decoded.entries){_mistakes[e.key]=Map<String,dynamic>.from(e.value as Map);}}
    _total=_prefs!.getInt('total_answers')??0; _correct=_prefs!.getInt('correct')??0; _wrong=_prefs!.getInt('wrong')??0; _corrected=_prefs!.getInt('corrected')??0; _xp=_prefs!.getInt('xp')??0; _streak=_prefs!.getInt('streak')??1;
    _loaded=true; notifyListeners();
  }

  StudyStats get stats=>StudyStats(totalAnswers:_total,correct:_correct,wrong:_wrong,corrected:_corrected,xp:_xp,streak:_streak,openMistakes:_mistakes.values.where((m)=>m['open']==true).length,level:(_xp~/300)+1);
  int get completedCount=>_completed.length;
  double get sessionProgress=>completedCount/42;
  List<String> get mistakePrompts=>_mistakes.values.where((m)=>m['open']==true).map((m)=>m['prompt'] as String).toList();

  bool isCompleted(String id)=>_completed.contains(id);
  bool isUnlocked(String id){
    final i=LessonCatalog.sessions.indexWhere((s)=>s.id==id); if(i<0)return false; return i==0 || isCompleted(LessonCatalog.sessions[i-1].id);
  }
  SessionInfo nextUnlockedSession()=>LessonCatalog.sessions.firstWhere((s)=>!isCompleted(s.id),orElse:()=>LessonCatalog.sessions.last);
  bool weekUnlocked(int week)=>LessonCatalog.sessions.where((s)=>s.week==week).any((s)=>isUnlocked(s.id));
  bool weekCompleted(int week)=>LessonCatalog.sessions.where((s)=>s.week==week).every((s)=>isCompleted(s.id));

  Future<void> recordAnswer({required String sessionId,required String questionId,required String prompt,required bool correct}) async {
    _total++;
    final existing=_mistakes[questionId];
    if(correct){
      _correct++;
      if(existing!=null && existing['open']==true){existing['open']=false;_corrected++;}
    }else{
      _wrong++;
      _mistakes[questionId]={'sessionId':sessionId,'prompt':prompt,'open':true};
    }
    await _save(); notifyListeners();
  }

  Future<void> completeSession(String id,int correct,int wrong) async {
    if(_completed.add(id)){
      _xp += 50 + correct*10;
      await _save(); notifyListeners();
    }
  }

  Future<void> _save() async {
    final p=_prefs ??= await SharedPreferences.getInstance();
    await p.setStringList('completed_sessions',_completed.toList());
    await p.setString('mistakes',jsonEncode(_mistakes));
    await p.setInt('total_answers',_total); await p.setInt('correct',_correct); await p.setInt('wrong',_wrong); await p.setInt('corrected',_corrected); await p.setInt('xp',_xp); await p.setInt('streak',_streak);
  }
}
