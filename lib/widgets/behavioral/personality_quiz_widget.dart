import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/value_objects/money_personality_type.dart';
import '../../domain/value_objects/life_stage.dart';
import '../../providers/behavioral_insight_provider.dart';

/// A widget that guides users through discovering their money personality
/// Uses behavioral questions to determine the user's financial archetype
class PersonalityQuizWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const PersonalityQuizWidget({
    super.key,
    this.onComplete,
  });

  @override
  State<PersonalityQuizWidget> createState() => _PersonalityQuizWidgetState();
}

class _PersonalityQuizWidgetState extends State<PersonalityQuizWidget> {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  final PageController _pageController = PageController();

  // Questions for personality determination
  static const List<QuizQuestion> _questions = [
    QuizQuestion(
      id: 'q1',
      text: 'When you receive unexpected money, what\'s your first thought?',
      options: [
        QuizOption(
          text: 'I should save or invest it',
          personality: MoneyPersonalityType.saver,
        ),
        QuizOption(
          text: 'Time to treat myself!',
          personality: MoneyPersonalityType.spender,
        ),
        QuizOption(
          text: 'Who can I help with this?',
          personality: MoneyPersonalityType.sharer,
        ),
        QuizOption(
          text: 'How can I grow this amount?',
          personality: MoneyPersonalityType.investor,
        ),
        QuizOption(
          text: 'Let\'s make even more!',
          personality: MoneyPersonalityType.gambler,
        ),
      ],
    ),
    QuizQuestion(
      id: 'q2',
      text: 'You see something you really want but can\'t quite afford. You...',
      options: [
        QuizOption(
          text: 'Wait and save up for it',
          personality: MoneyPersonalityType.saver,
        ),
        QuizOption(
          text: 'Buy it now, worry later',
          personality: MoneyPersonalityType.spender,
        ),
        QuizOption(
          text: 'Consider if buying it helps others',
          personality: MoneyPersonalityType.sharer,
        ),
        QuizOption(
          text: 'Calculate the opportunity cost',
          personality: MoneyPersonalityType.investor,
        ),
        QuizOption(
          text: 'It\'s a calculated risk',
          personality: MoneyPersonalityType.gambler,
        ),
      ],
    ),
    QuizQuestion(
      id: 'q3',
      text: 'Your friend asks to borrow money. You...',
      options: [
        QuizOption(
          text: 'Worry about getting it back',
          personality: MoneyPersonalityType.saver,
        ),
        QuizOption(
          text: 'Give it without thinking',
          personality: MoneyPersonalityType.spender,
        ),
        QuizOption(
          text: 'Always try to help',
          personality: MoneyPersonalityType.sharer,
        ),
        QuizOption(
          text: 'Consider the financial implications',
          personality: MoneyPersonalityType.investor,
        ),
        QuizOption(
          text: 'Maybe I\'ll get lucky',
          personality: MoneyPersonalityType.gambler,
        ),
      ],
    ),
    QuizQuestion(
      id: 'q4',
      text: 'What\'s your approach to budgeting?',
      options: [
        QuizOption(
          text: 'Track every penny',
          personality: MoneyPersonalityType.saver,
        ),
        QuizOption(
          text: 'Budgets are boring',
          personality: MoneyPersonalityType.spender,
        ),
        QuizOption(
          text: 'Budget for giving too',
          personality: MoneyPersonalityType.sharer,
        ),
        QuizOption(
          text: 'Focus on long-term growth',
          personality: MoneyPersonalityType.investor,
        ),
        QuizOption(
          text: 'Roll the dice each month',
          personality: MoneyPersonalityType.gambler,
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Your Money Personality'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(),

          // Questions
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length + 1, // +1 for results
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return _buildResultsPage();
                }
                return _buildQuestionPage(_questions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalSteps = _questions.length + 1;
    final progress = (_currentStep + 1) / totalSteps;

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[200],
      minHeight: 4,
    );
  }

  Widget _buildQuestionPage(QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),

          // Question number
          Text(
            'Question ${_questions.indexOf(question) + 1} of ${_questions.length}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 16),

          // Question text
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const Spacer(flex: 3),

          // Options
          ...question.options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                option: option,
                onTap: () => _selectOption(question, option),
              ),
            );
          }),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    final personality = _calculatePersonality();
    final provider = context.read<BehavioralInsightProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),

          // Result icon
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _getPersonalityEmoji(personality),
              style: const TextStyle(fontSize: 48),
            ),
          ),

          const SizedBox(height: 24),

          // Result label
          Text(
            'Your Money Personality',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Personality name
          Text(
            personality.displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Personality description
          Text(
            personality.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Traits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Traits',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...personality.traits.map((trait) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(trait)),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const Spacer(flex: 3),

          // Save button
          FilledButton(
            onPressed: () async {
              await provider.updatePersonalityType(personality);
              if (mounted) {
                widget.onComplete?.call();
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save & Continue'),
          ),

          const SizedBox(height: 16),

          // Retake button
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _answers.clear();
              });
              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            child: const Text('Retake Quiz'),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  void _selectOption(QuizQuestion question, QuizOption option) {
    _answers[question.id] = option.personality;

    // Animate to next page
    if (_currentStep < _questions.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  MoneyPersonalityType _calculatePersonality() {
    // Count occurrences of each personality
    final counts = <MoneyPersonalityType, int>{};
    for (final answer in _answers.values) {
      counts[answer] = (counts[answer] ?? 0) + 1;
    }

    // Find the most common
    MoneyPersonalityType? mostCommon;
    int maxCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon ?? MoneyPersonalityType.spender;
  }

  String _getPersonalityEmoji(MoneyPersonalityType personality) {
    switch (personality) {
      case MoneyPersonalityType.saver:
        return '🐷';
      case MoneyPersonalityType.spender:
        return '🛍️';
      case MoneyPersonalityType.sharer:
        return '🤝';
      case MoneyPersonalityType.investor:
        return '📈';
      case MoneyPersonalityType.gambler:
        return '🎲';
    }
  }
}

class _OptionCard extends StatelessWidget {
  final QuizOption option;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
}

class QuizOption {
  final String text;
  final MoneyPersonalityType personality;

  const QuizOption({
    required this.text,
    required this.personality,
  });
}

/// Extension for personality display
extension MoneyPersonalityExtension on MoneyPersonalityType {
  String get displayName {
    switch (this) {
      case MoneyPersonalityType.saver:
        return 'The Saver';
      case MoneyPersonalityType.spender:
        return 'The Spender';
      case MoneyPersonalityType.sharer:
        return 'The Sharer';
      case MoneyPersonalityType.investor:
        return 'The Investor';
      case MoneyPersonalityType.gambler:
        return 'The Gambler';
    }
  }

  String get description {
    switch (this) {
      case MoneyPersonalityType.saver:
        return 'You value security and are naturally frugal. Saving money gives you peace of mind.';
      case MoneyPersonalityType.spender:
        return 'You enjoy spending and treating yourself. Money is meant to be used for experiences.';
      case MoneyPersonalityType.sharer:
        return 'You find joy in helping others. Generosity is one of your core values.';
      case MoneyPersonalityType.investor:
        return 'You think long-term and look for opportunities to grow your wealth.';
      case MoneyPersonalityType.gambler:
        return 'You\'re comfortable with risk and seek high-reward opportunities.';
    }
  }

  List<String> get traits {
    switch (this) {
      case MoneyPersonalityType.saver:
        return [
          'Naturally frugal',
          'Plans ahead',
          'Security-focused',
          'Debt-averse',
        ];
      case MoneyPersonalityType.spender:
        return [
          'Enjoys treats',
          'Living in the moment',
          'Experience-oriented',
          'Generous with self',
        ];
      case MoneyPersonalityType.sharer:
        return [
          'Generous giver',
          'Community-focused',
          'Helps others first',
          'Values relationships',
        ];
      case MoneyPersonalityType.investor:
        return [
          'Long-term thinker',
          'Growth-oriented',
          'Financially literate',
          'Opportunity-seeker',
        ];
      case MoneyPersonalityType.gambler:
        return [
          'Risk-tolerant',
          'Thrill-seeker',
          'High-reward focused',
          'Optimistic',
        ];
    }
  }
}
