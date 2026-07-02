import 'package:flutter/material.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/worker/domain/worker_earnings.dart';
import 'package:handy_app/features/worker/presentation/worker_home_page.dart';

class WorkerEarningsPage extends StatelessWidget {
  const WorkerEarningsPage({
    required this.earningsFuture,
    required this.onReload,
    super.key,
  });

  final Future<WorkerEarnings> earningsFuture;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: FutureBuilder<WorkerEarnings>(
        future: earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                ErrorCard(
                  message: 'تعذر تحميل الأرباح.',
                  onRetry: onReload,
                ),
              ],
            );
          }

          final earnings = snapshot.data;
          if (earnings == null || earnings.jobsCount == 0) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                AppEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'لا توجد أرباح بعد.',
                  message:
                      'هتظهر هنا أرباحك (بعد خصم عمولة المنصة) بعد إتمام أول طلب.',
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              _EarningsSummary(earnings: earnings),
              const SizedBox(height: 20),
              const AppSectionHeader(
                title: 'تفاصيل الأعمال',
                subtitle: 'آخر الأعمال المكتملة وصافي مستحقك منها',
              ),
              const SizedBox(height: 12),
              for (final item in earnings.recent) ...[
                _EarningItemCard(item: item),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({required this.earnings});

  final WorkerEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'صافي أرباحك',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatMoney(earnings.totalNet)} جنيه',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'من ${earnings.jobsCount} عمل مكتمل',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'إجمالي الأعمال',
                    value: '${_formatMoney(earnings.totalGross)} ج',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'عمولة المنصة',
                    value: '${_formatMoney(earnings.totalCommission)} ج',
                    highlight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningItemCard extends StatelessWidget {
  const _EarningItemCard({required this.item});

  final WorkerEarningItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = item.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.serviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppBadge(
                  label: 'عمولة ${(item.commissionRate * 100).toStringAsFixed(0)}%',
                  variant: AppBadgeVariant.warning,
                ),
              ],
            ),
            if (item.categoryName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.categoryName,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            _AmountRow(label: 'قيمة العمل', value: item.grossAmount),
            const SizedBox(height: 6),
            _AmountRow(
              label: 'عمولة المنصة',
              value: -item.commissionAmount,
              color: theme.colorScheme.error,
            ),
            const Divider(height: 20),
            _AmountRow(
              label: 'صافي مستحقك',
              value: item.netAmount,
              bold: true,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final String label;
  final int value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sign = value < 0 ? '- ' : '';
    final amount = value.abs();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          '$sign${_formatMoney(amount)} جنيه',
          style: TextStyle(
            color: color ?? theme.colorScheme.onSurface,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _formatMoney(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
