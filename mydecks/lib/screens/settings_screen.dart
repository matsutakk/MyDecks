import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_voice_tutor/providers/language_provider.dart';
import 'package:my_voice_tutor/providers/theme_mode_provider.dart';

import '../components/language_selector.dart';
import '../components/confirmation_dialog.dart';

String getSafeLanguage(String language, List<String> availableLanguages) {
  return availableLanguages.contains(language)
      ? language
      : (availableLanguages.isNotEmpty ? availableLanguages.first : '日本語');
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final languageState = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || 
    (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    
    final safeNativeLanguage = getSafeLanguage(
      languageState.nativeLanguage, 
      languageState.availableLanguages
    );
    
    final safeTargetLanguage = getSafeLanguage(
      languageState.targetLanguage, 
      languageState.availableLanguages
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, '${l10n.account}設定'),
          
          _buildUserInfoTile(context),

          ListTile(
            leading: const Icon(Icons.language),
            title: Row(
              children: [
                Text(l10n.languageSettings),
                const Spacer(),
                Text(
                  safeNativeLanguage,
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
                Text(
                  safeTargetLanguage,
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 14),
                ),
              ],
            ),
            onTap: () => _showLanguageSelectionDialog(context),
          ),
          
          // ダークモード設定
          SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(l10n.darkMode),
            value: isDarkMode,
            onChanged: (bool value) {
              ref.read(themeModeProvider.notifier).updateThemeMode(
                value ? ThemeMode.dark : ThemeMode.light
              );
            },
          ),
          
          const Divider(),
          
          _buildSectionHeader(context, 'その他'),
          
          // 利用規約
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('利用規約'),
            onTap: () => _showWebContentDialog(context, '利用規約', _dummyTermsText),
          ),
          
          // プライバシーポリシー
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            onTap: () => _showWebContentDialog(context, 'プライバシーポリシー', _dummyPrivacyText),
          ),
          
          // お問い合わせ
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ・お問い合わせ'),
            onTap: () => _showContactDialog(context),
          ),
          
          // アプリ情報
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリ情報'),
            subtitle: const Text('バージョン: 1.0.0 (10)'),
            onTap: () => _showAboutAppDialog(context),
          ),
          
          const Divider(),
          
          // ログアウト
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('ログアウト', 
              style: TextStyle(color: Colors.orange),
            ),
            onTap: _confirmLogout,
          ),
          
          // 退会（アカウント削除）
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウント削除', 
              style: TextStyle(color: Colors.red),
            ),
            onTap: _confirmAccountDeletion,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(BuildContext context) {
    final user = _auth.currentUser;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      title: Text(user?.displayName ?? 'ユーザー'),
      subtitle: Text(user?.email ?? ''),
    );
  }

  void _showWebContentDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お問い合わせ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下の方法でお問い合わせください：'),
            const SizedBox(height: 16),
            const Text('メール: hoge'),
            const SizedBox(height: 8),
            const Text('電話: hoge'),
            const SizedBox(height: 8),
            const Text('受付時間: 平日 10:00 - 18:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アプリ情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MyDecks'),
            const Text('バージョン: 1.0.0'),
            const SizedBox(height: 16),
            const Text('© 2025 Takuya Matsuda'),
            const SizedBox(height: 16),
            const Text('言語学習をサポートするアプリです。日常会話から専門用語まで、幅広い語彙を効率的に習得できます。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'ログアウト',
        content: 'ログアウトしますか？',
        confirmText: 'ログアウト',
        cancelText: 'キャンセル',
        onConfirm: () async {
          await _auth.signOut();
          if (mounted) {
            // ログイン画面に戻る
            context.go('/login');
          }
        },
      ),
    );
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'アカウント削除',
        content: 'アカウントを削除すると、すべてのデータが完全に消去され、元に戻すことはできません。本当に削除しますか？',
        confirmText: '削除する',
        cancelText: 'キャンセル',
        isDestructive: true, // 危険な操作としてスタイルを変更
        onConfirm: () async {
          try {
            // 追加の認証が必要な場合は、再認証のためのダイアログを表示
            await _auth.currentUser?.delete();
            if (mounted) {
              // ログイン画面に戻る
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('アカウントが削除されました')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('アカウント削除に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectionDialog(),
    );
  }

  // ダミーのテキストデータ（実際には外部から取得するか、アセットに保存します）
  final String _dummyTermsText = '''
利用規約

1. はじめに
本利用規約（以下「本規約」といいます）は、当社が提供する語学学習アプリケーション（以下「本アプリ」といいます）の利用条件を定めるものです。

2. 利用資格
本アプリを利用するためには、以下の条件をすべて満たす必要があります。
・13歳以上であること
・本規約に同意していること
・過去に本規約に違反したことがないこと

3. アカウント管理
ユーザーは、自己の責任においてアカウント情報を管理し、第三者に漏洩しないよう努めるものとします。
アカウントの不正利用によって生じた損害について、当社は一切の責任を負いません。

4. 禁止事項
ユーザーは、本アプリの利用にあたり、以下の行為を行ってはなりません。
・法令または公序良俗に反する行為
・他のユーザーまたは第三者を害する行為
・当社のサービス運営を妨げる行為
・その他当社が不適切と判断する行為

5. 知的財産権
本アプリに関する一切の知的財産権は当社または正当な権利者に帰属します。
ユーザーは、当社の許可なく本アプリのコンテンツを複製、改変、配布することはできません。

6. 免責事項
当社は、本アプリの内容の正確性、完全性、有用性等について、いかなる保証もいたしません。
当社は、本アプリの利用によって生じたいかなる損害についても、一切の責任を負いません。

7. 規約の変更
当社は、必要と判断した場合には、ユーザーに通知することなく本規約を変更することがあります。
変更後の規約は、本アプリ上に表示した時点から効力を生じるものとします。

8. 準拠法と管轄裁判所
本規約の解釈および適用は、日本法に準拠するものとします。
本規約に関する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。

以上
''';

  final String _dummyPrivacyText = '''
プライバシーポリシー

1. 個人情報の収集
当社は、本アプリの提供にあたり、以下の個人情報を収集することがあります。
・氏名、メールアドレス等の登録情報
・利用履歴、学習データ等の利用情報
・位置情報、デバイス情報等の技術情報

2. 個人情報の利用目的
収集した個人情報は、以下の目的で利用します。
・本アプリのサービス提供および機能向上
・ユーザーサポートおよび問い合わせ対応
・新機能、更新情報等のお知らせ
・統計データの作成および分析

3. 個人情報の第三者提供
当社は、以下の場合を除き、ユーザーの同意なく個人情報を第三者に提供しません。
・法令に基づく場合
・人の生命、身体または財産の保護のために必要がある場合
・公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合
・国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合

4. 個人情報の安全管理
当社は、個人情報の漏洩、滅失またはき損の防止その他の個人情報の安全管理のために必要かつ適切な措置を講じます。

5. 個人情報の開示・訂正・削除
ユーザーは、当社に対して個人情報の開示、訂正、削除を請求することができます。
請求を行う場合は、本アプリのお問い合わせフォームよりご連絡ください。

6. Cookieの使用
本アプリでは、ユーザー体験の向上やサービス改善のためにCookieを使用することがあります。
ユーザーはブラウザの設定によりCookieの受け入れを拒否することができますが、その場合一部の機能が利用できなくなる可能性があります。

7. 改定
当社は、必要に応じて本ポリシーを改定することがあります。
重要な変更がある場合は、本アプリ上での告知または登録されたメールアドレスへの通知により、ユーザーに連絡します。

8. お問い合わせ
本ポリシーに関するお問い合わせは、以下の連絡先までお願いします。
メールアドレス: hoge

以上
''';
}