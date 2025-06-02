import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


class ReservationConfirmPopup extends StatelessWidget {
  final String destination;
  final DateTime date;
  final String time;
  final String carNumber;

  const ReservationConfirmPopup({
    super.key,
    required this.destination,
    required this.date,
    required this.time,
    required this.carNumber,
  });

  Future<void> saveReservationToFirebase(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인이 필요합니다.')),
    );
    return;
  }

  final formattedDate = DateFormat('yyyy-MM-dd').format(date);

  // 오전/오후 처리 포함된 시간 → 24시간제로 변환
  String convertTo24Hour(String time) {
    time = time.replaceAll('오전', 'AM').replaceAll('오후', 'PM').trim();
    final parsed = DateFormat('a h:mm', 'en_US').parse(time);
    return DateFormat('HH:mm').format(parsed); 
  }

  final time24 = convertTo24Hour(time); 
  final formattedDateTime = '$formattedDate $time24'; 
  final reservationDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(formattedDateTime);
  final reservationTimestamp = reservationDateTime.millisecondsSinceEpoch;

  final dbRef = FirebaseDatabase.instance.ref();
  final userReservationsRef = dbRef.child('users').child(uid).child('reservations');

  // 예약 개수 체크
  final snapshot = await userReservationsRef.get();

  int totalReservations = 0;
  if (snapshot.exists) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    for (final day in data.values) {
      if (day is Map<dynamic, dynamic>) {
        totalReservations += day.length;
      }
    }
  }

  if (totalReservations >= 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약은 최대 3개까지 가능합니다.')),
    );
    return;
  }

  // 예약 정보 저장
  await dbRef.child('reservations').child(destination).child(formattedDateTime).set({
    'carNumber': carNumber,
    'uid': uid,
    'expireAt': reservationTimestamp,
    'parked': false
  });

  await userReservationsRef.child(formattedDate).child(time).set({
    'destination': destination,
    'carNumber': carNumber,
    'expireAt': reservationTimestamp
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('예약이 완료되었습니다.')),
  );
  Navigator.of(context).pop();
}




  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 MM월 dd일').format(date);

    return Center(
      child: SizedBox(
        width: 245.w,
        height: 230.h,
        child: Stack(
          children: <Widget>[
            // 배경
            Positioned(
              top: 0.h,
              left: 0.82.w,
              child: Container(
                width: 244.18.w,
                height: 230.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    width: 1.w,
                  ),
                ),
              ),
            ),
            // 가로 구분선
            Positioned(
              top: 189.55.h,
              left: 0.w,
              child: Divider(
                color: const Color.fromRGBO(217, 217, 217, 1),
                thickness: 1,
                height: 1,
              ),
            ),
            // 세로 구분선
            Positioned(
              top: 189.55.h,
              left: 123.73.w,
              child: Transform.rotate(
                angle: -90 * (math.pi / 180),
                child: const Divider(
                  color: Color.fromRGBO(217, 217, 217, 1),
                  thickness: 1,
                  height: 1,
                ),
              ),
            ),
            // 내용
            Positioned(
              top: 39.43.h,
              left: 28.03.w,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/images/location.svg',
                        semanticsLabel: 'location',
                      ),
                      SizedBox(height: 30.h),
                      SvgPicture.asset(
                        'assets/images/time.svg',
                        semanticsLabel: 'time',
                      ),
                      SizedBox(height: 30.h),
                      SvgPicture.asset(
                        'assets/images/carNumber.svg',
                        semanticsLabel: 'carnumber',
                      ),
                    ],
                  ),
                  SizedBox(width: 15.w),
                  SizedBox(
                    width: 160.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          destination,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 30.h),
                        Text(
                          '$formattedDate $time',
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 30.h),
                        Text(
                          carNumber,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 확인 버튼
            Positioned(
              top: 199.h,
              left: 47.w,
              child: GestureDetector(
                onTap: () => saveReservationToFirebase(context),
                child: Text(
                  '확인',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.black,
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.normal,
                    height: 1,
                  ),
                ),
              ),
            ),
            // 취소 버튼
            Positioned(
              top: 199.h,
              left: 166.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  '취소',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.black,
                    fontFamily: 'Paperlogy',
                    fontSize: 20.sp,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.normal,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
