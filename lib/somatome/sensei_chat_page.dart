import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'sensei_service.dart';

class SenseiChatSheet extends StatefulWidget {
  final String level;
  final String contextDescription;

  const SenseiChatSheet({super.key, required this.level, this.contextDescription = ''});

  @override
  State<SenseiChatSheet> createState() => _SenseiChatSheetState();
}

class _SenseiMessage {
  final String text;
  final bool fromUser;

  const _SenseiMessage(this.text, {this.fromUser = false});
}

class _SenseiChatSheetState extends State<SenseiChatSheet> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool isTyping = false;
  final messages = <_SenseiMessage>[
    const _SenseiMessage(
      'こんにちは. Soy tu Sensei. Preguntame por gramatica, vocabulario, kanji o cualquier frase de tu ruta.',
    ),
  ];

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? preset]) async {
    final text = (preset ?? input.text).trim();
    if (text.isEmpty || isTyping) return;
    input.clear();
    setState(() {
      messages.add(_SenseiMessage(text, fromUser: true));
      isTyping = true;
    });
    final reply = await SenseiService.answerOnline(
      history: messages.map((message) => {
        'role': message.fromUser ? 'user' : 'assistant',
        'content': message.text,
      }).toList(),
      level: widget.level,
      contextDescription: widget.contextDescription,
    );
    if (!mounted) return;
    setState(() {
      messages.add(_SenseiMessage(reply.text));
      isTyping = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .82,
    minChildSize: .55,
    maxChildSize: .96,
    expand: false,
    builder: (context, sheetScroll) => Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.coral, AppColors.violet]),
                      boxShadow: [BoxShadow(color: AppColors.coral.withOpacity(.24), blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: const Center(child: SenseiCatMark(size: 27)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SENSEI', style: TextStyle(color: AppColors.coral, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.7)), const SizedBox(height: 3), const Text('Tu companero de estudio', style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(SenseiService.isOnlineConfigured ? 'Conectado a internet' : 'Modo local', style: TextStyle(color: SenseiService.isOnlineConfigured ? AppColors.mint : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w800))])),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), tooltip: 'Cerrar Sensei'),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border.withOpacity(.7)),
            Expanded(
              child: ListView.builder(
                controller: sheetScroll,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom: 12, left: 4), child: Text('Sensei esta pensando...', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700))));
                  }
                  final message = messages[index];
                  return Align(
                    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: message.fromUser ? AppColors.violet : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(19),
                          topRight: const Radius.circular(19),
                          bottomLeft: Radius.circular(message.fromUser ? 19 : 5),
                          bottomRight: Radius.circular(message.fromUser ? 5 : 19),
                        ),
                        border: Border.all(color: message.fromUser ? AppColors.violet : AppColors.border),
                      ),
                      child: Text(message.text, style: TextStyle(color: message.fromUser ? Colors.white : AppColors.ink, fontSize: 13, height: 1.42)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _SuggestionChip(label: 'ほど', onTap: () => send('Que significa ほど?')),
                  _SuggestionChip(label: 'ている', onTap: () => send('Explicame ている')),
                  _SuggestionChip(label: 'Vocabulario', onTap: () => send('Busca vocabulario')),
                  _SuggestionChip(label: 'Ejemplo', onTap: () => send('Dame un ejemplo')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Pregunta en espanol o japones...', prefixIcon: Icon(Icons.chat_bubble_outline_rounded)))),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: isTyping ? null : send, icon: const Icon(Icons.arrow_upward_rounded), tooltip: 'Enviar pregunta'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SenseiCatMark extends StatelessWidget {
  final double size;

  const SenseiCatMark({required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: SenseiCatPainter(),
  );
}

class SenseiCatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 40;
    canvas.save();
    canvas.scale(scale);
    const fur = Color(0xFFFFF9F0);
    const ink = Color(0xFF242233);
    const accent = Color(0xFFFFD166);
    final fill = Paint()..color = fur;
    final detail = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Distinct upright ears and a smooth silhouette keep Sensei recognizable.
    final silhouette = Path()
      ..moveTo(7, 17)
      ..lineTo(5.8, 5.2)
      ..quadraticBezierTo(5.7, 3.8, 7.1, 4.8)
      ..lineTo(14.3, 10.7)
      ..quadraticBezierTo(20, 8.7, 25.7, 10.7)
      ..lineTo(32.9, 4.8)
      ..quadraticBezierTo(34.3, 3.8, 34.2, 5.2)
      ..lineTo(33, 17)
      ..cubicTo(35.3, 20, 36, 22.6, 35.2, 26)
      ..cubicTo(33.7, 32, 27.8, 35.5, 20, 35.5)
      ..cubicTo(12.2, 35.5, 6.3, 32, 4.8, 26)
      ..cubicTo(4, 22.6, 4.7, 20, 7, 17)
      ..close();
    canvas.drawShadow(silhouette, const Color(0x550F1020), 2.2, false);
    canvas.drawPath(silhouette, fill);

    final leftEar = Path()
      ..moveTo(8, 8)
      ..lineTo(8.8, 15.1)
      ..lineTo(14.1, 11.8)
      ..close();
    final rightEar = Path()
      ..moveTo(32, 8)
      ..lineTo(31.2, 15.1)
      ..lineTo(25.9, 11.8)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = accent);
    canvas.drawPath(rightEar, Paint()..color = accent);

    final leftEye = Path()
      ..moveTo(12.4, 21)
      ..quadraticBezierTo(15, 23.2, 17.6, 21);
    final rightEye = Path()
      ..moveTo(22.4, 21)
      ..quadraticBezierTo(25, 23.2, 27.6, 21);
    canvas.drawPath(leftEye, detail);
    canvas.drawPath(rightEye, detail);
    canvas.drawCircle(const Offset(20, 24.2), 1.15, Paint()..color = accent);

    final smile = Path()
      ..moveTo(20, 25.3)
      ..lineTo(20, 26.5)
      ..quadraticBezierTo(20, 27.8, 18.2, 28);
    canvas.drawPath(smile, detail);
    final smileRight = Path()
      ..moveTo(20, 26.5)
      ..quadraticBezierTo(21.8, 27.8, 21.8, 28);
    canvas.drawPath(smileRight, detail);

    final whiskers = Paint()
      ..color = ink.withOpacity(.55)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(3.5, 24), const Offset(10, 24.8), whiskers);
    canvas.drawLine(const Offset(4.5, 28), const Offset(10.5, 27.2), whiskers);
    canvas.drawLine(const Offset(30, 24.8), const Offset(36.5, 24), whiskers);
    canvas.drawLine(const Offset(29.5, 27.2), const Offset(35.5, 28), whiskers);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.surface2,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}
