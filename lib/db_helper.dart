import 'package:assignment3/food.dart';
import 'package:assignment3/meal_plan.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Database helper class
class DatabaseHelper {
  static late DatabaseHelper _instance;
  static Database? _database;
  final String foodTable = 'Food';
  final String mealPlanTable = 'MealPlan';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Setup the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calories_db.db');
    Database db = await openDatabase(
      path,
      version: 7,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $foodTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            calories INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $mealPlanTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            food_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            FOREIGN KEY (food_id) REFERENCES $foodTable(id)
          )
        ''');

        await _insertInitialFoodItems(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {},
    );
    return db;
  }

  // Function to insert the preferred food items
  Future<void> _insertInitialFoodItems(Database db) async {
    final foodItems = [
      {'name': 'Apple', 'calories': 95},
      {'name': 'Banana', 'calories': 105},
      {'name': 'Orange', 'calories': 62},
      {'name': 'Grapes', 'calories': 69},
      {'name': 'Carrot', 'calories': 41},
      {'name': 'Broccoli', 'calories': 55},
      {'name': 'Chicken Breast (cooked)', 'calories': 165},
      {'name': 'Salmon (cooked)', 'calories': 206},
      {'name': 'Rice (cooked)', 'calories': 205},
      {'name': 'Quinoa (cooked)', 'calories': 222},
      {'name': 'Pasta (cooked)', 'calories': 200},
      {'name': 'Egg', 'calories': 68},
      {'name': 'Greek Yogurt', 'calories': 59},
      {'name': 'Almonds', 'calories': 7},
      {'name': 'Avocado', 'calories': 322},
      {'name': 'Spinach (raw)', 'calories': 7},
      {'name': 'Sweet Potato (baked)', 'calories': 180},
      {'name': 'Cheese (cheddar)', 'calories': 113},
      {'name': 'Milk (whole)', 'calories': 150},
      {'name': 'Dark Chocolate', 'calories': 170},
      {'name': 'Oatmeal', 'calories': 150},
      {'name': 'Peanut Butter', 'calories': 90},
      {'name': 'Ground Beef (cooked)', 'calories': 250},
      {'name': 'Tomato', 'calories': 22},
      {'name': 'Lettuce', 'calories': 5},
      {'name': 'Cucumber', 'calories': 16},
      {'name': 'Bell Pepper', 'calories': 25},
      {'name': 'Olive Oil', 'calories': 119},
      {'name': 'Whole Wheat Bread', 'calories': 69},
    ];

    for (final foodItem in foodItems) {
      await db.insert(
        'Food',
        foodItem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Function to get all the food items
  Future<List<Food>> getAllFoods() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(foodTable);
    return result.map((map) => Food.fromMap(map)).toList();
  }

  // Function to create a meal plan
  Future<int> createMealPlan(int foodId, String date) async {
    Database db = await database;
    return await db.insert(mealPlanTable, {'food_id': foodId, 'date': date});
  }

  // Function to remove all the food items for a particular date, in essence
  // it removes the meal plan for that date.
  Future<void> clearMealPlan(String date) async {
    Database db = await database;

    await db.delete(
      mealPlanTable,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // Function to delete a particular food item
  Future<int> deleteMealPlan(int mealPlanId) async {
    Database db = await database;
    return await db.delete(
      mealPlanTable,
      where: 'id = ?',
      whereArgs: [mealPlanId],
    );
  }

  // Function to get the meal plan for a particular date
  Future<List<Map<String, dynamic>>> getMealPlanByDate(String date) async {
    Database db = await database;
    return await db.rawQuery('''
    SELECT $mealPlanTable.id, $mealPlanTable.food_id, $mealPlanTable.date,
           $foodTable.name AS food_name, $foodTable.calories AS food_calories
    FROM $mealPlanTable
    INNER JOIN $foodTable ON $mealPlanTable.food_id = $foodTable.id
    WHERE $mealPlanTable.date = ?
  ''', [date]);
  }
}
