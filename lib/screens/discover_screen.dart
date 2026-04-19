// ============================================================
//  discover_screen.dart — Stack de swipe tipo Tinder
// ============================================================
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<UserProfile> _profiles = [];
  bool _loading = true;
  bool _swiping = false;

  // Drag state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    try {
      final users = await DiscoveryService.getDiscoverableUsers(limit: 20);
      setState(() { _profiles = users; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfiles: $e')),
        );
      }
    }
  }

  Future<void> _swipe(bool isLike) async {
    if (_profiles.isEmpty || _swiping) return;
    setState(() => _swiping = true);

    final target = _profiles.first;
    try {
      final isMatch = await DiscoveryService.swipe(
        targetUserId: target.id,
        isLike: isLike,
      );

      setState(() {
        _profiles.removeAt(0);
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _swiping = false;
      });

      if (isMatch && mounted) _showMatchDialog(target);
    } catch (e) {
      setState(() { _dragOffset = Offset.zero; _dragAngle = 0; _swiping = false; });
    }
  }

  void _showMatchDialog(UserProfile profile) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentWarm],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                '¡És un Match!',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu i ${profile.fullName ?? profile.username} us heu agradat',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('¡Enviar un misatge!',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text('Seguir explorant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SeeedSkill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _profiles.isEmpty
              ? _buildEmptyState()
              : _buildCardStack(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_off_rounded,
                color: AppColors.textSec, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Per ara això és tot',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrim,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Torna més tard per veure\nnoves persones aprop teu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSec, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            child: ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualitzar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Carta de fondo (siguiente)
                if (_profiles.length > 1)
                  Positioned.fill(
                    top: 16,
                    child: _ProfileCard(
                      profile: _profiles[1],
                      scale: 0.95,
                    ),
                  ),

                // Carta principal (draggable)
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      setState(() {
                        _dragOffset += d.delta;
                        _dragAngle = _dragOffset.dx / 300 * 0.3;
                      });
                    },
                    onPanEnd: (_) {
                      if (_dragOffset.dx > 100) {
                        _swipe(true);
                      } else if (_dragOffset.dx < -100) {
                        _swipe(false);
                      } else {
                        setState(() {
                          _dragOffset = Offset.zero;
                          _dragAngle = 0;
                        });
                      }
                    },
                    child: Transform.translate(
                      offset: _dragOffset,
                      child: Transform.rotate(
                        angle: _dragAngle,
                        child: Stack(
                          children: [
                            _ProfileCard(profile: _profiles.first),
                            // Indicador LIKE
                            if (_dragOffset.dx > 20)
                              Positioned(
                                top: 40, left: 24,
                                child: _SwipeLabel(
                                  label: 'LIKE',
                                  color: AppColors.like,
                                  opacity: (_dragOffset.dx / 120).clamp(0, 1),
                                ),
                              ),
                            // Indicador NOPE
                            if (_dragOffset.dx < -20)
                              Positioned(
                                top: 40, right: 24,
                                child: _SwipeLabel(
                                  label: 'NOPE',
                                  color: AppColors.dislike,
                                  opacity: (-_dragOffset.dx / 120).clamp(0, 1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botones de acción
        Padding(
          padding: const EdgeInsets.only(bottom: 28, top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.dislike,
                onTap: () => _swipe(false),
                size: 56,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.like,
                onTap: () => _swipe(true),
                size: 64,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de perfil ─────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final double scale;

  const _ProfileCard({required this.profile, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto / Avatar
            profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                ? Image.network(
                    profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),

            // Gradiente inferior
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Info del usuario
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            profile.fullName ?? profile.username,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (profile.birthDate != null)
                          Text(
                            '${_age(profile.birthDate!)}',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                      ],
                    ),
                    if (profile.location != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.accent, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            profile.location!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        profile.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(
          (profile.fullName ?? profile.username).substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 96,
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  int _age(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }
}

// ── Etiqueta de swipe ─────────────────────────────────────────
class _SwipeLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;

  const _SwipeLabel({
    required this.label,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ── Botón de acción circular ──────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
