import 'package:flutter/material.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/shared/app_text.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.actionsWidget,
    this.titleWidget,
    this.centerTitle = false,
    this.titleSpacing,
    this.onTapBack,
    this.bgColor,
    this.padding,
    this.automaticallyImplyLeading = true,
    this.icon,
    this.style,
    this.iconColor,
    this.leadingWidth,
    this.actionsPadding,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final List<Widget>? actionsWidget;
  final Widget? titleWidget;
  final bool centerTitle;
  final double? titleSpacing;
  final GestureTapCallback? onTapBack;
  final Color? bgColor;
  final bool automaticallyImplyLeading;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final EdgeInsetsGeometry? actionsPadding;
  final TextStyle? style;
  final Color? iconColor;
  final double? leadingWidth;

  @override
  Widget build(BuildContext context) {
    final appColor = context.churchColors;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AppBar(
        elevation: 1,
        actionsPadding: actionsPadding,
        backgroundColor: bgColor ?? appColor.background,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing ?? -12,
        surfaceTintColor: Colors.transparent,
        title:
            titleWidget ??
            AppText(
              title ?? '',
              style:
                  style ??
                  (context.isMobile
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium),
            ),
        leading: (automaticallyImplyLeading && Navigator.of(context).canPop())
            ? IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                // maybePop, like the system back, so a screen's PopScope can
                // stop it (e.g. to ask about unsaved changes).
                onPressed: onTapBack ?? () => Navigator.maybePop(context),
                iconSize: context.isMobile ? 20 : 24,
                color: iconColor ?? appColor.onPrimary,
                icon: Icon(icon ?? Icons.adaptive.arrow_back),
              )
            : null,
        leadingWidth: leadingWidth ?? 56.0,
        actions: actionsWidget ?? [const SizedBox()],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
