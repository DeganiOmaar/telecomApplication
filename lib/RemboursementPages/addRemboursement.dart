// ignore_for_file: deprecated_member_use

import 'package:application_telecom/shared/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:uuid/uuid.dart';

class AddRemboursement extends StatefulWidget {
  const AddRemboursement({super.key});

  @override
  State<AddRemboursement> createState() => _AddRemboursementState();
}

class _AddRemboursementState extends State<AddRemboursement> {
  bool isLoading = false;
  bool isLoadingData = true;
  DateTime startDate = DateTime.now();

  String? listePharmacie;
  String? genreClient;

  TextEditingController nomMedecinController = TextEditingController();
  TextEditingController specialiteController = TextEditingController();
  TextEditingController membreController = TextEditingController();
  TextEditingController codeCnamController = TextEditingController();
  TextEditingController numeroController = TextEditingController();

  Map userData = {};

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() => isLoadingData = true);
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
      userData = snapshot.data()!;
    } catch (e) {
      print(e.toString());
    }
    setState(() => isLoadingData = false);
  }

  Future<void> ajouterRemboursement() async {
    setState(() => isLoading = true);
    try {
      String id = const Uuid().v1();
      await FirebaseFirestore.instance.collection('remboursement').doc(id).set({
        'Remboursement_id': id,
        'user_id': userData['uid'],
        'nom': userData['nom'],
        'prenom': userData['prenom'],
        'nomMedecin': nomMedecinController.text,
        'specialite': specialiteController.text,
        'pharmacie': listePharmacie,
        'genre': genreClient,
        'member': membreController.text,
        'dateNaissance': startDate,
        'codeCnam': codeCnamController.text,
        'numero': numeroController.text,
        'etat': 'En attente',
      });
    } catch (err) {
      print("$err");
    }
    setState(() => isLoading = false);
  }

  void afficherAlert() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Votre remboursement a été ajouté !',
      onConfirmBtnTap: () {
        nomMedecinController.clear();
        specialiteController.clear();
        membreController.clear();
        codeCnamController.clear();
        numeroController.clear();
        setState(() {
          listePharmacie = null;
          genreClient = null;
          startDate = DateTime.now();
        });
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mainColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mainColor, width: 2),
          ),
        ),
        items:
            items
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  bool isDatePicked = false;

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000), // date neutre pour l’ouverture
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              startDate = picked;
              isDatePicked = true;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date de naissance",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            isDatePicked
                ? "${startDate.day}/${startDate.month}/${startDate.year}"
                : "Date de naissance", // ← affiche rien tant que l'utilisateur n'a rien choisi
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoadingData
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: LoadingAnimationWidget.discreteCircle(
              size: 32,
              color: Colors.black,
              secondRingColor: Colors.indigo,
              thirdRingColor: Colors.pink.shade400,
            ),
          ),
        )
        : Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              "Ajouter un Remboursement",
              style: TextStyle(
                fontSize: 18,
                color: blackColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            // elevation: 1,
            foregroundColor: Colors.black,
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _buildTextField("Nom Médecin", nomMedecinController),
                        _buildTextField("Spécialité", specialiteController),
                        _buildDropdown(
                          "Pharmacie",
                          listePharmacie,
                          ['pharmacie 1', 'pharmacie 2', 'pharmacie 3'],
                          (val) => setState(() => listePharmacie = val),
                        ),
                        _buildDropdown(
                          "Genre",
                          genreClient,
                          ['Homme', 'Femme'],
                          (val) => setState(() => genreClient = val),
                        ),
                        _buildTextField("Membre", membreController),
                        _buildDatePicker(context),
                        _buildTextField("Code CNAM", codeCnamController),
                        _buildTextField("Téléphone", numeroController),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ajouterRemboursement();
                        afficherAlert();
                      },
                      // icon: const Icon(Icons.send),
                      label:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Ajouter un Remboursement",
                                style: TextStyle(color: Colors.white),
                              ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
  }
}
