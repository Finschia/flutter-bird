import 'package:flutter/material.dart';
import 'package:flutter_bird/controller/flutter_bird_controller.dart';
import 'package:flutter_bird/view/main_menu_view.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() {
  dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => FlutterBirdController()..init(),
      child: MaterialApp(
        title: 'Flutter Bird',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainMenuView(title: 'Flutter Bird'),
      ),
    );
  }
}
