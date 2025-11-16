import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/premium_service.dart';

class HeartsIndicator extends StatefulWidget {
  final int totalHearts;
  final int remainingHearts;
  final double size;
  final VoidCallback? onTap;
  final bool showAddButton;

  const HeartsIndicator({
    super.key,
    required this.totalHearts,
    required this.remainingHearts,
    this.size = 24,
    this.onTap,
    this.showAddButton = false,
  });

  @override
  State<HeartsIndicator> createState() => _HeartsIndicatorState();
}

class _HeartsIndicatorState extends State<HeartsIndicator> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(HeartsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Premium servisi al
    final isPremium = Provider.of<PremiumService>(context).isPremium;
    
    return GestureDetector(
      onTap: isPremium ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
            Icon(
              Icons.favorite,
              color: isPremium 
                ? Colors.amber // Premium kullanıcılar için altın renk
                : (widget.remainingHearts > 0 
                  ? const Color(0xFFFF3366) // Canlı pembe-kırmızı
                  : Colors.grey.shade500),
              size: widget.size,
            ),
            const SizedBox(width: 6),
            isPremium
                ? Row(
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
                  )
                : Text(
                    '${widget.remainingHearts}/${widget.totalHearts}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.size * 0.7,
                    ),
                  ),
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
} 