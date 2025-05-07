import 'dart:io';
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
import 'package:application_telecom/RemboursementPages/addRemboursement.dart';

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
              onPressed: () => Get.to(
                () => const AddRemboursement(),
                transition: Transition.rightToLeftWithFade,
              ),
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
          stream: stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text('Une erreur est survenue'));
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.discreteCircle(
                  size: 32,
                  color: Colors.black,
                  secondRingColor: Colors.indigo,
                  thirdRingColor: Colors.pink.shade400,
                ),
              );
            }
            if (snap.data!.docs.isEmpty) {
              return const Center(child: Text("Aucun remboursement trouvé"));
            }

            return ListView.builder(
              itemCount: snap.data!.docs.length,
              itemBuilder: (context, i) {
                final doc = snap.data!.docs[i];
                final data = doc.data()! as Map<String, dynamic>;
                final docId = doc.id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
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
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
                        _buildInfoRow(
                          "📆 Naissance",
                          DateFormat('dd/MM/yyyy')
                              .format(data['dateNaissance'].toDate()),
                        ),
                        _buildInfoRow("📞 Téléphone", data['numero']),
                        _buildInfoRow("📍 Pharmacie", data['pharmacie']),
                        _buildInfoRow("👤 Genre", data['genre']),
                        _buildInfoRow(
                          "🧬 Membre",
                          "${data['member']} ${data['prenomMembre']}",
                        ),
                        _buildInfoRow("🪪 CIN", data['cin'].toString()),
                        _buildInfoRow("🆔 Code CNAM", data['codeCnam']),
                        const SizedBox(height: 12),

                        if (data['etat'] == 'En attente' &&
                            userRole == 'admin')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    changerEtat(docId, "Accepté"),
                                icon: const Icon(Icons.check),
                                label: const Text("Accepter"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    changerEtat(docId, "Refusé"),
                                icon: const Icon(Icons.close),
                                label: const Text("Refuser"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                              ),
                            ],
                          ),

                        if (data['etat'] == 'Accepté')
                          ElevatedButton.icon(
                            onPressed: () =>
                                generateAndOpenPdf(data, docId),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text("Télécharger PDF"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
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
    await FirebaseFirestore.instance
        .collection('remboursement')
        .doc(docId)
        .update({'etat': nouvelEtat});
  }

  Future<void> generateAndOpenPdf(
      Map<String, dynamic> data, String docId) async {
    // Charger le logo
    final logoBytes = (await rootBundle.load('assets/images/logoTT.png'))
        .buffer
        .asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    // Créer le PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 2),
            ),
            child: pw.Stack(
              children: [
                // logo en haut à droite
                pw.Positioned(
                  top: 0,
                  right: 0,
                  child: pw.Image(logo, width: 70),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Center(
                      child: pw.Text(
                        'Reçu de Remboursement',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    // tableau des infos
                    pw.Table.fromTextArray(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      headerDecoration:
                          pw.BoxDecoration(color: PdfColors.grey200),
                      headerHeight: 25,
                      cellHeight: 30,
                      cellAlignments: {
                        0: pw.Alignment.centerLeft,
                        1: pw.Alignment.centerLeft,
                      },
                      headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12),
                      cellStyle:
                          pw.TextStyle(fontSize: 11, color: PdfColors.black),
                      headers: ['Champ', 'Détail'],
                      data: [
                        ['Nom', '${data['nom']} ${data['prenom']}'],
                        ['Médecin', '${data['nomMedecin']} (${data['specialite']})'],
                        [
                          'Naissance',
                          DateFormat('dd/MM/yyyy')
                              .format(data['dateNaissance'].toDate())
                        ],
                        ['Téléphone', data['numero']],
                        ['Pharmacie', data['pharmacie']],
                        ['Genre', data['genre']],
                        ['Membre', '${data['member']} ${data['prenomMembre']}'],
                        ['CIN', data['cin'].toString()],
                        ['Code CNAM', data['codeCnam']],
                        ['État', data['etat']],
                      ],
                    ),
                    pw.Spacer(),
                    pw.Align(
                      alignment: pw.Alignment.bottomRight,
                      child: pw.Text(
                        'Émis le ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();

    // Sauvegarde dans dossier privé
    final appDoc = await getApplicationDocumentsDirectory();
    final internal = File('${appDoc.path}/remboursement_$docId.pdf');
    await internal.writeAsBytes(bytes);

    // Sur Android 11+, copie dans Downloads si permission
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        final downloads = Directory('/storage/emulated/0/Download');
        final external = File('${downloads.path}/remboursement_$docId.pdf');
        await external.writeAsBytes(bytes);
        await OpenFile.open(external.path);
        return;
      }
    }

    // Sinon, ouvre le PDF interne
    await OpenFile.open(internal.path);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 4,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            flex: 6,
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
