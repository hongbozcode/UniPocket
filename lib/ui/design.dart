import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const primaryBlue = Color(0xff3867e8);
const lavenderSoft = Color(0xfff0eaff);
const canvasColor = Color(0xfff5f8fd);
const inkColor = Color(0xff202b40);
const weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String dateText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    super.key,
  });
  final String title;
  final String subtitle;
  final String art;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
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
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
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
