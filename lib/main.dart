import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';


dynamic database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  database = openDatabase(
      join(await getDatabasesPath(), "taskInformationDB.db"),
      version: 1, onCreate: (db, version) {
    db.execute('''
        CREATE TABLE Task(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          date TEXT,
          isDone INTEGER DEFAULT 0)
        ''');
  });

  // String path = await getDatabasesPath();
  // print(path); //To check the path of database file

  runApp(const MyApp());
}

// Insert Data
Future<void> insertdata(ToDoModelClass object) async {
  final localDB = await database;

  await localDB.insert(
    "Task",
    object.toDoMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Fetch Data
Future<List<ToDoModelClass>> getdata() async {
  final localDB = await database;
  List<Map<String, dynamic>> dataMap = await localDB.query("Task");

  if (dataMap.isEmpty) {
    return [];
  }

  return List.generate(dataMap.length, (index) {
    return ToDoModelClass(
      id: dataMap[index]['id'],
      title: dataMap[index]['title'],
      description: dataMap[index]['description'],
      date: dataMap[index]['date'],
      isDone: dataMap[index]['isDone'] == 1 ? true : false,
    );
  });
}

//Delete Data
Future<void> deleteData(int? id) async {
  final localDB = await database;

  await localDB.delete("Task", where: "id = ?", whereArgs: [id]);
}

//Update Data
Future<void> updateData(ToDoModelClass object) async {
  final localDB = await database;

  await localDB.update("Task", object.toDoMap(),
      where: "id = ?", whereArgs: [object.id]);
}

//Delete the Table in database
Future<void> deleteTable() async {
  final localDB = await database;

  await localDB.execute('DROP TABLE IF EXISTS Task');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To Do App',
      home: ToDoApp(),
    );
  }
}

class ToDoApp extends StatefulWidget {
  const ToDoApp({
    super.key,
  });

  @override
  State<ToDoApp> createState() => _ToDoAppState();
}

class ToDoModelClass {
  final int? id;
  String title;
  String description;
  String date;
  bool isDone;

  ToDoModelClass({
    this.id,
    this.isDone = false,
    required this.title,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toDoMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'isDone': isDone ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'ToDoModelClass{id: $id,title: $title, description: $description, date: $date, isDone: $isDone}';
  }
}

class _ToDoAppState extends State<ToDoApp> {
  bool titleFlag = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  List<ToDoModelClass> cardInfo = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await getdata();
    setState(() {
      if (data.isNotEmpty) {
        titleFlag = true;
      } else {
        titleFlag = false;
      }
      cardInfo = data;
    });
  }

  //clear Textfield data
  void clearTextfield() {
    titleController.clear();
    descriptionController.clear();
    dateController.clear();
  }

  // submit function
  void onSubmit(BuildContext context, bool doEdit, [ToDoModelClass? object]) {
    setState(() {
      if (doEdit == false) {
        if (titleController.text.trim().isNotEmpty &&
            descriptionController.text.trim().isNotEmpty &&
            dateController.text.trim().isNotEmpty) {
          insertdata(ToDoModelClass(
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              date: dateController.text.trim()));
          fetchData();
          clearTextfield();
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          object!.title = titleController.text.trim();
          object.description = descriptionController.text.trim();
          object.date = dateController.text.trim();
          object.isDone = false;
          updateData(object);
          clearTextfield();
          Navigator.of(context).pop();
        });
      }
    });
  }

  //Delete Function
  void deleteCard(BuildContext context, int? id) {
    deleteData(id);
  }

  //Edit Function
  void editCard(BuildContext context, bool doEdit, ToDoModelClass object) {
    titleController.text = object.title;
    descriptionController.text = object.description;
    dateController.text = object.date;

    bottomSheet(context, doEdit, object);
  }

  void bottomSheet(BuildContext context, bool doEdit,
      [ToDoModelClass? object]) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              top: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 15,
              right: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                doEdit ? "Edit To-Do" : "Create To-Do",
                style: GoogleFonts.quicksand(
                    fontSize: 25, fontWeight: FontWeight.w500),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Title",
                    style: GoogleFonts.quicksand(
                        fontSize: 20,
                        color: const Color.fromRGBO(0, 0, 0, 1),
                        fontWeight: FontWeight.w600),
                  ),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Enter Title",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 139, 148, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 0, 0, 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Description",
                    style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromRGBO(0, 0, 0, 1)),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter Description",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 139, 148, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 0, 0, 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Date",
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: const Color.fromRGBO(0, 0, 0, 1)),
                  ),
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Pick A Date",
                      suffixIcon: IconButton(
                        onPressed: () async {
                          DateTime? pickeddate = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2025),
                          );

                          String formatedDate =
                              DateFormat.yMMMd().format(pickeddate!);
                          setState(() {
                            dateController.text = formatedDate;
                          });
                        },
                        icon: const Icon(Icons.calendar_month_rounded),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 139, 148, 1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(0, 139, 148, 1),
                        ),
                      ),
                    ),
                    onTap: () async {
                      DateTime? pickeddate = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2025),
                      );

                      String formatedDate =
                          DateFormat.yMMMd().format(pickeddate!);
                      setState(() {
                        dateController.text = formatedDate;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                ],
              ),
              ElevatedButton(
                style: const ButtonStyle(
                  fixedSize: MaterialStatePropertyAll(Size(300, 50)),
                  shape: MaterialStatePropertyAll(ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)))),
                  backgroundColor: MaterialStatePropertyAll(
                    Color.fromRGBO(0, 139, 148, 1),
                  ),
                ),
                onPressed: () {
                  doEdit
                      ? onSubmit(context, doEdit, object)
                      : onSubmit(context, doEdit);
                },
                child: Text(
                  "Submit",
                  style: GoogleFonts.quicksand(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(
                height: 30,
              )
            ],
          ),
        );
      },
    );
  }

   var listofColors = [
    const Color.fromRGBO(250, 232, 232, 1),
    const Color.fromRGBO(232, 237, 250, 1),
    const Color.fromRGBO(250, 249, 232, 1),
    const Color.fromRGBO(250, 232, 250, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 139, 148, 1),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromRGBO(0, 139, 148, 1),
          onPressed: () {
            clearTextfield();
            bottomSheet(context, false);
          },
          child: const Icon(
            Icons.edit_note_rounded,
            size: 42,
            color: Color.fromRGBO(255, 255, 255, 1),
          )),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 70,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "Hello,",
              style: GoogleFonts.quicksand(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              "Pratik.",
              style: GoogleFonts.quicksand(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(217, 217, 217, 1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    titleFlag ? "Today's Tasks" : "Create To Do List",
                    style: GoogleFonts.quicksand(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.only(top: 30),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: ListView.builder(
                          itemCount: cardInfo.length,
                          itemBuilder: (context, index) {
                            final item = cardInfo[index];
                            return Slidable(
                              closeOnScroll: true,
                              endActionPane: ActionPane(
                                  extentRatio: 0.2,
                                  motion: const DrawerMotion(),
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              editCard(context, true, item);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      0, 139, 148, 1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              deleteCard(context, item.id);
                                              fetchData();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      0, 139, 148, 1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          )
                                        ],
                                      ),
                                    ),
                                  ]),
                              key: ValueKey(index),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.08),
                                          blurRadius: 20,
                                        ),
                                      ]),
                                  child: Row(
                                    children: [
                                      Container(
                                          height: 80,
                                          width: 85,
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  offset: Offset(0, 0),
                                                  blurRadius: 5,
                                                ),
                                              ]),
                                          child:
                                              Image.asset("assets/logo.png")),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: GoogleFonts.quicksand(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            Text(
                                              item.description,
                                              style: GoogleFonts.quicksand(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(
                                              height: 8,
                                            ),
                                            Text(
                                              item.date,
                                              style: GoogleFonts.quicksand(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blueAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            //Toggle  isDone value
                                            item.isDone = true;
                                            updateData(item);
                                          });
                                        },
                                        icon: Icon(
                                          Icons.check_circle_outline_sharp,
                                          color:
                                              item.isDone ? Colors.green : null,
                                        ),
                                        iconSize: 30,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
