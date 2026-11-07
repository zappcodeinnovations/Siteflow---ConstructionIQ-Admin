import 'package:flutter/material.dart';
import '../network/api_client.dart';

/// App-wide notice shown while requests can't reach the server, so a lost
/// connection is reported once at app level instead of as a raw timeout
/// error inside whichever screen happened to be loading (ClickUp
/// 14yjutqgnrq). Clears itself on the next successful response.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ApiClient.connectionProblem,
      builder: (context, hasProblem, _) {
        if (!hasProblem) return const SizedBox.shrink();
        return Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Material(
              color: const Color(0xFF1F2937),
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Can't reach the server. Check your internet connection.",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () => ApiClient.connectionProblem.value = false,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
