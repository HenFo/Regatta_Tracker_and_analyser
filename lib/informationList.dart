import 'package:flutter/material.dart';
import 'helperClasses.dart';
import "regattaDatabase.dart";


class InformationList extends StatefulWidget {
  final List<RegattaInformation> listItems;

  InformationList(this.listItems);

  @override
  _InformationListState createState() => _InformationListState();
}

class _InformationListState extends State<InformationList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: this.widget.listItems.length,
        itemBuilder: (context, index) {
          var info = this.widget.listItems[index];
          return Card(
            child: Row(
              children: <Widget>[
                Expanded(
                    child: ListTile(
                  title: Text(info.title),
                  subtitle: Text(info.subtitle),
                )),
                Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Text(info.information))
              ],
            ),
          );
        });
  }
}
