import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

/// Саҳнаи "чароғи кашолашаванда": корбар сими чароғро поён мекашад, чароғ
/// равшан мешавад ва мундариҷаи воқеии экран (масалан, экрани хушомадгӯӣ/
/// бақайдгирӣ) бо аниматсия пайдо мешавад. Агар бозкашад, чароғ хомӯш шуда
/// мундариҷа пушида мешавад.
///
/// Ин як виҷети комилан визуалӣ аст — ҳеҷ мантиқи воқеӣ (бақайдгирӣ,
/// аутентификатсия) дар дохили он нест; [child] ҳамон мундариҷаи ҳозираи
/// воқеии экран (масалан AppLogo + матн + тугмаи "Давом" аслӣ)-ро мегирад ва
/// танҳо намоиши онро идора мекунад, бе тағйир додани мантиқи дохили он.
class LampPullReveal extends StatefulWidget {
  final Widget child;
  final double lampAreaHeight;

  const LampPullReveal({
    super.key,
    required this.child,
    this.lampAreaHeight = 230,
  });

  @override
  State<LampPullReveal> createState() => _LampPullRevealState();
}

class _Firefly {
  final double baseX, baseY, ampX, ampY, phase, speed, size;
  _Firefly({
    required this.baseX,
    required this.baseY,
    required this.ampX,
    required this.ampY,
    required this.phase,
    required this.speed,
    required this.size,
  });
}

class _LampPullRevealState extends State<LampPullReveal>
    with TickerProviderStateMixin {
  static const double _stringBaseLength = 46;
  static const double _maxPull = 72;
  static const double _pullThreshold = 34;

  bool _isOn = false;
  bool _dragging = false;
  double _dragDy = 0;

  late final AnimationController _fireflyController;
  late final AnimationController _hintController;
  final List<_Firefly> _fireflies = [];

  @override
  void initState() {
    super.initState();
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    final rnd = Random(7);
    for (var i = 0; i < 16; i++) {
      _fireflies.add(_Firefly(
        baseX: rnd.nextDouble(),
        baseY: rnd.nextDouble(),
        ampX: 14 + rnd.nextDouble() * 26,
        ampY: 14 + rnd.nextDouble() * 26,
        phase: rnd.nextDouble() * 2 * pi,
        speed: 0.05 + rnd.nextDouble() * 0.08,
        size: 3 + rnd.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _fireflyController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _dragging = true;
      _dragDy = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _dragDy = (_dragDy + d.delta.dy).clamp(0.0, _maxPull);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final pulled = _dragDy > _pullThreshold;
    setState(() {
      _dragging = false;
      _dragDy = 0;
    });
    if (pulled) {
      HapticFeedback.mediumImpact();
      setState(() => _isOn = !_isOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Ҳавои гарми чароғ дар паси ҳама чиз — танҳо вақте ки чароғ
          // равшан аст.
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _isOn ? 1 : 0,
              duration: const Duration(milliseconds: 700),
              child: Align(
                alignment: const Alignment(0, -0.8),
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFDC64).withValues(alpha: 0.16),
                        const Color(0xFFFFD600).withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: _buildFireflies()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: widget.lampAreaHeight,
                  width: double.infinity,
                  child: _buildLamp(),
                ),
                Expanded(child: _buildReveal()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireflies() {
    return AnimatedOpacity(
      opacity: _isOn ? 1 : 0,
      duration: const Duration(milliseconds: 600),
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _fireflyController,
              builder: (context, _) {
                // Истифодаи вақти муттасил (на танҳо 0..1) барои ҳаракати
                // бефосила, чунки контролер ҳар сония такрор мешавад.
                final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
                return Stack(
                  children: _fireflies.map((f) {
                    final dx = f.baseX * constraints.maxWidth +
                        sin((t * f.speed + f.phase) * 2 * pi) * f.ampX;
                    final dy = f.baseY * constraints.maxHeight +
                        cos((t * f.speed * 0.7 + f.phase) * 2 * pi) * f.ampY;
                    return Positioned(
                      left: dx,
                      top: dy,
                      child: Container(
                        width: f.size,
                        height: f.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFEA00),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFEA00).withValues(alpha: 0.85),
                              blurRadius: 8,
                              spreadRadius: 1.5,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLamp() {
    const anchorTop = 18.0;
    const headWidth = 118.0;
    const headHeight = 44.0;
    final stringLength = _stringBaseLength + _dragDy;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Партави нур — конуси гарм аз сар ба поён.
        Positioned(
          top: anchorTop + headHeight - 6,
          child: AnimatedOpacity(
            opacity: _isOn ? 1 : 0,
            duration: const Duration(milliseconds: 450),
            child: ClipPath(
              clipper: _BeamClipper(),
              child: Container(
                width: 260,
                height: widget.lampAreaHeight - headHeight - anchorTop,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFE68C).withValues(alpha: 0.55),
                      const Color(0xFFFFC850).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Сарпӯши чароғ (гунбаз).
        Positioned(
          top: anchorTop,
          child: Container(
            width: headWidth,
            height: headHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF17171A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(70),
                topRight: Radius.circular(70),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              boxShadow: _isOn
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD08C).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 14),
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
        // Лампочка — байзаи сафед дар зери сарпӯш.
        Positioned(
          top: anchorTop + headHeight - 8,
          child: AnimatedOpacity(
            opacity: _isOn ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            child: Container(
              width: 64,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFE696).withValues(alpha: 0.9), blurRadius: 30, spreadRadius: 10),
                  BoxShadow(color: const Color(0xFFFFC850).withValues(alpha: 0.6), blurRadius: 60, spreadRadius: 20),
                ],
              ),
            ),
          ),
        ),
        // Сим (банд).
        Positioned(
          top: anchorTop + headHeight - 4,
          child: Container(width: 2, height: stringLength, color: const Color(0xFF30343A)),
        ),
        // Дастаки кашолашаванда.
        Positioned(
          top: anchorTop + headHeight - 4 + stringLength - 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Container(
                width: 14,
                height: 26,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFEBD17A), Color(0xFFAA8529)],
                  ),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 3)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Дасти аниматсионӣ — ишорае ки симро бояд кашид.
        Positioned(
          top: anchorTop + headHeight + stringLength + 6,
          child: AnimatedOpacity(
            opacity: _isOn || _dragging ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: AnimatedBuilder(
              animation: _hintController,
              builder: (context, _) {
                final dy = Curves.easeInOut.transform(_hintController.value) * 14;
                return Transform.translate(
                  offset: Offset(26, dy),
                  child: Column(
                    children: [
                      Transform.rotate(
                        angle: -0.35,
                        child: const Text('🤚', style: TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('k442'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal() {
    return AnimatedSlide(
      offset: _isOn ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isOn ? 1 : 0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !_isOn,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Шакли трапецияшаклро барои конуси нур мебарорад (мисли CSS
/// clip-path: polygon(40% 0, 60% 0, 100% 100%, 0 100%)).
class _BeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.6, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
