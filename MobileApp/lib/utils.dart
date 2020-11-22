import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

dynamic jwtDecode(String jwt) {
  if (jwt == null) return null;

  final parts = jwt.split(r'.');

  if (parts.length != 3) return null;

  return jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  );
}

String formatDateTime(DateTime dt) {
  return new DateFormat('HH:mm dd.MM.yy').format(dt);
}

String formatTime(DateTime dt) {
  return new DateFormat('HH:mm').format(dt);
}

Future<void> exportAttendance(dynamic data) async {
  String str = [
    ['Name', 'Email', 'First Seen', 'Last Seen', 'Hits'],
    ...data['attendances'].map(
      (i) => [
        i['user']['name'],
        i['user']['email'],
        formatTime(DateTime.parse(i['first_seen_at'])),
        formatTime(DateTime.parse(i['last_seen_at'])),
        i['hits'],
      ],
    ),
  ].map((i) => i.join('\t')).join('\n');

  final directory = (await getTemporaryDirectory()).path;
  final filename = '$directory/${data['title']}.csv';
  await new File(filename).writeAsString(str);
  await Share.shareFiles([filename],
      subject: 'Attendance export: ${data['title']}'
          ', ${formatTime(DateTime.parse(data['starts_at']))}'
          ' to ${formatDateTime(DateTime.parse(data['ends_at']))}');
}
