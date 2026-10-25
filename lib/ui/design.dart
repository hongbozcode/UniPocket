import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const primaryBlue = Color(0xff3867e8);
const lavenderSoft = Color(0xfff0eaff);
const canvasColor = Color(0xfff5f8fd);
const inkColor = Color(0xff202b40);
const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

class RoundDesignButton extends StatelessWidget {
  const RoundDesignButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    super.key,
  });
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: primary ? primaryBlue : const Color(0xffedf2fb),
      shape: BoxShape.circle,
    ),
    child: Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          disabledBackgroundColor: const Color(0xfff2f4f8),
          minimumSize: const Size(44, 44),
        ),
        icon: DesignIcon(
          icon,
          size: 22,
          color: primary
              ? Colors.white
              : (onPressed == null ? const Color(0xffaeb8ca) : inkColor),
        ),
      ),
    ),
  );
}

String dateText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class AppNavigationItem extends StatelessWidget {
  const AppNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? lavenderSoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignIcon(
                    icon,
                    size: 22,
                    color: selected ? primaryBlue : const Color(0xff93a0b5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? primaryBlue : const Color(0xff73819a),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue).copyWith(
    primary: primaryBlue,
    surface: Colors.white,
    onSurface: inkColor,
    error: const Color(0xffb32643),
  ),
  scaffoldBackgroundColor: canvasColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: canvasColor,
    foregroundColor: inkColor,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: lavenderSoft,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
  ),
);

class DesignIcon extends StatelessWidget {
  const DesignIcon(this.name, {this.color, this.size = 24, super.key});
  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'docs/design/resources/icons/$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class PageContent extends StatelessWidget {
  const PageContent({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: children,
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title,
    this.subtitle, {
    this.art = 'calendar',
    this.bottomSpacing = 24,
    super.key,
  });
  final String title;
  final String subtitle;
  final String art;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomSpacing),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: Color(0xff73819a),
                  ),
                ),
              ],
            ),
          ),
          if (constraints.maxWidth > 340 &&
              MediaQuery.textScalerOf(context).scale(14) < 22)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: SvgPicture.asset(
                'docs/design/resources/illustrations/$art.svg',
                width: 72,
                height: 72,
                excludeFromSemantics: true,
              ),
            ),
        ],
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({required this.child, this.color, super.key});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class ProblemBanner extends StatelessWidget {
  const ProblemBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    ),
  );
}
