import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../exam/exam_selection_page.dart';
import 'level_provider.dart';

class LevelPage extends StatelessWidget {
  const LevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LevelProvider(),
      child: const LevelView(),
    );
  }
}

class LevelView extends StatelessWidget {
  const LevelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seviye Seçimi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seviyenizi Seçin',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Diğer seviyeler ilerledikçe açılacaktır',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final level = index + 1;
                  return LevelCard(level: level);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelCard extends StatelessWidget {
  final int level;

  const LevelCard({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LevelProvider>();
    final isLocked = provider.isLevelLocked(level);

    return Material(
      color: isLocked
          ? AppColors.surface.withOpacity(0.1)
          : AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked
            ? null
            : () {
                provider.setLevel(level);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExamSelectionPage(),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Seviye $level',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? AppColors.text.withOpacity(0.5)
                          : AppColors.text,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: AppColors.text.withOpacity(0.5),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isLocked ? 'Kilitli' : 'Açık',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 