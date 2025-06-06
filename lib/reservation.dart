import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  String? selectedCarNumber;
  late String destination;
  late int currentYear;
  late int currentMonth;

  final List<String> amTimes = ['7:12', '11:55'];
  final List<String> pmTimes = ['12:51', '2:00', '8:00', '10:30'];

  // 변경: Map<String, List<String>>로 타입 명시
  Map<String, List<String>> reservedTimes = {};
  DatabaseReference? _reservationsRef;
  StreamSubscription<DatabaseEvent>? _reservationsSubscription;

  @override
  void initState() {
    super.initState();
    destination = widget.destination;
    final today = DateTime.now();
    currentYear = today.year;
    currentMonth = today.month;
    selectedDate = today;

    _generateCalendar();
    _loadUserCarNumber();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _reservationsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _reservationsRef = FirebaseDatabase.instance.ref('reservations/$destination');
    _reservationsSubscription = _reservationsRef?.onValue.listen((event) {
      if (mounted) {
        _loadReservedTimes();
      }
    });
  }

  Future<void> _loadReservedTimes() async {
    final snapshot = await _reservationsRef?.get();

    if (snapshot?.exists ?? false) {
      final data = snapshot!.value as Map<dynamic, dynamic>;
      final Map<String, List<String>> result = {};

      data.forEach((fullKey, value) {
        if (fullKey is String) {
          final parts = fullKey.split(' ');
          if (parts.length == 2) {
            final date = parts[0];
            final time = parts[1];
            result.putIfAbsent(date, () => []).add(time);
          }
        }
      });

      if (mounted) {
        setState(() {
          reservedTimes = result;
        });
      }
    } else if (mounted) {
      setState(() {
        reservedTimes = {};
      });
    }
  }


  List<List<Map<String, dynamic>>> calendar = [];

  void _generateCalendar() {
    final weeks = <List<Map<String, dynamic>>>[];
    final firstDay = DateTime(currentYear, currentMonth, 1);
    final weekday = firstDay.weekday % 7;
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    final today = DateTime.now();
    final lastAvailableDate = today.add(const Duration(days: 9)); // 오늘 포함 10일

    List<Map<String, dynamic>> week = [];

    for (int i = 0; i < weekday; i++) {
      week.add({'date': '', 'disabled': true});
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentYear, currentMonth, day);
      bool isPast = date.isBefore(DateTime(today.year, today.month, today.day));
      bool isBeyondLimit = date.isAfter(lastAvailableDate);

      week.add({
        'date': day.toString(),
        'disabled': isPast || isBeyondLimit,
        'isBeyondLimit': isBeyondLimit,
      });

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

    setState(() {
      calendar = weeks;
    });
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
      _generateCalendar();
      selectedDate = null;
      selectedTime = null;
    });
    _loadReservedTimes();
  }

  Future<void> _loadUserCarNumber() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userInfo = await UserRepository().getUserAdditionalInfo(userId);
    if (userInfo != null && userInfo['carNumbers'] is List) {
      final cars = List<String>.from(userInfo['carNumbers']);
      if (mounted) {
        setState(() {
          carNumbers = cars;
          selectedCarNumber = cars.isNotEmpty ? cars.first : null;
        });
      }
    }
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool _isPastTime(String time, DateTime date, {required bool isPM}) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    final targetTime = DateTime(date.year, date.month, date.day, hour, minute);
    return targetTime.isBefore(DateTime.now());
  }

  String _convertTo24HourFormat(String period, String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];

    if (period == '오후' && hour != 12) hour += 12;
    if (period == '오전' && hour == 12) hour = 0;

    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  bool _isReserved(String dateKey, String period, String time) {
    if (!reservedTimes.containsKey(dateKey)) return false;
    
    final time24 = _convertTo24HourFormat(period, time);
    return reservedTimes[dateKey]!.contains(time24);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight * 1.1,
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
                  top: 430.h,
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
                          final dateKey = selectedDate == null ? '' : _formatDateKey(selectedDate!);
                          final isDisabled = selectedDate == null
                              ? false
                              : _isPastTime(time, selectedDate!, isPM: false) || _isReserved(dateKey, '오전', time);
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
                          final dateKey = selectedDate == null ? '' : _formatDateKey(selectedDate!);
                          final isDisabled = selectedDate == null
                              ? false
                              : _isPastTime(time, selectedDate!, isPM: true) || _isReserved(dateKey, '오후', time);
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
                  bottom: 50.h,
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
                    onPressed: () async {
                      
                      if (selectedDate != null && selectedTime != null && selectedCarNumber != null) {
                        final dateKey = _formatDateKey(selectedDate!);
                        final period = selectedTime!.split(' ')[0]; // 오전 오후
                        final time = selectedTime!.split(' ')[1]; // 시간
                        final time24 = _convertTo24HourFormat(period, time);

                        final fullKey = '$dateKey $time24';
                        final snapshot = await FirebaseDatabase.instance
                          .ref('reservations/$destination/$fullKey')
                          .get();

                        if(snapshot.exists){
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이미 예약된 시간입니다. 다른 시간을 선택해주세요.')),
                          );
                          return;
                        }
                        

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
              Text('$currentYear년 $currentMonth월',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

          // 요일 라벨 (색상 반영)
          Row(
            children: List.generate(7, (index) {
              const weekDays = ['일', '월', '화', '수', '목', '금', '토'];
              final Color textColor = index == 0
                  ? const Color(0xFFFF6B6B) // 일요일 - 빨강
                  : index == 6
                      ? const Color(0xFF4D70B4) // 토요일 - 파랑
                      : const Color(0xFF333333); // 평일 - 검정
              return Expanded(
                child: Center(
                  child: Text(
                    weekDays[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // 날짜 셀
          Column(
            children: calendar.map((week) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: week.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Map<String, dynamic> day = entry.value;

                  final bool isSelected = !day['disabled'] &&
                      selectedDate != null &&
                      selectedDate!.year == currentYear &&
                      selectedDate!.month == currentMonth &&
                      selectedDate!.day == int.parse(day['date']);

                  // 날짜 텍스트 색상
                  final Color textColor = isSelected
                      ? Colors.white
                      : day['disabled']
                          ? Colors.grey
                          : index == 0
                              ? const Color(0xFFFF6B6B) // 일요일
                              : index == 6
                                  ? const Color(0xFF4D70B4) // 토요일
                                  : Colors.black;

                  return GestureDetector(
                    onTap: day['disabled']
                        ? null
                        : () {
                            setState(() {
                              selectedDate = DateTime(currentYear, currentMonth, int.parse(day['date']));
                              selectedTime = null;
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
                            color: textColor,
                            fontWeight: FontWeight.w600,
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
            ? const Color(0xFF45539D)
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
