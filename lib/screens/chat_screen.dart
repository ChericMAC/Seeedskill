// ============================================================
//  chat_screen.dart — Chat individual con realtime
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final MatchWithProfile match;
  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<List<ChatMessage>>? _sub;
  List<ChatMessage> _messages = [];
  bool _sending = false;

  String get _conversationId => widget.match.conversationId;
  String get _myId => AuthService.currentUserId!;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _subscribeRealtime();
    ChatService.markAsRead(_conversationId);
  }

  Future<void> _loadHistory() async {
    final msgs = await ChatService.getMessages(_conversationId);
    setState(() => _messages = msgs);
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _sub = ChatService.watchMessages(_conversationId).listen((msgs) {
      setState(() => _messages = msgs);
      _scrollToBottom();
      ChatService.markAsRead(_conversationId);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
        conversationId: _conversationId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
        _controller.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.match.otherUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _SmallAvatar(user: other),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  other.fullName ?? other.username,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrim,
                  ),
                ),
                Text(
                  '@${other.username}',
                  style: const TextStyle(color: AppColors.textSec, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderId == _myId;
                      final showDate = i == 0 ||
                          _messages[i].createdAt.day !=
                              _messages[i - 1].createdAt.day;
                      return Column(
                        children: [
                          if (showDate) _DateDivider(dt: msg.createdAt),
                          _MessageBubble(message: msg, isMe: isMe),
                        ],
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    final other = widget.match.otherUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SmallAvatar(user: other, size: 72),
          const SizedBox(height: 16),
          Text(
            'Has conectat amb ${other.fullName ?? other.username}',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrim,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Di hola primer 👋',
            style: TextStyle(color: AppColors.textSec, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 12, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe algo...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _send,
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accentWarm],
                  ),
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Burbuja de mensaje ────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4, bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentWarm])
              : null,
          color: isMe ? null : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrim,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.65)
                    : AppColors.textSec,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Separador de fecha ────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime dt;
  const _DateDivider({required this.dt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = 'Avui';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      label = 'Ahir';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSec, fontSize: 12)),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}

// ── Avatar pequeño ────────────────────────────────────────────
class _SmallAvatar extends StatelessWidget {
  final UserProfile user;
  final double size;
  const _SmallAvatar({required this.user, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentWarm]),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? Image.network(user.avatarUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials())
              : _initials(),
        ),
      ),
    );
  }

  Widget _initials() => Container(
    color: AppColors.card,
    child: Center(
      child: Text(
        (user.fullName ?? user.username).substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: AppColors.accent,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
