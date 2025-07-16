import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/parameter.dart';

class KnobWidget extends StatefulWidget {
  final Parameter parameter;
  final double size;
  final VoidCallback? onTap;
  final Function(double)? onValueChanged;

  const KnobWidget({
    Key? key,
    required this.parameter,
    this.size = 100,
    this.onTap,
    this.onValueChanged,
  }) : super(key: key);

  @override
  _KnobWidgetState createState() => _KnobWidgetState();
}

class _KnobWidgetState extends State<KnobWidget> {
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.parameter.value;
  }

  @override
  void didUpdateWidget(KnobWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parameter.value != widget.parameter.value) {
      _currentValue = widget.parameter.value;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final position = details.localPosition - center;
    
    // Calculate angle from center
    final angle = math.atan2(position.dy, position.dx);
    
    // Convert angle to value (0-1)
    // Map from -π to π to 0-1, with some dead zone at the bottom
    const startAngle = -3 * math.pi / 4; // -135°
    const endAngle = 3 * math.pi / 4;    // +135°
    
    double normalizedAngle;
    if (angle >= startAngle && angle <= endAngle) {
      normalizedAngle = (angle - startAngle) / (endAngle - startAngle);
    } else {
      // Handle wrap-around
      if (angle < startAngle) {
        normalizedAngle = 0.0;
      } else {
        normalizedAngle = 1.0;
      }
    }
    
    final newValue = normalizedAngle.clamp(0.0, 1.0);
    
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onValueChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: _handlePanUpdate,
      child: Container(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: KnobPainter(
            parameter: widget.parameter.copyWith(value: _currentValue),
            theme: Theme.of(context),
          ),
        ),
      ),
    );
  }
}

class KnobPainter extends CustomPainter {
  final Parameter parameter;
  final ThemeData theme;

  KnobPainter({
    required this.parameter,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Draw outer ring with dots
    _drawOuterRing(canvas, center, radius);
    
    // Draw knob circle
    _drawKnobCircle(canvas, center, radius);
    
    // Draw value indicator
    _drawValueIndicator(canvas, center, radius);
    
    // Draw center dot
    _drawCenterDot(canvas, center);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw dots around the circumference
    const dotCount = 24;
    const dotRadius = 2.0;
    final outerRadius = radius + 8;

    for (int i = 0; i < dotCount; i++) {
      final angle = (i * 2 * math.pi / dotCount) - math.pi / 2;
      final dotX = center.dx + outerRadius * math.cos(angle);
      final dotY = center.dy + outerRadius * math.sin(angle);
      
      canvas.drawCircle(Offset(dotX, dotY), dotRadius, paint);
    }
  }

  void _drawKnobCircle(Canvas canvas, Offset center, double radius) {
    // Draw main knob circle
    final knobPaint = Paint()
      ..color = theme.colorScheme.surface
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 15, knobPaint);
    canvas.drawCircle(center, radius - 15, borderPaint);
  }

  void _drawValueIndicator(Canvas canvas, Offset center, double radius) {
    // Calculate angle based on parameter value (0-1)
    // Map 0-1 to -135° to +135° (270° total range)
    const startAngle = -3 * math.pi / 4; // -135°
    const endAngle = 3 * math.pi / 4;    // +135°
    final valueAngle = startAngle + (endAngle - startAngle) * parameter.value;
    
    // Draw the value indicator dot
    final indicatorPaint = Paint()
      ..color = Color.fromRGBO(
        parameter.color.r,
        parameter.color.g,
        parameter.color.b,
        1.0,
      )
      ..style = PaintingStyle.fill;

    final indicatorRadius = radius - 5;
    final indicatorX = center.dx + indicatorRadius * math.cos(valueAngle);
    final indicatorY = center.dy + indicatorRadius * math.sin(valueAngle);
    
    canvas.drawCircle(Offset(indicatorX, indicatorY), 4, indicatorPaint);
    
    // Draw arc showing the value range
    final arcPaint = Paint()
      ..color = Color.fromRGBO(
        parameter.color.r,
        parameter.color.g,
        parameter.color.b,
        0.3,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius - 5);
    canvas.drawArc(
      arcRect,
      startAngle,
      valueAngle - startAngle,
      false,
      arcPaint,
    );
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    final centerPaint = Paint()
      ..color = theme.colorScheme.onSurface
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint when parameter values change
  }
}

class KnobCard extends StatelessWidget {
  final Parameter parameter;
  final VoidCallback? onTap;
  final Function(double)? onValueChanged;

  const KnobCard({
    Key? key,
    required this.parameter,
    this.onTap,
    this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Parameter name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              parameter.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Knob widget
          KnobWidget(
            parameter: parameter,
            size: 80,
            onTap: onTap,
            onValueChanged: onValueChanged,
          ),
          
          const SizedBox(height: 8),
          
          // Parameter value
          Text(
            parameter.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

 