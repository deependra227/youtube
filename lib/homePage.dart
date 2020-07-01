import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_android_pip/flutter_android_pip.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:youtube_foreground/videoPlayer.dart';

class HomePage extends StatefulWidget {
  final String latestLink;
  HomePage({Key key, this.latestLink}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState(latestLink);
}

enum UniLinksType { string, uri }

class _HomePageState extends State<HomePage> {
  String latestLink;
  _HomePageState(this.latestLink);

  String _latestLink = 'Unknown';
  // Uri _latestUri;
  List videosList = List();
  var isfetching = false;
  StreamSubscription _sub;

  UniLinksType _type = UniLinksType.string;

  @override
  dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  _fetchUrl(String _url) async {
    setState(() {
      isfetching = true;
    });
    _url = _url.split('?')[1];
    print(_url);
    var response = await http.post("https://y2mate.guru/api/convert", body: {"url": "https://youtube.com/watch?" + _url});
    // print(response.body);
    if (response.statusCode == 200) {
      List responsejson = json.decode(response.body)['url'] as List;
      print(responsejson.length);
      setState(() {
        isfetching = false;
      });
      return responsejson;
    } else {
      throw Exception('Failed to fetch');
    }
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
        // _latestUri = null;
        try {
          // if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        // _latestUri = null;
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
    // Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
      // if (initialLink != null) initialUri = Uri.parse(initialLink);
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
      // initialUri = null;
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
      // initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestLink = initialLink;
    });
  }

  /// An implementation using the [Uri] convenience helpers
  initPlatformStateForUriUniLinks() async {
    // Attach a listener to the Uri links stream
    _sub = getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      setState(() {
        _latestLink = uri?.toString() ?? 'Unknown';
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        // _latestUri = null;
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
      // _latestUri = initialUri;
      _latestLink = initialLink;
    });
  }

  @override
  initState() {
    super.initState();
    setState(() {
      isLoaded = false;
    });
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
      children: <Widget>[
        FutureBuilder<InAppWebViewController>(
          future: _controller.future,
          builder: (BuildContext context, AsyncSnapshot<InAppWebViewController> controller) {
            return _webViewPage(context, controller);
          },
        ),
        (isLoaded == false)
            ? Scaffold(
                backgroundColor: Color.fromRGBO(40, 40, 40, 1),
                body: Center(
                    child: Image.asset(
                  'assets/logo.png',
                  scale: 2,
                )))
            : Container(),
      ],
    ));
  }

  var url = "https://m.youtube.com/?persist_app=1&app=m";
  bool isLoaded;
  final Completer<InAppWebViewController> _controller = Completer<InAppWebViewController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  backFunction(BuildContext context, AsyncSnapshot<InAppWebViewController> controller) async {
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
  bool youtubeBar = true;
  _webViewPage(BuildContext context, AsyncSnapshot<InAppWebViewController> controller) {
    return WillPopScope(
        onWillPop: () => backFunction(context, controller),
        child: Scaffold(
          key: _scaffoldKey,
          bottomNavigationBar: (MediaQuery.of(context).size.height > 300)
              ? BottomAppBar(
                  shape: CircularNotchedRectangle(),
                  elevation: 5.0,
                  color: Color.fromRGBO(16, 16, 16, 1),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, 0, 30, 0),
                    child: new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            webView.loadUrl(url: url);
                          },
                          icon: Icon(Icons.home),
                        ),
                        IconButton(
                            icon: Icon(Icons.file_download),
                            onPressed: () async {
                              var _url = await webView.getUrl();
                              print(_url);
                              videosList = await _fetchUrl(_url);
                              webView.loadUrl(url: videosList[0]['url']);
                              print(videosList);
                              //
                            }),
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Videos()));
                          },
                          icon: Icon(Icons.video_library),
                        ),
                        IconButton(
                          onPressed: () {
                            FlutterAndroidPip.enterPictureInPictureMode;
                            webView.evaluateJavascript(source: " document.getElementsByTagName('ytm-mobile-topbar-renderer')[0].style.display = 'none' ");
                            webView.evaluateJavascript(source: " document.documentElement.scrollTop = 0;");
                            webView.evaluateJavascript(source: " window.scrollBy(0, 50); ");
                            webView.evaluateJavascript(source: " document.getElementsByTagName('ytm-pivot-bar-renderer')[0].style.display = 'none' ");
                            youtubeBar = false;
                          },
                          icon: Icon(Icons.picture_in_picture_alt),
                        ),
                        IconButton(
                          onPressed: () {
                            if (youtubeBar) {
                              webView.evaluateJavascript(source: " document.getElementsByTagName('ytm-pivot-bar-renderer')[0].style.display = 'none' ");
                              setState(() {
                                youtubeBar = false;
                              });
                            } else {
                              webView.evaluateJavascript(source: " document.getElementsByTagName('ytm-pivot-bar-renderer')[0].style.display = '' ");
                              setState(() {
                                youtubeBar = true;
                              });
                            }
                          },
                          icon: youtubeBar ? Icon(Icons.arrow_drop_down) : Icon(Icons.arrow_drop_up),
                        )
                      ],
                    ),
                  ),
                )
              : BottomAppBar(),
          body: InAppWebView(
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
                  useOnDownloadStart: true,
                )),
            onWebViewCreated: (InAppWebViewController controller) {
              webView = controller;
              _controller.complete(controller);
            },
            onLoadStart: (context, url) async {
              print(_latestLink);
              print('aaaa');
              if (_latestLink != null) webView.loadUrl(url: _latestLink);
              _latestLink = null;
            },
            onLoadStop: (context, url) async {
              print(url);
              setState(() {
                isLoaded = true;
              });
            },
            onScrollChanged: (controller, int x, int y) {
              print('X: $x');
              print('Y: $y');
              if (y == 0) {
                webView.evaluateJavascript(source: " document.getElementsByTagName('ytm-mobile-topbar-renderer')[0].style.display = '' ");

                youtubeBar = true;
              }
            },
            onDownloadStart: (InAppWebViewController controller, String url) async {
              print("onDownloadStart");
              var path = (await getExternalStorageDirectory()).path;
              Uri uri = Uri.dataFromString(url);
              print(await Directory(path).listSync().toList());
              List dirFile = await Directory(path).list().toList();
              for (int i = 0; i < dirFile.length; i++) {
                if (dirFile[i].toString().substring(0, dirFile[i].toString().length - 1).split('files/')[1] == uri.queryParameters['title']) {
                  final snackBar = SnackBar(
                    backgroundColor: Color.fromRGBO(16, 16, 16, 1),
                    content: Text(
                      'You already downloaded it',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                  _scaffoldKey.currentState.showSnackBar(snackBar);
                  return;
                }
              }
              final taskId = await FlutterDownloader.enqueue(
                fileName: uri.queryParameters['title'],
                url: url,
                savedDir: path,
                // showNotification: true, // show download progress in status bar (for Android)
                // openFileFromNotification: true, // click on notification to open downloaded file (for Android)
              );
              
              final snackBar = SnackBar(
                    backgroundColor: Color.fromRGBO(16, 16, 16, 1),
                    content: Text(
                      'Download Compeleted',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                  _scaffoldKey.currentState.showSnackBar(snackBar);
              // // FlutterDownloader.open(taskId: taskId);
            },
          ),
        ));
  }
}
