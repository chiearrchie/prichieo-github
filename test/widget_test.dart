import 'dart:convert';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
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

  testWidgets('Input tersimpan saat dibuka ulang dan bisa dikosongkan', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'prichieo.inputs.v1': jsonEncode(<String, String>{
        'hpp.nama': 'Kopi Susu',
        'hpp.bahan': '100000',
        'kas.omset': '500000',
        'target.omset': '500000',
      }),
      'prichieo.modalPercent.v1': '77,5',
    });
    await AppData.instance.load();

    await tester.pumpWidget(const PrichieoApp());

    TextField hppField(int index) => tester.widget<TextField>(find.byType(TextField).at(index));
    expect(hppField(0).controller!.text, 'Kopi Susu');
    expect(hppField(2).controller!.text, '100000');

    await tester.tap(find.text('Pemisah Kas'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, '500000');

    await tester.tap(find.text('About'));
    await tester.pump();
    await tester.ensureVisible(find.text('KOSONGKAN INPUT'));
    await tester.pump();
    await tester.tap(find.text('KOSONGKAN INPUT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kosongkan'));
    await tester.pumpAndSettle();

    expect(AppData.instance.getInput('hpp.nama'), '');
    expect(AppData.instance.modalPercent.value, '60');

    await tester.tap(find.text('HPP'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, '');
  });
}
