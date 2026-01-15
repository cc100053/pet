import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../feed/feed_capture_view.dart';
import '../profile/profile_view.dart';
import '../../services/label_mapping/label_mapping_service.dart';
import '../chat/chat_room_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _creatingRoom = false;
  bool _testingFeed = false;
  bool _loadingRoom = true;
  String? _roomId;
  String? _inviteCode;
  String? _feedResult;
  String? _petId;
  bool _petBusy = false;
  Map<String, dynamic>? _petState;
  String? _petError;

  @override
  void initState() {
    super.initState();
    _loadExistingRoom();
  }

  Future<void> _loadExistingRoom() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _loadingRoom = false;
        });
        return;
      }

      // Find first active room membership
      final membership = await Supabase.instance.client
          .from('room_members')
          .select('room_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (membership != null) {
        final roomId = membership['room_id'] as String?;
        if (roomId != null) {
          // Get invite code from room
          final room = await Supabase.instance.client
              .from('rooms')
              .select('invite_code')
              .eq('id', roomId)
              .maybeSingle();

          setState(() {
            _roomId = roomId;
            _inviteCode = room?['invite_code'] as String?;
          });
        }
      }
    } catch (error) {
      debugPrint('Failed to load existing room: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingRoom = false;
        });
      }
    }
  }

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
      if (mounted) {
        setState(() {
          _creatingRoom = false;
        });
      }
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

      final labelObservations = [
        const LabelObservation(text: 'Coffee', confidence: 0.92),
        const LabelObservation(text: 'Cup', confidence: 0.71),
      ];

      final mappingRepository = LabelMappingRepository(
        Supabase.instance.client,
      );
      final mappingEntries = await mappingRepository.fetch();
      final mappingService = LabelMappingService(mappingEntries);
      final mappedLabels = mappingService.matchLabels(labelObservations);
      final matchByLabel = <String, LabelMatch>{};
      for (final match in mappedLabels) {
        matchByLabel[LabelMappingService.normalizeLabel(match.text)] = match;
      }
      final labelPayload = labelObservations
          .map((label) {
            final normalized = LabelMappingService.normalizeLabel(label.text);
            final match = matchByLabel[normalized];
            return {
              'text': label.text,
              'confidence': label.confidence,
              if (match != null) 'canonical_tag': match.canonicalTag,
            };
          })
          .toList();

      final response = await Supabase.instance.client.functions.invoke(
        'feed_validate',
        body: {
          'room_id': roomId,
          'labels': labelPayload,
          'canonical_tags': mappingService.matchCanonicalTags(labelObservations),
          'caption': 'Test feed',
          'image_url': 'https://example.com/test.jpg',
        },
      );

      setState(() {
        _feedResult = jsonEncode({
          'status': response.status,
          'data': response.data,
          'client_canonical_tags':
              mappingService.matchCanonicalTags(labelObservations),
        });
      });
    } catch (error) {
      setState(() {
        _feedResult = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _testingFeed = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _petBusy = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _petBusy = false;
        });
      }
    }
  }

  void _openFeedCamera() {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a room first.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCaptureView(roomId: roomId),
      ),
    );
  }

  void _openChat() {
    final roomId = _roomId;
    if (roomId == null || roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a room first.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomView(roomId: roomId),
      ),
    );
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
          if (_loadingRoom)
            const Center(child: CircularProgressIndicator())
          else if (_roomId != null)
            OutlinedButton(
              onPressed: null,
              child: Text('Room Loaded: ${_roomId!.substring(0, 8)}...'),
            )
          else
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
          FilledButton(
            onPressed: _openFeedCamera,
            child: const Text('Open Feed Camera'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _openChat,
            child: const Text('Open Chat'),
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
