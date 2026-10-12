import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shalomly_app/src/core/routing/app_routes.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shalomly_app/src/shared/app_text.dart';

/// Reusable user profile button with role badge and leadership portal link.
class UserAvatarButton extends StatelessWidget {
  final bool compact;

  const UserAvatarButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        return previous.runtimeType != current.runtimeType ||
            (previous is Authenticated &&
                current is Authenticated &&
                previous.user != current.user);
      },
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.role.isLeadership) ...[
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 15,
                  ),
                  label: AppText(
                    'Portal',
                    variant: AppTextVariant.label,
                    color: context.churchColors.onPrimary,
                  ),
                  onPressed: () => context.push(AppRoutes.admin),
                ),
                const SizedBox(width: 8),
              ],
              PopupMenuButton<String>(
                tooltip: 'Account Menu',
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: context.churchColors.border.withValues(alpha: 0.6),
                  ),
                ),
                color: context.churchColors.surface,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.churchColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.churchColors.primary.withValues(
                        alpha: 0.25,
                      ),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: context.churchColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                onSelected: (val) {
                  if (val == 'logout') {
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                  } else if (val == 'admin') {
                    context.push(AppRoutes.admin);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.churchColors.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.churchColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user.role.value.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.churchColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  if (user.role.isLeadership)
                    PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 18,
                            color: context.churchColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          const Text('Leadership Portal'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: context.churchColors.error,
                        ),
                        const SizedBox(width: 10),
                        const Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.login_rounded, size: 15),
          label: const Text(
            'Sign In',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          onPressed: () => context.push(AppRoutes.login),
        );
      },
    );
  }
}
