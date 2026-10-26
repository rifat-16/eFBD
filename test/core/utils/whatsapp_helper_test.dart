import 'package:flutter_test/flutter_test.dart';
import 'package:efbd/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsappHelper', () {
    group('formatNumber', () {
      test('returns empty string for empty input', () {
        expect(WhatsappHelper.formatNumber(''), '');
        expect(WhatsappHelper.formatNumber('   '), '');
      });

      test('returns original string if no digits are present', () {
        expect(WhatsappHelper.formatNumber('abc'), 'abc');
        expect(WhatsappHelper.formatNumber('!@#'), '!@#');
      });

      test('formats BD number starting with 880 (13 digits)', () {
        expect(WhatsappHelper.formatNumber('8801601734167'), '+8801601734167');
      });

      test('formats standard BD mobile number starting with 01 (11 digits)', () {
        expect(WhatsappHelper.formatNumber('01601734167'), '+8801601734167');
      });

      test('formats BD mobile number starting with 1 (10 digits)', () {
        expect(WhatsappHelper.formatNumber('1601734167'), '+8801601734167');
      });

      test('preserves + if already present', () {
        expect(WhatsappHelper.formatNumber('+8801601734167'), '+8801601734167');
        expect(WhatsappHelper.formatNumber('+447700900000'), '+447700900000');
      });

      test('removes non-digit characters and prefixes with +', () {
        expect(WhatsappHelper.formatNumber('016-017-34167'), '+8801601734167');
        expect(WhatsappHelper.formatNumber('016 017 34167'), '+8801601734167');
        expect(WhatsappHelper.formatNumber('(016) 017-34167'), '+8801601734167');
      });

      test('handles other international numbers correctly', () {
        expect(WhatsappHelper.formatNumber('12345678901'), '+12345678901'); // 11 digits not starting with 01
      });
    });
  });
}
