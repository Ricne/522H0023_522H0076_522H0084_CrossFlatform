import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';

class Join extends StatefulWidget {
  const Join({super.key});

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<Join> {
  bool clicked = false;
  String text = '';

  late TextEditingController _controller;

  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Join with a code',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                  child: Container(
                    width: 50,
                    height: 25,
                    child: Text(
                      'Dat ne',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  onTap: () {
                    clicked = true;
                    showAlertDialog(context);
                  }),
            )
          ],
        ),
      ),
    );
  }

  void showAlertDialog(BuildContext context) {
    Widget isButton = TextButton(
      child: Text('Dismiss'),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      content: Text("No such meeting"),
      actions: [
        isButton,
      ],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
