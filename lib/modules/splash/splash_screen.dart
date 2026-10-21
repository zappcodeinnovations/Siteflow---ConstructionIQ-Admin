import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Launch screen that follows the app theme the user picked (light, dark or
/// system): a night construction scene in dark mode, a daytime one in light.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _brandBlue = Color(0xFF1F5BFF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Matches the top of each background so the image fades in seamlessly.
    final skyColor = isDark ? const Color(0xFF010B23) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: .78)
        : const Color(0xFF475569);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: skyColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final logoCard = (width * .46).clamp(132.0, 210.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  isDark
                      ? 'assets/images/splash_night.jpg'
                      : 'assets/images/splash_day.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  frameBuilder: (context, child, frame, wasSyncLoaded) =>
                      wasSyncLoaded
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 400),
                          child: child,
                        ),
                ),
                // Fade the sky into a solid colour behind the branding so
                // the text stays readable on every screen size.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        skyColor,
                        skyColor.withValues(alpha: isDark ? .82 : .88),
                        skyColor.withValues(alpha: 0),
                      ],
                      // Short screens (e.g. iPhone SE) show more of the
                      // skyline, so keep the fade lower behind the text.
                      stops: height < 760
                          ? const [0, .52, .80]
                          : const [0, .38, .62],
                    ),
                  ),
                ),
                SafeArea(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - t)),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: height * .07),
                          _LogoCard(size: logoCard, isDark: isDark),
                          const SizedBox(height: 28),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: '',
                                    style: TextStyle(
                                      color: _brandBlue,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '   SITE FLOW',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _Tagline(color: mutedColor),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              strokeCap: StrokeCap.round,
                              color: _brandBlue,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: .18)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Loading your workspace...',
                            style: TextStyle(
                              color: isDark ? Colors.white : titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final double size;
  final bool isDark;

  const _LogoCard({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .17),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF1F5BFF).withValues(alpha: .28)
                : const Color(0xFF0F172A).withValues(alpha: .12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/splash_logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'SF Site & Construction',
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  final Color color;

  const _Tagline({required this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontSize: 15, letterSpacing: .3);
    Widget dot() => Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: SplashScreen._brandBlue,
        shape: BoxShape.circle,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('People', style: style),
        dot(),
        Text('Projects', style: style),
        dot(),
        Text('Progress', style: style),
      ],
    );
  }
}
