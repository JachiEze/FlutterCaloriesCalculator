import 'package:assignment3/db_helper.dart';
import 'package:assignment3/food.dart';
import 'package:assignment3/meal_plan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Page for editing a meal plan
class EditMealPlanPage extends StatefulWidget {
  final String selectedDate;
  final List<MealPlan> plans;

  EditMealPlanPage({
    required this.selectedDate,
    required this.plans,
  });

  @override
  _EditMealPlanPageState createState() => _EditMealPlanPageState();
}

class _EditMealPlanPageState extends State<EditMealPlanPage> {
  late DatabaseHelper databaseHelper;
  List<MealPlan> selectedMealPlans = [];
  int totalCalories = 0;
  int targetCalories = 1000;

  List<MultiSelectItem<MealPlan>> multiSelectMealPlans = [];

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    loadMealPlans();
  }

  // Function to load all the meals for that day
  void loadMealPlans() async {
    List<Food> fetchedFoods = await databaseHelper.getAllFoods();

    // parse the data and update the state variable
    setState(() {
      selectedMealPlans = widget.plans
          .where((plan) => plan.date == widget.selectedDate)
          .toList();

      multiSelectMealPlans = fetchedFoods.map((food) {
        final selectedPlan = selectedMealPlans.firstWhere(
          (plan) => plan.foodId == food.id,
          orElse: () => MealPlan(
              id: -1, foodId: -1, date: '', foodName: '', foodCalories: 0),
        );

        return MultiSelectItem<MealPlan>(
          selectedPlan.id != -1
              ? selectedPlan
              : MealPlan(
                  id: -1,
                  foodId: food.id,
                  date: widget.selectedDate,
                  foodName: food.name,
                  foodCalories: food.calories,
                ),
          '${food.name}',
        );
      }).toList();

      // calculate the total calories
      totalCalories =
          selectedMealPlans.fold(0, (sum, plan) => sum + plan.foodCalories);
    });
  }

  // Function to determine if calories have been exceeded
  void checkCaloriesExceeded() {
    if (totalCalories > targetCalories) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("EXCEEDED CALORIES"),
      ));
    }
  }

  // Function to save the meal plan after updating it
  void saveMealPlan() async {
    // check to see if calories are less than target
    if (totalCalories <= targetCalories) {
      await databaseHelper.clearMealPlan(widget.selectedDate);

      for (var mealPlan in selectedMealPlans) {
        await databaseHelper.createMealPlan(
            mealPlan.foodId, widget.selectedDate);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal plan saved!'),
        ),
      );

      Navigator.pop(context, true); // go back to previous page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Meal Plan'),
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
              items: multiSelectMealPlans,
              initialValue: selectedMealPlans,
              onConfirm: (values) {
                setState(() {
                  selectedMealPlans = multiSelectMealPlans
                      .where((item) => values.contains(item.value))
                      .map((item) => item.value)
                      .toList();

                  totalCalories = selectedMealPlans.fold(
                      0, (sum, plan) => sum + plan.foodCalories);

                  checkCaloriesExceeded();
                });
              },
              title: Text('Select Meal Plans'),
              selectedItemsTextStyle: TextStyle(color: Colors.blue),
              buttonText: Text('Select Meal Plans'),
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
