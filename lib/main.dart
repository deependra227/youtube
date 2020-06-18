import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var url = "https://www.youtube.com/";
  bool isLoaded;
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();

  @override
  void initState() {
    setState(() {
      isLoaded = false;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
      children: <Widget>[
        FutureBuilder<InAppWebViewController>(
          future: _controller.future,
          builder: (BuildContext context,
              AsyncSnapshot<InAppWebViewController> controller) {
            return _webViewPage(context, controller);
          },
        ),
        (isLoaded == false)
            ? Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                    child: Image.asset(
                  'assets/logo.png',
                  scale: 2,
                )))
            : Container()
      ],
    ));
  }

  backFunction(BuildContext context,
      AsyncSnapshot<InAppWebViewController> controller) async {
    if (controller.data.canGoBack() != null) {
      controller.data.goBack();
    }
  }

  _webViewPage(
      BuildContext context, AsyncSnapshot<InAppWebViewController> controller) {
    return WillPopScope(
        onWillPop: () => backFunction(context, controller),
        child: InAppWebView(
          initialUrl: url,
          initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                builtInZoomControls: false,
                allowContentAccess: true,
                allowFileAccess: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                hardwareAcceleration: true,
                cacheMode: AndroidCacheMode.LOAD_DEFAULT,
                networkAvailable: true,
              ),
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                cacheEnabled: true,
                debuggingEnabled: true,
                mediaPlaybackRequiresUserGesture: true,
                javaScriptCanOpenWindowsAutomatically: true,
                useOnLoadResource: true,
              )),
          onWebViewCreated: (InAppWebViewController controller) {
            _controller.complete(controller);
          },
          onLoadStart: (context, url) async {},
          onLoadStop: (context, url) async {
            print(url);
            setState(() {
              isLoaded = true;
            });
          },
        ));
  }
}
