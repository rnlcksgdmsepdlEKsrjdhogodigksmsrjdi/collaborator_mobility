# mobility

조선대학교 내의 전기차 충전소 예약 및 위치 확인 관련 앱 제작

## 기초 설정

- 플러터 설정 <br>
플러터를 사용해서 만들고 있어 플러터에 대한 기초 설정이 필요합니다. 
[플러터 설치 및 설정](https://docs.flutter.dev/get-started/install?_gl=1*1e6o7pb*_up*MQ..*_ga*MjA1OTY4MTEyOS4xNzQ0NjAzNzA0*_ga_04YGWK0175*MTc0NDYwMzcwMy4xLjAuMTc0NDYwMzcwMy4wLjAuMA..) <br>
플러터 버전  3.29.2 <br>
다트 버전: 3.7.2 <br>


- 안드로이드 설정
    [안드로이드 스튜디오 설치 및 설정](https://developer.android.com/studio?hl=ko) <br>
    안드로이드 스튜디오 버전 : Android Studio Meerkat | 2024.3.1 <br>

- iOS 설정 <br>
    아직 iOS 파트를 구현하지 않아서 설정하지 않음.

## 주의 사항
firebase SDK API 키 발급하지 말아주세요. <br>
branch해서 건들어도 API 키 변경은 절대로 하지 말아주세요.<BR>
lib 폴더에서 작업해주세요. <br>
main branch는 건들이지 말아주세요. <br>



## 기능 구현 내용
### 로그인
- 로그인 / 로그아웃 / 인증 파트 구현 
- 자동 로그인 확인
- Firebase Realtime Database에 uid 관련 정보 저장 완료
- 앱 디자인 적용 완료

### 회원가입 화면
- 회원 가입 기능 구현
- 회원 가입 페이지 디자인 구현 

### 아이디 찾기, 비밀번호 찾기 
- 디자인 x
- 구현 x
- 방식 생각해볼 필요가 있음.

### 회원정보 입력
- 회원 정보 입력 구현 
- 회원 정보 페이지 디자인 구현 

### 홈 화면 구축
- 네이버 지도 API 불러오기
- 네이버 지도 위치 마크 찍기
- 수정.
<!--
뭐라적는곳...
-->