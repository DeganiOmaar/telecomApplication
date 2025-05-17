// ignore_for_file: deprecated_member_use

import 'package:application_telecom/shared/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  bool validerNumero(String numero) {
    final RegExp regex = RegExp(r'^[0-9]+$');
    return regex.hasMatch(numero);
  }

  bool isLoading = false;
  bool isLoadingData = true;
  DateTime birthDate = DateTime.now();
  bool isBirthDatePicked = false;

  DateTime acteDate = DateTime.now();
  bool isActeDatePicked = false;

  String? listePharmacie;
  String? genreClient;
  final numeroBSController = TextEditingController();
  final nomMedecinController = TextEditingController();
  final nometprenomAdherentController = TextEditingController();
  final codeAdherentController = TextEditingController();
  final adresseController = TextEditingController();
  final nomEtPrenomMaladeController = TextEditingController();
  final acteController = TextEditingController();
  final specialiteController = TextEditingController();
  final prenomMembreController = TextEditingController();
  final codeCnamController = TextEditingController();
  final numeroController = TextEditingController();
 
  Map userData = {};

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() => isLoadingData = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      userData = snapshot.data()!;
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => isLoadingData = false);
  }

  Future<void> ajouterRemboursement() async {
    setState(() => isLoading = true);
    try {
      final remboursementId = const Uuid().v1();
      await FirebaseFirestore.instance
          .collection('remboursement')
          .doc(remboursementId)
          .set({
        'Remboursement_id': remboursementId,
        'user_id': userData['uid'],
        'nom': userData['nom'],
        'prenom': userData['prenom'],
        'numeroBS': numeroBSController.text,
        'nomEtPrenomAdherent': nometprenomAdherentController.text,
        'codeAdherent': codeAdherentController.text,
        'adresse': adresseController.text,
        'codeCnam': codeCnamController.text,
        'nomEtPrenomMalade': nomEtPrenomMaladeController.text,
        'acte': acteController.text,
        'dateActe': acteDate,
        'nomMedecin': nomMedecinController.text,
        'specialite': specialiteController.text,
        'pharmacie': listePharmacie,
        'genre': genreClient,
        'dateNaissance': birthDate,
        'prenomMembre': prenomMembreController.text,
        'etat': 'En attente',
      });

      final notifId = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notifId)
          .set({
        'notifId': notifId,
        'titre': "Demande de remboursement",
        'content':
            'Nouvelle demande de remboursement envoyée par ${userData['nom']} ${userData['prenom']}.',
        'date': Timestamp.now(),
      });
    } catch (err) {
      debugPrint(err.toString());
      rethrow;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: mainColor, width: 2),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBirthDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              birthDate = picked;
              isBirthDatePicked = true;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date de naissance",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            isBirthDatePicked
                ? DateFormat('dd/MM/yyyy').format(birthDate)
                : "Date de naissance",
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildActeDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              acteDate = picked;
              isActeDatePicked = true;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date de l'acte",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            isActeDatePicked
                ? DateFormat('dd/MM/yyyy').format(acteDate)
                : "Date de l'acte",
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: LoadingAnimationWidget.discreteCircle(
            size: 32,
            color: Colors.black,
            secondRingColor: Colors.indigo,
            thirdRingColor: Colors.pink.shade400,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Ajouter un Bulletin de Soin",
          style: TextStyle(
            fontSize: 18,
            color: blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Numéro Bulletin de Soin", numeroBSController),
              _buildTextField("Nom et prénom de l'adhérent", nometprenomAdherentController),
              _buildTextField("Code de l'adhérent", codeAdherentController),
              _buildTextField("Adresse", adresseController),
              _buildTextField("Code CNAM", codeCnamController),
              _buildTextField("Nom et prénom du malade", nomEtPrenomMaladeController),
              _buildTextField("Acte", acteController),
              _buildActeDatePicker(context),
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
              _buildBirthDatePicker(context),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!validerNumero(numeroBSController.text) ||
                            !validerNumero(codeAdherentController.text) ||
                            !validerNumero(codeCnamController.text)) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            text: "Le numéro de bulletin, le code adhérent et le code CNAM doivent être numériques.",
                          );
                          return;
                        }
                        try {
                          await ajouterRemboursement();
                          Get.back();
                          Get.snackbar(
                            'Succès',
                            'Bulletin de Soin ajouté',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (_) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            text: "Erreur lors de l'ajout.",
                          );
                        }
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text(
                  "Ajouter un Bulletin de Soin",
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    numeroBSController.dispose();
    nometprenomAdherentController.dispose();
    codeAdherentController.dispose();
    adresseController.dispose();
    nomEtPrenomMaladeController.dispose();
    acteController.dispose();
    nomMedecinController.dispose();
    specialiteController.dispose();
    prenomMembreController.dispose();
    codeCnamController.dispose();
    super.dispose();
  }
}
