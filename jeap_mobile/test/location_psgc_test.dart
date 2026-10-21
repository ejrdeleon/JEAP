import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeap_mobile/features/account/models/address.dart';
import 'package:jeap_mobile/features/location/models/psgc_models.dart';
import 'package:jeap_mobile/features/location/presentation/widgets/philippine_address_selector.dart';

void main() {
  group('PSGC Models & Address Hierarchy Tests', () {
    test('RegionItem correctly identifies NCR and display names', () {
      const ncr = RegionItem(
        code: '130000000',
        psgc10Digit: '1300000000',
        name: 'NCR',
        regionName: 'National Capital Region',
        islandGroup: 'luzon',
      );
      expect(ncr.isNcr, isTrue);
      expect(ncr.displayName, 'NCR (National Capital Region)');

      const region4a = RegionItem(
        code: '040000000',
        psgc10Digit: '0400000000',
        name: 'Region IV-A',
        regionName: 'CALABARZON',
        islandGroup: 'luzon',
      );
      expect(region4a.isNcr, isFalse);
      expect(region4a.displayName, 'Region IV-A (CALABARZON)');
    });

    test(
        'SelectedPhilippineAddress checks completeness correctly for NCR and Provinces',
        () {
      const ncr = RegionItem(
        code: '130000000',
        psgc10Digit: '1300000000',
        name: 'NCR',
        regionName: 'National Capital Region',
        islandGroup: 'luzon',
      );
      const taguig = LocalityItem(
        code: '137607000',
        psgc10Digit: '1381500000',
        name: 'City of Taguig',
        regionCode: '130000000',
        provinceCode: '',
        isCity: true,
        isMunicipality: false,
      );
      const fortBoni = BarangayItem(
        code: '137607020',
        psgc10Digit: '1381500020',
        name: 'Fort Bonifacio',
        cityCode: '137607000',
      );

      // In NCR, province is omitted/null
      const ncrSelection = SelectedPhilippineAddress(
        region: ncr,
        province: null,
        locality: taguig,
        barangay: fortBoni,
      );
      expect(ncrSelection.isComplete, isTrue);
      expect(ncrSelection.summary, contains('Fort Bonifacio'));
      expect(ncrSelection.summary, contains('City of Taguig'));
      expect(ncrSelection.summary, contains('NCR'));
    });

    test('Address fullAddress formatting includes PSGC parts cleanly', () {
      const address = Address(
        label: 'Home',
        recipientName: 'Juan Dela Cruz',
        phone: '09171234567',
        streetLine: 'Unit 4B High Street',
        subdivision: 'BGC',
        barangay: 'Fort Bonifacio',
        city: 'Taguig City',
        province: 'Metro Manila',
        regionName: 'NCR',
        zipCode: '1634',
        landmark: 'Near Central Square',
      );

      expect(address.fullAddress, contains('Unit 4B High Street'));
      expect(address.fullAddress, contains('BGC'));
      expect(address.fullAddress, contains('Brgy. Fort Bonifacio'));
      expect(address.fullAddress, contains('Taguig City'));
      expect(address.fullAddress, contains('1634'));
    });
  });

  group('PhilippineAddressSelector Widget Tests', () {
    testWidgets('Renders placeholder and opens modal on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhilippineAddressSelector(
              onAddressSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Administrative Location (PSGC)'), findsOneWidget);
      expect(
        find.text('Tap to select Region, Province, City & Barangay'),
        findsOneWidget,
      );

      // Tap on selector to open sheet
      await tester.tap(find.byType(PhilippineAddressSelector));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Select Philippine Address'), findsOneWidget);
    });
  });
}
