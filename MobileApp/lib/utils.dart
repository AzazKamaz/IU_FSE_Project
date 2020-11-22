import 'dart:convert';
import 'package:intl/intl.dart';

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