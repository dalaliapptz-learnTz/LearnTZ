import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/components/app_brand_logo.dart';
import '../../core/state/app_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final country = ref.watch(selectedCountryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AppBrandLogo(
                    height: 48,
                    productName: country.productName,
                    showTagline: true,
                  ),
                ),
              ),
              Text(
                l10n.helpTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent_outlined),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.helpDescription(country.productName),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
