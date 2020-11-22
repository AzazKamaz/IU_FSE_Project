import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:automated_attendance_app/providers/oauth.dart';
import 'package:flutter/rendering.dart';

import 'package:hasura/hasura.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/hasura.dart';
import '../utils.dart';

class ClassAttendance extends StatefulWidget {
  ClassAttendance({Key key, this.classId}) : super(key: key);

  final String classId;

  @override
  _ClassAttendance createState() => _ClassAttendance(classId);
}

class _ClassAttendance extends State<ClassAttendance> {
  final String classId;

  _ClassAttendance(this.classId) : super();

  Snapshot<dynamic> attendances;

  @override
  initState() {
    super.initState();

    attendances = HasuraModel.get(context).subscription("""
      subscription(\$class: uuid!) {
        class: classes_by_pk(id: \$class) {
          title
          starts_at
          ends_at
          attendances(order_by: {user: {name: asc}}) {
      			user {
              name
              email
            }
            first_seen_at
            last_seen_at
      			hits
          }
        }        
      }
    """, variables: {'class': classId});
  }

  @override
  Future<void> dispose() async {
    attendances?.close();
    super.dispose();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    attendances?.changeVariable({'class': classId});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: attendances?.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active ||
            !snapshot.hasData)
          return Material(
            child: CupertinoPageScaffold(
              child: ListView(
                shrinkWrap: true,
                controller: ModalScrollController.of(context),
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.all(16.0),
                children: [Center(child: CircularProgressIndicator())],
              ),
            ),
          );

        var attendances =
            snapshot.data["data"]["class"]["attendances"] as List<dynamic>;

        return Material(
            child: CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  leading: Container(),
                  middle: Text(snapshot.data["data"]["class"]["title"]),
                  trailing: IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => exportAttendance(snapshot.data["data"]["class"]),
                  ),
                ),
                child: SafeArea(
                    bottom: false,
                    child: ListView(
                      shrinkWrap: true,
                      controller: ModalScrollController.of(context),
                      physics: ClampingScrollPhysics(),
                      padding: EdgeInsets.all(16.0),
                      children: ListTile.divideTiles(
                        context: context,
                        tiles: attendances.map(this.listEntry),
                      ).toList(),
                    ))));
      },
    );
  }

  Widget listEntry(attendance) {
    DateTime firstSeen = DateTime.parse(attendance["first_seen_at"]);
    DateTime lastSeen = DateTime.parse(attendance["last_seen_at"]);
    int hits = attendance["hits"];

    return ListTile(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        children: [
          Text(
            attendance["user"]["name"],
            style: Theme.of(context).textTheme.headline6,
          )
        ],
      ),
      subtitle: Text(
          'Seen $hits times from ${formatTime(firstSeen)} to ${formatTime(lastSeen)}'),
      trailing: Text(
        '${lastSeen.difference(firstSeen).inMinutes}m',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}

Future<void> showClassAttendance(BuildContext context, String classId) async {
  showBarModalBottomSheet(
    backgroundColor: Colors.transparent,
    expand: false,
    context: context,
    builder: (context) => ClassAttendance(classId: classId),
  );
}
