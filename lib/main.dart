import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const VamooseApp());
}

class VamooseApp extends StatelessWidget {
  const VamooseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Vamoose',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('vamoose'))),
    );
  }
}
