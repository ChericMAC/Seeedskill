import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final p = await ProfileService.getMyProfile();
      setState(() { _profile = p; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _profile == null
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.textSec, size: 48),
          const SizedBox(height: 16),
          const Text('No se pudo cargar el perfil',
              style: TextStyle(color: AppColors.textSec)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final p = _profile!;
    final age = p.birthDate != null ? _calcAge(p.birthDate!) : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                    ? Image.network(p.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gradientBg())
                    : _gradientBg(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [Colors.transparent, AppColors.background],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 24, right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              p.fullName ?? p.username,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                              ),
                            ),
                          ),
                          if (age != null)
                            Text('$age',
                                style: const TextStyle(
                                    fontSize: 22, color: Colors.white70,
                                    fontWeight: FontWeight.w300)),
                        ],
                      ),
                      Text('@${p.username}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // Bio
              if (p.bio != null && p.bio!.isNotEmpty) ...[
                _sectionTitle('Sobre mí'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(p.bio!,
                      style: const TextStyle(
                          color: AppColors.textPrim, fontSize: 15, height: 1.6)),
                ),
                const SizedBox(height: 24),
              ],

              // Chips de info rápida
              if (_hasQuickInfo(p)) ...[
                _sectionTitle('Información'),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: [
                    if (p.gender != null)
                      _chip('⚧ ${_genderLabel(p.gender!)}'),
                    if (p.birthDate != null)
                      _chip('🎂 $age años'),
                    if (p.location != null)
                      _chip('📍 ${p.location}'),
                    if (p.interestedIn.isNotEmpty)
                      _chip('💙 ${p.interestedIn.join(", ")}'),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Datos de contacto / cuenta
              _sectionTitle('Dades de contacte'),
              _infoRow(Icons.alternate_email_rounded, 'Usuari', '@${p.username}'),
              if (p.email != null && p.email!.isNotEmpty)
                _infoRow(Icons.mail_outline_rounded, 'Email', p.email!),
              if (p.location != null)
                _infoRow(Icons.location_on_outlined, 'Ubicació', p.location!),

              const SizedBox(height: 24),

              // Miembro desde
              _sectionTitle('Usuari des de'),
              _infoRow(Icons.calendar_today_outlined, 'Registre', _formatDate(p.createdAt)),

              const SizedBox(height: 36),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Tancar sesió'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dislike,
                  side: const BorderSide(color: AppColors.dislike, width: 1.5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  bool _hasQuickInfo(UserProfile p) =>
      p.gender != null || p.birthDate != null ||
      p.location != null || p.interestedIn.isNotEmpty;

  Widget _gradientBg() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.accent, AppColors.accentWarm],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
    ),
    child: Text(label,
        style: const TextStyle(color: AppColors.textPrim, fontSize: 13)),
  );

  Widget _infoRow(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card, borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSec, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrim, fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );

  int _calcAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    return age;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jener','febrer','marc','abril','maij','juny',
      'juliol','agost','septembre','octombre','novembre','decembre'
    ];
    return '${months[dt.month - 1]} de ${dt.year}';
  }

  String _genderLabel(String g) {
    const map = {
      'male': 'Home', 'female': 'Dona',
      'non_binary': 'No binari', 'other': 'Altre',
    };
    return map[g] ?? g;
  }
}