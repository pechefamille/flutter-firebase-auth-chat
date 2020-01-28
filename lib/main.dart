import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<FirebaseUser> _handleSignIn() async {
    GoogleSignInAccount googleCurrentUser = _googleSignIn.currentUser;
    try {
      if (googleCurrentUser == null) googleCurrentUser = await _googleSignIn.signInSilently();
      if (googleCurrentUser == null) googleCurrentUser = await _googleSignIn.signIn();
      if (googleCurrentUser == null) return null;

      GoogleSignInAuthentication googleAuth = await googleCurrentUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
      print("signed in " + user.displayName);

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void transitionNextPage(FirebaseUser user) {
    if (user == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) =>
        NextPage(userData: user)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text('Sign in Google'),
                onPressed: () {
                  _handleSignIn()
                      .then((FirebaseUser user) =>
                      transitionNextPage(user)
                  )
                      .catchError((e) => print(e));
                },
              ),
            ]
        ),
      ),
    );
  }
}

class NextPage extends StatefulWidget {
  FirebaseUser userData;

  NextPage({Key key, this.userData}) : super(key: key);

  @override
  _NextPageState createState() => _NextPageState(userData);
}

class _NextPageState extends State<NextPage> {
  FirebaseUser userData;
  String name = "";
  String email;
  String photoUrl;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  _NextPageState(FirebaseUser userData) {
    this.userData = userData;
    this.name = userData.displayName;
    this.email = userData.email;
    this.photoUrl = userData.photoUrl;
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print(e);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("chat Test Screen"),
        ),
        body: chat()
    );
  }

  Widget chat() {
    final textController = new TextEditingController();

    Future<void> addMessage(String text) {
      return Firestore.instance.collection("chat").add({
        "message": text
      });
    }

    return Stack(
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('chat').snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError)
                return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return new Text('Loading...');
                default:
                  return new ListView(
                    padding: EdgeInsets.only(bottom: 80.0),
                    children: snapshot.data.documents.map((
                        DocumentSnapshot document) {
                      return Text(document["message"]);
                    }).toList(),
                  );
              }
            },
          ),
          Positioned(
            height: 80.0,
            left: 0.0,
            right: 0.0,
            bottom: .0,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.white
                ),
                padding: EdgeInsets.only(
                    top: 10.0, bottom: 20.0, left: 20.0, right: 20.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: textController,
                      ),
                    ),
                    Expanded(
                      child: FlatButton(
                        padding: EdgeInsets.all(10.0),
                        color: Colors.blue,
                        onPressed: () {
                          addMessage(textController.text);
                          textController.text = '';
                        },
                        child: Text('送信'),
                      ),
                    ),
                  ],
                )
            ),
          ),
        ]
    );
  }
}