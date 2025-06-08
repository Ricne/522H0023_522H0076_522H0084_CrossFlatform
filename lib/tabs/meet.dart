import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';
import 'package:final_project_flatform/tabs/join_meet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'drawer.dart';

class Meet extends StatefulWidget {
  const Meet({super.key});

  @override
  _MeetState createState() => _MeetState();
}

class _MeetState extends State<Meet> {
  CarouselController buttonCarouselController = CarouselController();
  int currentIndex = 0;
  List imgs = [
    'assets/meeting.png',
    'assets/conversation.png',
  ];

  List<T> customMap<T>(
      List list, T Function(int index, dynamic element) handler) {
    List<T> result = [];

    list.asMap().forEach((index, element) {
      result.add(handler(index, element));
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawers(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Meet',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: 15,
            ),
            Row(
              children: [
                SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(4),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 40,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.grey,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _showModalBottomSheet(context);
                    },
                    child: Text(
                      'New Meeting',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 2),
                    ),
                    //shape:
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                    child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Join()),
                    );
                    print("test pushed ok!");
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(0, 40),
                    side: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Join with a code',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                )),
                SizedBox(width: 15),
              ],
            ),
            carousel.CarouselSlider(
              items: [
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 100.0),
                      alignment: Alignment.center,
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/meeting.png'),
                          fit: BoxFit.fill,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 200,
                            child: Text(
                              "Get a link you can share",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 25.0),
                              textAlign: TextAlign.center,
                            )),
                        SizedBox(height: 8),
                        Container(
                          width: 250,
                          child: Text(
                            "Tap New meeting to get a link you can send to people you want to meet with",
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 15.0),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 100.0),
                      alignment: Alignment.center,
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/google_meet1.jpg'),
                          fit: BoxFit.fill,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 200,
                            child: Text(
                              "Your meeting is safe",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 25.0),
                              textAlign: TextAlign.center,
                            )),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                            width: 250,
                            child: Text(
                              "No one can join the meeting unless invited or admitted by the host",
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 15.0),
                              textAlign: TextAlign.center,
                            ))
                      ],
                    ),
                  ],
                ),
              ],
              options: carousel.CarouselOptions(
                height: 500,
                enableInfiniteScroll: false,
                autoPlayCurve: Curves.fastOutSlowIn,
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: customMap<Widget>(imgs, (index, url) {
                return Container(
                  width: 10.0,
                  height: 10.0,
                  margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        currentIndex == index ? Colors.redAccent : Colors.green,
                  ),
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return BottomSheetContent();
      },
    );
  }
}

// ignore: must_be_immutable
class BottomSheetContent extends StatelessWidget {
  //const BottomSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: Colors.transparent,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.link,
                              color: Colors.black,
                            ),
                            title: Text(
                              'Get a meeting link to share',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              showAlertDialog(context);
                            },
                          ),
                        ],
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.video_call,
                          color: Colors.black,
                        ),
                        title: Text(
                          'Start an instant meeting',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.black,
                        ),
                        title: Text(
                          'Schedule in Google Calendar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.close_rounded,
                          color: Colors.black,
                        ),
                        title: Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }

  String link = 'https://meet.google.com/zpu-dyqi-wkn';

  void showAlertDialog(BuildContext context) {
    Widget shareButton = (TextButton.icon(
      onPressed: () {
        _onShareData(context);
      },
      icon: const Icon(Icons.share),
      label: Text('Share'),
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.blue),
        ),
      ),
    ));

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 2),
            title: Text('Here is the link to your meeting'),
            content: Builder(
              builder: (context) {
                var width = MediaQuery.of(context).size.width;
                return Container(
                  height: 250,
                  width: width,
                  child: Column(
                    children: [
                      Text(
                          "Copy this link and send it to people you want to meet with. Be sure to save it so you can use it later, too.\n"),
                      Text(
                        link,
                        maxLines: 3,
                        style: TextStyle(
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          print("test pressed ok!");
                          Clipboard.setData(ClipboardData(text: link))
                              .then((result) {
                            final snackBar = SnackBar(
                              content: Text('Copied to Clipboard'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {},
                              ),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          });
                        },
                      ),
                      shareButton,
                    ],
                  ),
                );
              },
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15))),
          );
        });
    //show the dialog here
  }

  void _onShareData(BuildContext context) async {
    {
      await Share.share(link);
    }
  }
}
