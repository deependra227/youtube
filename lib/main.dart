import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum UniLinksType { string, uri }

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _latestLink = 'Unknown';
  Uri _latestUri;

  StreamSubscription _sub;

  UniLinksType _type = UniLinksType.string;

  @override
  initState() {
    super.initState();
    setState(() {
      isLoaded = false;
    });
    initPlatformState();
  }

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    } else {
      await initPlatformStateForUriUniLinks();
    }
  }

  /// An implementation using a [String] link
  initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _latestLink = link ?? 'Unknown';
        _latestUri = null;
        try {
          if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        _latestUri = null;
      });
    });

    // Attach a second listener to the stream
    getLinksStream().listen((String link) {
      print('got link: $link');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
      if (initialLink != null) initialUri = Uri.parse(initialLink);
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
      initialUri = null;
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
      initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestLink = initialLink;
      _latestUri = initialUri;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriUniLinks() async {
    // Attach a listener to the Uri links stream
    _sub = getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _latestUri = uri;
        _latestLink = uri?.toString() ?? 'Unknown';
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestUri = null;
        _latestLink = 'Failed to get latest link: $err.';
      });
    });

    // Attach a second listener to the stream
    getUriLinksStream().listen((Uri uri) {
      print('got uri: ${uri?.path} ${uri?.queryParametersAll}');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest Uri
    Uri initialUri;
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialUri = await getInitialUri();
      print('initial uri: ${initialUri?.path}'
          ' ${initialUri?.queryParametersAll}');
      initialLink = initialUri?.toString();
    } on PlatformException {
      initialUri = null;
      initialLink = 'Failed to get initial uri.';
    } on FormatException {
      initialUri = null;
      initialLink = 'Bad parse the initial link as Uri.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestUri = initialUri;
      _latestLink = initialLink;
    });
  }

  var url = "https://www.youtube.com/";
  bool isLoaded;
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
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
        ))
        // );

        );
  }

  backFunction(BuildContext context,
      AsyncSnapshot<InAppWebViewController> controller) async {
    if (await controller.data.canGoBack())
      controller.data.goBack();
    else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Do you really want to exit the app"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("No"),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  FlatButton(
                    child: Text("Yes"),
                    onPressed: () => exit(1),
                  ),
                ],
              ));
    }
  }

  InAppWebViewController webView;
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
            webView = controller;
            _controller.complete(controller);
          },
          onLoadStart: (context, url) async {
            print(_latestLink);
            if (_latestLink != null) webView.loadUrl(url: _latestLink);
            _latestLink = null;
          },
          onLoadStop: (context, url) async {
            print(url);

            setState(() {
              isLoaded = true;
            });
          },
        ));
  }
}
