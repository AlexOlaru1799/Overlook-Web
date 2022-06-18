import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:text_to_speech/text_to_speech.dart';

TextToSpeech tts = TextToSpeech();

Widget _buildPopupDialog(BuildContext context, id_mess, id_room) {
  return AlertDialog(
    title: Text("Leave an emote to this message"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
    ),
    actions: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              onPressed: () {
                FirebaseApi.sendEmote(1, id_mess, id_room);
              },
              icon: Icon(
                Icons.emoji_emotions_outlined,
                size: 30,
                color: secondaryColor,
              )),
          IconButton(
              onPressed: () {
                FirebaseApi.sendEmote(2, id_mess, id_room);
              },
              icon: Icon(FontAwesomeIcons.heart,
                  size: 30, color: secondaryColor)),
          IconButton(
              onPressed: () {
                FirebaseApi.sendEmote(3, id_mess, id_room);
              },
              icon: Icon(
                Icons.heart_broken,
                size: 30,
                color: secondaryColor,
              )),
          IconButton(
              onPressed: () {
                FirebaseApi.sendEmote(4, id_mess, id_room);
              },
              icon: Icon(
                FontAwesomeIcons.question,
                size: 30,
                color: secondaryColor,
              )),
        ],
      ),
      SizedBox(
        height: 50,
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Or remove the emote"),
            IconButton(
                onPressed: () {
                  FirebaseApi.sendEmote(0, id_mess, id_room);
                },
                icon: Icon(Icons.remove_circle_outline, color: secondaryColor)),
          ],
        ),
      )
    ],
  );
}

class ChatBubble extends StatelessWidget {
  const ChatBubble(
      {Key? key,
      required this.text,
      required this.isCurrentUser,
      required this.emote,
      required this.id_mess,
      required this.id_room})
      : super(key: key);
  final String text;
  final bool isCurrentUser;
  final int emote;
  final String id_mess;
  final String id_room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // asymmetric padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Align(
        // align the child within the container
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          children: [
            emote == 0
                ? SizedBox()
                : emote == 1
                    ? Icon(
                        Icons.emoji_emotions_outlined,
                        color: secondaryColor,
                      )
                    : emote == 2
                        ? Icon(FontAwesomeIcons.heart, color: secondaryColor)
                        : emote == 3
                            ? Icon(
                                Icons.heart_broken,
                                color: secondaryColor,
                              )
                            : Icon(
                                FontAwesomeIcons.question,
                                color: secondaryColor,
                              ),
            DecoratedBox(
              // chat bubble decoration
              decoration: BoxDecoration(
                color: isCurrentUser ? mainColor : secondaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: GestureDetector(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: isCurrentUser ? Colors.white : Colors.white),
                  ),
                ),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) =>
                        _buildPopupDialog(context, id_mess, id_room),
                  );
                },
              ),
            ),
            IconButton(
                onPressed: () {
                  tts.speak(text);
                },
                iconSize: 15,
                icon: Icon(
                  FontAwesomeIcons.soundcloud,
                  color: Colors.red,
                ))
          ],
        ),
      ),
    );
  }
}
