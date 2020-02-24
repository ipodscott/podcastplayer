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
  void parse(String url) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }
}

final url = 'https://omny.fm/shows/rock-92/playlists/put-up-or-shut-up.rss';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Podcast()..parse(url),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Podast App',
        home: EpisodesPage(),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Consumer<Podcast>(builder: (context, podcast, _) {
          return podcast.feed != null
              ? EpisodeListView(rssFeed: podcast.feed)
              : Center(
                  child: CircularProgressIndicator(),
                );
        }),
      ),
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
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
                    Provider.of<Podcast>(context, listen: false).selectedItem =
                        i;
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlayerPage(),
                    ));
                  }),
            ),
          )
          .toList(),
    );
  }
}

class PlayerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('Put Up or Shut UP - 2 Guys Name Chris',
              style: TextStyle(
                fontSize: 14.0,
                color: Color(0xff999999),
              )),
          backgroundColor: Color(0xFF000000),
        ),
        body: Player(),
      ),
    );
  }
}

class Player extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context);
    return Column(
      children: <Widget>[
        Flexible(flex: 4, child: Image.network(podcast.feed.image.url)),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(child: Text(podcast.selectedItem.title)),
        ),
        Flexible(
          flex: 3,
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

  void _play(String url) async {
    await _sound.startPlayer(url);

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
    final item = Provider.of<Podcast>(context).selectedItem;
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Slider(
            value: _playPosition,
            onChanged: null,
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
                    _play(item.enclosure.url);
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
