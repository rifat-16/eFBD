import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efbd/core/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    Widget buildTestableWidget(double width, Widget Function(BuildContext) builder) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(builder: builder),
        ),
      );
    }

    testWidgets('isMobile returns true when width < mobileBreakpoint', (WidgetTester tester) async {
      bool result = false;
      await tester.pumpWidget(buildTestableWidget(600, (context) {
        result = ResponsiveHelper.isMobile(context);
        return const SizedBox();
      }));
      expect(result, isTrue);
    });

    testWidgets('isMobile returns false when width >= mobileBreakpoint', (WidgetTester tester) async {
      bool result = true;
      await tester.pumpWidget(buildTestableWidget(ResponsiveHelper.mobileBreakpoint, (context) {
        result = ResponsiveHelper.isMobile(context);
        return const SizedBox();
      }));
      expect(result, isFalse);
    });

    testWidgets('isTablet returns true when mobileBreakpoint <= width < tabletBreakpoint', (WidgetTester tester) async {
      bool result = false;
      await tester.pumpWidget(buildTestableWidget(800, (context) {
        result = ResponsiveHelper.isTablet(context);
        return const SizedBox();
      }));
      expect(result, isTrue);
    });

    testWidgets('isTablet returns false when width < mobileBreakpoint', (WidgetTester tester) async {
      bool result = true;
      await tester.pumpWidget(buildTestableWidget(600, (context) {
        result = ResponsiveHelper.isTablet(context);
        return const SizedBox();
      }));
      expect(result, isFalse);
    });

    testWidgets('isTablet returns false when width >= tabletBreakpoint', (WidgetTester tester) async {
      bool result = true;
      await tester.pumpWidget(buildTestableWidget(ResponsiveHelper.tabletBreakpoint, (context) {
        result = ResponsiveHelper.isTablet(context);
        return const SizedBox();
      }));
      expect(result, isFalse);
    });

    testWidgets('isDesktop returns true when width >= tabletBreakpoint', (WidgetTester tester) async {
      bool result = false;
      await tester.pumpWidget(buildTestableWidget(1200, (context) {
        result = ResponsiveHelper.isDesktop(context);
        return const SizedBox();
      }));
      expect(result, isTrue);
    });

    testWidgets('isDesktop returns false when width < tabletBreakpoint', (WidgetTester tester) async {
      bool result = true;
      await tester.pumpWidget(buildTestableWidget(1000, (context) {
        result = ResponsiveHelper.isDesktop(context);
        return const SizedBox();
      }));
      expect(result, isFalse);
    });
  });

  group('ResponsiveLayout', () {
    Widget buildResponsiveLayout(double width) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: const ResponsiveLayout(
                mobile: Text('Mobile View'),
                tablet: Text('Tablet View'),
                desktop: Text('Desktop View'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders mobile widget when width < mobileBreakpoint', (WidgetTester tester) async {
      await tester.pumpWidget(buildResponsiveLayout(600));
      expect(find.text('Mobile View'), findsOneWidget);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('renders tablet widget when mobileBreakpoint <= width < tabletBreakpoint', (WidgetTester tester) async {
      await tester.pumpWidget(buildResponsiveLayout(800));
      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Tablet View'), findsOneWidget);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('renders desktop widget when width >= tabletBreakpoint', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildResponsiveLayout(1200));
      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsOneWidget);
    });

    testWidgets('renders mobile widget when tablet is not provided and mobileBreakpoint <= width < tabletBreakpoint', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              child: const ResponsiveLayout(
                mobile: Text('Mobile View'),
                desktop: Text('Desktop View'),
              ),
            ),
          ),
        ),
      ));
      expect(find.text('Mobile View'), findsOneWidget);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsNothing);
    });
  });
}
