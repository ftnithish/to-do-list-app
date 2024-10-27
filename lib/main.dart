import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ToDoListScreen(),
    );
  }
}

class ToDoItem {
  String task;
  String category;
  bool isCompleted;
  bool isFavourite;
  String priority;
  String status;
  DateTime createdTime;

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
  const ToDoListScreen({Key? key}) : super(key: key);

  @override
  State<ToDoListScreen> createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  final List<ToDoItem> _toDoItems = [];

  int _selectedIndex = 0;
  String _selectedFilter = "all";
  final List<String> filters = [
    "all",
    "unfinished",
    "finished",
  ];

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

  String formatCreatedTime(DateTime createdTime) {
    final now = DateTime.now();
    final difference = now.difference(createdTime).inDays;
    if (difference == 0) {
      return "today";
    } else if (difference == 1) {
      return "yesterday";
    } else {
      return '${createdTime.day}/${createdTime.month}/${createdTime.year}';
    }
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
              style: TextStyle(
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
                      item.priority == "High" ? Colors.red : Colors.grey),
              Divider(),
              _buildDetailRow(Icons.calendar_today, "Added on:",
                  formatCreatedTime(item.createdTime)),
              Divider(),
              _buildDetailRow(
                Icons.hourglass_top,
                "Status:",
                item.status,
                iconColor: item.isCompleted ? Colors.green : Colors.orange,
              ),
              Divider(),
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
                child: Text(
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
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => _calendarScreen()));
  }

  void _promptAddToDoItem() {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New Task"),
          content: TextField(
            autofocus: true,
            controller: taskController,
            decoration: InputDecoration(hintText: "Enter text here"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                taskController.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: Text("done"),
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
      endActionPane: ActionPane(motion: ScrollMotion(), children: [
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
        title: Text("To-Do List"),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        backgroundColor: Colors.grey,
        centerTitle: true,
        toolbarHeight: 60.2,
        toolbarOpacity: 0.8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_task),
            tooltip: "Add from template",
            onPressed: _openTaskTemplate,
          )
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: filters.map((filters) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "My Tasks"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
        selectedItemColor: Colors.grey,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _promptAddToDoItem,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TaskTemplateScreen extends StatelessWidget {
  final Function(String, String) onTaskSelected;

  TaskTemplateScreen({required this.onTaskSelected});

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
      appBar: AppBar(title: Text("Task Templates")),
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
                  child: Text(
                    "Add",
                  ),
                  style: ButtonStyle(
                      iconColor: MaterialStateProperty.all(Colors.orange)),
                  onPressed: () {
                    onTaskSelected(task['title'], 'general');
                    Navigator.of(context).pop();
                  },
                ),
              ));
        },
      ),
    );
  }
}

class _calendarScreen extends StatefulWidget {
  const _calendarScreen({super.key});

  @override
  State<_calendarScreen> createState() => __calendarScreenState();
}

class __calendarScreenState extends State<_calendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _task = {};

  void _addTaskForToday(String task) {
    if (task.isNotEmpty) {
      setState(() {
        if (_task[_selectedDay!] != null) {
          _task[_selectedDay!]!.add(task);
        } else {
          _task[_selectedDay!] = [task];
        }
      });
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
                decoration: InputDecoration(hintText: "enter text here"),
              ),
              actions: [
                TextButton(
                  child: Text("cancel"),
                  onPressed: () {
                    taskController.clear();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("done"),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("please add new task"),
      ));
    }
  }

  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
        backgroundColor: Colors.grey,
        toolbarHeight: 60.2,
        toolbarOpacity: 0.8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      body: Column(
        children: [
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
            },
            calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                selectedDecoration:
                    BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          ),
          Expanded(
            child: ListView(
                children: _task[_selectedDay] != null
                    ? _task[_selectedDay]!
                        .map((task) => ListTile(title: Text(task)))
                        .toList()
                    : [Center(child: Text('No tasks for this day'))]),
          ),
        ],
      ),
    );
  }
}
