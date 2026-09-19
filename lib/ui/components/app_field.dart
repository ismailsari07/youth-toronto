import 'package:flutter/material.dart';

import '../../theme/app_icon.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Spec §7.7's field row: padding 12/18, an optional 34×34 icon tile, the
/// label above the input.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.divided = false,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String? icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool divided;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconName = icon;
    final field = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconName != null) ...[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColor.neutralTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(iconName, size: 17, color: AppColor.ink3),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ).c(AppColor.ink3),
                ),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  onTap: onTap,
                  cursorColor: AppColor.green,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)
                      .c(AppColor.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle:
                        const TextStyle(fontSize: 15.5).c(const Color(0xFFA4B0AA)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!divided) return field;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.hairline)),
      ),
      child: field,
    );
  }
}

/// A grouped card of fields, matching the list-row card treatment.
class FieldGroup extends StatelessWidget {
  const FieldGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColor.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.card,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
