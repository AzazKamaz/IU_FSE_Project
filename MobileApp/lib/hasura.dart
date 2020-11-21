import 'package:hasura_connect/hasura_connect.dart';

const String hasuraUrl = 'http://84.201.168.8:8080/v1/graphql';
HasuraConnect hasura = new HasuraConnect(hasuraUrl);

void hasuraUseAuthorization(String token) {
  hasura = new HasuraConnect(hasuraUrl, headers: {
    'Authorization': token
  });
}