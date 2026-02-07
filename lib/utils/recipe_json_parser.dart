import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class RecipeJsonParser {
  /// Parses a JSON string into a [Recipe] object.
  /// 
  /// Handles markdown code blocks, function call parameter structures,
  /// and ensures all entities have unique IDs.
  static Recipe parse(String input) {
    // 1. Clean Input: Remove markdown code blocks (```json ... ```) and trim whitespace.
    String cleaned = input.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.length >= 2 && lines.first.startsWith('```') && lines.last.startsWith('```')) {
        cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }

    // 2. Parse: Use jsonDecode.
    dynamic decoded = jsonDecode(cleaned);
    Map<String, dynamic> data;
    
    // 3. Structure Handling:
    // If the JSON has a parameters key (function call format), use json['parameters'] as the recipe data.
    if (decoded is Map<String, dynamic> && decoded.containsKey('parameters')) {
      data = Map<String, dynamic>.from(decoded['parameters']);
    } else if (decoded is Map<String, dynamic>) {
      data = decoded;
    } else {
      throw const FormatException('Invalid JSON structure: Expected an object');
    }

    // 4. Validation: Ensure name, steps, and ingredients are present.
    if (!data.containsKey('name') || !data.containsKey('steps') || !data.containsKey('ingredients')) {
      throw const FormatException('Missing required fields: name, steps, or ingredients');
    }

    final uuid = const Uuid();

    // 5. UUID Generation:
    // If recipe.id is missing, generate one.
    if (data['id'] == null) {
      data['id'] = uuid.v4();
    }
    final String recipeId = data['id'];

    // Iterate through ingredients list. If id is missing or null, generate one.
    if (data['ingredients'] is List) {
      final List rawIngredients = data['ingredients'];
      for (var i = 0; i < rawIngredients.length; i++) {
        if (rawIngredients[i] is Map) {
          final Map<String, dynamic> ingredient = Map<String, dynamic>.from(rawIngredients[i]);
          if (ingredient['id'] == null) {
            ingredient['id'] = uuid.v4();
          }
          rawIngredients[i] = ingredient;
        }
      }
    }

    // Iterate through steps list. If id is missing or null, generate one.
    if (data['steps'] is List) {
      final List rawSteps = data['steps'];
      for (var i = 0; i < rawSteps.length; i++) {
        if (rawSteps[i] is Map) {
          final Map<String, dynamic> step = Map<String, dynamic>.from(rawSteps[i]);
          if (step['id'] == null) {
            step['id'] = uuid.v4();
          }
          // Also set recipe_id if missing, as it's required by Step model
          if (step['recipe_id'] == null) {
            step['recipe_id'] = recipeId;
          }
          // Ensure order_index is set if missing
          if (step['order_index'] == null) {
            step['order_index'] = i;
          }
          rawSteps[i] = step;
        }
      }
    }

    // 6. Return: A Recipe object using Recipe.fromJson.
    return Recipe.fromJson(data);
  }
}
