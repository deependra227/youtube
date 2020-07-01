import 'dart:io';

import 'package:youtube_foreground/homePage.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_android_pip/flutter_android_pip.dart';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class Videos extends StatefulWidget {
  final prevUrl;

  const Videos({Key key, this.prevUrl}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideosState(prevUrl);
  }
}

class _VideosState extends State<Videos> {
  final prevUrl;
  _VideosState(this.prevUrl);

  TargetPlatform platform;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  int selectedIndex;
  bool isPlaying = false, isEndPlaying = false;
  List<Color> listItemColor = new List<Color>();

  @override
  void initState() {
    super.initState();
    _listofFiles();
    videoPlayed = false;
    videoPlayerController = VideoPlayerController.network('');
    selectedIndex = 0;
    videoPlayerController.addListener(_videoListener);
    chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        aspectRatio: aspectRatio,
        autoPlay: true,
        looping: false,
        );
  }

  bool videoPlayed;
  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  String directory;
  List file = new List();
  void _listofFiles() async {
    directory = (await getExternalStorageDirectory()).path;
    setState(() {
      file = Directory("$directory/").listSync(); //use your folder name insted of resume.
    });
  }

  VideoPlayerController _videoPlayerController;
  double aspectRatio = 16 / 9;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.of(context).size.height > 500 ? 50 : 0,
          leading: IconButton(
            icon: Image.asset('assets/logo.png'),
            onPressed: () {
              print(prevUrl);
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage(
                            latestLink: prevUrl,
                          )));
            },
          ),
          title: Text('Downloads'),
          actions: [
            IconButton(
                icon: Icon(Icons.picture_in_picture_alt),
                onPressed: () async {
                  FlutterAndroidPip.enterPictureInPictureMode;
                  setState(() {
                    aspectRatio = _videoPlayerController.value.aspectRatio * 5;
                  });
                }),
          ],
        ),
        body: Container(
          child: Column(
            children: <Widget>[
              videoPlayed ? AspectRatio(aspectRatio: aspectRatio, child: _playView()) : Container(),
              Expanded(
                child: _listView(file),
              )
            ],
          ),
        ),
      ),
    );
  }
GlobalKey _refresh = GlobalKey();
  // list area
  Widget _listView(List file) {
    return Material(
        child: file.length != 0
            ? RefreshIndicator(
              key: _refresh,
              onRefresh: ()async { _listofFiles();},
                          child: ListView.builder(
                shrinkWrap: true,
                  
                  itemCount: file.length,
                  itemBuilder: (BuildContext context, int i) {
                    print(file);
                    String name = file[i].toString().substring(0, file[i].toString().length - 1).split('files/')[1];
                    return _tile(name, " ", Icons.theaters, name);
                  }),
            )
            : Center(
                child: Center(child: Text("No Downloaded Videos..."),),
              )
        );
  }

  Container _tile(String _title, String _subtitle, IconData _icon, String _path) => Container(
        child: Card(
          child: ListTile(
            title: Text(
              _title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            subtitle: Text(_subtitle),
            leading: Icon(
              _icon,
              color: Colors.red,
            ),
            onLongPress: () => {
             showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text("Do you really want to delete the video"),
                actions: <Widget>[
                  FlatButton(
                    child: Text("No"),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  FlatButton(
                    child: Text("Yes"),
                    onPressed: () async{
                      // _listofFiles();
                      // _refresh.currentState.build(context);
                     await Directory('/storage/emulated/0/Android/data/com.example.youtube_foreground/files/' + _path.toString()).delete(recursive: true);
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Videos()));
                    },
                  ),
                ],
              ))
            },
            onTap: () => _onTappedTile(_path),
          ),
        ),
      );

  // play view area
  Widget _playView() {
    chewieController.play();
    return Chewie(controller: chewieController);
  }

  void _onTappedTile(String _path) async {
    videoPlayerController.pause();

    isPlaying = true;
    isEndPlaying = false;
    print((await getExternalStorageDirectory()).path + _path);
    videoPlayerController = VideoPlayerController.file(File('/storage/emulated/0/Android/data/com.example.youtube_foreground/files/' + _path));
    setState(() {
      chewieController.dispose();
      videoPlayerController.pause();
      videoPlayerController.seekTo(Duration(seconds: 0));
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        
        allowFullScreen: true,
        aspectRatio: aspectRatio,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: true,
      );
      videoPlayed = true;
    });
  }

  void _videoListener() {
    if (videoPlayerController.value.position == videoPlayerController.value.duration) {
      print('video ended');
      isEndPlaying = true;
      isPlaying = false;
    if(!mounted)

      setState(() {
        listItemColor[selectedIndex] = Colors.grey;
      });
    }
  }
}
