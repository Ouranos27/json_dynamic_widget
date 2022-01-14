import 'package:expressions/expressions.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class ExpressionArgProcessor implements ArgProcessor {
  final _matchRegexp = RegExp(r'^\${\s*(.*?)\s*}$');
  @override
  bool support(dynamic arg) {
    return arg != null && arg is String && _matchRegexp.hasMatch(arg);
  }

  @override
  ProcessedArg process(JsonWidgetRegistry registry, dynamic arg) {
    var dynamicKeys = <String>{};
    var regexpMatch = _matchRegexp.firstMatch(arg.toString())!;
    var expression = Expression.tryParse(regexpMatch.group(1)!);
    if (expression != null) {
      var evaluator = ArgsExpressionEvaluator(registry);
      arg = evaluator.evaluate(expression);
      dynamicKeys = evaluator.dynamicKeys;
    }
    return ProcessedArg(dynamicKeys: dynamicKeys, value: arg);
  }
}

class ArgsExpressionEvaluator extends ExpressionEvaluator {
  ArgsExpressionEvaluator(this.registry);

  final Set<String> _dynamicKeys = {};
  final JsonWidgetRegistry registry;

  Set<String> get dynamicKeys => _dynamicKeys;

  dynamic evaluate(Expression expression) {
    return super.eval(expression, {});
  }

  @override
  dynamic evalVariable(Variable variable, Map<String, dynamic> context) {
    var variableName = variable.identifier.name;
    return super
        .evalVariable(variable, _updateContextIfNeeded(context, variableName));
  }

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    var variableName = '${expression.object}.${expression.property}';
    return evalVariable(Variable(Identifier(variableName)), context);
  }

  @override
  dynamic evalIndexExpression(
      IndexExpression expression, Map<String, dynamic> context) {
    dynamic objectIndexValue;
    var objectValue = eval(expression.object, context);
    if (objectValue != null) {
      objectIndexValue =
          eval(expression.object, context)[eval(expression.index, context)];
    }
    return objectIndexValue;
  }

  @override
  dynamic evalCallExpression(
    CallExpression expression,
    Map<String, dynamic> context,
  ) {
    dynamic result;
    var callee = eval(expression.callee, context);
    var arguments = expression.arguments.map((e) => eval(e, context)).toList();
    if (callee is JsonWidgetFunction) {
      result = Function.apply(callee, null, {
        const Symbol('args'): arguments,
        const Symbol('registry'): registry,
      });
    } else {
      result = Function.apply(callee, arguments);
    }
    return result;
  }

  Map<String, dynamic> _updateContextIfNeeded(
      Map<String, dynamic> context, String variableName) {
    if (!context.containsKey(variableName)) {
      var function = registry.getFunction(variableName);
      if (function == null) {
        _dynamicKeys.add(variableName);
        context[variableName] = registry.getValue(variableName);
      } else {
        context[variableName] = function;
      }
    }
    return context;
  }
}
