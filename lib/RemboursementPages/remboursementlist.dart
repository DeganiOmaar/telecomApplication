import 'dart:convert';
import 'package:application_telecom/RemboursementPages/addRemboursement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../shared/colors.dart';

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
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
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
          child: LoadingAnimationWidget.staggeredDotsWave(
            size: 32,
            color: Colors.black,
          ),
        ),
      );
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Choix du flux en fonction du rôle
    final Stream<QuerySnapshot> remboursementStream =
        userRole == 'admin'
            ? FirebaseFirestore.instance
                .collection('remboursement')
                .snapshots()
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
              onPressed: () {
                Get.to(
                  () => const AddRemboursement(),
                  transition: Transition.rightToLeftWithFade,
                );
              },
              icon: const Icon(Icons.add_circle_rounded),
            ),
        ],
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Mes Remboursements",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: blackColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: blackColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: remboursementStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Une erreur est survenue'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  size: 32,
                  color: Colors.black,
                  secondRingColor: Colors.indigo,
                  thirdRingColor: Colors.pink.shade400,
                ),
              );
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("Aucun remboursement trouvé"),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data()! as Map<String, dynamic>;
                final docId = doc.id;

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${data['nom']} ${data['prenom']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(
                                data['etat'],
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                                  data['etat'] == "Accepté"
                                      ? Colors.green
                                      : data['etat'] == "Refusé"
                                          ? Colors.red
                                          : Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildInfoRow("👨‍⚕️ Médecin",
                            data['nomMedecin']),
                        _buildInfoRow("💉 Spécialité",
                            data['specialite']),
                        _buildInfoRow(
                          "📆 Naissance",
                          DateFormat('dd/MM/yyyy').format(
                              data['dateNaissance'].toDate()),
                        ),
                        _buildInfoRow(
                            "📞 Téléphone", data['numero']),
                        _buildInfoRow(
                            "📍 Pharmacie", data['pharmacie']),
                        _buildInfoRow("👤 Genre", data['genre']),
                        _buildInfoRow(
                          "🧬 Membre",
                          "${data['member']} ${data['prenomMembre']}",
                        ),
                        _buildInfoRow(
                            "🪪 CIN", data['cin'].toString()),
                        _buildInfoRow(
                            "🆔 Code CNAM", data['codeCnam']),
                        const SizedBox(height: 12),
                        if (data['etat'] == 'En attente' &&
                            userRole == 'admin')
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => changerEtat(
                                  docId,
                                  "Accepté",
                                  data['fcmToken'],
                                  data['nom'],
                                  data['prenom'],
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text("Accepter"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => changerEtat(
                                  docId,
                                  "Refusé",
                                  data['fcmToken'],
                                  data['nom'],
                                  data['prenom'],
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text("Refuser"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
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

  Future<void> changerEtat(
    String docId,
    String nouvelEtat,
    String fcmToken,
    String nom,
    String prenom,
  ) async {
    await FirebaseFirestore.instance
        .collection('remboursement')
        .doc(docId)
        .update({'etat': nouvelEtat});
    // Vous pouvez ici ajouter l'envoi de notification via fcmToken si souhaité
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
