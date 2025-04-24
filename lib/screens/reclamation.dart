import 'package:application_telecom/shared/tfield_reclamation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:uuid/uuid.dart';

import '../shared/colors.dart';

class SendReclamation extends StatefulWidget {
  final String userId;
  final String userNom;
  final String userPrenom;
  final String userEmail;

  const SendReclamation({
    super.key,
    required this.userId,
    required this.userNom,
    required this.userPrenom,
    required this.userEmail,
  });

  @override
  State<SendReclamation> createState() => _SendReclamationState();
}

class _SendReclamationState extends State<SendReclamation> {
  TextEditingController emailController = TextEditingController();
  TextEditingController subjectController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  bool isLoadingReclamation = false;

ajouterReclamation() async {
  setState(() {
    isLoadingReclamation = true;
  });

  try {
    String newId = const Uuid().v1();
    CollectionReference reclamations = FirebaseFirestore.instance.collection('reclamations');

    await reclamations.doc(newId).set({
      'reclamation_id': newId,
      'user_id': widget.userId,
      'nom': widget.userNom,
      'prenom': widget.userPrenom,
      'email': widget.userEmail,
      'subject': subjectController.text,
      'message': messageController.text,
      'reclamation_date': DateTime.now(),
    });

    String notifId = const Uuid().v4();
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
      'notifId': notifId,
      'titre': 'Nouvelle réclamation',
      'content': " ${widget.userPrenom} ${widget.userNom} a envoyé une nouvelle réclamation.",
      'date': Timestamp.now(),
    });

  } catch (err) {
    if (!mounted) return;
    print("Error: $err");
  }

  setState(() {
    isLoadingReclamation = false;
  });
}

  afficherAlert() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: "Success",
      text: 'Reclamation ajouter avec succes!',
      onConfirmBtnTap: () {
        emailController.clear();
        subjectController.clear();
        messageController.clear();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
         title: const Text(
          "Espace de Reclamation",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/images/typing.svg',
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.9,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Bienvenue dans notre espace de contact",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                SizedBox(height: 50,),
                const SizedBox(height: 20),
                CustomTextField(text: "Sujet", controller: subjectController),
                const SizedBox(height: 20),

                SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.9, // <-- TextField width
                  height: 180, // <-- TextField height
                  child: TextField(
                    controller: messageController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: "Message",
                      hintStyle: const TextStyle(color: Colors.black),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.black87),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 220, 220, 220),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      alignLabelWithHint:
                          true, // Ensure hint text stays aligned with content
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ajouterReclamation();
                        afficherAlert();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      ),
                      child:
                          isLoadingReclamation
                              ? Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: whiteColor,
                                  size: 32,
                                ),
                              )
                              : const Text(
                                "Submit",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
