import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qtetgglxmvivfbdgylbz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0ZXRnZ2x4bXZpdmZiZGd5bGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MzIzMjQsImV4cCI6MjA3NzEwODMyNH0.kvUeTqnRI6b3d2GjbjXfoxqMvcjKqle29q2rmw6Xyzc',
  );

  runApp(const MarketMoveApp());
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketMove App',
      home: Scaffold(
        appBar: AppBar(title: const Text('MarketMove')),
        body: const Center(child: Text('Conexión con Supabase lista')),
      ),
    );
  }
}
