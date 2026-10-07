import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final bool isRange;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String title;

  const CustomDatePickerDialog({
    super.key,
    this.isRange = false,
    this.initialStartDate,
    this.initialEndDate,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title = 'Select Date',
  });

  /// Show a custom date range picker dialog
  static Future<DateTimeRange?> showCustomDateRangePicker({
    required BuildContext context,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date Range',
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CustomDatePickerDialog(
        isRange: true,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2101),
        title: title,
      ),
    );
    if (result is DateTimeRange) return result;
    return null;
  }

  /// Show a custom single date picker dialog
  static Future<DateTime?> showCustomDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CustomDatePickerDialog(
        isRange: false,
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2101),
        title: title,
      ),
    );
    if (result is DateTime) return result;
    return null;
  }

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _currentMonth;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  DateTime? _selectedSingle;

  final List<String> _weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  void initState() {
    super.initState();
    if (widget.isRange) {
      _selectedStart = widget.initialStartDate != null
          ? _stripTime(widget.initialStartDate!)
          : null;
      _selectedEnd = widget.initialEndDate != null
          ? _stripTime(widget.initialEndDate!)
          : null;
      _currentMonth = DateTime(
        _selectedStart?.year ?? DateTime.now().year,
        _selectedStart?.month ?? DateTime.now().month,
        1,
      );
    } else {
      _selectedSingle = widget.initialDate != null
          ? _stripTime(widget.initialDate!)
          : _stripTime(DateTime.now());
      _currentMonth = DateTime(
        _selectedSingle?.year ?? DateTime.now().year,
        _selectedSingle?.month ?? DateTime.now().month,
        1,
      );
    }
  }

  DateTime _stripTime(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      if (!widget.isRange) {
        _selectedSingle = date;
        return;
      }

      // Range mode
      if (_selectedStart == null) {
        _selectedStart = date;
        _selectedEnd = null;
      } else if (_selectedEnd == null) {
        if (date.isBefore(_selectedStart!)) {
          _selectedStart = date;
          _selectedEnd = null;
        } else {
          _selectedEnd = date;
        }
      } else {
        // Both were selected, restart selection with this as new start
        _selectedStart = date;
        _selectedEnd = null;
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime day) {
    if (_selectedStart == null || _selectedEnd == null) return false;
    return day.isAfter(_selectedStart!) && day.isBefore(_selectedEnd!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F2C4A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryColor = const Color(0xFF0D6EFD);

    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // Sunday = 0

    final totalCells = firstDayWeekday + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    final monthFormat = DateFormat('MMMM yyyy');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Month / Year & Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    monthFormat.format(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(IconlyLight.arrow_left_2, size: 18),
                      color: textColor,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _prevMonth,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(IconlyLight.arrow_right_2, size: 18),
                      color: textColor,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ],
            ),

            if (widget.isRange) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(IconlyLight.calendar, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedStart == null
                            ? "Select start date"
                            : _selectedEnd == null
                                ? "From: ${DateFormat('dd/MM/yyyy').format(_selectedStart!)} (Select end date)"
                                : "${DateFormat('dd/MM/yyyy').format(_selectedStart!)}  →  ${DateFormat('dd/MM/yyyy').format(_selectedEnd!)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedStart == null ? textSecondary : textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Weekday Headers
            Row(
              children: _weekDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Calendar Days Grid
            for (int row = 0; row < rowsCount; row++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    for (int col = 0; col < 7; col++) ...[
                      Expanded(
                        child: _buildDayCell(
                          row: row,
                          col: col,
                          firstDayWeekday: firstDayWeekday,
                          daysInMonth: daysInMonth,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons (Cancel / Apply)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (widget.isRange) {
                      if (_selectedStart == null) return;
                      final start = _selectedStart!;
                      final end = _selectedEnd ?? _selectedStart!;
                      Navigator.pop(context, DateTimeRange(start: start, end: end));
                    } else {
                      if (_selectedSingle == null) return;
                      Navigator.pop(context, _selectedSingle);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E88E5) : primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Apply",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required int row,
    required int col,
    required int firstDayWeekday,
    required int daysInMonth,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
  }) {
    final cellIndex = row * 7 + col;
    final dayNum = cellIndex - firstDayWeekday + 1;

    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 36);
    }

    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);

    final isStart = _selectedStart != null && _isSameDay(date, _selectedStart!);
    final isEnd = _selectedEnd != null && _isSameDay(date, _selectedEnd!);
    final inRange = widget.isRange && _isInRange(date);
    final isSingleSelected = !widget.isRange && _selectedSingle != null && _isSameDay(date, _selectedSingle!);

    final isSelected = isStart || isEnd || isSingleSelected;

    Color? rangeBg;
    if (inRange) {
      rangeBg = isDark
          ? primaryColor.withValues(alpha: 0.25)
          : const Color(0xFFE8F2FF);
    } else if (isStart && _selectedEnd != null && !_isSameDay(_selectedStart!, _selectedEnd!)) {
      rangeBg = isDark
          ? primaryColor.withValues(alpha: 0.25)
          : const Color(0xFFE8F2FF);
    } else if (isEnd && _selectedStart != null && !_isSameDay(_selectedStart!, _selectedEnd!)) {
      rangeBg = isDark
          ? primaryColor.withValues(alpha: 0.25)
          : const Color(0xFFE8F2FF);
    }

    BorderRadius? rangeRadius;
    if (isStart && _selectedEnd != null && !_isSameDay(_selectedStart!, _selectedEnd!)) {
      rangeRadius = const BorderRadius.horizontal(left: Radius.circular(18));
    } else if (isEnd && _selectedStart != null && !_isSameDay(_selectedStart!, _selectedEnd!)) {
      rangeRadius = const BorderRadius.horizontal(right: Radius.circular(18));
    }

    return GestureDetector(
      onTap: () => _onDaySelected(date),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: rangeBg,
          borderRadius: rangeRadius,
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (inRange
                          ? (isDark ? Colors.white : primaryColor)
                          : textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
