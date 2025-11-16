import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../quiz/quiz_page.dart';
import '../quiz/quiz_provider.dart';
import 'package:provider/provider.dart';
import '../learn/word_card_page.dart';
import '../../core/widgets/native_ad_widget.dart';
import '../../services/premium_service.dart';

class ExamSelectionPage extends StatelessWidget {
  final String category;
  final String? level;
  final String? wordListType;

  const ExamSelectionPage({
    super.key,
    required this.category,
    this.level,
    this.wordListType,
  });

  String getPageTitle() {
    if (wordListType != null) {
      switch (wordListType) {
        case 'oxford_3000':
          return 'The Oxford 3000';
        case 'oxford_5000':
          return 'The Oxford 5000';
        case 'word_bank':
          return 'Word Bank';
        case 'american_3000':
          return 'American Oxford 3000';
        case 'american_5000':
          return 'American Oxford 5000';
        default:
          return 'Word List';
      }
    } else {
      return 'Level $level';
    }
  }

  IconData getPageIcon() {
    if (wordListType != null) {
      switch (wordListType) {
        case 'oxford_3000':
          return Icons.auto_stories;
        case 'oxford_5000':
          return Icons.school;
        case 'word_bank':
          return Icons.account_balance;
        case 'american_3000':
          return Icons.language;
        case 'american_5000':
          return Icons.psychology;
        default:
          return Icons.book;
      }
    } else {
      return Icons.play_arrow;
    }
  }

  Color getPageColor() {
    if (wordListType != null) {
      switch (wordListType) {
        case 'oxford_3000':
          return Colors.blue;
        case 'oxford_5000':
          return Colors.purple;
        case 'word_bank':
          return Colors.orange;
        case 'american_3000':
          return Colors.red;
        case 'american_5000':
          return Colors.green;
        default:
          return Colors.blue;
      }
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageColor = getPageColor();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: pageColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getPageIcon(),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getPageTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF34495E),
            ],
          ),
        ),
        child: SafeArea(
          child: wordListType != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView(
                    children: [
                      Text(
                        'Select Level',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLevelCard(
                        context: context,
                        title: 'Mix',
                        subtitle: 'Mixed levels practice',
                        icon: Icons.shuffle,
                        color: const Color(0xFF9C27B0),
                      ),
                      const SizedBox(height: 16),
                      if (wordListType == 'oxford_5000' || wordListType == 'american_5000' || wordListType == 'word_bank') ...[
                        _buildLevelCard(
                          context: context,
                          title: 'A1 Level',
                          subtitle: 'Beginner',
                          icon: Icons.star_border,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'A2 Level',
                          subtitle: 'Elementary',
                          icon: Icons.star_half,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'B1 Level',
                          subtitle: 'Intermediate',
                          icon: Icons.star,
                          color: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'B2 Level',
                          subtitle: 'Upper Intermediate',
                          icon: Icons.stars,
                          color: const Color(0xFFF44336),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'C1 Level',
                          subtitle: 'Advanced',
                          icon: Icons.workspace_premium,
                          color: const Color(0xFF673AB7),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<PremiumService>(
                                builder: (context, premiumService, _) {
                                  if (premiumService.isPremium) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                                    child: Text(
                                      'Sponsorlu',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                                child: NativeAdWidget(
                                  height: 150,
                                  margin: 0,
                                  factoryId: wordListType == 'oxford_3000' 
                                      ? 'oxford3000NativeAd'
                                      : wordListType == 'oxford_5000'
                                          ? 'oxford5000NativeAd'
                                          : wordListType == 'american_3000'
                                              ? 'americanOxford3000NativeAd'
                                              : wordListType == 'american_5000'
                                                  ? 'americanOxford5000NativeAd'
                                                  : 'examPageNativeAd',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _buildLevelCard(
                          context: context,
                          title: 'A1 Level',
                          subtitle: 'Beginner',
                          icon: Icons.star_border,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'A2 Level',
                          subtitle: 'Elementary',
                          icon: Icons.star_half,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'B1 Level',
                          subtitle: 'Intermediate',
                          icon: Icons.star,
                          color: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          context: context,
                          title: 'B2 Level',
                          subtitle: 'Upper Intermediate',
                          icon: Icons.stars,
                          color: const Color(0xFFF44336),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<PremiumService>(
                                builder: (context, premiumService, _) {
                                  if (premiumService.isPremium) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                                    child: Text(
                                      'Sponsorlu',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(20)),
                                child: NativeAdWidget(
                                  height: 150,
                                  margin: 0,
                                  factoryId: wordListType == 'oxford_3000' 
                                      ? 'oxford3000NativeAd'
                                      : wordListType == 'oxford_5000'
                                          ? 'oxford5000NativeAd'
                                          : wordListType == 'american_3000'
                                              ? 'americanOxford3000NativeAd'
                                              : wordListType == 'american_5000'
                                                  ? 'americanOxford5000NativeAd'
                                                  : 'examPageNativeAd',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 24),
                      child: Text(
                        'Select Level',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 150, // Ekran boyutuna göre ayarlanmış yükseklik
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          final examNumber = index + 1;
                          return Consumer<QuizProvider>(
                            builder: (context, quizProvider, _) {
                              final quizId = '${category}_${level}_$examNumber';
                              final status = quizProvider.getQuizStatus(quizId);

                              return Card(
                                elevation: 4,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    quizProvider.loadQuestions(
                                      category,
                                      level!,
                                      examNumber,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuizPage(
                                          category: category,
                                          level: level!,
                                          examNumber: examNumber,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              alignment: Alignment.center,
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: pageColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$examNumber',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: pageColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Test $examNumber',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '10 Questions',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (status == QuizStatus.completed)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (status == QuizStatus.inProgress)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.play_circle,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (quizProvider.getHighScore(quizId) > 0)
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.emoji_events,
                                                  color: Colors.amber.shade700,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${quizProvider.getHighScore(quizId)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          String level = title.split(' ')[0];  // Extract level (A1, A2, etc.)
          if (category == 'learn') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WordCardPage(
                  level: level,
                  wordListType: wordListType ?? '',
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizPage(
                  category: category,
                  level: level,
                  examNumber: 1,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 