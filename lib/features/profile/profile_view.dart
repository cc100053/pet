import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nicknameController = TextEditingController();
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final defaultNickname = AppLocalizations.of(
      context,
    )!.profileDefaultNickname;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile != null) {
      return profile;
    }

    await Supabase.instance.client.from('profiles').insert({
      'user_id': user.id,
      'nickname': defaultNickname,
    });

    return Supabase.instance.client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      return;
    }

    await Supabase.instance.client
        .from('profiles')
        .update({'nickname': nickname})
        .eq('user_id', user.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
    );

    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(l10n.profileLoadFailed(snapshot.error.toString())),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return Center(child: Text(l10n.profileEmpty));
        }

        final nickname = profile['nickname'] as String? ?? '';
        if (_nicknameController.text.isEmpty) {
          _nicknameController.text = nickname;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profileTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(l10n.profileUserId(profile['user_id'])),
              const SizedBox(height: 16),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: l10n.profileNicknameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveProfile,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        );
      },
    );
  }
}
