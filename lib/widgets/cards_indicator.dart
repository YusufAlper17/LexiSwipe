import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/premium_service.dart';

class CardsIndicator extends StatefulWidget {
  final int totalCards;
  final int remainingCards;
  final double size;
  final VoidCallback? onTap;
  final bool showAddButton;

  const CardsIndicator({
    super.key,
    required this.totalCards,
    required this.remainingCards,
    this.size = 24,
    this.onTap,
    this.showAddButton = false,
  });

  @override
  State<CardsIndicator> createState() => _CardsIndicatorState();
}

class _CardsIndicatorState extends State<CardsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  int _previousCards = 0;

  @override
  void initState() {
    super.initState();
    _previousCards = widget.remainingCards;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didUpdateWidget(CardsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingCards < _previousCards) {
      _controller.forward(from: 0.0).then((_) {
        _controller.reset();
      });
    }
    _previousCards = widget.remainingCards;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium servisini al
    final isPremium = Provider.of<PremiumService>(context).isPremium;
    
    return GestureDetector(
      onTap: isPremium ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isPremium ? Colors.amber.withOpacity(0.5) : Colors.white.withOpacity(0.3),
            width: isPremium ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Subtle glow behind icon
                Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Icon(
                  Icons.style_rounded,
                  color: isPremium ? Colors.amber : Colors.white,
                  size: widget.size,
                ),
              ],
            ),
            const SizedBox(width: 8),
            isPremium ? _buildPremiumCardCount() : _buildCardCount(),
            if (!isPremium && widget.showAddButton)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade500,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCardCount() {
    return Row(
      children: [
        Icon(
          Icons.all_inclusive,
          color: Colors.amber,
          size: widget.size * 0.7,
        ),
        SizedBox(width: 3),
        Text(
          "Premium",
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w600,
            fontSize: widget.size * 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCardCount() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isAnimating = _controller.isAnimating;
        
        return Transform.scale(
          scale: isAnimating ? _scaleAnimation.value : 1.0,
          child: Opacity(
            opacity: isAnimating ? _opacityAnimation.value : 1.0,
            child: Text(
              "${widget.remainingCards}/${widget.totalCards}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: "Roboto",  // Material Design font
                fontSize: widget.size * 0.75,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
} 