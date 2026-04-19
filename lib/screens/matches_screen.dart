import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchWithProfile> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    try {
      final matches = await MatchService.getMatches();
      setState(() { _matches = matches; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conexions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _matches.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surface,
                  onRefresh: _loadMatches,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: AppColors.divider, indent: 84, endIndent: 20,
                    ),
                    itemBuilder: (_, i) => _MatchTile(
                      match: _matches[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(match: _matches[i]),
                          ),
                        );
                        _loadMatches();
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              color: AppColors.card, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded,
                color: AppColors.accent, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aún sense conexions',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 22, fontWeight: FontWeight.w700,
              color: AppColors.textPrim,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Quan facis match amb algú\nserà aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSec, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchWithProfile match;
  final VoidCallback onTap;

  const _MatchTile({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = match.otherUser;
    final lastMsg = match.lastMessage;
    final isMe = lastMsg?.senderId == AuthService.currentUserId!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: onTap,
      leading: _Avatar(user: user, size: 56),
      title: Text(
        user.fullName ?? user.username,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrim,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          lastMsg != null
              ? '${isMe ? "Tu: " : ""}${lastMsg.content}'
              : 'Nou match! Trenca el gel 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: lastMsg == null ? AppColors.accent : AppColors.textSec,
            fontSize: 13,
            fontStyle: lastMsg == null ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
      trailing: lastMsg != null
          ? Text(
              _formatTime(lastMsg.createdAt),
              style: const TextStyle(color: AppColors.textSec, fontSize: 11),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Text('NUEVO',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }
}

class _Avatar extends StatelessWidget {
  final UserProfile user;
  final double size;
  const _Avatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentWarm],
        ),
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

  Widget _initials() {
    return Container(
      color: AppColors.card,
      child: Center(
        child: Text(
          (user.fullName ?? user.username).substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            color: AppColors.accent,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
