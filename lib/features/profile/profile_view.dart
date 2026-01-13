import 'package:flutter/material.dart';
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
      'nickname': 'Pet Parent',
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
      const SnackBar(content: Text('Profile updated')),
    );

    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load profile: ${snapshot.error}'),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text('No profile available.'));
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
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('User ID: ${profile['user_id']}'),
              const SizedBox(height: 16),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
