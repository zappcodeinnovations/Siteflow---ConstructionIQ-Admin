import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton placeholders shown while a screen loads for the first time, so
/// the layout appears straight away instead of an empty page with a spinner.

class _SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const _SkeletonShimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF242C36) : const Color(0xFFE6EBF1),
      highlightColor: isDark
          ? const Color(0xFF323C48)
          : const Color(0xFFF7F9FC),
      child: child,
    );
  }
}

/// A shimmering placeholder block (the shimmer recolours it).
class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBox({this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// One card-shaped placeholder: a normal card surface with shimmering
/// title, text lines and a footer row inside it.
class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5E9EF),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return _SkeletonShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: w * .55, height: 14),
                const SizedBox(height: 12),
                _SkeletonBox(width: w * .85, height: 10),
                const SizedBox(height: 8),
                _SkeletonBox(width: w * .4, height: 10),
                const Spacer(),
                Row(
                  children: [
                    _SkeletonBox(width: w * .22, height: 18, radius: 9),
                    const Spacer(),
                    _SkeletonBox(width: w * .18, height: 18, radius: 9),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ShimmerLoadingCard extends StatelessWidget {
  final double height;

  const ShimmerLoadingCard({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _SkeletonCard(height: height),
    );
  }
}

/// A list of card placeholders. Works both inside scroll views (unbounded
/// height) and inside Expanded (bounded height - only as many cards as fit).
class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 140,
    this.padding,
  });

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = (padding ?? EdgeInsets.zero).resolve(
          Directionality.of(context),
        );
        var count = itemCount;
        if (constraints.hasBoundedHeight) {
          final available = constraints.maxHeight - resolvedPadding.vertical;
          final fits = ((available + _gap) / (itemHeight + _gap)).floor();
          count = fits.clamp(1, itemCount);
        }
        return ClipRect(
          child: Padding(
            padding: resolvedPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(height: _gap),
                  _SkeletonCard(height: itemHeight),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerLoadingDashboard extends StatelessWidget {
  const ShimmerLoadingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonShimmer(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _SkeletonBox(height: 96, radius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: _SkeletonBox(height: 96, radius: 14)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _SkeletonBox(height: 96, radius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: _SkeletonBox(height: 96, radius: 14)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          _SkeletonCard(height: 220),
          SizedBox(height: 16),
          _SkeletonCard(height: 160),
        ],
      ),
    );
  }
}
