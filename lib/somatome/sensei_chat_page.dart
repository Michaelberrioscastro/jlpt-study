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
    final fill = Paint()..color = Colors.white;
    final ink = Paint()..color = AppColors.violet..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final head = Rect.fromCenter(center: center, width: size.width * .68, height: size.height * .56);
    final ears = Path()
      ..moveTo(size.width * .19, size.height * .40)
      ..lineTo(size.width * .25, size.height * .10)
      ..lineTo(size.width * .43, size.height * .30)
      ..moveTo(size.width * .57, size.height * .30)
      ..lineTo(size.width * .75, size.height * .10)
      ..lineTo(size.width * .81, size.height * .40);
    canvas.drawPath(ears, fill);
    canvas.drawOval(head, fill);
    canvas.drawCircle(Offset(size.width * .39, size.height * .49), 1.2, ink);
    canvas.drawCircle(Offset(size.width * .61, size.height * .49), 1.2, ink);
    canvas.drawCircle(Offset(size.width * .50, size.height * .60), 1.1, ink);
    canvas.drawArc(Rect.fromCenter(center: Offset(size.width * .50, size.height * .63), width: size.width * .17, height: size.height * .12), 0, 3.14, false, ink);
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
