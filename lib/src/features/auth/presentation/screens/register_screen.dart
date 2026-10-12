import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();

    return Scaffold(
      backgroundColor: context.churchColors.primary,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go(AppRoutes.devotional);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.churchColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Hero Section
                Expanded(
                  flex: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient(context.churchColors),
                    ),
                    child: Stack(
                      children: [
                        if (Navigator.canPop(context))
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: context.churchColors.onPrimary,
                              ),
                              onPressed: () => Navigator.maybePop(context),
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: context.churchColors.onPrimary.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: context.churchColors.onPrimary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 28,
                                  color: context.churchColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                appConfig.churchName,
                                textAlign: TextAlign.center,
                                style: AppTheme.serif(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: context.churchColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect with our church family',
                                textAlign: TextAlign.center,
                                style: AppTheme.sans(
                                  fontSize: 13,
                                  color: context.churchColors.onPrimary.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Sheet Card
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.churchColors.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: context.churchColors.text.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Drag Handle Pill
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: context.churchColors.border.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Text(
                                'Join Congregation',
                                style: AppTheme.serif(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.churchColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create your member profile to connect with the church family.',
                                style: AppTheme.sans(
                                  fontSize: 12.5,
                                  color: context.churchColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),

                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    color: context.churchColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: context.churchColors.raised,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address (Optional if phone provided)',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: context.churchColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: context.churchColors.raised,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number (Optional if email provided)',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: context.churchColors.primary,
                                  ),
                                  filled: true,
                                  fillColor: context.churchColors.raised,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password (min 10 characters)',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: context.churchColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: context.churchColors.textMuted,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: context.churchColors.raised,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: context.churchColors.border.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.churchColors.primary,
                                  foregroundColor: context.churchColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: isLoading ? null : _submitRegister,
                                child: isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: context.churchColors.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: AppTheme.sans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: AppTheme.sans(
                                      fontSize: 13,
                                      color: context.churchColors.textMuted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.maybePop(context),
                                    child: Text(
                                      'Sign in',
                                      style: AppTheme.sans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: context.churchColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isNotEmpty && password.length >= 10 && (email.isNotEmpty || phone.isNotEmpty)) {
      context.read<AuthBloc>().add(
            AuthRegisterSubmitted(
              fullName: name,
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
              password: password,
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please provide your name, password (min 10 chars), and either email or phone.'),
          backgroundColor: context.churchColors.error,
        ),
      );
    }
  }
}
