import 'package:flutter/material.dart';

import '../../../core/content/content_bundle.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/components/app_card.dart';
import '../../../ui/components/app_scaffolding.dart';

/// Profile → Mosque services → an `info` service from the panel (Qur'an
/// classes, iftar…): its title and text. The body, else the summary.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = service.body.resolve(l.localeName);
    final text = body.isEmpty ? service.summary.resolve(l.localeName) : body;
    return Scaffold(
      backgroundColor: AppColor.ground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlainNavBar(
            eyebrow: l.burialEyebrow,
            title: service.title.resolve(l.localeName),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.pageGutter,
                18,
                AppSpace.pageGutter,
                40,
              ),
              children: [
                if (text.isNotEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                      ).c(AppColor.ink2),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
