import 'package:flutter/material.dart';

class ReservationConfirmScreen extends StatelessWidget {
  final DateTime date;
  final String time;

  const ReservationConfirmScreen({
    super.key,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 확인'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.month}월 ${date.day}일 $time',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text('예약이 완료되었습니다!'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}