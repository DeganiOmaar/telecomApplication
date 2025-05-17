import 'dart:io';
import 'dart:convert';
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

                        _buildInfoRow("🧾 Numéro BS", data['numeroBS'].toString()),
                        _buildInfoRow("🧑‍⚕️ Adhérent", data['nomEtPrenomAdherent']),
                        _buildInfoRow("🔢 Code Adhérent", data['codeAdherent'].toString()),
                        _buildInfoRow("🏠 Adresse", data['adresse']),
                        _buildInfoRow("💳 Code CNAM", data['codeCnam'].toString()),
                        _buildInfoRow("🤕 Malade", data['nomEtPrenomMalade']),
                        _buildInfoRow("💉 Acte", data['acte']),
                        _buildInfoRow(
                          "📅 Date de l'acte",
                          DateFormat('dd/MM/yyyy').format((data['dateActe'] as Timestamp).toDate()),
                        ),
                        _buildInfoRow("👨‍⚕️ Médecin", data['nomMedecin']),
                        _buildInfoRow("🩺 Spécialité", data['specialite']),
                        _buildInfoRow("📍 Pharmacie", data['pharmacie']),
                        _buildInfoRow("👤 Genre", data['genre']),
                        _buildInfoRow(
                          "🎂 Date de naissance",
                          DateFormat('dd/MM/yyyy').format((data['dateNaissance'] as Timestamp).toDate()),
                        ),

                        const SizedBox(height: 12),

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

                        if (data['etat'] == 'Accepté')
                          ElevatedButton.icon(
                            onPressed: () async {
                              await generateAndOpenPdf(data, docId);
                              Get.snackbar('Téléchargement', 'PDF téléchargé et ouvert', snackPosition: SnackPosition.TOP);
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

  Future<void> changerEtat(String docId, String nouvelEtat) async {
    await FirebaseFirestore.instance.collection('remboursement').doc(docId).update({'etat': nouvelEtat});
  }

  Future<void> generateAndOpenPdf(Map<String, dynamic> data, String docId) async {
    // Logo
    final logoBytes = (await rootBundle.load('assets/images/logoTT.png')).buffer.asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    // Signature admin si existante
    pw.MemoryImage? signature;
    if (data['signature'] != null && data['signature'] is String) {
      signature = pw.MemoryImage(base64Decode(data['signature'] as String));
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [pw.Image(logo, width: 60)],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Bulletin de Soins',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Champ', 'Détail'],
              data: [
                ['Numéro BS', data['numeroBS']],
                ['Adhérent', data['nomEtPrenomAdherent']],
                ['Code Adhérent', data['codeAdherent']],
                ['Adresse', data['adresse']],
                ['Code CNAM', data['codeCnam']],
                ['Malade', data['nomEtPrenomMalade']],
                ['Acte', data['acte']],
                ['Date de l\'acte', DateFormat('dd/MM/yyyy').format((data['dateActe'] as Timestamp).toDate())],
                ['Médecin', data['nomMedecin']],
                ['Spécialité', data['specialite']],
                ['Pharmacie', data['pharmacie']],
                ['Genre', data['genre']],
                ['Date de naissance', DateFormat('dd/MM/yyyy').format((data['dateNaissance'] as Timestamp).toDate())],
              ],
            ),
            if (signature != null) pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Text('Signature Admin :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Image(signature, width: 150, height: 80),
              ],
            ),
            pw.Spacer(),
            pw.Text(
              'Émis le ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bulletin_$docId.pdf');
    await file.writeAsBytes(bytes);

    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        final downloads = Directory('/storage/emulated/0/Download');
        final outFile = File('${downloads.path}/bulletin_$docId.pdf');
        await outFile.writeAsBytes(bytes);
        await OpenFile.open(outFile.path);
        return;
      }
    }
    await OpenFile.open(file.path);
  }
}