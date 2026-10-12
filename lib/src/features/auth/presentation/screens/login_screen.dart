import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/shared/app_icon_button.dart';
import 'package:shalomly_app/src/shared/app_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
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
            showSnackBar(context, state.message, type: ResponseTypeEnum.error);
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
                  flex: 4,
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
                            child: AppIconButton(
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
                              // Church Logo Container
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: context.churchColors.onPrimary
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: context.churchColors.onPrimary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  Icons.church_rounded,
                                  size: 32,
                                  color: context.churchColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                appConfig.churchName,
                                textAlign: TextAlign.center,
                                style: AppTheme.serif(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: context.churchColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your church community, always within reach',
                                textAlign: TextAlign.center,
                                style: AppTheme.sans(
                                  fontSize: 13,
                                  color: context.churchColors.onPrimary
                                      .withValues(alpha: 0.85),
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
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.churchColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.churchColors.text.withValues(
                            alpha: 0.08,
                          ),
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
                                    color: context.churchColors.border
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              Text(
                                'Welcome',
                                style: AppTheme.serif(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.churchColors.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to continue to your church',
                                style: AppTheme.sans(
                                  fontSize: 13,
                                  color: context.churchColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),

                              TextField(
                                controller: _identifierController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email address or Phone number',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
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
                                      color: context.churchColors.border
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: AppTheme.sans(fontSize: 13),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: context.churchColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: context.churchColors.textMuted,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
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
                                      color: context.churchColors.border
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.churchColors.primary,
                                  foregroundColor:
                                      context.churchColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: isLoading ? null : _submitLogin,
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
                                        'Sign In',
                                        style: AppTheme.sans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),

                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'New to ${appConfig.churchName}? ',
                                    style: AppTheme.sans(
                                      fontSize: 13,
                                      color: context.churchColors.textMuted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push(AppRoutes.register),
                                    child: Text(
                                      'Create account',
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

  void _submitLogin() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    if (identifier.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(
        AuthLoginSubmitted(identifier: identifier, password: password),
      );
    }
  }
}
