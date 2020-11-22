import 'package:flutter/widgets.dart';
// import 'package:hasura_connect/hasura_connect.dart';
import 'package:hasura/hasura.dart';
import 'package:hasura/src/services/local_storage_in_memory.dart';
import 'package:provider/provider.dart';

const String _HASURA_URL = 'http://84.201.168.8:8080/v1/graphql';

class HasuraModel extends ChangeNotifier {
  final HasuraConnect hasura =
      new HasuraConnect(_HASURA_URL, headers: {'Authorization': 'None'},
      localStorageDelegate: () => LocalStorageInMemory());

  @override
  Future<void> dispose() async {
    await hasura.disconnect();
    super.dispose();
  }

  void setToken(String token) {
    // hasura.headers.addAll({'Authorization': 'Bearer $token'});
    hasura.addHeader('Authorization', 'Bearer $token');
  }

  static HasuraConnect get(BuildContext context) =>
      Provider.of<HasuraModel>(context, listen: false).hasura;
}
