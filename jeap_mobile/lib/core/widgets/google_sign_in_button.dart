import 'package:flutter/material.dart';

/// Official Google Sign-In button adhering to Google Identity guidelines.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          side: const BorderSide(color: Color(0xFF747775), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleLogo(),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Google multi-color G
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final innerRadius = radius * 0.55;

    // Blue horizontal bar & right arc
    final bluePath = Path();
    bluePath.moveTo(center.dx, center.dy - innerRadius * 0.35);
    bluePath.lineTo(w, center.dy - innerRadius * 0.35);
    bluePath.lineTo(w, center.dy + innerRadius * 0.35);
    bluePath.lineTo(center.dx, center.dy + innerRadius * 0.35);
    bluePath.close();

    final blueArcPath = Path();
    blueArcPath.addArc(
        Rect.fromCircle(center: center, radius: radius), -0.5, 1.0);
    blueArcPath.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius), 0.5, -1.0, false);
    blueArcPath.close();

    // Red arc (top)
    final redPath = Path();
    redPath.addArc(
        Rect.fromCircle(center: center, radius: radius), -2.35, 1.85);
    redPath.arcTo(Rect.fromCircle(center: center, radius: innerRadius), -0.5,
        -1.85, false);
    redPath.close();

    // Yellow arc (left)
    final yellowPath = Path();
    yellowPath.addArc(
        Rect.fromCircle(center: center, radius: radius), -3.6, 1.25);
    yellowPath.arcTo(Rect.fromCircle(center: center, radius: innerRadius),
        -2.35, -1.25, false);
    yellowPath.close();

    // Green arc (bottom)
    final greenPath = Path();
    greenPath.addArc(
        Rect.fromCircle(center: center, radius: radius), 0.5, 1.55);
    greenPath.arcTo(Rect.fromCircle(center: center, radius: innerRadius), 2.05,
        -1.55, false);
    greenPath.close();

    canvas.drawPath(redPath, redPaint);
    canvas.drawPath(yellowPath, yellowPaint);
    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(blueArcPath, bluePaint);
    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
