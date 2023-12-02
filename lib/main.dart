import 'package:assignment3/db_helper.dart';
import 'package:assignment3/meal_plan.dart';
import 'package:assignment3/edit_meal_plan_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:assignment3/add_meal_plan_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // setup main app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MealPlanPage(),
    );
  }
}

// Create the MealPlan page
class MealPlanPage extends StatefulWidget {
  @override
  _MealPlanPageState createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<MealPlan> mealPlan = [];

  final DatabaseHelper dbHelper = DatabaseHelper();

  // Fetch a meal plan given a certain date string
  Future<void> fetchMealPlan(String date) async {
    List<Map<String, dynamic>> plans = await dbHelper.getMealPlanByDate(date);

    // Parse the list and update the state variable
    List<MealPlan> mealPlansList =
        plans.map((map) => MealPlan.fromMap(map)).toList();
    setState(() {
      mealPlan = mealPlansList;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchMealPlan(selectedDate);
  }

  // Configure the date picker and fetch the meal plan for that particular date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2024),
    );
    if (pickedDate != null && pickedDate != DateTime.now()) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      fetchMealPlan(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMealPlan = mealPlan.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Plan for $selectedDate'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body:
          !hasMealPlan // let users create a meal plan if one has not been created
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No meal plan available for this date.'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMealPlanPage(
                                selectedDate: selectedDate,
                              ),
                            ),
                          );

                          if (result != null && result == true) {
                            fetchMealPlan(selectedDate);
                          }
                        },
                        child: Text('Create'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  // display a list of food for the day
                  itemCount: mealPlan.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('${mealPlan[index].foodName}'),
                        subtitle:
                            Text('Calories: ${mealPlan[index].foodCalories}'),
                      ),
                    );
                  },
                ),
      floatingActionButton: hasMealPlan // show button for editing a meal plan
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditMealPlanPage(
                      selectedDate: selectedDate,
                      plans: mealPlan,
                    ),
                  ),
                );

                if (result != null && result == true) {
                  fetchMealPlan(selectedDate);
                }
              },
              child: Icon(Icons.edit),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
