import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/session_utils.dart';
import '../../services/fcm_service.dart';

import '../../services/label_mapping/label_mapping_service.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../chat/chat_room_view.dart';
import '../feed/feed_capture_view.dart';
import '../gallery/memory_calendar_view.dart';
import '../store/store_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> with SingleTickerProviderStateMixin {
  // Logic State
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  bool _testingFeed = false;
  bool _loadingRoom = true;
  String? _roomId;
  String? _inviteCode;
  String? _feedResult;
  String? _petId;
  bool _petBusy = false;
  Map<String, dynamic>? _petState;
  String? _petError;
  List<Map<String, dynamic>> _myRooms = []; // Stores room info

  // Chat State
  final GlobalKey<ChatMessageListState> _chatListKey = GlobalKey();
  final TextEditingController _messageController = TextEditingController();
  bool _sendingFilter = false;

  // Top Sheet State
  late AnimationController _sheetController; // Controls the height factor (0.0 to 1.0)
  late Animation<double> _sheetAnimation;
  double _dragHeight = 0.0;
  // Config
  static const double _minHeightFraction = 0.45; // 45% (Collapsed) - Fits ~3 messages
  static const double _maxHeightFraction = 0.90; // 90% (Expanded)

  @override
  void initState() {
    super.initState();
    _sheetController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 300)
    );
    _ensureProfile().whenComplete(_fetchRooms);

    // Init FCM
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).initialize();
    });
  }
  
  // Update drag height on layout
  void _updateDragHeight(double screenHeight) {
     if (_dragHeight == 0.0) {
        _dragHeight = screenHeight * _minHeightFraction;
     }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---
  Future<void> _ensureProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        await Supabase.instance.client.from('profiles').insert({
          'user_id': user.id,
          'nickname': 'Pet Parent',
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRooms() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loadingRoom = false);
        return;
      }

      final responses = await Supabase.instance.client
          .from('room_members')
          .select('room_id, role, rooms(name, invite_code)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('joined_at', ascending: false);

      final List<Map<String, dynamic>> rooms = [];
      for (final r in responses) {
         final roomData = r['rooms'] as Map<String, dynamic>?;
          if (roomData != null) {
            rooms.add({
              'id': r['room_id'],
              'name': roomData['name'],
              'invite_code': roomData['invite_code'],
              'role': r['role'],
            });
          }
      }

      setState(() {
        _myRooms = rooms;
      });

      if (_roomId != null) {
        final current =
            rooms.firstWhere((r) => r['id'] == _roomId, orElse: () => {});
        if (current.isNotEmpty) {
          setState(() {
            _inviteCode = current['invite_code'];
          });
        }
      }
      
      if (rooms.isNotEmpty) {
          // If no room selected, or selected room not in list, select first
          if (_roomId == null || !rooms.any((r) => r['id'] == _roomId)) {
             _switchRoom(rooms.first['id'] as String);
          }
      }

    } catch (_) {} finally {
      if (mounted) setState(() => _loadingRoom = false);
    }
  }

  void _switchRoom(String roomId) {
     setState(() {
       _roomId = roomId;
       final room = _myRooms.firstWhere((r) => r['id'] == roomId, orElse: () => {});
       _inviteCode = room['invite_code'];
       _petState = null; // Clear old state
       _petId = null;
     });
     _refreshPetState();
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _createRoom() async {
    if (_myRooms.length >= 2) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Free limit reached (2 rooms max). Upgrade to create more!')),
       );
       return;
    }
  
    setState(() => _creatingRoom = true);
    try {
      final response = await Supabase.instance.client
          .rpc('create_room', params: {'p_name': 'New Room'})
          .single();

      // Refresh list and switch
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      final newId = response['room_id'] as String?;
      if (newId != null) {
         _switchRoom(newId);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room created! Check the Drawer.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $error')),
      );
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Future<void> _joinRoomByCode() async {
    if (_joiningRoom) return;

    String codeValue = '';
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Room'),
        content: TextField(
          onChanged: (value) => codeValue = value,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit code',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = codeValue.trim();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty) {
      return;
    }

    setState(() => _joiningRoom = true);
    try {
      final response = await Supabase.instance.client.rpc(
        'join_room_by_code',
        params: {'code': code},
      );

      String? roomId;
      if (response is String) {
        roomId = response;
      } else if (response is Map) {
        final value = response.values.isNotEmpty ? response.values.first : null;
        if (value is String) {
          roomId = value;
        }
      } else if (response is List && response.isNotEmpty) {
        final value = response.first;
        if (value is String) {
          roomId = value;
        } else if (value is Map) {
          final inner = value.values.isNotEmpty ? value.values.first : null;
          if (inner is String) {
            roomId = inner;
          }
        }
      }

      await _fetchRooms();
      if (!mounted) {
        return;
      }
      if (roomId != null) {
        _switchRoom(roomId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined room successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: $error')),
      );
    } finally {
      if (mounted) setState(() => _joiningRoom = false);
    }
  }

  Future<void> _regenerateInviteCode(String roomId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'regenerate_invite_code',
        params: {'p_room_id': roomId},
      );

      String? newCode;
      if (response is String) {
        newCode = response;
      }
      await _fetchRooms();
      if (!mounted) {
        return;
      }
      if (newCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New invite code: $newCode')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite code regenerated.')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate code: $error')),
      );
    }
  }
  
  Future<void> _leaveRoom(String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text('You will lose access to this pet until you are invited again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
             onPressed: () => Navigator.pop(context, true), 
             style: TextButton.styleFrom(foregroundColor: Colors.red),
             child: const Text('Leave')
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.rpc('leave_room', params: {'p_room_id': roomId});
      
      // Refresh list
      await _fetchRooms();
      
      // If we left the current room, switch to another or clear
      if (_roomId == roomId) {
         if (_myRooms.isNotEmpty) {
           _switchRoom(_myRooms.first['id']);
         } else {
           setState(() {
             _roomId = null;
             _inviteCode = null;
             _petState = null;
           });
         }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left room successfully.')));
      }
    } catch (_) {
      // Fallback: Set is_active = false manually
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
           await Supabase.instance.client
             .from('room_members')
             .update({'is_active': false})
             .eq('room_id', roomId)
             .eq('user_id', userId);
           
           await _fetchRooms();
           if (_roomId == roomId) {
              if (_myRooms.isNotEmpty) {
                _switchRoom(_myRooms.first['id']);
              } else {
                setState(() {
                  _roomId = null;
                  _inviteCode = null;
                  _petState = null;
                });
              }
           }
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left room successfully.')));
           }
        }
      } catch (e2) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to leave room: $e2')));
         }
      }
    }
  }

  Future<void> _runFeedTest() async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _testingFeed = true;
      _feedResult = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final debugResult = await ensureValidAccessTokenWithDebug();
      final accessToken = debugResult.token;
      final userId = auth.currentUser?.id;
      String tokenPreview;
      if (accessToken == null) {
        tokenPreview = 'null';
      } else if (accessToken.length <= 16) {
        tokenPreview = accessToken;
      } else {
        tokenPreview =
            '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 6)}';
      }
      final expiryText = debugResult.expiresAt?.toIso8601String() ?? 'unknown';
      final remainingText =
          debugResult.remaining?.inSeconds.toString() ?? 'unknown';
      final claims = debugResult.claims ?? const {};
      final ref = claims['ref'] ?? 'unknown';
      final aud = claims['aud'] ?? 'unknown';
      final issuer = claims['iss'] ?? 'unknown';
      final sub = claims['sub'] ?? 'unknown';
      final role = claims['role'] ?? 'unknown';

      setState(() {
        _feedResult =
            'auth: user=$userId | token=$tokenPreview | '
            'ref=$ref | aud=$aud | iss=$issuer | sub=$sub | role=$role | '
            'expires=$expiryText | remaining=${remainingText}s | '
            '${debugResult.message}';
      });
      debugPrint('[feed_test] ${_feedResult ?? ''}');

      if (accessToken == null) {
        return;
      }

      final labelObservations = [
        const LabelObservation(text: 'Coffee', confidence: 0.92),
        const LabelObservation(text: 'Cup', confidence: 0.71),
      ];

      final mappingRepository = LabelMappingRepository(Supabase.instance.client);
      final mappingEntries = await mappingRepository.fetch();
      final mappingService = LabelMappingService(mappingEntries);
      
      final mappedLabels = mappingService.matchLabels(labelObservations);
      final matchByLabel = <String, LabelMatch>{};
      for (final match in mappedLabels) {
        matchByLabel[LabelMappingService.normalizeLabel(match.text)] = match;
      }
      
      final labelPayload = labelObservations.map((label) {
        final normalized = LabelMappingService.normalizeLabel(label.text);
        final match = matchByLabel[normalized];
        return {
          'text': label.text,
          'confidence': label.confidence,
          if (match != null) 'canonical_tag': match.canonicalTag,
        };
      }).toList();

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'feed_validate',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'room_id': roomId,
            'labels': labelPayload,
            'canonical_tags': mappingService.matchCanonicalTags(labelObservations),
            'caption': 'Test feed',
            'image_url': 'https://example.com/test.jpg',
          },
        );
      }

      FunctionResponse response;
      try {
        response = await invokeWithToken(accessToken);
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          response = await invokeWithToken(refreshedToken);
        } else {
          rethrow;
        }
      }

      final data = response.data;
      String details = 'status ${response.status}';
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data);
        final webhookSkipped = payload['webhook_skipped'];
        final webhookStatus = payload['webhook_status'];
        final webhookError = payload['webhook_error'];
        details =
            'status ${response.status} | webhook_skipped=$webhookSkipped | '
            'webhook_status=$webhookStatus | webhook_error=$webhookError';
      }

      setState(() {
        _feedResult = 'Success: $details';
      });
      _chatListKey.currentState?.refreshLatest();
    } on FunctionException catch (error) {
      final detailsText = error.details == null ? '' : ' | ${error.details}';
      setState(() => _feedResult =
          'Error: status ${error.status} ${error.reasonPhrase}$detailsText');
    } catch (error) {
      setState(() => _feedResult = 'Error: $error');
    } finally {
      if (mounted) setState(() => _testingFeed = false);
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
    if (roomId == null) return;

    setState(() {
      _petBusy = true;
      _petError = null;
    });

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        setState(() => _petError = 'No pet found.');
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
          .select()
          .eq('pet_id', petId)
          .maybeSingle();

      setState(() {
        _petId = petId;
        _petState = state;
      });
    } catch (error) {
      setState(() => _petError = 'Pet sync error: $error');
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _applyPetAction(String action) async {
    final roomId = _roomId;
    if (roomId == null) return;

    setState(() {
      _petBusy = true;
      _petError = null;
    });
    
    // Haptic Feedback for actions
    HapticFeedback.mediumImpact();

    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) return;

      await Supabase.instance.client.rpc(
        'apply_pet_action',
        params: {'p_pet_id': petId, 'p_action_type': action},
      );

      await _refreshPetState();
    } catch (error) {
      setState(() => _petError = 'Action failed: $error');
    } finally {
      if (mounted) setState(() => _petBusy = false);
    }
  }

  Future<void> _openFeedCamera() async {
    final roomId = _roomId;
    if (roomId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FeedCaptureView(roomId: roomId)),
    );
    if (!mounted) {
      return;
    }
    _chatListKey.currentState?.refreshLatest();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _sendingFilter = true);
    _messageController.clear();
    HapticFeedback.lightImpact();

    // Optimistic Update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
        id: tempId,
        roomId: _roomId!,
        senderId: userId,
        type: 'text',
        body: text,
        imageUrl: null,
        caption: null,
        coinsAwarded: 0,
        createdAt: DateTime.now().toUtc(),
        clientCreatedAt: DateTime.now().toUtc(),
        labels: const [],
      );
      
    _chatListKey.currentState?.addOptimisticMessage(optimisticMessage);

    try {
      await Supabase.instance.client.from('messages').insert({
        'room_id': _roomId,
        'sender_id': userId,
        'type': 'text',
        'body': text,
        'client_created_at': DateTime.now().toUtc().toIso8601String(),
      });
      _chatListKey.currentState?.refreshLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _sendingFilter = false);
    }
  }
  
  // --- Gestures for Top Sheet ---
  void _onVerticalDragUpdate(DragUpdateDetails details, double screenHeight) {
    setState(() {
      _dragHeight += details.delta.dy;
      // Clamp
      final minH = screenHeight * _minHeightFraction;
      final maxH = screenHeight * _maxHeightFraction;
      if (_dragHeight < minH) _dragHeight = minH;
      if (_dragHeight > maxH) _dragHeight = maxH;
    });
  }
  
  void _onVerticalDragEnd(DragEndDetails details, double screenHeight) {
    final minH = screenHeight * _minHeightFraction;
    final maxH = screenHeight * _maxHeightFraction;
    final velocity = details.primaryVelocity ?? 0;
    
    double targetH;
    if (velocity > 500) {
       targetH = maxH; // Swiped Down
    } else if (velocity < -500) {
       targetH = minH; // Swiped Up
    } else {
       // Snap to nearest
       final distMin = (_dragHeight - minH).abs();
       final distMax = (_dragHeight - maxH).abs();
       targetH = distMin < distMax ? minH : maxH;
    }
    
    // Animate
    _sheetAnimation = Tween<double>(
      begin: _dragHeight, 
      end: targetH
    ).animate(CurvedAnimation(parent: _sheetController, curve: Curves.easeOutBack));
    
    _sheetController.reset();
    _sheetController.forward();
    _sheetController.addListener(() {
      setState(() {
        _dragHeight = _sheetAnimation.value;
      });
    });
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    if (_loadingRoom) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final size = MediaQuery.of(context).size;
    _updateDragHeight(size.height);

    if (_roomId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No Room Found', style: TextStyle(fontSize: 20)),
              const Gap(20),
              FilledButton(
                onPressed: _creatingRoom ? null : _createRoom,
                child: const Text('Create New Home'),
              ),
              const Gap(12),
              OutlinedButton(
                onPressed: _joiningRoom ? null : _joinRoomByCode,
                child: const Text('Join with Invite Code'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: _buildSideDrawer(), // Room List Drawer
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // Layer 1: Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF9E5), Color(0xFFFFECE5)], // Warm Pudding colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Background Blobs (Floating)
          Positioned(
            bottom: 150,
            left: -20,
            child: JuicyFloat(
              yOffset: 20,
              delay: 500.ms,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 300,
            right: -30,
            child: JuicyFloat(
              yOffset: 30,
              delay: 1000.ms,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Layer 2: Pet (At Bottom)
          Positioned(
            bottom: size.height * 0.15, // 15% from bottom
            left: 0,
            right: 0,
            child: Center(
              child: JuicyFloat(
                yOffset: 15,
                child: JuicyScaleButton(
                  onTap: _petBusy ? null : () => _applyPetAction('touch'), // Touch interaction
                  child: _buildPetAvatar(),
                ),
              ),
            ),
          ),
          
          // Pet Status Pill (Near Pet)
          Positioned(
            bottom: size.height * 0.12,
            right: 24,
            child: _buildPetStatusPill(),
          ),

          // Layer 3: Chat Shade (Top Anchored)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _dragHeight,
            child: Container(
               decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
               ),
               child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: BackdropFilter(
                     filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                     child: Stack(
                        children: [
                           // Input Bar (Fixed at Top of Chat Content? Or Bottom of Sheet?)
                           // Design: Input fixed at BOTTOM of the SHEET area.
                           // Actually GDD said "Input Bar: Fixed in Layer 3 bottom".
                           
                           Column(
                             children: [
                               // Menu Button (Inside Sheet safely)
                               AppBar(
                                 backgroundColor: Colors.transparent,
                                 elevation: 0,
                                 leading: Builder(
                                   builder: (context) {
                                     return IconButton(
                                       icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                                       onPressed: () => Scaffold.of(context).openDrawer(),
                                     );
                                   }
                                 ),
                                 title: Text('Room: ${_inviteCode ?? '...'}', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                                 centerTitle: true,
                               ),
                               
                               Expanded(
                                 child: GestureDetector(
                                    onTap: () => FocusScope.of(context).unfocus(),
                                    child: ChatMessageList(
                                       key: _chatListKey,
                                       roomId: _roomId!,
                                       currentUserId: Supabase.instance.client.auth.currentUser?.id,
                                    ),
                                 ),
                               ),
                               
                               _buildInputBar(size.height),
                             ],
                           ),
                        ],
                     ),
                  ),
               ),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildPetAvatar() {
    // Placeholder Pet logic
    Color petColor = Colors.orangeAccent;
    if (_petState != null) {
        // Simple visualization of mood
        final mood = _petState!['mood'] as String? ?? 'low';
        switch (mood) {
          case 'high': petColor = Colors.pinkAccent; break;
          case 'mid': petColor = Colors.orangeAccent; break;
          case 'sad': petColor = Colors.blueGrey; break;
        }
    }

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: petColor,
        shape: BoxShape.circle,
        boxShadow: [
           BoxShadow(
             color: petColor.withValues(alpha: 0.4),
             blurRadius: 40,
             spreadRadius: 5,
             offset: const Offset(0, 10),
           )
        ]
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
           // Eyes
           Positioned(
             top: 80,
             left: 70,
             child: _buildEye(),
           ),
           Positioned(
             top: 80,
             right: 70,
             child: _buildEye(),
           ),
           // Mouth
           Positioned(
             bottom: 100,
             child: Container(
               width: 40, height: 20,
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
               ),
             ),
           )
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 30, height: 40,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(5),
          width: 10, height: 10,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scaleY(begin: 1.0, end: 0.1, duration: 200.ms, delay: 3000.ms, curve: Curves.easeInOut); // Blink
  }

  Widget _buildPetStatusPill() {
    if (_petState == null) return const SizedBox.shrink();
    final hunger = _petState!['hunger'] as int? ?? 0;
    final mood = _petState!['mood'] as String? ?? 'neutral';
    final hygiene = _petState!['hygiene'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hunger
          Row(
            children: [
              const Icon(Icons.lunch_dining_rounded, size: 16, color: Colors.orange),
              const Gap(4),
              Text('$hunger%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          
          Container(
             height: 12, width: 1, color: Colors.black12, 
             margin: const EdgeInsets.symmetric(horizontal: 8)
          ),

          // Mood
          Row(
            children: [
              const Icon(Icons.mood_rounded, size: 16, color: Colors.purpleAccent),
              const Gap(4),
              Text(mood.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          
          Container(
             height: 12, width: 1, color: Colors.black12, 
             margin: const EdgeInsets.symmetric(horizontal: 8)
          ),

          // Hygiene
          Row(
            children: [
              const Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.blue),
              const Gap(4),
              Text('$hygiene%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildInputBar(double screenHeight) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, 
        right: 12, 
        top: 12, 
        bottom: MediaQuery.of(context).viewInsets.bottom // Dynamic bottom padding
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5), // Subtle backing
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input Row
          Row(
            children: [
              // Camera Button (Juicy)
              JuicyScaleButton(
                onTap: _openFeedCamera,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D5C63), // Dark Teal from GDD/Memory
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Gap(10),
              
              // Input Field
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                         color: Colors.black.withValues(alpha: 0.05),
                         blurRadius: 5,
                         offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (_sendingFilter) {
                        return;
                      }
                      _sendMessage();
                    },
                    enabled: !_sendingFilter,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
              ),
              
              const Gap(10),
              
              // Send Button
              JuicyScaleButton(
                onTap: _sendingFilter ? null : _sendMessage,
                child: Icon(
                  Icons.send_rounded,
                  color: _sendingFilter
                      ? Colors.black26
                      : const Color(0xFF0D5C63),
                  size: 28,
                ),
              ),
            ],
          ),
          
          // Drag Handle Area (Integrated)
          GestureDetector(
             onTap: () {
               final minH = screenHeight * _minHeightFraction;
               final maxH = screenHeight * _maxHeightFraction;
               
               // Toggle
               final targetH = (_dragHeight - minH).abs() < (_dragHeight - maxH).abs()
                   ? maxH : minH;

               _sheetAnimation = Tween<double>(
                 begin: _dragHeight, 
                 end: targetH
               ).animate(CurvedAnimation(parent: _sheetController, curve: Curves.easeOutBack));
               
               _sheetController.reset();
               _sheetController.forward();
               _sheetController.addListener(() {
                 setState(() {
                   _dragHeight = _sheetAnimation.value;
                 });
               });
             },
             onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, screenHeight),
             onVerticalDragEnd: (d) => _onVerticalDragEnd(d, screenHeight),
             behavior: HitTestBehavior.translucent, // Catch misses
             child: Container(
                height: 36, // Tap target size
                width: double.infinity,
                alignment: Alignment.center,
                child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideDrawer() {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
           // Header
           Container(
             padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
             color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
             child: Row(
               children: [
                 CircleAvatar(
                   backgroundColor: Theme.of(context).primaryColor,
                   child: Text(userId?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white)),
                 ),
                 const Gap(12),
                 const Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('My Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       Text('Free Plan', style: TextStyle(fontSize: 12, color: Colors.black54)),
                     ],
                   ),
                 )
               ],
             ),
           ),
           
           // Room List
           Expanded(
             child: _myRooms.isEmpty 
               ? const Center(child: Text('No rooms yet.'))
               : ListView.builder(
                   padding: const EdgeInsets.symmetric(vertical: 8),
                   itemCount: _myRooms.length,
                   itemBuilder: (context, index) {
                     final room = _myRooms[index];
                     final isSelected = room['id'] == _roomId;
                     final isOwner = room['role'] == 'owner';
                     return ListTile(
                       leading: Icon(
                         isSelected ? Icons.home_filled : Icons.home_outlined,
                         color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
                       ),
                       title: Text(room['name'] ?? 'Room'),
                       subtitle: Text('Code: ${room['invite_code']}'),
                       selected: isSelected,
                       selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           if (isOwner)
                             IconButton(
                               icon: const Icon(Icons.refresh, size: 20, color: Colors.black54),
                               tooltip: 'Regenerate invite code',
                               onPressed: () {
                                 Navigator.pop(context);
                                 _regenerateInviteCode(room['id']);
                               },
                             ),
                           IconButton(
                             icon: const Icon(Icons.delete_outline, size: 20, color: Colors.black45),
                             onPressed: () {
                               Navigator.pop(context); // Close Drawer first
                               _leaveRoom(room['id']);
                             },
                           ),
                         ],
                       ),
                       onTap: () {
                          if (!isSelected) _switchRoom(room['id']);
                          Navigator.pop(context); // Close Drawer
                       },
                     );
                   },
                 ),
           ),
           
           const Divider(),
           
           // Actions
           ListTile(
             leading: const Icon(Icons.add_circle_outline),
             title: const Text('Create New Room'),
             onTap: () {
               Navigator.pop(context);
               _createRoom();
             },
           ),

           ListTile(
             leading: const Icon(Icons.meeting_room_outlined),
             title: const Text('Join with Invite Code'),
             onTap: _joiningRoom
                 ? null
                 : () {
                     Navigator.pop(context);
                     _joinRoomByCode();
                   },
           ),

           ListTile(
             leading: const Icon(Icons.calendar_month_outlined),
             title: const Text('Memories'),
             onTap: () {
               final roomId = _roomId;
               if (roomId == null) {
                 return;
               }
               Navigator.pop(context);
               Navigator.of(context).push(
                 MaterialPageRoute(
                   builder: (_) => MemoryCalendarView(
                     roomId: roomId,
                     currentUserId:
                         Supabase.instance.client.auth.currentUser?.id,
                   ),
                 ),
               );
             },
           ),

           ListTile(
             leading: const Icon(Icons.storefront_outlined),
             title: const Text('Store'),
             onTap: () {
               Navigator.pop(context);
               Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => const StoreView()),
               );
             },
           ),
           
           ExpansionTile(
             leading: const Icon(Icons.bug_report_outlined),
             title: const Text('Debug Tools'),
             children: [
                ListTile(
                  title: const Text('Force Refresh Pet'),
                  onTap: _petBusy ? null : () => _refreshPetState(tick: true),
                  trailing: _petBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
               ListTile(
                  title: const Text('Simulate Feed'),
                  subtitle: _feedResult == null ? null : Text(_feedResult!),
                  onTap: _testingFeed ? null : _runFeedTest,
                  trailing: _testingFeed
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                ListTile(
                  title: const Text('Test Local Notification'),
                  onTap: () => ref.read(fcmServiceProvider).showTestNotification(),
                ),
                if (_petError != null)
                  ListTile(
                    title: const Text('Pet Error'),
                    subtitle: Text(_petError!),
                  ),
             ],
           ),
           
           ListTile(
             leading: const Icon(Icons.logout, color: Colors.redAccent),
             title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
             onTap: _signOut,
           ),
           const Gap(20),
        ],
      ),
    );
  }
}
