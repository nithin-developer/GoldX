import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(
              actionText!,
              style: const TextStyle(color: AppColors.primaryBright),
            ),
          ),
      ],
    );
  }
}
