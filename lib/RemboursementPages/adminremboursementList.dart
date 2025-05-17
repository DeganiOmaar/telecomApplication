// RemboursementAdminList.dart
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
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import '../shared/colors.dart';
import 'addRemboursement.dart';
import 'signature_page.dart';

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
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'Toutes', child: Text("Toutes")),
                    DropdownMenuItem(value: 'En attente', child: Text("En attente")),
                  ],
                  onChanged: (v) => setState(() => selectedFilter = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedFilter == 'Toutes'
                    ? FirebaseFirestore.instance.collection('remboursement').snapshots()
                    : FirebaseFirestore.instance
                        .collection('remboursement')
                        .where('etat', isEqualTo: 'En attente')
                        .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    return const Center(child: Text('Une erreur est survenue'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: LoadingAnimationWidget.discreteCircle(
                        size: 32, color: Colors.black,
                        secondRingColor: Colors.indigo,
                        thirdRingColor: Colors.pink.shade400,
                      ),
                    );
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("Aucune demande trouvée"));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data()! as Map<String, dynamic>;
                      final id = docs[i].id;
                      final status = data['etat'] as String;
                      return Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête : nom + statut + actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${data['nom']} ${data['prenom']}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  if (status == 'En attente')
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          onPressed: () async {
                                            // Signature avant acceptation
                                            final signed = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SignaturePage(remboursementId: id),
                                              ),
                                            );
                                            if (signed == true) setState(() {});
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          onPressed: () => _changerEtat(id, 'Refusé'),
                                        ),
                                      ],
                                    )
                                  else
                                    // bouton PDF si déjà traité
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                      onPressed: () async {
                                        await generateAndOpenPdfAdmin(data, id);
                                        Get.snackbar('Téléchargement', 'PDF enregistré',
                                            snackPosition: SnackPosition.TOP);
                                      },
                                    ),
                                ],
                              ),

                              const Divider(height: 20),

                              // Tous les champs + emojis
                              _buildInfoRow('📄 ID', data['Remboursement_id']),
                              _buildInfoRow('👤 Utilisateur', data['user_id']),
                              _buildInfoRow('🧾 Numéro BS', data['numeroBS']),
                              _buildInfoRow('🧑‍⚕️ Adhérent', data['nomEtPrenomAdherent']),
                              _buildInfoRow('🔢 Code Adhérent', data['codeAdherent']),
                              _buildInfoRow('🏠 Adresse', data['adresse']),
                              _buildInfoRow('💳 Code CNAM', data['codeCnam']),
                              _buildInfoRow('🤕 Malade', data['nomEtPrenomMalade']),
                              _buildInfoRow('💉 Acte', data['acte']),
                              _buildInfoRow(
                                '📅 Date Acte',
                                DateFormat('dd/MM/yyyy')
                                    .format((data['dateActe'] as Timestamp).toDate()),
                              ),
                              _buildInfoRow('👨‍⚕️ Médecin', data['nomMedecin']),
                              _buildInfoRow('🩺 Spécialité', data['specialite']),
                              _buildInfoRow(
                                '🎂 Naissance',
                                DateFormat('dd/MM/yyyy')
                                    .format((data['dateNaissance'] as Timestamp).toDate()),
                              ),
                              _buildInfoRow('📞 Téléphone', data['numero']),
                              _buildInfoRow('📍 Pharmacie', data['pharmacie']),
                              _buildInfoRow('👤 Genre', data['genre']),
                              _buildInfoRow('👥 Prénom Membre', data['prenomMembre']),
                              _buildInfoRow('🔖 État', data['etat']),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _changerEtat(String id, String nouvelEtat) async {
    try {
      final ref = FirebaseFirestore.instance.collection('remboursement').doc(id);
      final snap = await ref.get();
      if (!snap.exists) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: "Demande introuvable",
        );
        return;
      }
      final userId = snap.data()!['user_id'];
      await ref.update({'etat': nouvelEtat});

      // Notification à l’utilisateur
      final notifId = FirebaseFirestore.instance.collection('tmp').doc().id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notifId)
          .set({
        'type': nouvelEtat == 'Accepté' ? 'acceptée' : 'refusée',
        'content': 'Votre demande de remboursement a été $nouvelEtat.',
        'date': Timestamp.now(),
        'notifId': notifId,
      });

      QuickAlert.show(
        context: context,
        type: nouvelEtat == 'Accepté' ? QuickAlertType.success : QuickAlertType.error,
        text: 'Remboursement ${nouvelEtat.toLowerCase()} !',
        autoCloseDuration: const Duration(seconds: 2),
        showConfirmBtn: false,
      );
      setState(() {});
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: "Erreur : ${e.toString()}",
      );
    }
  }

  Future<void> generateAndOpenPdfAdmin(Map<String, dynamic> data, String id) async {
    // Chargement du logo
    final logoBytes = (await rootBundle.load('assets/images/logoTT.png')).buffer.asUint8List();
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    // Signature (si présente)
    pw.MemoryImage? signature;
    if (data['signature'] != null) {
      signature = pw.MemoryImage(base64Decode(data['signature']));
    }

    // Construction du PDF
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo et titre
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Image(logo, width: 60), pw.SizedBox()],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Reçu de Remboursement',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 24),

            // Tableau des champs
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Champ', 'Détail'],
              data: [
                ['ID', data['Remboursement_id']],
                ['Utilisateur', data['user_id']],
                ['Numéro BS', data['numeroBS']],
                ['Adhérent', data['nomEtPrenomAdherent']],
                ['Code Adhérent', data['codeAdherent']],
                ['Adresse', data['adresse']],
                ['Code CNAM', data['codeCnam']],
                ['Malade', data['nomEtPrenomMalade']],
                ['Acte', data['acte']],
                [
                  'Date Acte',
                  DateFormat('dd/MM/yyyy').format((data['dateActe'] as Timestamp).toDate())
                ],
                ['Médecin', data['nomMedecin']],
                ['Spécialité', data['specialite']],
                ['Téléphone', data['numero']],
                ['Pharmacie', data['pharmacie']],
                ['Genre', data['genre']],
                [
                  'Naissance',
                  DateFormat('dd/MM/yyyy').format((data['dateNaissance'] as Timestamp).toDate())
                ],
                ['Prénom Membre', data['prenomMembre']],
                ['État', data['etat']],
              ],
            ),
            pw.Spacer(),

            // Signature et date d’émission
            if (signature != null) pw.Image(signature, width: 150, height: 80),
            pw.SizedBox(height: 20),
            pw.Text(
              'Émis le ${DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    // Sauvegarde & ouverture
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/remboursement_$id.pdf');
    await file.writeAsBytes(bytes);

    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        final downloads = Directory('/storage/emulated/0/Download');
        final outFile = File('${downloads.path}/remboursement_$id.pdf');
        await outFile.writeAsBytes(bytes);
        await OpenFile.open(outFile.path);
        return;
      }
    }
    await OpenFile.open(file.path);
  }
}
