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


      setState(() {
        reservations = loaded;
      });
    }
  }

   Future<void> cancelReservation(Map<String, dynamic> reservation) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 필드 추출
    final date = reservation['date'];
    final time = reservation['time'];
    final destination = reservation['destination'];
    final carNumber = reservation['carNumber'];
    final formattedDateTime = '$date $time';

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
            height: 230.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFD9D9D9), width: 1),
            ),
            child: Stack(
              children: [
                // 메시지
                Positioned(
                  top: 80.h,
                  left: 0.w,
                  right: 0.w,
                  child: Center(
                    child: Text(
                      '정말 예약을\n취소하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: 'Paperlogy',
                        color: Colors.black,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                // 확인 버튼
                Positioned(
                  top: 146.h,
                  left: 18.3.w,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm(); // 실제 예약 취소 처리
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
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                // 취소 버튼
                Positioned(
                  top: 146.h,
                  left: 125.3.w,
                  child: GestureDetector(
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
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
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
              top: 45.h,
              left: 20.w,
              child: SizedBox(
                width: 28.w,
                height: 28.h,
                child: SvgPicture.asset(
                  'assets/images/icon.svg',
                  semanticsLabel: 'icon',
                ),
              ),
            ),
            Positioned(
              top: 49.h,
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
                                    SizedBox(height: 17),
                                    SvgPicture.asset('assets/images/carNumber.svg', semanticsLabel: 'carnumber'),
                                  ],
                                ),
                              ),

                              // 텍스트 정보
                              Positioned(
                                top: 23.h,
                                left: 90.w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['destination'] ?? '',
                                      style: TextStyle(fontFamily: 'Paperlogy', fontSize: 16.sp),
                                    ),
                                    SizedBox(height: 17.h),
                                    Text(
                                      '${item['date']} ${item['time']}',
                                      style: TextStyle(fontFamily: 'Paperlogy', fontSize: 16.sp),
                                    ),
                                    SizedBox(height: 17.h),
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
