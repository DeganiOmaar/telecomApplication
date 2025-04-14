import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../shared/colors.dart';

class RemboursementAdminList extends StatefulWidget {
  const RemboursementAdminList({super.key});

  @override
  State<RemboursementAdminList> createState() => _RemboursementAdminListState();
}

class _RemboursementAdminListState extends State<RemboursementAdminList> {
  String selectedFilter = 'Toutes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Toutes les Demandes",
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
        child: Column(
          children: [
            // Filtre
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Filtrer : "),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'Toutes', child: Text("Toutes")),
                    DropdownMenuItem(value: 'En attente', child: Text("En attente")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste des remboursements
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedFilter == 'Toutes'
                    ? FirebaseFirestore.instance
                        .collection('remboursement')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('remboursement')
                        .where('etat', isEqualTo: 'En attente')
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
                    return const Center(child: Text("Aucune demande trouvée"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data =
                          snapshot.data!.docs[index].data()! as Map<String, dynamic>;

                      return Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête
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
                                  data['etat'] == "En attente"
                                      ? Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.green),
                                              onPressed: () => _changerEtat(data['Remboursement_id'], "Accepté"),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              onPressed: () => _changerEtat(data['Remboursement_id'], "Refusé"),
                                            ),
                                          ],
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                              const Divider(height: 20),
                              _buildInfoRow("👨‍⚕️ Médecin", data['nomMedecin']),
                              _buildInfoRow("💉 Spécialité", data['specialite']),
                              _buildInfoRow(
                                "📆 Naissance",
                                DateFormat('dd/MM/yyyy').format(data['dateNaissance'].toDate()),
                              ),
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
          ],
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
            child: Text(label, style: const TextStyle(color: Colors.grey)),
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

  Future<void> _changerEtat(String remboursementId, String nouvelEtat) async {
    try {
      await FirebaseFirestore.instance
          .collection('remboursement')
          .doc(remboursementId)
          .update({'etat': nouvelEtat});

      afficherAlert(
        "Remboursement ${nouvelEtat.toLowerCase()} !",
        nouvelEtat == "Accepté" ? QuickAlertType.success : QuickAlertType.error,
      );
    } catch (e) {
      afficherAlert("Erreur : ${e.toString()}", QuickAlertType.error);
    }
  }

  void afficherAlert(String message, QuickAlertType type) {
    QuickAlert.show(
      context: context,
      type: type,
      text: message,
      autoCloseDuration: const Duration(seconds: 2),
      showConfirmBtn: false,
    );
  }
}
