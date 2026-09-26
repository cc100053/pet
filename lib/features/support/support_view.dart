import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/juice_wrappers.dart';

/// Single in-app support thread. User messages are emailed to the team by the
/// support_notify Edge Function; replies come back as `sender = 'admin'` rows.
class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = const [];
  bool _loading = true;
  bool _sending = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await _supabase
          .from('support_messages')
          .select('id, sender, body, created_at')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (error, stack) {
      if (!mounted) return;
      setState(() => _loading = false);
      showJuiceSnackbar(
        context: context,
        message: userFacingError(
          context,
          error,
          stackTrace: stack,
          source: 'support_load',
        ),
        tone: AppDialogTone.danger,
      );
    }
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      await _supabase.from('support_messages').insert({
        'body': body,
        'meta': await _deviceMeta(locale),
      });
      _controller.clear();
      await _load();
    } catch (error, stack) {
      if (!mounted) return;
      showJuiceSnackbar(
        context: context,
        message: userFacingError(
          context,
          error,
          stackTrace: stack,
          source: 'support_send',
        ),
        tone: AppDialogTone.danger,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static Future<Map<String, String>> _deviceMeta(String locale) async {
    final package = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    var model = 'unknown';
    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      model = '${ios.utsname.machine} (${ios.modelName})';
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      model = '${android.manufacturer} ${android.model}';
    }
    return {
      'app_version': '${package.version}+${package.buildNumber}',
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'device_model': model,
      'locale': locale,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profileFeedback,
          style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildThread(l10n)),
            _buildComposer(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildThread(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.profileFeedbackEncouragement,
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _SupportBubble(
            body: message['body'] as String? ?? '',
            fromUser: message['sender'] == 'user',
          );
        },
      ),
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.chatMessageHint,
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
          ),
          const Gap(8),
          JuicyScaleButton(
            onTap: _sending ? null : _send,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                _sending ? l10n.commonSending : l10n.commonSend,
                style: GoogleFonts.mPlusRounded1c(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportBubble extends StatelessWidget {
  const _SupportBubble({required this.body, required this.fromUser});

  final String body;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: fromUser ? const Color(0xFFFFF3B0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: SelectableText(
          body,
          style: GoogleFonts.mPlusRounded1c(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
