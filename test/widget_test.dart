import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_stories/main.dart';

void main() {
  testWidgets('Verifica a renderizacao inicial do aplicativo', (WidgetTester tester) async {
    // Renderiza o widget raiz do aplicativo no ambiente de testes.
    await tester.pumpWidget(const RescueStoriesApp());
  });
}