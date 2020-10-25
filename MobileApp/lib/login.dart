import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'oauth.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login into attendance tracker'),
      ),
      body: Center(
        child: MaterialButton(
          child: const Text('Log In'),
          onPressed: () => Provider.of<OauthModel>(context).login(),
        ),
      ),
    );
  }
}
