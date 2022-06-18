import 'package:flutter/material.dart';
import 'package:overlook/utils/constants.dart';

class NumbersWidget extends StatelessWidget {
  @override
  int? followers;
  int? following;
  NumbersWidget(int followers, int following) {
    this.followers = followers;
    this.following = following;
  }

  void updateNumbersFollowers(int followers) {
    this.followers = followers;
  }

  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          buildButton(context, this.following.toString(), 'Following'),
          buildDivider(),
          buildButton(context, this.followers.toString(), 'Followers'),
        ],
      );
  Widget buildDivider() => Container(
        height: 24,
        child: VerticalDivider(),
      );

  Widget buildButton(BuildContext context, String value, String text) =>
      MaterialButton(
        padding: EdgeInsets.symmetric(vertical: 4),
        onPressed: () {},
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            changedColors
                ? Stack(
                    children: <Widget>[
                      // Stroked text as border.
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = secondaryColor,
                        ),
                      ),
                      // Solid text as fill.
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: mainColor,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: <Widget>[
                      // Stroked text as border.
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = secondaryColor,
                        ),
                      ),
                      // Solid text as fill.
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 2),
            Stack(
              children: <Widget>[
                // Stroked text as border.
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = secondaryColor,
                  ),
                ),
                // Solid text as fill.
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: mainColor,
                  ),
                ),
              ],
            ),
            // Text(
            //   text,
            //   style: TextStyle(fontSize: 15, color: Colors.white),
            // ),
          ],
        ),
      );
}
