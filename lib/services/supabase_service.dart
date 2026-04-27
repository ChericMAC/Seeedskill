import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _db = Supabase.instance.client;

class UserProfile {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final DateTime? birthDate;
  final String? gender;
  final List<String> interestedIn;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.bio,
    this.avatarUrl,
    this.birthDate,
    this.gender,
    this.interestedIn = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      username: map['username'] as String,
      fullName: map['full_name'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'] as String)
          : null,
      gender: map['gender'] as String?,
      interestedIn: (map['interested_in'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      location: map['location'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class MatchWithProfile {
  final String matchId;
  final String conversationId;
  final UserProfile otherUser;
  final DateTime matchedAt;
  final ChatMessage? lastMessage;

  MatchWithProfile({
    required this.matchId,
    required this.conversationId,
    required this.otherUser,
    required this.matchedAt,
    this.lastMessage,
  });
}

class SessionManager {
  static const _key = 'current_user_id';
  static String? _cachedId;

  static Future<void> save(String userId) async {
    _cachedId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, userId);
  }

  static Future<String?> load() async {
    if (_cachedId != null) return _cachedId;
    final prefs = await SharedPreferences.getInstance();
    _cachedId = prefs.getString(_key);
    return _cachedId;
  }

  static Future<void> clear() async {
    _cachedId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String? get currentId => _cachedId;
}

class AuthService {
  // Registrar usuario nuevo
  static Future<UserProfile> signUp({
    required String username,
    required String password,
    String? fullName,
    String? email,
    String? bio, 
    String? location,
    DateTime? birthDate,
    String? gender,
  }) async {
    // Comprobar si existe
    final existing = await _db
        .from('profiles')
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('El nom de usuari ja està en us.');
    }

    // Insertar perfil
    final data = await _db.from('profiles').insert({
      'username': username.trim(),
      'password': password,          
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName.trim(),
      'is_active': true,
      'email': email?.trim(),
      'bio': bio?.trim(),
      'location': location?.trim(),
      'birth_date': birthDate.toIso8601String(),
      'gender': gender?.trim()
    }).select().single();

    final profile = UserProfile.fromMap(data);
    await SessionManager.save(profile.id);
    return profile;
  }

  // Login
  static Future<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('username', username.trim())
        .maybeSingle();

    if (data == null) {
      throw Exception('Usuari no trobat.');
    }

    if (data['password'] != password) {
      throw Exception('Contrasenya incorrecta.');
    }

    final profile = UserProfile.fromMap(data);
    await SessionManager.save(profile.id);
    return profile;
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    await SessionManager.clear();
  }

  // ID usuario
  static String? get currentUserId => SessionManager.currentId;

  // Cargar sesión
  static Future<bool> restoreSession() async {
    final id = await SessionManager.load();
    return id != null;
  }
}

class ProfileService {
  static Future<UserProfile> getProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromMap(data);
  }

  static Future<UserProfile> getMyProfile() async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('No hay sesión activa.');
    return getProfile(uid);
  }

  static Future<UserProfile> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    List<String>? interestedIn,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('No hay sesión activa.');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (birthDate != null)
        'birth_date': birthDate.toIso8601String().substring(0, 10),
      if (gender != null) 'gender': gender,
      if (interestedIn != null) 'interested_in': interestedIn,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final data = await _db
        .from('profiles')
        .update(updates)
        .eq('id', uid)
        .select()
        .single();

    return UserProfile.fromMap(data);
  }
}

class DiscoveryService {
  static Future<List<UserProfile>> getDiscoverableUsers({
    int limit = 20,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('No hay sesión activa.');

    final swipedData = await _db
        .from('swipes')
        .select('swiped_id')
        .eq('swiper_id', uid);

    final swipedIds = (swipedData as List)
        .map((e) => e['swiped_id'] as String)
        .toList();

    final excludeIds = [uid, ...swipedIds];

    final data = await _db
        .from('profiles')
        .select()
        .eq('is_active', true)
        .limit(limit + excludeIds.length);

    final all = (data as List).map((e) => UserProfile.fromMap(e)).toList();
    return all.where((p) => !excludeIds.contains(p.id)).take(limit).toList();
  }

  static Future<bool> swipe({
    required String targetUserId,
    required bool isLike,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('No hay sesión activa.');

    await _db.from('swipes').insert({
      'swiper_id': uid,
      'swiped_id': targetUserId,
      'direction': isLike ? 'like' : 'dislike',
    });

    if (isLike) {
      final u1 = uid.compareTo(targetUserId) < 0 ? uid : targetUserId;
      final u2 = uid.compareTo(targetUserId) < 0 ? targetUserId : uid;
      final matchData = await _db
          .from('matches')
          .select()
          .eq('user1_id', u1)
          .eq('user2_id', u2)
          .maybeSingle();
      return matchData != null;
    }
    return false;
  }
}

class MatchService {
  static Future<List<MatchWithProfile>> getMatches() async {
  final uid = AuthService.currentUserId;
  if (uid == null) throw Exception('No hay sesión activa.');

  final matchData = await _db
      .from('matches')
      .select()
      .or('user1_id.eq.$uid,user2_id.eq.$uid')
      .order('created_at', ascending: false);

  final List<MatchWithProfile> result = [];

  for (final match in matchData as List) {
    final otherUserId =
        match['user1_id'] == uid ? match['user2_id'] : match['user1_id'];

    final convoData = await _db
        .from('conversations')
        .select()
        .eq('match_id', match['id'])
        .maybeSingle();

    if (convoData == null) continue;

    final conversationId = convoData['id'] as String;

    final profileData = await _db
        .from('profiles')
        .select()
        .eq('id', otherUserId)
        .maybeSingle();

    if (profileData == null) continue;

    final lastMsgData = await _db
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    result.add(MatchWithProfile(
      matchId: match['id'] as String,
      conversationId: conversationId,
      otherUser: UserProfile.fromMap(profileData),
      matchedAt: DateTime.parse(match['created_at'] as String),
      lastMessage: lastMsgData != null
          ? ChatMessage.fromMap(lastMsgData)
          : null,
    ));
  }

  return result;
}
}

class ChatService {
  static Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final data = await _db
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at')
        .limit(limit);

    return (data as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  static Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) throw Exception('No hay sesión activa.');
    if (content.trim().isEmpty) throw Exception('Mensaje vacío.');

    final data = await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': uid,
      'content': content.trim(),
    }).select().single();

    return ChatMessage.fromMap(data);
  }

  static Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((e) => ChatMessage.fromMap(e)).toList());
  }

  static Future<void> markAsRead(String conversationId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;
    await _db
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('is_read', false)
        .neq('sender_id', uid);
  }
}
