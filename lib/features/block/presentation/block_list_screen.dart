import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../application/block_list_controller.dart';

class BlockListScreen extends ConsumerStatefulWidget {
  const BlockListScreen({super.key});

  @override
  ConsumerState<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends ConsumerState<BlockListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(blockListControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(blockListControllerProvider);
    final controller = ref.read(blockListControllerProvider.notifier);
    final dateFormat = DateFormat.yMMMd(l10n.localeName).add_Hm();

    ref.listen<BlockListState>(blockListControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.blockListTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: () => controller.load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FullScreenLoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: state.items.isEmpty
                ? Center(
                    child: Text(
                      l10n.blockListEmpty,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          leading: _Avatar(avatarUrl: item.avatarUrl),
                          title: Text(
                            item.nickname.isNotEmpty
                                ? item.nickname
                                : l10n.blockListUnknownUser,
                          ),
                          subtitle: Text(dateFormat.format(item.createdAt.toLocal())),
                          trailing: TextButton(
                            onPressed: () => _confirmUnblock(l10n, item.userId),
                            child: Text(l10n.blockListUnblock),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmUnblock(AppLocalizations l10n, String targetUserId) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.blockListUnblockTitle,
      message: l10n.blockListUnblockMessage,
      confirmLabel: l10n.blockListUnblockConfirm,
      cancelLabel: l10n.composeCancel,
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(blockListControllerProvider.notifier).unblock(targetUserId);
  }

  Future<void> _handleMessage(AppLocalizations l10n, BlockListMessage message) async {
    switch (message) {
      case BlockListMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case BlockListMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.blockListLoadFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
      case BlockListMessage.unblockFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.blockListUnblockFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.person));
          },
        ),
      ),
    );
  }
}
