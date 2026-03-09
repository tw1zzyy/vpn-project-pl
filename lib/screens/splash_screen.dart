import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';

import '../main.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 2500), () {
      //exit full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      //navigate to home
      Get.off(() => HomeScreen());
      // Navigator.pushReplacement(
      //     context, MaterialPageRoute(builder: (_) => HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          //app logo
          Positioned(
            left: mq.width * .3,
            top: mq.height * .2,
            width: mq.width * .4,
            child: Image.asset('assets/images/logo.png'),
          ),

          //label
          Positioned(
            bottom: mq.height * .15,
            width: mq.width,
            child: Text(
              'Welcome to my VPN.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
