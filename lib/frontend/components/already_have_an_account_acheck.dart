import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlook/utils/constants.dart';

class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login;
  final Function press;
  const AlreadyHaveAnAccountCheck({
    Key? key,
    this.login = true,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          login ? "Don’t have an Account ? " : "Already have an Account ? ",
          style: GoogleFonts.openSans(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            press();
          },
          child: Text(login ? "Sign Up" : "Sign In",
              style: GoogleFonts.openSans(
                color: mainColor,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              )),
        )
      ],
    );
  }
}
