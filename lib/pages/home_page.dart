import 'package:flutter/material.dart';
import 'package:mobile_app/core/time_utils.dart';
import 'package:mobile_app/services/canteen_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.status,
  });

  final CanteenRepository? repository;
  final String status;

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    final balance = repo?.balance;
    final balanceUpdatedAt = repo?.balanceUpdatedAt;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('一粟'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status message
                  if (status.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: status.contains('失败')
                            ? colorScheme.errorContainer
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status.contains('失败')
                                ? Icons.error_outline
                                : Icons.info_outline,
                            color: status.contains('失败')
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: status.contains('失败')
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Balance Card
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '当前余额',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            balance == null
                                ? '¥ --'
                                : '¥ ${balance.toStringAsFixed(2)}',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            balanceUpdatedAt == null || balanceUpdatedAt.isEmpty
                                ? '点击右下角刷新按钮同步余额'
                                : '更新于 ${formatDateTime(balanceUpdatedAt)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
