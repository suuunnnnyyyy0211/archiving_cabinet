import 'dart:math' as math;
import 'package:flutter/material.dart';

class MainDashboardBackground extends StatefulWidget {
  final Widget child;

  const MainDashboardBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MainDashboardBackground> createState() => _MainDashboardBackgroundState();
}

class _MainDashboardBackgroundState extends State<MainDashboardBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<DeepSeaParticle> _particles = [];
  final int _particleCount = 50;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 초기 빛 입자 생성 (시안 #00CEC9 & 코랄핑크 #FF6B81 조합)
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(DeepSeaParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 3.5 + 1.5,
        speed: _random.nextDouble() * 0.025 + 0.008,
        amplitude: _random.nextDouble() * 0.015 + 0.004,
        frequency: _random.nextDouble() * 2.5 + 1.0,
        phase: _random.nextDouble() * 2 * math.pi,
        color: _random.nextBool()
            ? const Color(0xFF00CEC9) // Cyan
            : const Color(0xFFFF6B81), // Coral Pink
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // 상단 중앙에서 퍼져나가는 방사형 그라데이션 (네온 바이올렛 -> 심해 딥 네이비)
        gradient: RadialGradient(
          center: Alignment(0.0, -0.7),
          radius: 1.3,
          colors: [
            Color(0xFF6B2D8C), // 네온 바이올렛 / 마젠타 중심부
            Color(0xFF1D0D33), // 중간 전환 퍼플
            Color(0xFF0A041A), // 하단 심해 딥 네이비
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 산호초 실루엣 및 유기적 빛 입자 페인터
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: DeepSeaPainter(
                  animationValue: _controller.value,
                  particles: _particles,
                ),
                size: Size.infinite,
              );
            },
          ),
          // 메인 대시보드 컨텐츠 레이어
          widget.child,
        ],
      ),
    );
  }
}

class DeepSeaParticle {
  double x;
  double y;
  double radius;
  double speed;
  double amplitude;
  double frequency;
  double phase;
  Color color;

  DeepSeaParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.color,
  });

  void update(double t) {
    // 위로 서서히 떠오르는 움직임
    y -= speed * 0.04;
    if (y < -0.05) {
      y = 1.05;
      x = math.Random().nextDouble();
    }
    // 사인파 공식을 적용한 좌우 호 그리며 떠다니는 해류 효과
    x += math.sin(t * frequency * 2 * math.pi + phase) * amplitude * 0.1;
  }
}

class DeepSeaPainter extends CustomPainter {
  final double animationValue;
  final List<DeepSeaParticle> particles;

  DeepSeaPainter({
    required this.animationValue,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 하단 산호초 실루엣 렌더링 (저폴리곤/기하학적 형태)
    _drawCoralSilhouettes(canvas, size);

    // 2. 빛의 합성 모드(BlendMode.screen)를 적용한 입자 렌더링
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update(animationValue);
      final dx = particle.x * size.width;
      final dy = particle.y * size.height;

      // 입자 코어 (선명한 네온 빛)
      paint.color = particle.color.withOpacity(0.85);
      canvas.drawCircle(Offset(dx, dy), particle.radius, paint);

      // 주변 후광 효과 (은은하게 퍼지는 빛)
      paint.color = particle.color.withOpacity(0.25);
      canvas.drawCircle(Offset(dx, dy), particle.radius * 2.8, paint);
    }
  }

  void _drawCoralSilhouettes(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 뒷단 심해 산호초 레이어 (어두운 퍼플톤)
    paint.color = const Color(0xFF130826).withOpacity(0.95);
    final pathBack = Path();
    pathBack.moveTo(0, size.height);
    pathBack.lineTo(0, size.height * 0.78);
    pathBack.lineTo(size.width * 0.12, size.height * 0.72);
    pathBack.lineTo(size.width * 0.25, size.height * 0.82);
    pathBack.lineTo(size.width * 0.40, size.height * 0.68);
    pathBack.lineTo(size.width * 0.55, size.height * 0.80);
    pathBack.lineTo(size.width * 0.70, size.height * 0.70);
    pathBack.lineTo(size.width * 0.85, size.height * 0.77);
    pathBack.lineTo(size.width, size.height * 0.73);
    pathBack.lineTo(size.width, size.height);
    pathBack.close();
    canvas.drawPath(pathBack, paint);

    // 앞단 메인 산호초 레이어 (심해 실루엣)
    final pathFront = Path();
    pathFront.moveTo(0, size.height);
    pathFront.lineTo(0, size.height * 0.85);
    pathFront.lineTo(size.width * 0.08, size.height * 0.76);
    pathFront.lineTo(size.width * 0.20, size.height * 0.88);
    pathFront.lineTo(size.width * 0.32, size.height * 0.73);
    pathFront.lineTo(size.width * 0.46, size.height * 0.90);
    pathFront.lineTo(size.width * 0.60, size.height * 0.79);
    pathFront.lineTo(size.width * 0.78, size.height * 0.86);
    pathFront.lineTo(size.width, size.height * 0.80);
    pathFront.lineTo(size.width, size.height);
    pathFront.close();

    paint.color = const Color(0xFF0B0417);
    canvas.drawPath(pathFront, paint);

    // 산호초 끝단 네온 엣지 라인 (시안 및 코랄핑크 포인트 발광)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..blendMode = BlendMode.screen;

    strokePaint.color = const Color(0xFF00CEC9).withOpacity(0.65);
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.88),
      Offset(size.width * 0.24, size.height * 0.80),
      strokePaint,
    );

    strokePaint.color = const Color(0xFFFF6B81).withOpacity(0.65);
    canvas.drawLine(
      Offset(size.width * 0.46, size.height * 0.90),
      Offset(size.width * 0.50, size.height * 0.82),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant DeepSeaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainDashboardBackground(
        child: Center(
          child: Text(
            'Abyssrium Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}