import 'answer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  final List<Map<String, String>> faqList = const [
    {
      'question': '회원가입은 어떻게 하나요?',
      'answer': '회원가입은 이메일과 비밀번호를 입력한 후 해당 이메일을 인증하시면 됩니다.',
    },
    {
      'question': '비밀번호를 잊어버렸어요.',
      'answer': '로그인 화면에서 \'비밀번호 찾기\'를 클릭하여 임시 비밀번호를 발급받으실 수 있습니다.',
    },
    {
      'question': '예약을 취소하고 싶어요.',
      'answer': '예약 내역에서 해당 예약을 선택한 후 취소할 수 있습니다.',
    },
    {
      'question' : '회원 탈퇴는 어떻게 하나요?',
      'answer' : '메뉴에서 \'탈퇴하기\'를 클릭하고 안내에 따라 탈퇴할 수 있습니다.'
    },
    {
      'question' : '앱이 정상적으로 작동하지 않아요.',
      'answer' : '앱을 재실행하거나, 최신 버전으로 업데이트해보세요.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
              top: 50.h,
              left: 20.w,
              child: SizedBox(
                width: 28.w,
                height: 28.h,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(
                    'assets/images/icon.svg',
                    width: 28.w,
                    height: 28.h,
                    semanticsLabel: 'icon',
                  ),
                ),
              ),
            ),

          Positioned(
            top: 50.h,
            left: 20.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.asset(
                'assets/images/icon.svg',
                width: 28.w,
                height: 28.h,
                semanticsLabel: '뒤로가기 아이콘',
              ),
            ),
          ),

          Positioned(
            top: 52.h,
            left: 173.w,
            child: Text(
              'FAQ',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 20.sp,
                color: Colors.black,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Positioned.fill(
            top: 100.h,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                final question = faqList[index]['question']!;
                final answer = faqList[index]['answer']!;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FAQAnswerScreen(
                          question: question,
                          answer: answer,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 34.w,
                          height: 34.h,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF030361),
                          ),
                          child: Text(
                            'Q',
                            style: TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 15.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            question,
                            style: TextStyle(
                              fontFamily: 'Paperlogy',
                              fontSize: 15.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
