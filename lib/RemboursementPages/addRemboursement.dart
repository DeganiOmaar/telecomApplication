

import 'package:application_telecom/shared/addavistfield.dart';
import 'package:application_telecom/shared/colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

class AddRemboursement extends StatefulWidget {
  // final String uid;
  const AddRemboursement({super.key});

  @override
  State<AddRemboursement> createState() => _AddRemboursementState();
}

class _AddRemboursementState extends State<AddRemboursement> {
  GlobalKey<FormState> formstate = GlobalKey<FormState>();
  // TextEditingController nomController = TextEditingController();
  // TextEditingController prenomController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController dureeController = TextEditingController();
  TextEditingController categorieController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController numeroController = TextEditingController();

  afficherAlert() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Remboursement ajouter avec succes!',
      onConfirmBtnTap: () {
        // nomController.clear();
        // prenomController.clear();
        dateController.clear();
        dureeController.clear();
        categorieController.clear();
        descriptionController.clear();
        numeroController.clear();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Ajouter un Remboursement",
          style: TextStyle(
            fontSize: 17,
            color: blackColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: formstate,
          child: Column(
            children: [
              const Gap(30),
              AddAvisTField(
                title: 'Date de Remboursement',
                text: '',
                controller: dateController,
                validator: (value) {
                  return value!.isEmpty ? "ne peut être vide" : null;
                },
              ),

              const Gap(10),
              AddAvisTField(
                title: 'Type de Reboursement',
                text: '',
                controller: dateController,
                validator: (value) {
                  return value!.isEmpty ? "ne peut être vide" : null;
                },
              ),
               

              
              const Gap(10),
              AddAvisTField(
                title: 'Description de Remboursement',
                text: '',
                controller: descriptionController,
                validator: (value) {
                  return value!.isEmpty ? "ne peut être vide" : null;
                },
              ),

             const Gap(10),
              AddAvisTField(
                title: 'Téléphone',
                text: '',
                controller: numeroController,
                validator: (value) {
                  return value!.isEmpty ? "ne peut être vide" : null;
                },
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {},
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(mainColor),
                        padding:
                        //  isLoading
                        //     ? MaterialStateProperty.all(
                        //         const EdgeInsets.all(9))
                        //     :
                        MaterialStateProperty.all(const EdgeInsets.all(12)),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      child:
                      // isLoading
                      //     ? Center(
                      //         child:
                      //             LoadingAnimationWidget.staggeredDotsWave(
                      //           color: whiteColor,
                      //           size: 32,
                      //         ),
                      //       )
                      //     :
                      const Text(
                        "Ajouter un Remboursement",
                        style: TextStyle(fontSize: 16, color: whiteColor),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }
}
