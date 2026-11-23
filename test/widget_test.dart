import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prichieo/main.dart';

void main() {
  testWidgets('PRICHIEO membuka tab awal dan riwayat kosong', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppData.instance.load();

    await tester.pumpWidget(const PrichieoApp());

    expect(find.text('Kalkulator HPP'), findsOneWidget);
    expect(find.text('Pemisah Kas'), findsOneWidget);
    expect(find.text('Target'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pump();

    expect(find.text('Belum ada riwayat'), findsOneWidget);
  });
}
