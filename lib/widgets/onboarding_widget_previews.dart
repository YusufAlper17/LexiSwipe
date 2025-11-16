import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Word Bank kartının önizlemesi
class WordBankPreview extends StatelessWidget {
  const WordBankPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.purple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Word Bank',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '125 kelime',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.swipe_left, size: 12, color: Colors.blue.shade700),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Sola kaydırdığınız kelimeler burada saklanır',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 10),
          _buildWordItem('appropriate', 'uygun', 'B1'),
          _buildWordItem('enhance', 'artırmak', 'B2'),
        ],
      ),
    );
  }

  Widget _buildWordItem(String word, String meaning, String level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            Icons.swipe_left,
            size: 10,
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 4,
            child: Text(
              word,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              meaning,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor(level).withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              level,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _getLevelColor(level),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return Colors.green;
      case 'A2':
        return Colors.lightGreen;
      case 'B1':
        return Colors.amber;
      case 'B2':
        return Colors.orange;
      case 'C1':
        return Colors.deepOrange;
      case 'C2':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

/// Mistakes kartının önizlemesi
class MistakesPreview extends StatelessWidget {
  const MistakesPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hatalar',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '8 hata',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Practice bölümünde yaptığınız hatalar burada saklanır',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          _buildMistakeItem('accommodate', 'barındırmak', 'C1'),
          _buildMistakeItem('ambiguous', 'belirsiz', 'B2'),
        ],
      ),
    );
  }

  Widget _buildMistakeItem(String word, String meaning, String level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.close_rounded,
            color: Colors.red.shade400,
            size: 12,
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 4,
            child: Text(
              word,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              meaning,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: _getLevelColor(level).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              level,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getLevelColor(level),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return Colors.green;
      case 'A2':
        return Colors.lightGreen;
      case 'B1':
        return Colors.amber;
      case 'B2':
        return Colors.orange;
      case 'C1':
        return Colors.deepOrange;
      case 'C2':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

/// Kelime kartı önizlemesi
class WordCardPreview extends StatelessWidget {
  final bool isFlipped;
  
  const WordCardPreview({super.key, this.isFlipped = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isFlipped
                  ? [Colors.blue.shade50, Colors.indigo.shade100]
                  : [Colors.amber.shade50, Colors.orange.shade100],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'B2',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFlipped ? 'Anlamı:' : 'Word:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFlipped ? 'açıklamak, izah etmek' : 'elaborate',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (isFlipped) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Örnek Cümle:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Could you elaborate on your proposal?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Icon(
                  Icons.volume_up,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 