import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter login UI',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(title: 'Flutter Login'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
        onPressed: launchURL,
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

launchURL() async {
  const url =
      'https://sso.university.innopolis.ru/adfs/oauth2/authorize/?client_id=c393d763-6d21-4f25-9e64-857b6822336c&response_type=code&redirect_uri=https%3A%2F%2Fmoodle.innopolis.university%2Fadmin%2Foauth2callback.php&state=%2Fauth%2Foauth2%2Flogin.php%3Fwantsurl%3Dhttps%253A%252F%252Fmoodle.innopolis.university%252F%26sesskey%3DWmSbiNbZe3%26id%3D1&scope=openid%20profile%20email%20allatclaims&response_mode=form_post';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
