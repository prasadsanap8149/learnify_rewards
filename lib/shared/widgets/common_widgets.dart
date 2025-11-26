import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Loading indicator widget
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSizes.xxl * 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error widget
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppIconSizes.xxl * 1.5,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom app bar with gradient
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

/// LP Balance badge
class LPBadge extends StatelessWidget {
  final double balance;
  final bool large;

  const LPBadge({
    super.key,
    required this.balance,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSpacing.md : AppSpacing.sm,
        vertical: large ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            size: large ? AppIconSizes.md : AppIconSizes.sm,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: large ? AppSpacing.sm : AppSpacing.xs),
          Text(
            '${balance.toInt()} LP',
            style: (large
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Difficulty chip
class DifficultyChip extends StatelessWidget {
  final String difficulty;
  final bool compact;

  const DifficultyChip({
    super.key,
    required this.difficulty,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor(difficulty);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: compact ? AppIconSizes.xs : AppIconSizes.sm,
            color: color,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            difficulty.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? AppFontSizes.xs : AppFontSizes.sm,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case AppConstants.difficultyBeginner:
        return const Color(AppColors.beginnerValue);
      case AppConstants.difficultyIntermediate:
        return const Color(AppColors.intermediateValue);
      case AppConstants.difficultyAdvanced:
        return const Color(AppColors.advancedValue);
      default:
        return Colors.grey;
    }
  }
}

/// Activity type icon
class ActivityTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const ActivityTypeIcon({
    super.key,
    required this.type,
    this.size = AppIconSizes.lg,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(type);
    final color = _getColor(type);

    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        iconData,
        size: size,
        color: color,
      ),
    );
  }

  IconData _getIconData(String type) {
    switch (type.toLowerCase()) {
      case AppConstants.activityTypeMath:
        return Icons.calculate;
      case AppConstants.activityTypeWord:
        return Icons.font_download;
      case AppConstants.activityTypePuzzle:
        return Icons.extension;
      case AppConstants.activityTypeQuiz:
        return Icons.quiz;
      default:
        return Icons.school;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case AppConstants.activityTypeMath:
        return const Color(AppColors.mathColor);
      case AppConstants.activityTypeWord:
        return const Color(AppColors.wordColor);
      case AppConstants.activityTypePuzzle:
        return const Color(AppColors.puzzleColor);
      case AppConstants.activityTypeQuiz:
        return const Color(AppColors.quizColor);
      default:
        return Colors.grey;
    }
  }
}

/// Stat card widget
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIconSizes.lg,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress indicator with percentage
class ProgressCard extends StatelessWidget {
  final String title;
  final double progress; // 0.0 to 1.0
  final String? subtitle;
  final Color? color;

  const ProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: progressColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom bottom sheet
class CustomBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: actions!
                  .expand((widget) => [widget, const SizedBox(width: AppSpacing.sm)])
                  .toList()
                ..removeLast(),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
