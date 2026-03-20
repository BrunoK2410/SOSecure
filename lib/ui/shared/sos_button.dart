import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SosButton extends StatefulWidget {
  final VoidCallback? onCompleted;

  const SosButton({super.key, this.onCompleted});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shadowAnimation;

  Timer? _holdTimer;
  double _progress = 0.0;
  bool _isHolding = false;

  static const int _holdDurationMs = 2000;
  static const int _tickMs = 20;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 18, end: 30).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHolding() {
    if (_isHolding) return;

    _isHolding = true;
    _holdTimer?.cancel();

    final totalTicks = _holdDurationMs ~/ _tickMs;
    int currentTick = 0;

    _holdTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (timer) {
      currentTick++;
      final newProgress = currentTick / totalTicks;

      setState(() {
        _progress = newProgress.clamp(0.0, 1.0);
      });

      if (_progress >= 1.0) {
        timer.cancel();
        _isHolding = false;
        widget.onCompleted?.call();

        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          setState(() {
            _progress = 0.0;
          });
        });
      }
    });
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    _isHolding = false;

    if (_progress < 1.0) {
      setState(() {
        _progress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.62;
    final ringSize = buttonSize + 26;

    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: _stopHolding,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.danger,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.35),
                          blurRadius: _shadowAnimation.value,
                          spreadRadius: 4,
                        ),
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
