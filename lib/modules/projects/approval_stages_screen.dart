import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class ApprovalStagesScreen extends StatefulWidget {
  const ApprovalStagesScreen({Key? key}) : super(key: key);

  @override
  State<ApprovalStagesScreen> createState() => _ApprovalStagesScreenState();
}

class _ApprovalStagesScreenState extends State<ApprovalStagesScreen> {
  // Mock data for stages
  List<Map<String, dynamic>> _stages = [
    {
      "title": "test 1",
      "declaration": "abc",
      "users": ["Kanhaiya Gore"],
    }
  ];

  void _showAddStageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return const AddApprovalStageDialog();
      },
    ).then((newStage) {
      if (newStage != null) {
        setState(() {
          _stages.add(newStage);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Approval Stages",
          style: TextStyle(
            color: Color(0xFF0F2C4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _showAddStageDialog,
              child: const Text("Add Stage", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Configure declaration stages and signer access for this template.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (_stages.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(IconlyLight.document, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No approval stages found.", style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              ..._stages.map((stage) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2C4A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage['declaration'] ?? '',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Users: ${(stage['users'] as List).join(', ')}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {},
                            child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() {
                                _stages.remove(stage);
                              });
                            },
                            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class AddApprovalStageDialog extends StatefulWidget {
  const AddApprovalStageDialog({Key? key}) : super(key: key);

  @override
  State<AddApprovalStageDialog> createState() => _AddApprovalStageDialogState();
}

class _AddApprovalStageDialogState extends State<AddApprovalStageDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _declarationController = TextEditingController();
  
  // Mock users
  final List<String> _allUsers = [
    "Amarjit Singh (amarjitsunner098@gmail.com)",
    "Anna Brennan (anna@euroside.co.uk)",
    "Ashu Sharma (patwarimedical007@gmail.com)",
    "Avtar Singh (avtarsunner12@gmail.com)",
    "Charanjit Singh (cs3344012@gmail.com)",
    "Constantin Tugulea (tuguleaconstantin0@gmail.com)",
    "Felix Emmanuel (felix@euroside.co.uk)",
  ];
  
  final List<String> _selectedUsers = [];

  bool _isLoadingUsers = true; // Simulate loading

  @override
  void initState() {
    super.initState();
    // Simulate API delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _declarationController.dispose();
    super.dispose();
  }

  void _saveStage() {
    if (_titleController.text.trim().isEmpty || _declarationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and Declaration are required.")));
      return;
    }
    
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one user.")));
      return;
    }

    final newStage = {
      "title": _titleController.text.trim(),
      "declaration": _declarationController.text.trim(),
      "users": _selectedUsers,
    };
    
    Navigator.of(context).pop(newStage);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Approval Stage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2C4A),
                    fontFamily: 'Inter',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 20),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: "Title ",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: "Enter approval stage title",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text.rich(
                      TextSpan(
                        text: "Declaration ",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _declarationController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: "Enter the declaration text...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text.rich(
                      TextSpan(
                        text: "Users That Can Sign ",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isLoadingUsers
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _allUsers.isEmpty
                              ? const Center(child: Text("No users found.", style: TextStyle(color: Colors.grey)))
                              : ListView.separated(
                                  itemCount: _allUsers.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final user = _allUsers[index];
                                    final isSelected = _selectedUsers.contains(user);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedUsers.remove(user);
                                          } else {
                                            _selectedUsers.add(user);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: isSelected ? const Color(0xFF0D6EFD) : Colors.grey.shade400,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                user,
                                                style: TextStyle(
                                                  color: isSelected ? const Color(0xFF0D6EFD) : Colors.black87,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                  fontSize: 13.5,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _saveStage,
                  child: const Text("Save Stage", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
