// SignaturePage.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';        // add dependency: signature: ^4.2.0
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:quickalert/models/quickalert_type.dart';

class SignaturePage extends StatefulWidget {
  final String remboursementId;
  const SignaturePage({Key? key, required this.remboursementId})
      : super(key: key);

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _signController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _signController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signController.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        text: 'Veuillez signer avant de valider.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final Uint8List? data = await _signController.toPngBytes();
    if (data == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Erreur lors de la capture de la signature.',
      );
      setState(() => _isSaving = false);
      return;
    }

    // Encode en base64 et enregistre dans Firestore
    final String base64Sig = base64Encode(data);
    await FirebaseFirestore.instance
        .collection('remboursement')
        .doc(widget.remboursementId)
        .update({
      'signature': base64Sig,
      'etat': 'Accepté',
    });

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Signature enregistrée.\nRemboursement accepté.',
      autoCloseDuration: const Duration(seconds: 2),
      showConfirmBtn: false,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signer le remboursement'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Signature(
              controller: _signController,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => _signController.clear(),
                  child: const Text('Effacer'),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSignature,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Valider'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
