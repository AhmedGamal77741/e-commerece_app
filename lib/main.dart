import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/e_commerce_app.dart';
import 'package:ecommerece_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(EcommerceApp(appRouter: AppRouter()));
}
