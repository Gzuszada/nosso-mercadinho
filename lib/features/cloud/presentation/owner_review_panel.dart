import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/collaboration.dart';

class OwnerReviewPanel extends StatelessWidget {
  const OwnerReviewPanel({
    super.key,
    required this.reviews,
    required this.isOwner,
    required this.busy,
    required this.onApprove,
    required this.onRemove,
  });

  final List<PlanReviewItem> reviews;
  final bool isOwner;
  final bool busy;
  final ValueChanged<PlanReviewItem> onApprove;
  final ValueChanged<PlanReviewItem> onRemove;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Revisão do owner'),
          subtitle: const Text('Nenhum item aguardando revisão.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Revisão do owner',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Badge(label: Text(reviews.length.toString())),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isOwner
                  ? 'Itens adicionados por outras pessoas aguardam sua decisão.'
                  : 'Estes itens aguardam a decisão do dono da casa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            for (final review in reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${review.planName} · Adicionado por '
                      '${review.authorName ?? review.authorUid ?? 'membro'} '
                      '· ${_formatDate(review.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: busy ? null : () => onApprove(review),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Confirmar item'),
                            ),
                            OutlinedButton.icon(
                              onPressed: busy ? null : () => onRemove(review),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Remover da lista'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return DateFormat('d MMM, HH:mm', 'pt_BR').format(local);
  }
}
