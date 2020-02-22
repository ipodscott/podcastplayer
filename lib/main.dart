import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selectedItem;

  RssFeed get feed => _feed;
  void parse(String xmlStr) {
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }
}

final _putUpURL =
    'https://omny.fm/shows/rock-92/playlists/put-up-or-shut-up.rss';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Podast App',
      home: EpisodesPage(),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder(
            future: http.get(_putUpURL),
            builder: (context, AsyncSnapshot<http.Response> snapshot) {
              if (snapshot.hasData) {
                final response = snapshot.data;
                if (response.statusCode == 200) {
                  final rssString = response.body;
                  var rssFeed = RssFeed.parse(rssString);
                  return EpisodeListName(rssFeed: rssFeed);
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            }),
      ),
    );
  }
}

class EpisodeListName extends StatelessWidget {
  const EpisodeListName({
    Key key,
    @required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items
          .map(
            (i) => Card(
              child: ListTile(
                  title: Text(i.title),
                  subtitle: Text(i.pubDate),
                  leading: Icon(Icons.play_circle_outline),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlayerPage(item: i),
                    ));
                  }),
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  PlayerPage({this.item});
  final RssItem item;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.title),
        ),
        body: Player(),
      ),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Placeholder(),
        ),
        Expanded(
          flex: 2,
          child: AudioControls(),
        ),
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (PlaybackButton());
  }
}

class PlaybackButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [PlaybackButton()]);
  }
}

class PlaybackButton extends StatefulWidget {
  @override
  _PlayBackButtonState createState() => _PlayBackButtonState();
}

class _PlayBackButtonState extends State<PlaybackButton> {
  bool _isPlaying = false;
  FlutterSound _sound;
  final _url = 'https://staging.hazzardlabs.com/streams/edge_of_water.mp3';
  double _playPosition;
  Stream<PlayStatus> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _sound = FlutterSound();
    _playPosition = 0;
  }

  void _stop() async {
    await _sound.pausePlayer();
    setState(() => _isPlaying = false);
  }

  void _play() async {
    await _sound.startPlayer(_url);

    _playerSubscription = _sound.onPlayerStateChanged
      ..listen((e) {
        if (e != null) {
          //print(e.currentPosition);
          setState(() => _playPosition = (e.currentPosition / e.duration));
          //_playPosition = e.currentPosition;
        }
      });
    setState(() => _isPlaying = true);
  }

  void _fastForward() {}

  void _rewind() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Slider(
            value: _playPosition,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: IconButton(
                    icon: Icon(Icons.fast_rewind), onPressed: _rewind),
              ),
              IconButton(
                icon: _isPlaying
                    ? Icon(Icons.pause_circle_outline)
                    : Icon(Icons.play_circle_outline),
                onPressed: () {
                  if (_isPlaying) {
                    _stop();
                  } else {
                    _play();
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 1, 0),
                child: IconButton(
                    icon: Icon(Icons.fast_forward), onPressed: _fastForward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
