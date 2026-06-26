import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {

  final String status;

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    Color color = Colors.green;

    if (status == "Pending") {
      color = Colors.orange;
    }

    if (status == "Completed") {
      color = Colors.green;
    }

    if (status == "In Progress") {
      color = Colors.blue;
    }

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          CircleAvatar(
            radius: 4,
            backgroundColor: color,
          ),

          const SizedBox(width: 8),

          Text(
            status,

            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}