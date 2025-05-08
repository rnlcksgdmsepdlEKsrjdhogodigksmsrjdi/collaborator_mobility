import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobility/user_repository.dart';
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
  List<String> carNumbers = [];
  String? selectedCarNumber; // 차량 번호 상태 추가

  late String destination;
  late int currentYear;
  late int currentMonth;

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

    final today = DateTime.now();
    currentYear = today.year;
    currentMonth = today.month;
    selectedDate = today;

    calendar = _generateCalendar(currentYear, currentMonth);
    print('선택된 목적지: $destination');
    _loadUserCarNumber();
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

  Future<void> _loadUserCarNumber() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userInfo = await UserRepository().getUserAdditionalInfo(userId);

    if (userInfo != null && userInfo['carNumbers'] is List) {
      final cars = List<String>.from(userInfo['carNumbers']);
      if (cars.isNotEmpty) {
        setState(() {
          carNumbers = cars;
          selectedCarNumber = cars.first;
        });
      }
    }
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  bool _isPastTime(String time, DateTime selectedDate) {
    final List<String> timeParts = time.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);
    final DateTime timeOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
    final DateTime today = DateTime.now();

    return timeOfDay.isBefore(today);
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
                              : _isPastTime(time, selectedDate!) || (reservedTimes[_formatDateKey(selectedDate!)]?.contains(time) ?? false);
                          return TimeButton(
                            time: time,
                            isSelected: selectedTime == '오전 $time',
                            isDisabled: isDisabled,
                            onPressed: () {
                              setState(() {
                                if (selectedTime == '오전 $time') {
                                  selectedTime = null;
                                } else {
                                  selectedTime = '오전 $time';
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
                              : _isPastTime(time, selectedDate!) || (reservedTimes[_formatDateKey(selectedDate!)]?.contains(time) ?? false);
                          return TimeButton(
                            time: time,
                            isSelected: selectedTime == '오후 $time',
                            isDisabled: isDisabled,
                            onPressed: () {
                              setState(() {
                                if (selectedTime == '오후 $time') {
                                  selectedTime = null;
                                } else {
                                  selectedTime = '오후 $time';
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // 차량 번호 선택
                      if (carNumbers.isNotEmpty)
                        DropdownButton<String>(
                          value: selectedCarNumber,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCarNumber = newValue;
                            });
                          },
                          items: carNumbers.map<DropdownMenuItem<String>>((String carNumber) {
                            return DropdownMenuItem<String>(
                              value: carNumber,
                              child: Text(carNumber),
                            );
                          }).toList(),
                          hint: Text('차량 번호 선택'),
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
                      if (selectedDate != null && selectedTime != null && selectedCarNumber != null) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return ReservationConfirmPopup(
                              date: selectedDate!,
                              time: selectedTime!,
                              destination: destination,
                              carNumber: selectedCarNumber!,
                            );
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('날짜, 시간, 차량 번호를 선택해주세요.')),
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
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 16.sp,
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
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black,
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