// lib/features/auth/register_screen.dart
//
// Faithfully recreates the Figma prototype:
//   - Light mint green background
//   - Dark green wave shapes at top and bottom (using CustomPainter)
//   - "Create New Account" bold heading in the centre
//   - "Already Registered? Log in here." subtitle link
//   - Rounded pill-shaped fields: Username (person icon), Password (lock icon), Email (mail icon)
//   - Green circular checkmark button on the right side of the fields

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(
      email: email,
      password: password,
      fullName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Navigate to dashboard once registration succeeds
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isSuccess && !next.isLoading) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.critical,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Background mint color ──
          Container(color: AppColors.primaryLight),

          // ── Top dark-green wave ──
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 280),
            painter: _TopWavePainter(),
          ),

          // ── Bottom dark-green wave ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: _BottomWavePainter(),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  // Title
                  const Text(
                    'Create New\nAccount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle link
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Already Registered? Log in here.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Input fields stacked with checkmark button ──
                  // The Figma shows the fields grouped tightly with a single
                  // green circle checkmark button overlapping the right side.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // White rounded card holding all three fields
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,
                        ),
                        child: Column(
                          children: [
                            // Username
                            _FieldRow(
                              controller: _nameController,
                              hint: 'Username',
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                            ),
                            const Divider(height: 1, color: Color(0xFFDDDDDD)),
                            // Password
                            _FieldRow(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              obscure: _obscurePassword,
                              onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const Divider(height: 1, color: Color(0xFFDDDDDD)),
                            // Email
                            _FieldRow(
                              controller: _emailController,
                              hint: 'Email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onRegister(),
                            ),
                          ],
                        ),
                      ),

                      // Green circular checkmark button — positioned to the right,
                      // overlapping the password row like in the Figma design.
                      Positioned(
                        right: -16,
                        top: 58,
                        child: GestureDetector(
                          onTap: auth.isLoading ? null : _onRegister,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3343A047),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: auth.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable field row inside the grouped card ────────────────────────────────
class _FieldRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _FieldRow({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
      ),
    );
  }
}

// ── Wave painters — these create the blob shapes from the Figma prototype ────

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryDark;
    final path = Path();
    // Top-left dark blob
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, 0);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.2, size.height * 0.6);
    path.quadraticBezierTo(0, size.height * 0.7, 0, size.height * 0.5);
    path.close();
    canvas.drawPath(path, paint);

    // Lighter secondary blob
    final paint2 = Paint()..color = AppColors.primary.withOpacity(0.7);
    final path2 = Path();
    path2.moveTo(0, 0);
    path2.lineTo(size.width * 0.55, 0);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.4, size.width * 0.05, size.height * 0.5);
    path2.quadraticBezierTo(0, size.height * 0.55, 0, size.height * 0.4);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryDark;
    final path = Path();
    path.moveTo(size.width * 0.3, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.1, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.3, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
