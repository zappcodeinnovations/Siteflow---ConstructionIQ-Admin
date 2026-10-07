import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? .22 : .05,
            ),
            blurRadius: 10,
          ),
        ],
      ),

      child: Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title.toUpperCase(),

                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  value,

                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
