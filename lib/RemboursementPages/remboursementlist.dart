import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import '../shared/colors.dart';
import 'addRemboursement.dart';

class RemboursementList extends StatefulWidget {
  const RemboursementList({super.key});
  @override
  State<RemboursementList> createState() => _RemboursementListState();
}

class _RemboursementListState extends State<RemboursementList> {
  String? userRole;
  bool isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    getUserRole();
  }

  Future<void> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      userRole = userDoc.data()?['role'] ?? '';
      isLoadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingRole) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(size: 32, color: Colors.black),
        ),
      );
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stream = userRole == 'admin'
      ? FirebaseFirestore.instance.collection('remboursement').snapshots()
      : FirebaseFirestore.instance
          .collection('remboursement')
          .where('user_id', isEqualTo: uid)
          .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          if (userRole != 'admin')
            IconButton(
              onPressed: () => Get.to(() => const AddRemboursement(), transition: Transition.rightToLeftWithFade),
              icon: const Icon(Icons.add_circle_rounded),
            ),
        ],
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Mes Bulletins de Soins",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: blackColor),
        ),
        backgroundColor: Colors.white,
        foregroundColor: blackColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            if (snap.hasError) return const Center(child: Text('Une erreur est survenue'));
            if (snap.connectionState == ConnectionState.waiting) return Center(
              child: LoadingAnimationWidget.discreteCircle(
                size: 32,
                color: Colors.black,
                secondRingColor: Colors.indigo,
                thirdRingColor: Colors.pink.shade400,
              ),
            );
            if (snap.data!.docs.isEmpty) return const Center(child: Text("Aucun Bulletin trouvé"));

            return ListView.builder(
              itemCount: snap.data!.docs.length,
              itemBuilder: (context, i) {
                final doc = snap.data!.docs[i];
                final data = doc.data()! as Map<String, dynamic>;
                final docId = doc.id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête : Nom + État
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${data['nom']} ${data['prenom']}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text(data['etat'], style: const TextStyle(color: Colors.white)),
                              backgroundColor: data['etat'] == "Accepté"
                                  ? Colors.green
                                  : data['etat'] == "Refusé"
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // Affichage de tous les champs demandés
                        _buildInfoRow("📄ID Remboursement", data['Remboursement_id']),
                        _buildInfoRow("👤Utilisateur (ID)", data['user_id']),
                        _buildInfoRow("🧾Numéro BS", data['numeroBS']),
                        _buildInfoRow("🧑‍⚕️Adhérent", data['nomEtPrenomAdherent']),
                        _buildInfoRow("🔢Code Adhérent", data['codeAdherent']),
                        _buildInfoRow("🏠Adresse", data['adresse']),
                        _buildInfoRow("💳Code CNAM", data['codeCnam']),
                        _buildInfoRow("🤕Malade", data['nomEtPrenomMalade']),
                        _buildInfoRow("💉Acte", data['acte']),
                        _buildInfoRow("📅Date de l'acte", DateFormat('dd/MM/yyyy').format(data['dateActe'].toDate())),
                        _buildInfoRow("👨‍⚕️Médecin", data['nomMedecin']),
                        _buildInfoRow("🩺Spécialité", data['specialite']),
                        _buildInfoRow("📍Pharmacie", data['pharmacie']),
                        _buildInfoRow("👤Genre", data['genre']),
                        _buildInfoRow("🎂Date de naissance", DateFormat('dd/MM/yyyy').format(data['dateNaissance'].toDate())),

                        const SizedBox(height: 12),

                        // Actions selon rôle et état
                        if (data['etat'] == 'En attente' && userRole == 'admin')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => changerEtat(docId, "Accepté"),
                                icon: const Icon(Icons.check),
                                label: const Text("Accepter"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => changerEtat(docId, "Refusé"),
                                icon: const Icon(Icons.close),
                                label: const Text("Refuser"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              ),
                            ],
                          ),

                        // Télécharger PDF si accepté
                        if (data['etat'] == 'Accepté')
                          ElevatedButton.icon(
                            onPressed: () async {
                              await generateAndOpenPdf(data, docId);
                              Get.snackbar('Téléchargement', 'PDF téléchargé avec succès', snackPosition: SnackPosition.TOP);
                            },
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                            label: const Text("Télécharger PDF", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> changerEtat(String docId, String nouvelEtat) async {
    await FirebaseFirestore.instance.collection('remboursement').doc(docId).update({'etat': nouvelEtat});
  }

  Future<void> generateAndOpenPdf(Map<String, dynamic> data, String docId) async {
    // ... même code que précédemment ...
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(flex: 6, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87))),
        ],
      ),
    );
  }
}
