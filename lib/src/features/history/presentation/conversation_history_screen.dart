import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';

/// Thread history and audit entry point.
class ConversationHistoryScreen extends StatelessWidget {
  /// Creates the conversation history screen.
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<ConversationThreadView>>(
        stream: bootstrap.conversationRepository.watchThreads(),
        builder: (context, snapshot) {
          final threads = snapshot.data ?? const <ConversationThreadView>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Conversation History',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Each thread preserves the audit trail from discussion to proposal to confirmation.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: threads.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        title: Text(thread.title),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${thread.lastMessagePreview}\n'
                            '${formatDayAndTime(thread.lastUpdatedAt)}',
                          ),
                        ),
                        trailing: thread.pendingProposalCount > 0
                            ? Chip(
                                label: Text(
                                  '${thread.pendingProposalCount} pending',
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          bootstrap.appSession.selectThread(thread.threadId);
                          context.go('/chat');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
