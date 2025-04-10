// ignore_for_file: unused_local_variable
import 'package:application_telecom/loginPages/login.dart';
import 'package:application_telecom/screens/home.dart' show HomePage;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:get/get.dart';
import '../../shared/colors.dart';
import 'registartiontextfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
   GlobalKey<FormState> formstate = GlobalKey<FormState>();
  bool isPasswordVisible = true;
  String? selectedRole ; 
  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Form(
          key: formstate,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Inscription",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                 "Rejoignez notre communauté en quelques étapes simples.",
                  style: TextStyle(color: Colors.black)),
              const SizedBox(
                height: 50,
              ),
              Row(
                children: [
                  Expanded(
                    child: RegistrationTextField(
                      icon: CupertinoIcons.person,
                      text: "  Nom",
                      controller: nomController,
                        validator: (value) {
                  return value!.isEmpty ? "Entrez un nom valide" : null;
                },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: RegistrationTextField(
                      icon: CupertinoIcons.person,
                      text: "Prenon",
                      controller: prenomController,
                        validator: (value) {
                  return value!.isEmpty ? "Entrez un prenom valide" : null;
                },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              RegistrationTextField(
                icon: CupertinoIcons.mail,
                text: "  Email",
                controller: emailController,
                  validator: (email) {
                  return email!.contains(RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"))
                      ? null
                      : "Entrez un email valide";
                },
              ),
              const SizedBox(
                height: 30,
              ),
              const SizedBox(
                height: 10,
              ),
                TextFormField(
                    validator: (value) {
                  return value!.isEmpty
                      ? "Entrer au moins 6 caractères"
                      : null;
                },
                obscureText: isPasswordVisible,
                controller: passwordController,
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      child: isPasswordVisible
                          ? const Icon(
                              CupertinoIcons.eye,
                              color: Colors.black,
                              size: 22,
                            )
                          : const Icon(
                              CupertinoIcons.eye_slash,
                              color: Colors.black,
                              size: 22,
                            )),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      top: 2.0,
                      left: 3.0,
                    ),
                    child: Icon(
                      CupertinoIcons.lock_rotation_open,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                  hintText: "Mot de passe",
                  hintStyle:
                      const TextStyle(color: Colors.black, fontSize: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            
              const SizedBox(
                height: 30,
              ),
                TextFormField(
                    validator: (value) {
                  return value!.isEmpty
                      ? "Entrer au moins 6 caractères"
                      : null;
                },
                obscureText: isPasswordVisible,
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      child: isPasswordVisible
                          ? const Icon(
                              CupertinoIcons.eye,
                              color: Colors.black,
                              size: 22,
                            )
                          : const Icon(
                              CupertinoIcons.eye_slash,
                              color: Colors.black,
                              size: 22,
                            )),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      top: 2.0,
                      left: 3.0,
                    ),
                    child: Icon(
                      CupertinoIcons.lock_rotation_open,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                  hintText: "Confirmer mot de passe",
                  hintStyle:
                      const TextStyle(color: Colors.black, fontSize: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: Colors.black,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Mot de passe oublie?",
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 35,
              ),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () async {
                            
                     
                      Get.to(() => const HomePage(),
                      transition: Transition.downToUp);

                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all(mainColor),
                            padding: isLoading
                                ? WidgetStateProperty.all(
                                    const EdgeInsets.all(10))
                                : WidgetStateProperty.all(
                                    const EdgeInsets.all(13)),
                            shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25))),
                          ),
                          child: isLoading
                              ? Center(
                                  child:
                                      LoadingAnimationWidget.staggeredDotsWave(
                                    color: whiteColor,
                                    size: 32,
                                  ),
                                )
                              : const Text(
                                  "Enregistrer",
                                  style: TextStyle(
                                      fontSize: 16, color: whiteColor, fontWeight: FontWeight.bold),
                                ))),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text(
                  "Vous avez un compte?",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                ),
                TextButton(
                    onPressed: () {
                       Get.off( () => const LoginPage(), transition: Transition.upToDown);
                    },
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 17),
                    ))
              ])
            ],
          ),
        ),
      ),
    );
  }
}
