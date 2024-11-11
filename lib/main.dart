import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'main.g.dart';
part 'task.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ToDoListScreen(),
    );
  }
}

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final DateTime createdAt;

  Task({required this.title, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

@HiveType(typeId: 1)
class ToDoItem {
  @HiveField(0)
  String task;
  @HiveField(1)
  String category;
  @HiveField(2)
  bool isCompleted;
  @HiveField(3)
  bool isFavourite;
  @HiveField(4)
  String priority;
  @HiveField(5)
  String status;
  @HiveField(6)
  DateTime createdTime;
  @HiveField(7)
  ToDoItem({
    required this.task,
    required this.category,
    required this.createdTime,
    this.isFavourite = false,
    this.isCompleted = false,
    this.priority = "low",
    this.status = "pending",
  });
}

class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});

  @override
  State<ToDoListScreen> createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  final List<ToDoItem> _toDoItems = [];
  late Box<ToDoItem> _todoBox;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _todoBox = await Hive.openBox<ToDoItem>('todoBox');
    final _toDoItems = _todoBox.values.toList();
  }

  Future<void> _addTask(ToDoItem task) async {
    await _todoBox.add(task);
    setState(() {}); // Refresh UI
  }

  Future<void> _deleteTask(int index) async {
    await _todoBox.deleteAt(index);
    setState(() {}); // Refresh UI
  }

  @override
  @override
  int _selectedIndex = 0;
  String _selectedFilter = "all";
  final List<String> filters = [
    "all",
    "unfinished",
    "finished",
  ];
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void _addToDoItem(String task, String priority) {
    if (task.isNotEmpty) {
      setState(() {
        _toDoItems.add(ToDoItem(
            task: task,
            category: _selectedFilter,
            priority: priority,
            createdTime: DateTime.now()));
      });
    }
  }

  @override
  void dispose() {
    _todoBox.close();
    _taskController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String formatCreatedTime(DateTime createdTime) {
    final now = DateTime.now();
    final difference = now.difference(createdTime).inDays;
    String formattedDate =
        '${createdTime.day} ${_getMonthName(createdTime.month)}';
    if (difference == 0) {
      return "today,$formattedDate";
    } else if (difference == 1) {
      return "yesterday";
    } else {
      return formattedDate;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showTaskDetails(ToDoItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Center(
            child: Text(
              item.task,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.teal,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.flag, "Priority:", item.priority,
                  iconColor:
                      item.priority == "High" ? Colors.green : Colors.grey),
              const Divider(),
              _buildDetailRow(Icons.calendar_today, "Added on:",
                  formatCreatedTime(item.createdTime)),
              const Divider(),
              _buildDetailRow(
                Icons.hourglass_top,
                "Status:",
                item.status,
                iconColor: item.isCompleted ? Colors.green : Colors.orange,
              ),
              const Divider(),
              _buildDetailRow(
                Icons.task,
                "Completion:",
                item.isCompleted ? "Completed" : "Pending",
                iconColor: item.isCompleted ? Colors.green : Colors.orange,
              ),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.teal, fontSize: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color iconColor = Colors.blueGrey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  List<ToDoItem> get filteredToDoItems {
    List<ToDoItem> sortedItems;
    if (_selectedFilter == "unfinished") {
      sortedItems = _toDoItems.where((item) => !item.isCompleted).toList();
    } else if (_selectedFilter == "finished") {
      sortedItems = _toDoItems.where((item) => item.isCompleted).toList();
    } else {
      sortedItems = _toDoItems;
    }
    sortedItems.sort((a, b) {
      if (a.priority == 'high' && b.priority != 'high') return -1;
      if (a.priority != 'high' && b.priority == 'high') return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;

      return 0;
    });
    return sortedItems;
  }

  void _toggleFavourite(int index) {
    setState(() {
      _toDoItems[index].isFavourite = !_toDoItems[index].isFavourite;
      _toDoItems[index].priority =
          _toDoItems[index].isFavourite ? 'high' : 'low';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_toDoItems[index].isFavourite
            ? 'Marked as high priority'
            : 'Set to low priority')));
  }

  void _addToCalendar(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${_toDoItems[index].task} to calendar')));
  }

  void _toggleTaskStatus(int index) {
    setState(() {
      _toDoItems[index].isCompleted = !_toDoItems[index].isCompleted;
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _removeToDoItem(int index) {
    setState(() {
      _toDoItems.removeAt(index);
    });
  }

  void _openCalendarScreen() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => _calendarScreen(onTaskAdded: (task) {
              _addToDoItem(task, 'general');
            })));
  }

  void _promptAddToDoItem() {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("New Task"),
          content: TextField(
            autofocus: true,
            controller: taskController,
            decoration: const InputDecoration(hintText: "Enter text here"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                taskController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: const Text("done"),
                onPressed: () {
                  if (taskController.text.isNotEmpty) {
                    _addToDoItem(taskController.text, _selectedFilter);
                  }
                  taskController.clear();
                  Navigator.of(context).pop();
                })
          ],
        );
      },
    );
  }

  void _openTaskTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskTemplateScreen(
          onTaskSelected: _addToDoItem,
        ),
      ),
    );
  }

  Widget _buildToDoItem(ToDoItem toDoItem, int index) {
    return Slidable(
      key: Key(toDoItem.task),
      endActionPane: ActionPane(motion: const ScrollMotion(), children: [
        SlidableAction(
          onPressed: (context) {
            _toggleFavourite(index);
          },
          backgroundColor:
              toDoItem.priority == 'high' ? Colors.green : Colors.brown,
          foregroundColor: Colors.white,
          icon: Icons.star,
        ),
        SlidableAction(
          onPressed: (context) {
            _addToCalendar(index);
          },
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          icon: Icons.calendar_today,
        ),
        SlidableAction(
          onPressed: (context) {
            _removeToDoItem(index);
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          icon: Icons.delete,
        )
      ]),
      child: ListTile(
        title: Text(
          toDoItem.task,
          style: TextStyle(
            decoration: toDoItem.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        leading: IconButton(
          icon: Icon(toDoItem.isCompleted
              ? Icons.check_box
              : Icons.check_box_outline_blank),
          onPressed: () => _toggleTaskStatus(index),
        ),
        onTap: () => _showTaskDetails(toDoItem),
      ),
    );
  }

  void _onNavItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _openCalendarScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        backgroundColor: Colors.grey,
        centerTitle: true,
        toolbarHeight: 60.2,
        toolbarOpacity: 0.8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: "Add from template",
            onPressed: _openTaskTemplate,
          )
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: filters.map((filters) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(filters),
                    selected: _selectedFilter == filters,
                    onSelected: (_) => _selectFilter(filters),
                    selectedColor: Colors.teal,
                    backgroundColor: Colors.grey[200],
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredToDoItems.length,
              itemBuilder: (context, index) {
                return _buildToDoItem(filteredToDoItems[index], index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "My Tasks"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Calendar"),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.settings), label: "Settings"),
        ],
        selectedItemColor: Colors.grey,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _promptAddToDoItem,
        tooltip: 'Add Task',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TaskTemplateScreen extends StatelessWidget {
  final Function(String, String) onTaskSelected;

  TaskTemplateScreen({super.key, required this.onTaskSelected});

  final List<Map<String, dynamic>> taskTemplates = [
    {
      'icon': Icons.local_drink,
      'title': 'Drink Water',
    },
    {
      'icon': Icons.directions_run,
      'title': 'Morning Run',
    },
    {
      'icon': Icons.book,
      'title': 'Read a Book',
    },
    {
      'icon': Icons.bedtime,
      'title': 'Go to Bed Early',
    },
    {
      'icon': Icons.breakfast_dining,
      'title': "Reminder for Your Breakfast",
    },
    {
      'icon': Icons.music_note,
      'title': 'Healing Time',
    },
    {
      'icon': Icons.favorite,
      'title': 'Practice Gratitude',
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Go Shopping',
    },
    {
      'icon': Icons.work,
      'title': 'Prepare Presentation',
    },
    {
      'icon': Icons.coffee,
      'title': 'Take a Break',
    },
    {
      'icon': Icons.message,
      'title': 'Check on Family',
    },
    {
      'icon': Icons.medication,
      'title': 'Take Your Pills',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Templates")),
      body: ListView.builder(
        itemCount: taskTemplates.length,
        itemBuilder: (context, index) {
          final task = taskTemplates[index];
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(task['icon']),
                title: Text(task['title']),
                trailing: TextButton(
                  style: ButtonStyle(
                      iconColor: WidgetStateProperty.all(Colors.orange)),
                  onPressed: () {
                    onTaskSelected(task['title'], 'general');
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Add",
                  ),
                ),
              ));
        },
      ),
    );
  }
}

class _calendarScreen extends StatefulWidget {
  Function(String) onTaskAdded;
  _calendarScreen({required this.onTaskAdded});

  @override
  State<_calendarScreen> createState() => __calendarScreenState();
}

class __calendarScreenState extends State<_calendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _task = {};
  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _addTaskForToday(String task) {
    if (task.isNotEmpty) {
      setState(() {
        DateTime normalizedDay = _normalizeDay(_selectedDay!);
        if (_task[normalizedDay] != null) {
          _task[normalizedDay]!.add(task);
        } else {
          _task[normalizedDay] = [task];
        }
      });
      widget.onTaskAdded(task);
    }
  }

  void _promptAddToTask() {
    if (_selectedDay != null) {
      TextEditingController taskController = TextEditingController();
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("new task on ${_selectedDay!.toLocal()}"),
              content: TextField(
                autofocus: true,
                controller: taskController,
                decoration: const InputDecoration(hintText: "Enter text here"),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    taskController.clear();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Done"),
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      _addTaskForToday(
                        taskController.text,
                      );
                    }
                    taskController.clear();
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("please add new task"),
      ));
    }
  }

  void _showTasksForSelectedDay() {
    DateTime normalizedDay = _normalizeDay(_selectedDay!);
    if (_task[normalizedDay] != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          final tasksForSelectedDay = _task[normalizedDay]!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Tasks on ${DateFormat('MMMM d, y').format(_selectedDay!)}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ...tasksForSelectedDay.map((task) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.task_alt, color: Colors.blue),
                        title: Text(
                          task,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Status: Pending',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: const Icon(Icons.star, color: Colors.amber),
                        onTap: () {},
                      ),
                    )),
                if (tasksForSelectedDay.isEmpty)
                  const Center(
                    child: Text(
                      'No tasks for this day',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No tasks for the selected day"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Calendar",
        ),
        backgroundColor: Colors.grey,
        toolbarHeight: 60.2,
        toolbarOpacity: 0.8,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      body: Column(children: [
        TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _selectedDay = selectedDay;
            });
            return _showTasksForSelectedDay();
          },
          eventLoader: (day) => _task[_normalizeDay(day)] ?? [],
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blueGrey,
              shape: BoxShape.circle,
            ),
            selectedDecoration:
                BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
            markerDecoration:
                BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            markersAlignment: Alignment.bottomCenter,
          ),
        ),
        Expanded(
          child: ListView(
              children:
                  _task[_normalizeDay(_selectedDay ?? _focusedDay)] != null
                      ? _task[_normalizeDay(_selectedDay ?? _focusedDay)]!
                          .map((task) => ListTile(title: Text(task)))
                          .toList()
                      : [const Center(child: Text('No tasks for this day'))]),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _promptAddToTask,
        tooltip: 'Add Task for Selected Day',
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
