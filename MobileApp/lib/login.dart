import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'oauth.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final welcomeText = Material(
        child: Text(
      "Welcome to Attendance App",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 20)
          .copyWith(color: Colors.green, fontWeight: FontWeight.bold),
    ));
    final loginWithIUButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.green,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: () => Provider.of<OauthModel>(context).login(),
        child: Text("Login with Innopolis University",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20)
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );

    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 35.0,
                ),
                welcomeText,
                SizedBox(
                  height: 25.0,
                ),
                loginWithIUButton
              ],
            ),
          ),
        ),
      ),
    );
  }
}
