import 'package:flutter_test/flutter_test.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

void main() {
  test('type', () {
    const type = JsonTooltipBuilder.type;

    expect(type, 'text');
    expect(
      JsonWidgetRegistry.instance.getWidgetBuilder(type) is Function,
      true,
    );
    expect(
      JsonWidgetRegistry.instance.getWidgetBuilder(type)({
        'message': 'foo',
      }) is JsonTooltipBuilder,
      true,
    );
  });
}
