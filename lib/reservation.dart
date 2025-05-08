import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/widgets/reservation_confirm_popup.dart';

class ReservationScreen extends StatefulWidget {
  final String destination;
  const ReservationScreen({super.key, required this.destination});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  String? destination;

  int currentYear = 2025;
  int currentMonth = 5;

  final List<String> amTimes = ['12:00', '3:30', '7:00', '10:30'];
  final List<String> pmTimes = ['12:00', '3:30', '7:00', '10:30'];

  final Map<String, List<String>> reservedTimes = {
    '2025-05-18': ['10:30', '11:00', '12:00', '3:30', '7:00'],
    '2025-05-19': ['8:00', '10:30'],
    '2025-05-20': ['4:30', '7:00'],
  };

  List<List<Map<String, dynamic>>> calendar = [];

  @override
  void initState() {
    super.initState();
    destination = widget.destination;
    calendar = _generateCalendar(currentYear, currentMonth);
  }

  List<List<Map<String, dynamic>>> _generateCalendar(int year, int month) {
    List<List<Map<String, dynamic>>> weeks = [];
    DateTime firstDay = DateTime(year, month, 1);
    int weekday = firstDay.weekday % 7;
    int daysInMonth = DateTime(year, month + 1, 0).day;

    List<Map<String, dynamic>> week = [];
    for (int i = 0; i < weekday; i++) {
      week.add({'date': '', 'disabled': true});
    }

    for (int day = 1; day <= daysInMonth; day++) {
      week.add({'date': day.toString(), 'disabled': false});
      if (week.length == 7) {
        weeks.add(week);
        week = [];
      }
    }

    if (week.isNotEmpty) {
      while (week.length < 7) {
        week.add({'date': '', 'disabled': true});
      }
      weeks.add(week);
    }

    return weeks;
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth += offset;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear += 1;
      } else if (currentMonth < 1) {
        currentMonth = 12;
        currentYear -= 1;
      }
      calendar = _generateCalendar(currentYear, currentMonth);
      selectedDate = null;
      selectedTime = null;
    });
  }

  bool _isPastTime(DateTime date, String time, {required bool isAm}) {
  final now = DateTime.now();

  // 시간 문자열을 시:분 형태로 나눔
  final parts = time.split(':');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);

  if (isAm) {
    if (hour == 12) hour = 0; // 오전 12시는 0시
  } else {
    if (hour != 12) hour += 12; // 오후 시간 변환
  }

  final fullDateTime = DateTime(date.year, date.month, date.day, hour, minute);

  return fullDateTime.isBefore(now);
}


  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight * 1.3,
            child: Stack(
              children: [
                Positioned(
                  top: 20.h,
                  left: 20.w,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 28.w,
                      height: 28.h,
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                Positioned(
                  top: 22.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '예약',
                      style: TextStyle(
                        fontFamily: 'Paperlogy',
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 70.h,
                  left: 20.w,
                  right: 20.w,
                  child: _buildCalendar(),
                ),
                Positioned(
                  top: 400.h,
                  left: 20.w,
                  right: 20.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오전', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: amTimes.map((time) {
                          final isDisabled = selectedDate == null
                              ? false
                              : (reservedTimes[_formatDateKey(selectedDate!)]?.contains(time) ?? false) ||_isPastTime(selectedDate!, time, isAm: true);
                          return TimeButton(
                            time: time,
                            isSelected: selectedTime == '오전 $time',
                            isDisabled: isDisabled,
                            onPressed: () {
                              setState(() {
                                if (selectedTime == '오전 $time') {
                                  selectedTime = null; // 선택 버튼 누르면 해제
                                }
                                else {
                                  selectedTime = '오전 $time'; //버튼 선택 O
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('오후', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: pmTimes.map((time) {
                          final isDisabled = selectedDate == null
                              ? false
                              : (reservedTimes[_formatDateKey(selectedDate!)]?.contains(time) ?? false) ||_isPastTime(selectedDate!, time, isAm: false);
                          return TimeButton(
                            time: time,
                            isSelected: selectedTime == '오후 $time',
                            isDisabled: isDisabled,
                            onPressed: () {
                              setState(() {
                                if(selectedTime == '오후 $time') {
                                  selectedTime = null;
                                }
                                else {
                                  selectedTime = '오후 $time';
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30.h,
                  left: 20.w,
                  right: 20.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF45539D),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (selectedDate != null && selectedTime != null) {
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationConfirmScreen(
                              date: selectedDate!,
                              time: selectedTime!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('날짜와 시간을 선택해주세요.')),
                        );
                      }
                    },
                    child: const Text('예약하기', style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currentYear년 $currentMonth월', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeMonth(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _WeekDayText('일'),
              _WeekDayText('월'),
              _WeekDayText('화'),
              _WeekDayText('수'),
              _WeekDayText('목'),
              _WeekDayText('금'),
              _WeekDayText('토'),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: calendar.map((week) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: week.map((day) {
                  final bool isSelected = !day['disabled'] &&
                      selectedDate != null &&
                      selectedDate!.year == currentYear &&
                      selectedDate!.month == currentMonth &&
                      selectedDate!.day == int.parse(day['date']);

                  return GestureDetector(
                    onTap: day['disabled']
                        ? null
                        : () {
                            setState(() {
                              selectedDate = DateTime(currentYear, currentMonth, int.parse(day['date']));
                              selectedTime = null; // 시간 선택 초기화
                            });
                          },
                    child: Container(
                      width: 35.w,
                      height: 35.h,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF45539D) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          day['date'],
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: day['disabled']
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeekDayText extends StatelessWidget {
  final String text;

  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class TimeButton extends StatelessWidget {
  final String time;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onPressed;

  const TimeButton({super.key, 
    required this.time,
    required this.isSelected,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xFF45539D) : Colors.white,
        minimumSize: const Size(80, 35),
        elevation: 0, // 그림자 제거
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
            ? Colors.blue
            : isDisabled
              ? Colors.grey.shade300
              : Colors.grey.shade500,
            width: 1,
          )
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : isDisabled ? Colors.grey : Colors.black,
        ),
      ),
    );
  }
}