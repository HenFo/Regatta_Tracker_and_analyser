import 'package:flutter/material.dart';
import '../helperClasses.dart';
import "../regattaDatabase.dart";


class MainList extends StatefulWidget {
  final List<Regatta> listItems;
  final Function editRegatta;
  final Function playRegatta;

  MainList(this.listItems, this.editRegatta, this.playRegatta);

  @override
  _MainListState createState() => _MainListState();
}

class _MainListState extends State<MainList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: this.widget.listItems.length,
        itemBuilder: (context, index) {
          var regatta = this.widget.listItems[index];
          return Card(
            child: Row(
              children: <Widget>[
                Expanded(
                    child: ListTile(
                  title: Text(regatta.name),
                  subtitle: Text(regatta.location),
                )),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    widget.editRegatta(index);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () {
                    widget.playRegatta(index);
                  },
                ),
              ],
            ),
          );
        });
  }
}
