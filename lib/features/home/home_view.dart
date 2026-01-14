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
  String? _petId;
  bool _petBusy = false;
  Map<String, dynamic>? _petState;
  String? _petError;

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

  Future<String?> _loadPetId(String roomId) async {
    final response = await Supabase.instance.client
        .from('pets')
        .select('id')
        .eq('room_id', roomId)
        .maybeSingle();

    return response?['id'] as String?;
  }

  Future<void> _refreshPetState({bool tick = false}) async {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) {
      setState(() {
        _petError = 'Create a room first.';
      });
      return;
    }

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        setState(() {
          _petError = 'No pet found for this room.';
        });
        return;
      }

      if (tick) {
        await Supabase.instance.client.rpc(
          'tick_pet_state',
          params: {
            'p_pet_id': petId,
            'p_now': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }

      final state = await Supabase.instance.client
          .from('pet_state')
          .select(
            'pet_id,hunger,hygiene,mood,poop_at,'
            'mood_boost,mood_boost_expires_at,'
            'feed_count_since_poop,last_decay_at,'
            'last_feed_at,last_touch_at,last_clean_at',
          )
          .eq('pet_id', petId)
          .maybeSingle();

      setState(() {
        _petId = petId;
        _petState = state;
      });
    } catch (error) {
      setState(() {
        _petError = 'Pet state error: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _petBusy = false;
      });
    }
  }

  Future<void> _applyPetAction(String action) async {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) {
      setState(() {
        _petError = 'Create a room first.';
      });
      return;
    }

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        setState(() {
          _petError = 'No pet found for this room.';
        });
        return;
      }

      await Supabase.instance.client.rpc(
        'apply_pet_action',
        params: {
          'p_pet_id': petId,
          'p_action_type': action,
        },
      );

      await _refreshPetState();
    } catch (error) {
      setState(() {
        _petError = 'Pet action error: $error';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _petBusy = false;
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _petBusy ? null : () => _applyPetAction('feed'),
                child: const Text('Feed Pet'),
              ),
              FilledButton(
                onPressed: _petBusy ? null : () => _applyPetAction('clean'),
                child: const Text('Clean Pet'),
              ),
              FilledButton(
                onPressed: _petBusy ? null : () => _applyPetAction('touch'),
                child: const Text('Touch Pet'),
              ),
              OutlinedButton(
                onPressed: _petBusy ? null : () => _refreshPetState(tick: true),
                child: const Text('Tick + Refresh'),
              ),
              OutlinedButton(
                onPressed: _petBusy ? null : _refreshPetState,
                child: const Text('Refresh Pet State'),
              ),
            ],
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
          if (_petId != null) ...[
            const SizedBox(height: 12),
            Text('Pet ID: $_petId'),
          ],
          if (_petState != null) ...[
            const SizedBox(height: 12),
            Text('Pet State: ${jsonEncode(_petState)}'),
          ],
          if (_petError != null) ...[
            const SizedBox(height: 12),
            Text(_petError!),
          ],
          const SizedBox(height: 24),
          const ProfileView(),
        ],
      ),
    );
  }
}
