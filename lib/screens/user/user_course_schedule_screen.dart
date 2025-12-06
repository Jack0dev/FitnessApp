import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/enrollment_model.dart';
import '../../models/course_lesson_model.dart';
import '../../services/course/lesson_service.dart';
import '../../widgets/loading_widget.dart';
import '../../core/localization/app_localizations.dart';

class UserCourseScheduleScreen extends StatefulWidget {
  final CourseModel course;
  final EnrollmentModel enrollment;

  const UserCourseScheduleScreen({
    super.key,
    required this.course,
    required this.enrollment,
  });

  @override
  State<UserCourseScheduleScreen> createState() => _UserCourseScheduleScreenState();
}

class _UserCourseScheduleScreenState extends State<UserCourseScheduleScreen> {
  final _lessonService = LessonService();
  List<CourseLessonModel> _lessons = [];
  bool _isLoading = true;
  String? _error;
  
  // Calendar view state
  DateTime _currentDate = DateTime.now();
  bool _isMonthView = false; // false = week view, true = month view

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessons = await _lessonService.getCourseLessons(widget.course.id);
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Get lessons for a specific date
  // Note: Schedule is now managed separately, so this returns empty list
  List<CourseLessonModel> _getLessonsForDate(DateTime date) {
    // Schedule is managed in separate schedules table
    return [];
  }

  // Get start of week
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return date.subtract(Duration(days: weekday - 1));
  }

  // Get all dates in current week
  List<DateTime> _getWeekDates() {
    final startOfWeek = _getStartOfWeek(_currentDate);
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // Get all dates in current month
  List<DateTime> _getMonthDates() {
    final firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    
    // Get start of week for first day
    final startDate = _getStartOfWeek(firstDay);
    // Get end of week for last day
    final endWeekday = lastDay.weekday;
    final endDate = lastDay.add(Duration(days: 7 - endWeekday));
    
    final dates = <DateTime>[];
    var current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  // Get Vietnamese day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.translate('schedule')} - ${widget.course.title}'),
        actions: [
          IconButton(
            icon: Icon(_isMonthView ? Icons.view_week : Icons.calendar_view_month),
            onPressed: () {
              setState(() {
                _isMonthView = !_isMonthView;
              });
            },
            tooltip: _isMonthView ? 'Xem theo tuần' : 'Xem theo tháng',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $_error',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLessons,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _lessons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No schedule available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your instructor will add lesson schedule soon!',
                            style: TextStyle(color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      child: Column(
                        children: [
                          // Calendar Header with Navigation
                          _buildCalendarHeader(),
                          // Calendar Table
                          Expanded(
                            child: _isMonthView ? _buildMonthView() : _buildWeekView(),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthYear = '${_currentDate.month}/${_currentDate.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_isMonthView) {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
                } else {
                  _currentDate = _currentDate.subtract(const Duration(days: 7));
                }
              });
            },
          ),
          Text(
            monthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_isMonthView) {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
                } else {
                  _currentDate = _currentDate.add(const Duration(days: 7));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    final weekDates = _getWeekDates();
    final today = DateTime.now();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Day headers
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: List.generate(7, (index) {
                final date = weekDates[index];
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey[300]!,
                          width: index < 6 ? 1 : 0,
                        ),
                      ),
                      color: isToday ? Colors.blue[50] : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.blue[800] : Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.blue[800] : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Flexible(
                          child: Text(
                            '${date.month}/${date.year}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isToday ? Colors.blue[600] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Day content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (index) {
              final date = weekDates[index];
              final lessons = _getLessonsForDate(date);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              
              return Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey[300]!,
                        width: index < 6 ? 1 : 0,
                      ),
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                    color: isToday ? Colors.blue.withOpacity(0.05) : Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: lessons.isEmpty
                      ? Center(
                          child: Text(
                            'Không có lịch',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: lessons.map((lesson) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue[300]!),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final monthDates = _getMonthDates();
    final today = DateTime.now();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Day headers
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: List.generate(7, (index) {
                final weekday = index + 1; // 1 = Monday
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey[300]!,
                          width: index < 6 ? 1 : 0,
                        ),
                      ),
                    ),
                    child: Text(
                      _getDayName(weekday),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            ),
          ),
          // Calendar grid
          ...List.generate((monthDates.length / 7).ceil(), (weekIndex) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (dayIndex) {
                final dateIndex = weekIndex * 7 + dayIndex;
                if (dateIndex >= monthDates.length) {
                  return Expanded(child: Container());
                }
                
                final date = monthDates[dateIndex];
                final isCurrentMonth = date.month == _currentDate.month;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final lessons = isCurrentMonth ? _getLessonsForDate(date) : [];
                
                return Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey[300]!,
                          width: dayIndex < 6 ? 1 : 0,
                        ),
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                      color: isToday
                          ? Colors.blue[50]
                          : isCurrentMonth
                              ? Colors.white
                              : Colors.grey[50],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Colors.blue[800]
                                : isCurrentMonth
                                    ? Colors.black87
                                    : Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (lessons.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          ...lessons.take(2).map((lesson) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          if (lessons.length > 2)
                            Text(
                              '+${lessons.length - 2}',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
