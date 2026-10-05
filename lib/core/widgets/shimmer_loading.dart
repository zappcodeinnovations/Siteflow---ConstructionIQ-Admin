import 'package:flutter/material.dart';

class ShimmerLoadingCard extends StatelessWidget {
  const ShimmerLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ShimmerLoadingDashboard extends StatelessWidget {
  const ShimmerLoadingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
