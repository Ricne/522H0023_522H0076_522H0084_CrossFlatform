import 'package:flutter/material.dart';

class LabelManager extends StatefulWidget {
  @override
  _LabelManagerState createState() => _LabelManagerState();
}

class _LabelManagerState extends State<LabelManager> {
  List<Label> labels = [];
  final TextEditingController _newLabelNameController = TextEditingController();
  Label? _selectedLabel; // Thêm biến để lưu trữ label cha đã chọn

  void _createNewLabel() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('New label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newLabelNameController,
                decoration: InputDecoration(
                  hintText: 'Please enter a new label name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Tạo label mới và gắn vào label cha nếu có
                setState(() {
                  if (_selectedLabel != null) {
                    _selectedLabel!.subLabels.add(
                      Label(name: _newLabelNameController.text),
                    );
                  } else {
                    // Nếu không có label cha, tạo label mới ở cấp cao nhất
                    labels.add(Label(name: _newLabelNameController.text));
                  }
                });
                _newLabelNameController.clear();
                Navigator.of(context).pop();
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labels'),
      ),
      body: ListView.builder(
        itemCount: labels.length,
        itemBuilder: (ctx, index) {
          return ListTile(
            title: Text(labels[index].name),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _selectedLabel = labels[index]; // Chọn label làm cha
                });
                _createNewLabel(); // Mở dialog tạo label con
              },
            ),
            onTap: () {
              // Hiển thị sub-labels khi nhấn vào một label cha
              showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text('Sub-labels of ${labels[index].name}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: labels[index]
                          .subLabels
                          .map((subLabel) => Text(subLabel.name))
                          .toList(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewLabel,
        child: Icon(Icons.add),
      ),
    );
  }
}

class Label {
  String name;
  List<Label> subLabels;

  Label({required this.name, this.subLabels = const []});
}
