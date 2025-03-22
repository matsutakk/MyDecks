import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_voice_tutor/components/add_data_dialog.dart';
import 'package:my_voice_tutor/components/language_selector.dart';
import 'package:my_voice_tutor/constants/app_routes.dart';
import 'package:my_voice_tutor/providers/user_provider.dart';
import 'package:my_voice_tutor/providers/words_provider.dart';

class WrapperHomeScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  
  const WrapperHomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<WrapperHomeScreen> createState() => _WrapperHomeScreenState();
}

class _WrapperHomeScreenState extends ConsumerState<WrapperHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(wordProvider.notifier).loadRecentWords();
      ref.read(userStatsProvider.notifier).loadUserStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final colorScheme = theme.colorScheme;
    
    int currentIndex = widget.navigationShell.currentIndex;
    
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        title: const LanguageSelector(),
        titleSpacing: 16,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.bottomAppBarTheme.color ?? primaryColor,
        elevation: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.home,
                  color: currentIndex == 0 
                    ? colorScheme.secondary
                    : colorScheme.onSurface,
                  size: 32,
                ),
                onPressed: () => widget.navigationShell.goBranch(0),
              ),
            ),
            const Expanded(child: SizedBox()),
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.history,
                  color: currentIndex == 1 
                    ? colorScheme.secondary
                    : colorScheme.onSurface,
                  size: 32,
                ),
                onPressed: () => widget.navigationShell.goBranch(1),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDataDialog,
        backgroundColor: colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddDataDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDataDialog(),
    );
  }
}