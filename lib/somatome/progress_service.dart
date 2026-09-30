import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../study/study_catalog.dart';

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
  String _level='N4';

  String get level => _level;

  Future<void> load() async {
    if (_loaded) return;
    _prefs=await SharedPreferences.getInstance();
    StudyCatalog.activeLevel=_level;

    final suffix=_level;
    final completedKey='completed_sessions_'+suffix;
    final mistakesKey='mistakes_'+suffix;
    final totalKey='total_answers_'+suffix;
    final correctKey='correct_'+suffix;
    final wrongKey='wrong_'+suffix;
    final correctedKey='corrected_'+suffix;
    final xpKey='xp_'+suffix;
    final streakKey='streak_'+suffix;

    final legacyN4=_level=='N4';
    _completed.addAll(_prefs!.getStringList(completedKey) ??
        (legacyN4 ? (_prefs!.getStringList('completed_sessions') ?? const []) : const []));

    final raw=_prefs!.getString(mistakesKey) ??
        (legacyN4 ? _prefs!.getString('mistakes') : null);
    if(raw!=null){
      final decoded=jsonDecode(raw) as Map<String,dynamic>;
      for(final e in decoded.entries){
        _mistakes[e.key]=Map<String,dynamic>.from(e.value as Map);
      }
    }

    _total=_prefs!.getInt(totalKey) ?? (legacyN4 ? (_prefs!.getInt('total_answers')??0) : 0);
    _correct=_prefs!.getInt(correctKey) ?? (legacyN4 ? (_prefs!.getInt('correct')??0) : 0);
    _wrong=_prefs!.getInt(wrongKey) ?? (legacyN4 ? (_prefs!.getInt('wrong')??0) : 0);
    _corrected=_prefs!.getInt(correctedKey) ?? (legacyN4 ? (_prefs!.getInt('corrected')??0) : 0);
    _xp=_prefs!.getInt(xpKey) ?? (legacyN4 ? (_prefs!.getInt('xp')??0) : 0);
    _streak=_prefs!.getInt(streakKey) ?? (legacyN4 ? (_prefs!.getInt('streak')??1) : 1);
    _loaded=true;
    notifyListeners();
  }

  Future<void> setLevel(String value) async {
    if(value==_level && _loaded) return;
    _level=value;
    StudyCatalog.activeLevel=value;
    _completed.clear();
    _mistakes.clear();
    _total=0; _correct=0; _wrong=0; _corrected=0; _xp=0; _streak=1;
    _loaded=false;
    await load();
  }

  StudyStats get stats=>StudyStats(
    totalAnswers:_total,correct:_correct,wrong:_wrong,corrected:_corrected,
    xp:_xp,streak:_streak,
    openMistakes:_mistakes.values.where((m)=>m['open']==true).length,
    level:(_xp~/300)+1,
  );

  int get completedCount=>_completed.length;
  double get sessionProgress=>StudyCatalog.totalSessions==0 ? 0 : completedCount/StudyCatalog.totalSessions;
  List<String> get mistakePrompts=>_mistakes.values.where((m)=>m['open']==true).map((m)=>m['prompt'] as String).toList();

  bool isCompleted(String id)=>_completed.contains(id);
  bool isUnlocked(String id){
    final i=StudyCatalog.sessions.indexWhere((s)=>s.id==id);
    if(i<0)return false;
    return i==0 || isCompleted(StudyCatalog.sessions[i-1].id);
  }

  SessionInfo nextUnlockedSession()=>StudyCatalog.sessions.firstWhere((s)=>!isCompleted(s.id),orElse:()=>StudyCatalog.sessions.last);

  bool weekUnlocked(int week)=>StudyCatalog.sessions.where((s)=>s.week==week).any((s)=>isUnlocked(s.id));
  bool weekCompleted(int week){
    final items=StudyCatalog.sessions.where((s)=>s.week==week).toList();
    return items.isNotEmpty && items.every((s)=>isCompleted(s.id));
  }

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
    final suffix=_level;
    await p.setStringList('completed_sessions_'+suffix,_completed.toList());
    await p.setString('mistakes_'+suffix,jsonEncode(_mistakes));
    await p.setInt('total_answers_'+suffix,_total);
    await p.setInt('correct_'+suffix,_correct);
    await p.setInt('wrong_'+suffix,_wrong);
    await p.setInt('corrected_'+suffix,_corrected);
    await p.setInt('xp_'+suffix,_xp);
    await p.setInt('streak_'+suffix,_streak);
  }
}
