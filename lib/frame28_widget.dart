import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Frame28Widget extends StatelessWidget {
  const Frame28Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(217, 217, 217, 0.6),
            offset: Offset(0, 4),
            blurRadius: 13,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(217, 217, 217, 1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              
              const SizedBox(height: 30),
              const Divider(color: Color.fromRGBO(245, 245, 245, 1), thickness: 9),

              const SizedBox(height: 20),
            
              // 목적지 목록들
              buildPlaceItem('assets/images/place1.svg', '조선대학교 해오름관'),
              buildPlaceItem('assets/images/place2.svg', '조선대학교 중앙도서관'),
              buildPlaceItem('assets/images/place3.svg', '조선대학교 IT융합대학'),
            ],
          ),
        ),
      ),
    );
  }

    Widget buildPlaceItem(String iconPath, String label) {
    return Column(
      children: [
        Row(
          children: [
            SvgPicture.asset(iconPath),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'Paperlogy',
                  fontSize: 20,
                  height: 1.0,
                ),
              ),
            ),
            Container(
              width: 76,
              height: 33,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(3, 3, 97, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text(
                '예약하기',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Paperlogy',
                  fontSize: 15,
                  letterSpacing: -0.5,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(
          thickness: 1,
          color: Color(0xFFD9D9D9),
          indent: 0,
          endIndent: 0,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
