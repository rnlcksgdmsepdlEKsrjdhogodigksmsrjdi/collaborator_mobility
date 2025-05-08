import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

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
    required this.carNumber
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 MM월 dd일').format(date);

    return Center(
      child: SizedBox(
        width: 245,
        height: 230,
        child: Stack(
          children: <Widget>[
            // 배경 컨테이너
            Positioned(
              top: 0,
              left: 0.82,
              child: Container(
                width: 244.18,
                height: 230,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    width: 1,
                  ),
                ),
              ),
            ),
            // 가로 구분선
            const Positioned(
              top: 189.55,
              left: 0,
              child: Divider(
                color: Color.fromRGBO(217, 217, 217, 1),
                thickness: 1,
                height: 1,
              ),
            ),
            // 세로 구분선
            Positioned(
              top: 189.55,
              left: 123.73,
              child: Transform.rotate(
                angle: -90 * (math.pi / 180),
                child: const Divider(
                  color: Color.fromRGBO(217, 217, 217, 1),
                  thickness: 1,
                  height: 1,
                ),
              ),
            ),
            // 아이콘들
            // 아이콘 + 텍스트 (location, time, car number)
            Positioned(
              top: 39.43,
              left: 28.03,
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
                      const SizedBox(height: 30),
                      SvgPicture.asset(
                        'assets/images/time.svg',
                        semanticsLabel: 'time',
                      ),
                      const SizedBox(height: 30),
                      SvgPicture.asset(
                        'assets/images/carNumber.svg',
                        semanticsLabel: 'carnumber',
                      ),
                    ],
                  ),
                  const SizedBox(width: 15), // 아이콘과 텍스트 사이 간격
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                        child: Text(
                          destination,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 20,
                        child: Text(
                          '$formattedDate $time',
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 20,
                        child: Text(
                          carNumber,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            color: Colors.black,
                            fontFamily: 'Paperlogy',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 확인 텍스트
            const Positioned(
              top: 199,
              left: 47,
              child: Text(
                '확인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Colors.black,
                  fontFamily: 'Paperlogy',
                  fontSize: 20,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
            // 취소 텍스트
            const Positioned(
              top: 199,
              left: 166,
              child: Text(
                '취소',
                textAlign: TextAlign.center,
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Colors.black,
                  fontFamily: 'Paperlogy',
                  fontSize: 20,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.normal,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
