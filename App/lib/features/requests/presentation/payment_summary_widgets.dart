import 'package:flutter/material.dart';
import 'package:handy_app/core/widgets/app_ui.dart';

String paymentMethodLabel(String? paymentMethod) {
  return switch (paymentMethod) {
    'cash' => 'كاش',
    _ => paymentMethod ?? '',
  };
}

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    required this.status,
    this.acceptedPrice,
    this.finalPrice,
    this.paymentMethod,
    super.key,
  });

  final String status;
  final int? acceptedPrice;
  final int? finalPrice;
  final String? paymentMethod;

  bool get _showPending =>
      status == 'accepted' ||
      status == 'on_the_way' ||
      status == 'in_progress';

  bool get _showCompleted =>
      (status == 'completed' || status == 'complaint') && finalPrice != null;

  @override
  Widget build(BuildContext context) {
    if (_showCompleted) {
      return _CompletedPaymentCard(
        acceptedPrice: acceptedPrice,
        finalPrice: finalPrice!,
        paymentMethod: paymentMethod,
      );
    }

    if (_showPending && acceptedPrice != null && acceptedPrice! > 0) {
      return _PendingCashPaymentCard(acceptedPrice: acceptedPrice!);
    }

    return const SizedBox.shrink();
  }
}

class _PendingCashPaymentCard extends StatelessWidget {
  const _PendingCashPaymentCard({required this.acceptedPrice});

  final int acceptedPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تفاصيل الدفع',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _PaymentRow(
              icon: Icons.handshake_outlined,
              label: 'السعر المتفق عليه',
              value: '$acceptedPrice جنيه',
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الدفع كاش عند إتمام الشغل',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _CashChip(label: paymentMethodLabel('cash')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedPaymentCard extends StatelessWidget {
  const _CompletedPaymentCard({
    required this.acceptedPrice,
    required this.finalPrice,
    required this.paymentMethod,
  });

  final int? acceptedPrice;
  final int finalPrice;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final methodLabel = paymentMethodLabel(paymentMethod);
    final showAcceptedPrice =
        acceptedPrice != null && acceptedPrice! > 0 && acceptedPrice != finalPrice;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'ملخص الدفع',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const Spacer(),
                if (methodLabel.isNotEmpty) _CashChip(label: methodLabel),
              ],
            ),
            if (showAcceptedPrice) ...[
              const SizedBox(height: 12),
              _PaymentRow(
                icon: Icons.handshake_outlined,
                label: 'السعر المتفق عليه',
                value: '$acceptedPrice جنيه',
                valueColor: colorScheme.onSecondaryContainer,
                labelColor: colorScheme.onSecondaryContainer,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'السعر النهائي',
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              '$finalPrice جنيه',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            if (methodLabel.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'تم الدفع $methodLabel',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkerCompletePaymentSection extends StatelessWidget {
  const WorkerCompletePaymentSection({
    required this.acceptedPrice,
    super.key,
  });

  final int acceptedPrice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (acceptedPrice > 0)
              _PaymentRow(
                icon: Icons.handshake_outlined,
                label: 'السعر المتفق عليه',
                value: '$acceptedPrice جنيه',
              ),
            if (acceptedPrice > 0) const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.payments_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'سجّل المبلغ اللي استلمته كاش من العميل',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _CashChip(label: paymentMethodLabel('cash')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.icon,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: labelColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: labelColor)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}

class _CashChip extends StatelessWidget {
  const _CashChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: label,
      variant: AppBadgeVariant.success,
      icon: Icons.payments_outlined,
    );
  }
}
