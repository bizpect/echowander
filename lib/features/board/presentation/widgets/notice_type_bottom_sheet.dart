import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/common_codes/common_code.dart';

class NoticeTypeBottomSheet extends StatelessWidget {
  const NoticeTypeBottomSheet({
    super.key,
    required this.title,
    required this.allLabel,
    required this.selectedCode,
    required this.types,
    required this.locale,
  });

  final String title;
  final String allLabel;
  final String? selectedCode;
  final List<CommonCode> types;
  final String locale;

  static const allCode = '__all__';

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String allLabel,
    required String? selectedCode,
    required List<CommonCode> types,
    required String locale,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => NoticeTypeBottomSheet(
        title: title,
        allLabel: allLabel,
        selectedCode: selectedCode,
        types: types,
        locale: locale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <_NoticeTypeItem>[
      _NoticeTypeItem(code: allCode, label: allLabel),
      ...types.map(
        (type) => _NoticeTypeItem(
          code: type.codeValue,
          label: type.resolveLabel(locale),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSm.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item.code == selectedCode;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.label,
                  style: AppTextStyles.body.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(item.code),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoticeTypeItem {
  const _NoticeTypeItem({required this.code, required this.label});

  final String? code;
  final String label;
}
