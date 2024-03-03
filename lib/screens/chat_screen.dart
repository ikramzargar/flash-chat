import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static String id = 'Chat_Screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final messageTextController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  late  String messageText;
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async{
 try
     {
       final user = await _auth.currentUser;
       if (user !=null){
         loggedInUser = user;
       }
     }
     catch(e){
   print(e);
     }
  }

  void messagesStream() async{
    await for (var snapshot in _firestore.collection('messages').snapshots())
    {
      for (var message in snapshot.docs)
      {
      print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
               _auth.signOut();
               Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),
                builder: (context , snapshot)
                {
                 if (!snapshot.hasData)
                 {
                 return Center(
                   child: CircularProgressIndicator
                     (
                     backgroundColor: Colors.lightBlueAccent,
                     ),
                 );
                 }
                 final messages = snapshot.data!.docs;
                 List<chatBubble> messageWidgets = [];
                 for (var message in messages)
                 {
                   final a = message.data() as Map;
                   final messageText = a['text'];
                   final messageSender = a['sender'];
                   final currentUser = loggedInUser.email;
                   final messageWidget = chatBubble(sender: messageSender,  text: messageText, isMe: messageSender==currentUser,);
                   messageWidgets.add(messageWidget);
                  }
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   _scrollController.animateTo(
                     _scrollController.position.maxScrollExtent,
                     duration: Duration(milliseconds: 300),
                     curve: Curves.easeOut,
                   );
                 });
                 return Expanded(
                   child: ListView(
                     controller: _scrollController,
                     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                     children: messageWidgets,
                   ),
                 );
                }
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: TextField(
                    controller: messageTextController,
                    onChanged: (value){
                      messageText = value;
                    },
                  ),),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text' : messageText,
                        'sender' : loggedInUser.email,
                        'timestamp' : FieldValue.serverTimestamp(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class  chatBubble extends StatelessWidget {
  chatBubble({required this.sender, required this. text, required this.isMe});
  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(30) : Radius.circular(0),
              topRight: isMe ? Radius.circular(0) : Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            elevation: 10,
            color: isMe ? Colors.lightGreen : Colors.lightBlueAccent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
