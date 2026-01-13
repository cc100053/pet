import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _creatingRoom = false;
  bool _testingFeed = false;
  String? _roomId;
  String? _inviteCode;
  String? _feedResult;

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _createRoom() async {
    setState(() {
      _creatingRoom = true;
    });

    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': 'Test Room'})
          .single();

      setState(() {
        _roomId = response['room_id'] as String?;
        _inviteCode = response['invite_code'] as String?;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room created: ${_roomId ?? 'unknown'}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $error')),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _creatingRoom = false;
      });
    }
  }

  Future<void> _runFeedTest() async {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a room first.')),
      );
      return;
    }

    setState(() {
      _testingFeed = true;
      _feedResult = null;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _feedResult = 'Error: No active session. Please sign in again.';
        });
        return;
      }

      try {
        await Supabase.instance.client.auth.getUser();
      } catch (error) {
        setState(() {
          _feedResult = 'Session check failed: $error';
        });
        return;
      }

      Supabase.instance.client.functions.setAuth(session.accessToken);

      final response = await Supabase.instance.client.functions.invoke(
        'feed_validate',
        body: {
          'room_id': roomId,
          'labels': [
            {'text': 'Coffee', 'confidence': 0.92},
          ],
          'caption': 'Test feed',
          'image_url': 'https://example.com/test.jpg',
        },
      );

      setState(() {
        _feedResult = jsonEncode({
          'status': response.status,
          'data': response.data,
        });
      });
    } catch (error) {
      setState(() {
        _feedResult = 'Error: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _testingFeed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PicPet'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Test Tools',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _creatingRoom ? null : _createRoom,
            child: Text(_creatingRoom ? 'Creating...' : 'Create Test Room'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _testingFeed ? null : _runFeedTest,
            child: Text(_testingFeed ? 'Running...' : 'Run Feed Test'),
          ),
          if (_roomId != null) ...[
            const SizedBox(height: 12),
            Text('Room ID: $_roomId'),
            if (_inviteCode != null) Text('Invite Code: $_inviteCode'),
          ],
          if (_feedResult != null) ...[
            const SizedBox(height: 12),
            Text('Feed Test Result: $_feedResult'),
          ],
          const SizedBox(height: 24),
          const ProfileView(),
        ],
      ),
    );
  }
}
