import 'dart:convert';

dynamic jwtDecode(String jwt) {
  if (jwt == null) return null;

  final parts = jwt.split(r'.');

  if (parts.length != 3) return null;

  return jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  );
}