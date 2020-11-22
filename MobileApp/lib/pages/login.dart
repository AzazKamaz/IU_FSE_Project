import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/oauth.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool busy = Provider.of<OauthModel>(context).busy;

    final welcomeText = Text(
      "Welcome to Attendance App",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 20)
          .copyWith(color: Colors.green, fontWeight: FontWeight.bold),
    );

    final loginButtonContent = AnimatedCrossFade(
      firstChild: Text(
        "Login with Innopolis University",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20)
            .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      secondChild: Padding(
        padding: const EdgeInsets.all(2.0),
        child: SizedBox(
          height: 36,
          width: 36,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 4.0,
            ),
          ),
        ),
      ),
      crossFadeState:
          busy ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );

    final loginButton = Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(30.0),
      color: Colors.green,
      child: MaterialButton(
        minWidth: MediaQuery.of(context).size.width,
        padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        onPressed: busy ? null : () => Provider.of<OauthModel>(context).login(),
        child: loginButtonContent,
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
                const SizedBox(height: 35.0),
                welcomeText,
                const SizedBox(height: 25.0),
                loginButton
              ],
            ),
          ),
        ),
      ),
    );
  }
}
