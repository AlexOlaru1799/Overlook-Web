// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:overlook/frontend/components/chatBubble.dart';
import 'package:overlook/frontend/singleChat.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

String searchChat = "";
var messageControler = TextEditingController();

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

String? _otherUID;
String? _otherUsername;
String? _docUID;
String? message;

bool clickedChat = false;

class _MessagesPageState extends State<MessagesPage> {
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
    ScrollController _controller = ScrollController();

    return Scaffold(
      body: Container(
        color: secondaryColor,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Row(children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width / 2,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  child: Row(children: [
                    Flexible(
                      child: TextFormField(
                        style: TextStyle(color: thirdColor),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: thirdColor),
                          labelText: 'Search chat...',
                          focusColor: mainColor,
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: thirdColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: mainColor),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchChat = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search_rounded),
                      color: mainColor,
                    ),
                  ]),
                ),
              ),
              Flexible(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("rooms")
                      .orderBy("lastMessage", descending: true)
                      .where("UserUIDs", arrayContains: FirebaseApi.realUserUID)
                      .snapshots(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.hasError)
                      return new Text('Error: ${snapshot.error}');
                    else {
                      return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: ((context, index) {
                            DocumentSnapshot document =
                                snapshot.data!.docs[index];
                            String docUID = document.reference.id;
                            String? otherUID;
                            if (FirebaseApi.realUserUID ==
                                document["UserUIDs"][0]) {
                              otherUID = document["UserUIDs"][1];
                            } else {
                              otherUID = document["UserUIDs"][0];
                            }

                            //return Text(document["createdAT"].toString());

                            return StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection("rooms")
                                  .doc(docUID)
                                  .collection("messages")
                                  .orderBy("createdAT", descending: true)
                                  .snapshots(),
                              builder: (BuildContext context2,
                                  AsyncSnapshot<
                                          QuerySnapshot<Map<String, dynamic>>>
                                      snapshot2) {
                                if (snapshot2.hasError) {
                                  return Text("Error!");
                                } else {
                                  DocumentSnapshot document2 =
                                      snapshot2.data!.docs[0];

                                  Timestamp timestamp = document2['createdAT'];
                                  DateTime date = timestamp.toDate();
                                  var _today = DateTime.parse(date.toString());
                                  var _formatToday =
                                      DateFormat.yMMMd().format(date);

                                  bool? realAuthor;
                                  if (document2["authorID"] ==
                                      FirebaseApi.realUserUID) {
                                    realAuthor = true;
                                  } else {
                                    realAuthor = false;
                                  }

                                  String lastMessage = "";
                                  String shortName = "";

                                  if (document2["text"] != "") {
                                    if (document2["text"].length > 10) {
                                      lastMessage =
                                          document2["text"].substring(0, 10) +
                                              "...";
                                    } else {
                                      lastMessage = document2["text"];
                                    }

                                    return StreamBuilder(
                                      stream: FirebaseFirestore.instance
                                          .collection("RegularUsers")
                                          .where("UID", isEqualTo: otherUID)
                                          .snapshots(),
                                      builder: (BuildContext context3,
                                          AsyncSnapshot<
                                                  QuerySnapshot<
                                                      Map<String, dynamic>>>
                                              snapshot3) {
                                        DocumentSnapshot document3 =
                                            snapshot3.data!.docs[0];
                                        String otherUsername =
                                            document3["username"];

                                        if (searchChat != "") {
                                          if (otherUsername
                                              .contains(searchChat)) {
                                            if (otherUsername.length > 10) {
                                              shortName = "They";
                                            } else {
                                              shortName = otherUsername;
                                            }
                                            if (snapshot3.hasError) {
                                              return Text("Error!");
                                            } else {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 5, 0, 0),
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    primary: secondaryColor,
                                                    elevation: 0,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              singleChat(
                                                                  otherUID!,
                                                                  otherUsername,
                                                                  docUID)),
                                                    );
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: secondaryColor,
                                                        border: Border.all(
                                                          color: mainColor,
                                                          width: 1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        children: [
                                                          Column(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 25,
                                                                backgroundColor:
                                                                    mainColor,
                                                                child:
                                                                    CircleAvatar(
                                                                        radius:
                                                                            35.0,
                                                                        backgroundColor:
                                                                            mainColor,
                                                                        child:
                                                                            ClipOval(
                                                                          child:
                                                                              Image.network(
                                                                            document3["profileImage"],
                                                                            width:
                                                                                50,
                                                                            height:
                                                                                50,
                                                                            fit:
                                                                                BoxFit.cover,
                                                                          ),
                                                                        )),
                                                              ),
                                                              Text(
                                                                document3[
                                                                    "username"],
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        15),
                                                              ),
                                                            ],
                                                          ),
                                                          Spacer(),
                                                          realAuthor!
                                                              ? Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          0.0),
                                                                  child:
                                                                      Container(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Text(
                                                                          "You: " +
                                                                              lastMessage,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              5,
                                                                        ),
                                                                        Text(
                                                                          _formatToday,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )
                                                              : Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                              .all(
                                                                          0.0),
                                                                  child:
                                                                      Container(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Text(
                                                                          shortName +
                                                                              ": " +
                                                                              lastMessage,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              5,
                                                                        ),
                                                                        Text(
                                                                          _formatToday,
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                          Spacer(),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          } else {
                                            return SizedBox();
                                          }
                                        } else {
                                          if (otherUsername.length > 10) {
                                            shortName = "They";
                                          } else {
                                            shortName = otherUsername;
                                          }
                                          if (snapshot3.hasError) {
                                            return Text("Error!");
                                          } else {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 5, 0, 0),
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  primary: secondaryColor,
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    clickedChat = true;
                                                    _otherUID = otherUID;
                                                    _otherUsername =
                                                        otherUsername;
                                                    _docUID = docUID;

                                                    _controller =
                                                        ScrollController();
                                                    messageControler =
                                                        TextEditingController();
                                                  });

                                                  // Navigator.push(
                                                  //   context,
                                                  //   MaterialPageRoute(
                                                  //       builder: (context) =>
                                                  //           singleChat(
                                                  //               otherUID!,
                                                  //               otherUsername,
                                                  //               docUID)),
                                                  // );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: secondaryColor,
                                                      border: Border.all(
                                                        color: mainColor,
                                                        width: 1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  10))),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      children: [
                                                        Column(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 25,
                                                              backgroundColor:
                                                                  mainColor,
                                                              child:
                                                                  CircleAvatar(
                                                                      radius:
                                                                          35.0,
                                                                      backgroundColor:
                                                                          mainColor,
                                                                      child:
                                                                          ClipOval(
                                                                        child: Image
                                                                            .network(
                                                                          document3[
                                                                              "profileImage"],
                                                                          width:
                                                                              50,
                                                                          height:
                                                                              50,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      )),
                                                            ),
                                                            Text(
                                                              document3[
                                                                  "username"],
                                                              style: TextStyle(
                                                                  fontSize: 15),
                                                            ),
                                                          ],
                                                        ),
                                                        Spacer(),
                                                        realAuthor!
                                                            ? Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        0.0),
                                                                child:
                                                                    Container(
                                                                  child: Column(
                                                                    children: [
                                                                      Text(
                                                                        "You: " +
                                                                            lastMessage,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            5,
                                                                      ),
                                                                      Text(
                                                                        _formatToday,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              )
                                                            : Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        0.0),
                                                                child:
                                                                    Container(
                                                                  child: Column(
                                                                    children: [
                                                                      Text(
                                                                        shortName +
                                                                            ": " +
                                                                            lastMessage,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            5,
                                                                      ),
                                                                      Text(
                                                                        _formatToday,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                        Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  } else {
                                    return SizedBox(
                                      height: 1,
                                      width: 1,
                                    );
                                  }
                                }
                              },
                            );
                          }));
                    }
                  },
                ),
              ),
            ]),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height,
            color: secondaryColor,
            child: clickedChat
                ? Scaffold(
                    resizeToAvoidBottomInset: false,
                    backgroundColor: secondaryColor,
                    body: Scaffold(
                      body: SingleChildScrollView(
                        child: Container(
                          child: Column(
                            children: [
                              Container(
                                height:
                                    MediaQuery.of(context).size.height / 1.15,
                                width: MediaQuery.of(context).size.width,
                                color: Colors.white,
                                child: StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection("rooms")
                                      .doc(_docUID)
                                      .collection("messages")
                                      .orderBy("createdAT", descending: false)
                                      .snapshots(),
                                  builder: (context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasError)
                                      return new Text(
                                          'Error: ${snapshot.error}');
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
                                              id_room: _docUID!,
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
                      offset: Offset(
                          0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
                      child: BottomAppBar(
                        child: Container(
                          height: 60,
                          color: secondaryColor,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                  padding:
                                      EdgeInsets.fromLTRB(1.0, 2.0, 3.0, 4.0),
                                  width: MediaQuery.of(context).size.width / 5,
                                  height: 50,
                                  child: TextFormField(
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
                                      onFieldSubmitted: (value) async {
                                        print(message!);
                                        print("UID " + _otherUID!);
                                        await FirebaseApi.sendMessage(
                                            message!, _otherUID!);
                                        messageControler.clear();
                                        Timer(Duration(milliseconds: 500), () {
                                          _controller.jumpTo(_controller
                                              .position.maxScrollExtent);
                                        });
                                      },
                                      onChanged: ((value) {
                                        message = value;
                                      }))),
                              InitSpeechWidget(_hasSpeech, initSpeechState),
                              SpeechControlWidget(
                                  _hasSpeech,
                                  speech.isListening,
                                  startListening,
                                  stopListening,
                                  cancelListening),
                              Container(
                                width: MediaQuery.of(context).size.width / 10,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.send_rounded,
                                  ),
                                  iconSize: 30,
                                  color: mainColor,
                                  onPressed: () async {
                                    print(message!);
                                    print("UID " + _otherUID!);
                                    await FirebaseApi.sendMessage(
                                        message!, _otherUID!);
                                    messageControler.clear();
                                    Timer(Duration(milliseconds: 500), () {
                                      _controller.jumpTo(
                                          _controller.position.maxScrollExtent);
                                    });
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: MediaQuery.of(context).size.width / 2.5,
                    height: MediaQuery.of(context).size.height / 10,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/gifs/messages.gif'),
                          fit: BoxFit.contain),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                  ),
          )
        ]),
      ),
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
