import 'package:flutter/material.dart';

class Label {
  String? id;
  String? name;
  Label({this.id, this.name});
}

class LabelManager extends StatefulWidget {
  const LabelManager({super.key});

  @override
  State<LabelManager> createState() => _LabelManagerState();
}

class _LabelManagerState extends State<LabelManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  body: _children[current_Index],
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.red,
        // onTap: () {},
        // currentIndex: current_Index,
        items: [
          new BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0),
              child: new Stack(
                children: <Widget>[
                  new Icon(
                    Icons.mail,
                    size: 35,
                  ),
                  new Positioned(
                    right: 0,
                    top: 0.0,
                    child: new Container(
                      padding: EdgeInsets.all(1),
                      decoration: new BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: new Text(
                        '9+',
                        style: new TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ],
              ),
            ),
            label: 'Mail',
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.video_call, size: 35.0),
            label: 'Meet',
          )
        ],
      ),
    );
  }
}
