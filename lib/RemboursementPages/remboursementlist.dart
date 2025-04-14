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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Get.to(()=>AddRemboursement(), 
              transition: Transition.rightToLeftWithFade
              );
            },
            icon: Icon(Icons.add_circle_rounded),
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
          stream: FirebaseFirestore.instance
              .collection('remboursement')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
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
                Map<String, dynamic> data =
                    snapshot.data!.docs[index].data()! as Map<String, dynamic>;

                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: data['etat'] == "Accepté"
                                  ? Colors.green
                                  : data['etat'] == "Refusé"
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildInfoRow("👨‍⚕️ Médecin", data['nomMedecin']),
                        _buildInfoRow("💉 Spécialité", data['specialite']),
                        _buildInfoRow("📆 Naissance", DateFormat('dd/MM/yyyy').format(data['dateNaissance'].toDate())),
                        _buildInfoRow("📞 Téléphone", data['numero']),
                        _buildInfoRow("📍 Pharmacie", data['pharmacie']),
                        _buildInfoRow("👤 Genre", data['genre']),
                        _buildInfoRow("🧬 Membre", data['member']),
                        _buildInfoRow("🪪 Code CNAM", data['codeCnam']),
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
              )),
          Expanded(
              flex: 6,
              child: Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.black87),
              )),
        ],
      ),
    );
  }
}
