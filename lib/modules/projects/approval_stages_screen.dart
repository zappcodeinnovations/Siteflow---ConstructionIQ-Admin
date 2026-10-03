import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final appBarBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "Approval Stages",
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
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
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (_stages.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(IconlyLight.document, size: 48, color: secondaryTextColor),
                      const SizedBox(height: 16),
                      Text("No approval stages found.", style: TextStyle(color: secondaryTextColor)),
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
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage['declaration'] ?? '',
                              style: TextStyle(color: secondaryTextColor, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Users: ${(stage['users'] as List).join(', ')}",
                              style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {},
                            child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: isDark ? Colors.red.withOpacity(0.4) : Colors.red.shade200),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final inputBg = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Dialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
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
                Text(
                  "Add Approval Stage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Inter',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
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
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
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
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: inputBg,
                        hintText: "Enter approval stage title",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
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
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
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
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        hintText: "Enter the declaration text...",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
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
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
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
                        color: inputBg,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isLoadingUsers
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _allUsers.isEmpty
                              ? Center(child: Text("No users found.", style: TextStyle(color: secondaryTextColor)))
                              : ListView.separated(
                                  itemCount: _allUsers.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
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
                                        color: isSelected ? const Color(0xFF0D6EFD).withOpacity(0.1) : Colors.transparent,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: isSelected ? const Color(0xFF0D6EFD) : secondaryTextColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                user,
                                                style: TextStyle(
                                                  color: isSelected ? const Color(0xFF0D6EFD) : textColor,
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
                    foregroundColor: secondaryTextColor,
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
