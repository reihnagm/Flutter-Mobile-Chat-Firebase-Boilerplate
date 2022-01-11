import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';


class ChatsProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;

  ChatsProvider({
    required this.authenticationProvider,
    required this.databaseService
  });

  List<Chat>? chats;
  List<ChatUser>? members;
  StreamSubscription? chatsStream;
  StreamSubscription? membersGroupStream;
  
  @override 
  void dispose() {
    chatsStream!.cancel();
    membersGroupStream!.cancel();
    super.dispose();
  }

  void getChats() {
    try {
      chatsStream = databaseService.getChatsForUser(authenticationProvider.userUid())!.listen((snapshot) async {
        chats = await Future.wait(snapshot.docs.map((doc) async {
          Map<String, dynamic> chatData = doc.data() as Map<String, dynamic>;
    
          List<ChatUser> members = [];
          List<ChatMessage> messagesPersonalCount = [];
          List<dynamic> messagesGroupCount = [];
          List<ChatMessage> messages = [];
          GroupData groupData;
          
          groupData = GroupData.fromJson(chatData["group"]);
        
          for (var member in chatData["members"]) {
            members.add(ChatUser.fromJson(member));
          }
    
          QuerySnapshot<Object?>? readerCountIds = await databaseService.readerCountIds(
            chatUid: doc.id, 
            userUid: authenticationProvider.userUid()
          );

          if(readerCountIds!.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in readerCountIds.docs) {
              Map<String, dynamic> readerDataCount = item.data() as Map<String, dynamic>;
              List<dynamic> readerCountIds = readerDataCount["readerCountIds"];
              int readerCount = readerCountIds.where((uids) => uids == authenticationProvider.userUid()).toList().length; 
              messagesGroupCount.add(readerCount);
            }
          }

          QuerySnapshot<Object?>? chatMessageCount = await databaseService.getMessageCountForChat(doc.id);
          QuerySnapshot<Object?>? chatMessage = await databaseService.getLastMessageForChat(doc.id);
          if(chatMessage!.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in chatMessageCount!.docs) {
              Map<String, dynamic> messageDataCount = item.data() as Map<String, dynamic>;
              ChatMessage message = ChatMessage.fromJSON(messageDataCount);
              messagesPersonalCount.add(message);
            }
            Map<String, dynamic> messageData = chatMessage.docs.first.data() as Map<String, dynamic>;
            ChatMessage message = ChatMessage.fromJSON(messageData);
            messages.add(message);
          } //* Prevent Bad State No Element
          return Chat(
            uid: doc.id, 
            currentUserId: authenticationProvider.userUid(), 
            activity: chatData["is_activity"], 
            group: chatData["is_group"], 
            groupData: GroupData(
              image: groupData.image,
              name: groupData.name,
              tokens: groupData.tokens
            ),
            members: members,
            messages: messages, 
            messagesPersonalCount: messagesPersonalCount,
            messagesGroupCount: messagesGroupCount,
          );
        }).toList());
        notifyListeners();
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void membersGroup({required String userId}) {
    try {
    
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteChat({required String chatId}) async {
    try {
      await databaseService.deleteChat(chatId);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

   Future<void> deleteMsg({required String chatId, required String msgId}) async {
    try {
      await databaseService.deleteMsg(chatId: chatId, msgId: msgId);
    } catch(e) {
      debugPrint(e.toString());
    }
  }
}