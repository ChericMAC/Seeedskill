import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;

  // Login
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();

  // Registro
  final _regUser     = TextEditingController();
  final _regPass     = TextEditingController();
  final _regName     = TextEditingController();
  final _regEmail    = TextEditingController();
  final _regBio      = TextEditingController();
  final _regLocation = TextEditingController();
  DateTime? _regBirthDate;
  String? _regGender;

  bool _obscureLogin = true;
  bool _obscureReg   = true;

  static const _genders = [
    {'value': 'male',       'label': 'Home'},
    {'value': 'female',     'label': 'Dona'},
    {'value': 'non_binary', 'label': 'No binari'},
    {'value': 'other',      'label': 'Altre'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUser.dispose(); _loginPass.dispose();
    _regUser.dispose(); _regPass.dispose(); _regName.dispose();
    _regEmail.dispose(); _regBio.dispose(); _regLocation.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginUser.text.isEmpty || _loginPass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(
        username: _loginUser.text.trim(),
        password: _loginPass.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_regUser.text.isEmpty || _regPass.text.isEmpty) {
      _showError('Usuario y contraseña son obligatorios.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.signUp(
        username:  _regUser.text.trim(),
        password:  _regPass.text,
        fullName:  _regName.text.trim(),
        email:     _regEmail.text.trim(),
        bio:       _regBio.text.trim(),
        location:  _regLocation.text.trim(),
        birthDate: _regBirthDate,
        gender:    _regGender,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.dislike,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
            onSurface: AppColors.textPrim,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _regBirthDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withOpacity(0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accentWarm.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'SeeedSkill',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Troba les teves conexions.',
                    style: TextStyle(color: AppColors.textSec, fontSize: 16),
                  ),
                  const SizedBox(height: 50),

                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSec,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Iniciar sesión'),
                        Tab(text: 'Crear cuenta'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Altura fija para el login, scroll libre para registro
                  [_buildLoginForm(), _buildRegisterForm()]
                      [_tabController.index],
                ],
              ),
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _loginUser,
          decoration: const InputDecoration(
            hintText: 'Usuari',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textSec),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _loginPass,
          obscureText: _obscureLogin,
          decoration: InputDecoration(
            hintText: 'Contrasenya',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSec),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLogin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSec,
              ),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _login, child: const Text('Entrar')),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Obligatorios
        _sectionLabel('Cuenta'),
        TextField(
          controller: _regUser,
          decoration: const InputDecoration(
            hintText: 'Nom de usuari *',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.textSec),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPass,
          obscureText: _obscureReg,
          decoration: InputDecoration(
            hintText: 'Contrasenya *',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSec),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureReg ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSec,
              ),
              onPressed: () => setState(() => _obscureReg = !_obscureReg),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Personales
        _sectionLabel('Informació personal'),
        TextField(
          controller: _regName,
          decoration: const InputDecoration(
            hintText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSec),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textSec),
          ),
        ),
        const SizedBox(height: 12),

        // Fecha de nacimiento
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.textSec, size: 20),
                const SizedBox(width: 12),
                Text(
                  _regBirthDate == null
                      ? 'Data de naixement'
                      : '${_regBirthDate!.day}/${_regBirthDate!.month}/${_regBirthDate!.year}',
                  style: TextStyle(
                    color: _regBirthDate == null
                        ? AppColors.textSec
                        : AppColors.textPrim,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _regGender,
              isExpanded: true,
              dropdownColor: AppColors.card,
              hint: const Text('Género',
                  style: TextStyle(color: AppColors.textSec)),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textSec),
              items: _genders.map((g) => DropdownMenuItem(
                value: g['value'],
                child: Text(g['label']!,
                    style: const TextStyle(color: AppColors.textPrim)),
              )).toList(),
              onChanged: (v) => setState(() => _regGender = v),
            ),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regLocation,
          decoration: const InputDecoration(
            hintText: 'Ciutat',
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSec),
          ),
        ),
        const SizedBox(height: 24),

        _sectionLabel('Sobre ti'),
        TextField(
          controller: _regBio,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Digues alguna cosa sobre tu...',
            counterStyle: TextStyle(color: AppColors.textSec),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(onPressed: _register, child: const Text('Crear compte')),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
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
  }
}
