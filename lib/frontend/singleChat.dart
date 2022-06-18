// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, unnecessary_new, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlook/frontend/components/chatBubble.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

String? message;
String? roomUID;
final ScrollController _controller = ScrollController();

class singleChat extends StatefulWidget {
  String? guestUID;
  String? guestUsername;
  singleChat(String guestUID, String guestUsername, String roomUID2) {
    this.guestUID = guestUID;
    this.guestUsername = guestUsername;
    roomUID = roomUID2;
  }

  @override
  _singleChatState createState() => _singleChatState();
}

class _singleChatState extends State<singleChat> {
  SpeechToText speech = SpeechToText();
  bool _hasSpeech = false;
  bool _logEvents = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];

  Future<void> waitForRoomUID() async {
    await Future.delayed(const Duration(milliseconds: 100), () {});

    roomUID = await FirebaseApi.getRoomUID(widget.guestUID!);
    print("DONE");
  }

  final messageControler = TextEditingController();

  @override
  void initState() {
    Timer(Duration(milliseconds: 500), () {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
    super.initState();
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      print('$eventTime $eventDescription');
    }
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    final pauseFor = 3;
    final listenFor = 30;
    // Note that `listenFor` is the maximum, not the minimun, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: listenFor ?? 30),
        pauseFor: Duration(seconds: pauseFor ?? 3),
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = '${result.recognizedWords}';
      messageControler.text = lastWords;
      message = lastWords;
      print("=-= " + lastWords);
    });
  }

  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: secondaryColor,
      body: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 1.3,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("rooms")
                        .doc(roomUID)
                        .collection("messages")
                        .orderBy("createdAT", descending: false)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError)
                        return new Text('Error: ${snapshot.error}');
                      else {
                        return ListView.builder(
                          controller: _controller,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot document =
                                snapshot.data!.docs[index];

                            bool realUserBool = false;

                            if (document["authorID"] ==
                                FirebaseApi.realUserUID) {
                              realUserBool = true;
                            }

                            if (document["text"] != "TEST MESS") {
                              return ListTile(
                                  title: ChatBubble(
                                isCurrentUser: realUserBool,
                                text: document["text"],
                                emote: document["emote"],
                                id_mess: document.id,
                                id_room: roomUID!,
                              ));
                            } else {
                              return SizedBox();
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Transform.translate(
        // TO MODIFY!
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: BottomAppBar(
          child: Container(
            height: 60,
            color: secondaryColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    padding: EdgeInsets.fromLTRB(1.0, 2.0, 3.0, 4.0),
                    width: MediaQuery.of(context).size.width / 3,
                    height: 50,
                    child: TextField(
                        controller: messageControler,
                        style: TextStyle(color: mainColor),
                        decoration: InputDecoration(
                          filled: true,
                          hintText: "message...",
                          hintStyle: GoogleFonts.lobster(
                            color: mainColor,
                            fontSize: 17,
                          ),
                          fillColor: secondaryColor,
                        ),
                        onChanged: ((value) {
                          message = value;
                        }))),
                InitSpeechWidget(_hasSpeech, initSpeechState),
                SpeechControlWidget(_hasSpeech, speech.isListening,
                    startListening, stopListening, cancelListening),
                Container(
                  width: MediaQuery.of(context).size.width / 10,
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                    ),
                    iconSize: 30,
                    color: mainColor,
                    onPressed: () async {
                      await FirebaseApi.sendMessage(message!, widget.guestUID!);
                      messageControler.clear();
                      Timer(Duration(milliseconds: 500), () {
                        _controller
                            .jumpTo(_controller.position.maxScrollExtent);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed:
      //       // If not yet listening for speech start, otherwise stop
      //       _speechToText.isNotListening ? _startListening : _stopListening,
      //   tooltip: 'Listen',
      //   child: Icon(
      //     _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
      //     color: mainColor,
      //   ),
      // ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: Text('Initialize Message Recorder'),
        ),
      ],
    );
  }
}

class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(this.hasSpeech, this.isListening,
      this.startListening, this.stopListening, this.cancelListening,
      {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        IconButton(
          onPressed: !hasSpeech || isListening ? null : startListening,
          icon: Icon(
            Icons.mic,
            color: mainColor,
          ),
        ),
        TextButton(
          onPressed: isListening ? stopListening : null,
          child: Text(
            'Stop',
            style: TextStyle(color: mainColor),
          ),
        ),
      ],
    );
  }
}
