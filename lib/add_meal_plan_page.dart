import 'package:assignment3/db_helper.dart';
import 'package:assignment3/food.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Add meal page
class AddMealPlanPage extends StatefulWidget {
  final String selectedDate;

  AddMealPlanPage({required this.selectedDate});

  @override
  _AddMealPlanPageState createState() => _AddMealPlanPageState();
}

class _AddMealPlanPageState extends State<AddMealPlanPage> {
  late DatabaseHelper databaseHelper;
  List<Food> foods = [];
  List<Food> selectedFoods = [];
  int totalCalories = 0;
  int targetCalories = 1000;

  List<MultiSelectItem<Food>> multiSelectFoods = [];

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    loadFoods();
  }

  // get all the food items to populate the multiselect
  Future<void> loadFoods() async {
    List<Food> fetchedFoods = await databaseHelper.getAllFoods();

    setState(() {
      foods = fetchedFoods;
      multiSelectFoods = fetchedFoods
          .map((food) => MultiSelectItem<Food>(
                food,
                food.name,
              ))
          .toList();
    });
  }

  // function to update the total calories
  void updateTotalCalories() {
    int sum = 0;
    selectedFoods.forEach((food) {
      sum += food.calories;
    });
    setState(() {
      totalCalories = sum;
    });
  }

  // function to check to see if the calories exceed the set amount
  // if it does then show a toast
  void checkCaloriesExceeded() {
    if (totalCalories > targetCalories) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("EXCEEDED CALORIES"),
      ));
    }
  }

  // function to save the meal plan
  void saveMealPlan() async {
    if (totalCalories <= targetCalories) {
      for (var food in selectedFoods) {
        await databaseHelper.createMealPlan(food.id, widget.selectedDate);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal plan saved!'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Meal Plan'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected Date: ${widget.selectedDate}'),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Calories',
                hintText: 'Enter target calories',
                border: OutlineInputBorder(),
              ),
              controller:
                  TextEditingController(text: targetCalories.toString()),
              onChanged: (value) {
                setState(() {
                  targetCalories = int.tryParse(value) ?? 0;
                });
              },
            ),
            MultiSelectDialogField(
              items: multiSelectFoods,
              initialValue: selectedFoods,
              onConfirm: (values) {
                selectedFoods = values.cast<Food>();
                updateTotalCalories();
                checkCaloriesExceeded();
              },
              title: Text('Select Foods'),
              selectedItemsTextStyle: TextStyle(color: Colors.blue),
              buttonText: Text('Select Foods'),
            ),
            SizedBox(height: 10),
            Text('Total Calories: $totalCalories'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: totalCalories > targetCalories ? null : saveMealPlan,
        child: Icon(Icons.save),
        backgroundColor: totalCalories > targetCalories ? Colors.grey : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
