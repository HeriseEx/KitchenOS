import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_os/models/models.dart';
import 'package:kitchen_os/utils/utils.dart';

void main() {
  group('RecipeJsonParser - Clean JSON', () {
    test('should parse a valid simple JSON', () {
      const jsonStr = '''
      {
        "id": "recipe-1",
        "name": "Pasta Carbonara",
        "estimated_minutes": 20,
        "ingredients": [
          {
            "id": "i-1",
            "name": "Pasta",
            "quantity": 200.0,
            "unit": "g"
          }
        ],
        "steps": [
          {
            "id": "s-1",
            "recipe_id": "recipe-1",
            "action": "Boil water",
            "duration_seconds": 600,
            "order_index": 0
          }
        ]
      }
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.id, equals('recipe-1'));
      expect(recipe.name, equals('Pasta Carbonara'));
      expect(recipe.ingredients.length, equals(1));
      expect(recipe.ingredients[0].name, equals('Pasta'));
      expect(recipe.steps.length, equals(1));
      expect(recipe.steps[0].action, equals('Boil water'));
    });
  });

  group('RecipeJsonParser - Markdown', () {
    test('should parse JSON wrapped in markdown code blocks', () {
      const jsonStr = '''
      ```json
      {
        "name": "Markdown Recipe",
        "estimated_minutes": 10,
        "ingredients": [],
        "steps": []
      }
      ```
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.name, equals('Markdown Recipe'));
    });

    test('should parse JSON wrapped in generic code blocks', () {
      const jsonStr = '''
      ```
      {
        "name": "Generic Block Recipe",
        "estimated_minutes": 15,
        "ingredients": [],
        "steps": []
      }
      ```
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.name, equals('Generic Block Recipe'));
    });
  });

  group('RecipeJsonParser - Function Call', () {
    test('should unwrap parameters from function call format', () {
      const jsonStr = '''
      {
        "parameters": {
          "name": "Function Call Recipe",
          "estimated_minutes": 5,
          "ingredients": [
            {
              "name": "Salt",
              "quantity": 5.0,
              "unit": "g"
            }
          ],
          "steps": [
            {
              "action": "Add salt",
              "duration_seconds": 10
            }
          ]
        }
      }
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.name, equals('Function Call Recipe'));
      expect(recipe.ingredients.length, equals(1));
      expect(recipe.steps.length, equals(1));
    });
  });

  group('RecipeJsonParser - UUID Generation', () {
    test('should generate UUIDs for recipe, ingredients, and steps if missing',
        () {
      const jsonStr = '''
      {
        "name": "Auto ID Recipe",
        "estimated_minutes": 30,
        "ingredients": [
          {
            "name": "Ingredient 1",
            "quantity": 100.0,
            "unit": "g"
          }
        ],
        "steps": [
          {
            "action": "Step 1",
            "duration_seconds": 60
          }
        ]
      }
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.id, isNotEmpty);
      expect(recipe.ingredients[0].id, isNotEmpty);
      expect(recipe.steps[0].id, isNotEmpty);
      expect(recipe.steps[0].recipeId, equals(recipe.id));
      expect(recipe.steps[0].orderIndex, equals(0));
    });

    test('should preserve existing IDs', () {
      const jsonStr = '''
      {
        "id": "custom-recipe-id",
        "name": "Preserve ID Recipe",
        "estimated_minutes": 30,
        "ingredients": [
          {
            "id": "custom-ingredient-id",
            "name": "Ingredient 1",
            "quantity": 100.0,
            "unit": "g"
          }
        ],
        "steps": [
          {
            "id": "custom-step-id",
            "action": "Step 1",
            "duration_seconds": 60
          }
        ]
      }
      ''';

      final recipe = RecipeJsonParser.parse(jsonStr);

      expect(recipe.id, equals('custom-recipe-id'));
      expect(recipe.ingredients[0].id, equals('custom-ingredient-id'));
      expect(recipe.steps[0].id, equals('custom-step-id'));
    });
  });

  group('RecipeJsonParser - Error Handling', () {
    test('should throw FormatException for malformed JSON', () {
      const jsonStr = '{ "name": "Malformed", "invalid" }';

      expect(() => RecipeJsonParser.parse(jsonStr),
          throwsA(isA<FormatException>()));
    });

    test('should throw FormatException for missing required fields', () {
      const jsonStr = '{ "name": "Missing Fields" }';

      expect(
          () => RecipeJsonParser.parse(jsonStr),
          throwsA(predicate((e) =>
              e is FormatException &&
              e.message.contains('Missing required fields'))));
    });

    test('should throw FormatException for invalid structure (not an object)',
        () {
      const jsonStr = '[1, 2, 3]';

      expect(
          () => RecipeJsonParser.parse(jsonStr),
          throwsA(predicate((e) =>
              e is FormatException &&
              e.message.contains('Invalid JSON structure'))));
    });
  });
}
