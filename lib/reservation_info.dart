import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReservationInfo extends StatefulWidget {
  const ReservationInfo({super.key});

  @override
  _ReservationInfoWidgetState createState() => _ReservationInfoWidgetState();
}

class _ReservationInfoWidgetState extends State<ReservationInfo> {
  List<Map<String, String>> reservations = [];

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseDatabase.instance.ref('users/$uid/reservations');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      List<Map<String, String>> loaded = [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((date, value) {
        final times = Map<String, dynamic>.from(value);
        times.forEach((time, detail) {
          final info = Map<String, dynamic>.from(detail);
          loaded.add({
            'date': date,
            'time': time,
            'destination': info['destination'] ?? '',
            'carNumber': info['carNumber'] ?? '',
            'key': '${date}_${time}_${info['destination']}_${uid.substring(0, 5)}',
            'dateTime': time, // 전체 경로가 필요한 경우
          });
        });
      });

      // 시간 순 정렬 
      loaded.sort((a, b) {
        DateTime parseCustomDateTime(String date, String time) {
          // time 예시: '오후 8:00' 또는 '오전 9:30'
          final isPM = time.contains('오후');
          final cleanTime = time.replaceAll(RegExp(r'[오전오후 ]'), '');
          final parts = cleanTime.split(':');

          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);

          // 오전 / 오후 구분 
          if (isPM && hour < 12) {
            hour += 12;
          } else if (!isPM && hour == 12) {
            hour = 0;
          }

          return DateTime.parse('$date ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        }

        final aDateTime = parseCustomDateTime(a['date']!, a['time']!);
        final bDateTime = parseCustomDateTime(b['date']!, b['time']!);
        return aDateTime.compareTo(bDateTime);
      });

      setState(() {
        reservations = loaded;
      });
    }
  }

  String convertTo24Hour(String date, String time) {
    final isPM = time.contains('오후');
    final cleanTime = time.replaceAll(RegExp(r'[오전오후 ]'), '');
    final parts = cleanTime.split(':');

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    if (isPM && hour < 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$date $hourStr:$minuteStr';
  }


   Future<void> cancelReservation(Map<String, dynamic> reservation) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 필드 추출
    final date = reservation['date'];
    final time = reservation['time'];
    final destination = reservation['destination'];
    final carNumber = reservation['carNumber'];
    final formattedDateTime = convertTo24Hour(date, time);
    // 고유 ID 생성 (삭제 확인용)
    final reservationId = '${date}_${time}_$destination';

    try {
      // 1. 공통 예약에서 삭제 (UID로 본인 것만 확인 후 삭제)
      final globalRef = FirebaseDatabase.instance.ref()
          .child('reservations')
          .child(destination)
          .child(formattedDateTime);

      final snapshot = await globalRef.get();
      if (snapshot.exists && snapshot.child('uid').value == uid) {
        await globalRef.remove();
      }

      // 2. 사용자 예약에서 삭제
      await FirebaseDatabase.instance.ref()
          .child('users')
          .child(uid)
          .child('reservations')
          .child(date)
          .child(time)
          .remove();

      // 3. 로컬 상태 업데이트 (더 엄격한 조건)
      setState(() {
        reservations.removeWhere((r) =>
            r['date'] == date &&
            r['time'] == time &&
            r['destination'] == destination);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약이 취소되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약 취소 실패: ${e.toString()}')));
    }
  }

  void showCancelDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 236.34.w,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFD9D9D9), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.h),
                Text(
                  '정말 예약을\n취소하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontFamily: 'Paperlogy',
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 40.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 확인 버튼
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: Container(
                        width: 95.w,
                        height: 43.h,
                        decoration: BoxDecoration(
                          color: Color(0xFF030361),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontFamily: 'Paperlogy',
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // 취소 버튼
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 95.w,
                        height: 43.h,
                        decoration: BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontFamily: 'Paperlogy',
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 390.w,
        height: 844.h,
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            // 상단 아이콘과 제목
            Positioned(
              top: 49.h,
              left: 20.w,
              child: SizedBox(
                width: 28.w,
                height: 28.h,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(
                  'assets/images/icon.svg',
                  semanticsLabel: 'icon',
                ),
                )
                
              ),
            ),
            Positioned(
              top: 52.h,
              left: 158.w,
              child: Text(
                '예약 내역',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Paperlogy',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),

            // 예약 카드 리스트
            Positioned(
              top: 110.h,
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: reservations.isEmpty
                  ? Center(child: Text('예약 내역이 없습니다.'))
                  : ListView.builder(
                      itemCount: reservations.length,
                      itemBuilder: (context, index) {
                        final item = reservations[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Stack(
                            children: [
                              // 배경 카드
                              Container(
                                width: 350.w,
                                height: 174.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),

                              // 아이콘 3개
                              Positioned(
                                top: 20.h,
                                left: 31.w,
                                child: Column(
                                  children: [
                                    SvgPicture.asset('assets/images/location.svg', semanticsLabel: 'location'),
                                    SizedBox(height: 17),
                                    SvgPicture.asset('assets/images/time.svg', semanticsLabel: 'time'),
                                    SizedBox(height: 19),
                                    SvgPicture.asset('assets/images/carNumber.svg', semanticsLabel: 'carnumber'),
                                  ],
                                ),
                              ),

                              // 텍스트 정보
                              Positioned(
                                top: 17.h,
                                left: 70.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['destination'] ?? '',
                                      style: TextStyle(fontFamily: 'Paperlogy', fontSize: 16.sp),
                                    ),
                                    SizedBox(height: 11.h),
                                    Text(
                                      '${item['date']} ${item['time']}',
                                      style: TextStyle(fontFamily: 'Paperlogy', fontSize: 16.sp),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      item['carNumber'] ?? '',
                                      style: TextStyle(fontFamily: 'Paperlogy', fontSize: 16.sp),
                                    ),
                                  ],
                                ),
                              ),

                              // 예약 취소 버튼
                              Positioned(
                                top: 129.h,
                                left: 21.w,
                                child: GestureDetector(
                                  onTap:() {
                                    showCancelDialog(
                                      context: context,
                                      onConfirm: () {
                                        cancelReservation(item);
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: 307.w,
                                    height: 37.h,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(3, 3, 97, 1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '예약 취소',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Paperlogy',
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


