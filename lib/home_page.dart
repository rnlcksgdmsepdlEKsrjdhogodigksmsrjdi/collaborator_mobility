import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'frame28_widget.dart'; 

class MapWithBottomSheetPage extends StatefulWidget {
  const MapWithBottomSheetPage({super.key});

  @override
  _MapWithBottomSheetPageState createState() => _MapWithBottomSheetPageState();
}

class _MapWithBottomSheetPageState extends State<MapWithBottomSheetPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MapChannel',
        onMessageReceived: (message) {
          debugPrint('받은 메시지: ${message.message}');
        },
      )
      ..loadRequest(Uri.parse('https://mobility-1997a.web.app/map.html')); // html로 해서 웹으로 가져옴
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 지도 (WebView)
          WebViewWidget(controller: _controller),

          /// 하단 시트 - 스크롤 기능
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.1,
            maxChildSize: 0.50,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController, // 스크롤 설정 관련
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Frame28Widget(), 
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
