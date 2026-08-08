import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, dynamic>> documents = [

      {
        "title": "Project Requirements",
        "icon": IconlyLight.paper,
      },

      {
        "title": "Company Policies",
        "icon": IconlyLight.category,
      },

      {
        "title": "Flutter Documentation",
        "icon": IconlyLight.category,
      },

      {
        "title": "Design Assets",
        "icon": IconlyLight.image,
      },
    ];

    return Scaffold(

      appBar: AppBar(
        title: const Text("Library"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.builder(

          itemCount: documents.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),

          itemBuilder: (context, index) {

            final item = documents[index];

            return Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    item["icon"],
                    size: 50,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    item["title"],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}