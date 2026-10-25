import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:woosh/l10n/app_localizations.dart';
import '../../../providers/language_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _rideUpdates = true;
  bool _offersPromotions = false;
  bool _whatsappUpdates = true;
  bool _hideFullName = true;

  void _showLanguageSelectionSheet(BuildContext context, WidgetRef ref, AppLocalizations loc) {
    final currentLocale = ref.read(languageProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.selectLanguage,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(loc.english),
                trailing: currentLocale.languageCode == 'en'
                    ? const Icon(Icons.check_circle, color: Color(0xFFD40B7E))
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(loc.hindi),
                trailing: currentLocale.languageCode == 'hi'
                    ? const Icon(Icons.check_circle, color: Color(0xFFD40B7E))
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLocale(const Locale('hi'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Color(0xFF1E1E1E),
              size: 28,
            ),
          ),
        ),
        title: Text(
          loc.settings,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                loc.preferences,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildNavItem(
                    loc.language,
                    trailingText: currentLocale.languageCode == 'hi' ? loc.hindi : loc.english,
                    onTap: () => _showLanguageSelectionSheet(context, ref, loc),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildToggleItem(
                    loc.rideUpdates,
                    _rideUpdates,
                    (val) => setState(() => _rideUpdates = val),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildToggleItem(
                    loc.offersPromotions,
                    _offersPromotions,
                    (val) => setState(() => _offersPromotions = val),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildToggleItem(
                    loc.whatsappUpdates,
                    _whatsappUpdates,
                    (val) => setState(() => _whatsappUpdates = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                loc.privacy,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildNavItem(
                    loc.locationAccess,
                    trailingText: 'While using',
                    onTap: () {},
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildToggleItem(
                    loc.hideFullNameFromRiders,
                    _hideFullName,
                    (val) => setState(() => _hideFullName = val),
                    subtitle: loc.hideFullNameSubtitle,
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildNavItem(loc.privacyPolicy, onTap: () {}),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildNavItem(loc.termsOfService, onTap: () {}),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                loc.account,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF757575),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildNavItem(
                    loc.changeMpin,
                    onTap: () => context.push('/change-mpin'),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildNavItem(
                    loc.deleteAccount,
                    onTap: () {},
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '${loc.appTitle} v 1.0.0',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String title, {
    String? trailingText,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF1E1E1E),
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFFBDBDBD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFFD40B7E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
