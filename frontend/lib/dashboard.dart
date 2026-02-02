import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class Dashboard extends StatefulWidget {
  final String token;
  final VoidCallback onLogout; 
  const Dashboard({required this.token, required this.onLogout, super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late String? userId, emailId;
  final TextEditingController _todoTitle = TextEditingController();
  final TextEditingController _todoDesc = TextEditingController();
  List items = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true; // ADD THIS LINE
    });
    _decodeTokenAndLoadTodos();
  }

  void _decodeTokenAndLoadTodos() async {
    try {
      setState(() {
        isLoading = true; // ADD THIS LINE
      });
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      userId = jwtDecodedToken['id'];
      emailId = jwtDecodedToken['email'];
      // print('✅ User ID: $userId, Email: $emailId');

      if (userId != null) {
        await getTodoList(userId!);
      } else {
        setState(() {
          errorMessage = 'Could not extract user ID from token';
          isLoading = false;
        });
      }
    } catch (e) {
      // print('❌ JWT Decode Error: $e');
      setState(() {
        errorMessage = 'Authentication error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  bool _isHtmlResponse(String body) {
    return body.contains('<!DOCTYPE') ||
        body.contains('<html') ||
        body.contains('<head>') ||
        body.contains('<body>');
  }

  void addTodo() async {
    if (_todoTitle.text.isEmpty || _todoDesc.text.isEmpty) {
      _showSnackBar('Please enter both title and description', Colors.orange);
      return;
    }

    if (userId == null) {
      _showSnackBar('User authentication error', Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var regBody = {
        "userId": userId,
        "title": _todoTitle.text.trim(),
        "desc": _todoDesc.text.trim(),
      };

      // print('📤 Creating todo for user: $userId');

      var response = await http
          .post(
            Uri.parse("http://localhost:5000/createToDo"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(regBody),
          )
          .timeout(Duration(seconds: 15));

      // print('📥 Response: ${response.statusCode}');

      if (_isHtmlResponse(response.body)) {
        throw FormatException('Backend returned HTML instead of JSON.');
      }

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['status'] == true) {
          // SUCCESS!
          _todoDesc.clear();
          _todoTitle.clear();

          Navigator.pop(context);
          await getTodoList(userId!); // Refresh automatically

          _showSnackBar('✅ Todo added successfully!', Colors.green);
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Backend failed to create todo',
          );
        }
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${jsonResponse['message'] ?? 'Unknown error'}',
        );
      }
    } on SocketException catch (e) {
      // print('NETWORK ERROR: $e');
      setState(() {
        errorMessage =
            'Cannot connect to server. Make sure backend is running.';
      });
      _showSnackBar('Network error. Check your connection.', Colors.red);
    } on FormatException catch (e) {
      print('FORMAT ERROR: $e');
      setState(() {
        errorMessage = 'Server returned invalid response.';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
      _showSnackBar('Failed to add todo: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        isRefreshing = false;
        isLoading = false;
      });
    }
  }

  // ✅ TOGGLE TODO STATUS - INSTANT UI UPDATE
  void toggleTodoStatus(int index) async {
    if (index < 0 || index >= items.length) return;

    // Save original state for potential rollback
    final originalItem = Map<String, dynamic>.from(items[index]);
    final wasCompleted = originalItem['completed'] ?? false;
    final todoId = originalItem['_id']?.toString();

    if (todoId == null || todoId.isEmpty) {
      _showSnackBar('Cannot toggle - invalid todo ID', Colors.red);
      return;
    }

    // Immediately update UI
    setState(() {
      items[index]['completed'] = !wasCompleted;
      items[index]['updatedAt'] = DateTime.now().toIso8601String();

      if (!wasCompleted) {
        // Marking as completed
        items[index]['completedAt'] = DateTime.now().toIso8601String();
      } else {
        // Unchecking
        items[index]['completedAt'] = null;
      }

      // Re-sort list
      _sortTodos();
    });

    // Show feedback
    _showSnackBar(
      !wasCompleted ? '✅ Task completed!' : '↩️ Task marked incomplete',
      !wasCompleted ? Colors.green : Colors.blue,
      duration: Duration(seconds: 1),
    );

    // Sync with backend in background
    try {
      final response = await http
          .post(
            Uri.parse("http://localhost:5000/toggleTodo"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"id": todoId}),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true) {
          // print('✅ Synced toggle with backend');

          // ✅ REFRESH THE LIST AFTER CHECK/UNCHECK
          await getTodoList(userId!);
        } else {
          // print('⚠️ Backend returned error: ${jsonResponse['message']}');
        }
      } else {
        // print('⚠️ Sync failed with status: ${response.statusCode}');
      }
    } catch (e) {
      // print('⚠️ Background sync failed: $e');
    }
  }

  void _sortTodos() {
    setState(() {
      items.sort((a, b) {
        bool aCompleted = a['completed'] ?? false;
        bool bCompleted = b['completed'] ?? false;

        // Incomplete tasks first
        if (aCompleted != bCompleted) {
          return aCompleted ? 1 : -1;
        }

        // Then sort by date (newest first)
        DateTime aDate = DateTime.parse(
          a['completedAt'] ??
              a['createdAt'] ??
              DateTime.now().toIso8601String(),
        );
        DateTime bDate = DateTime.parse(
          b['completedAt'] ??
              b['createdAt'] ??
              DateTime.now().toIso8601String(),
        );
        return bDate.compareTo(aDate);
      });
    });
  }

  Future<void> getTodoList(String userId) async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      errorMessage = null;
    });

    try {
      // print('📋 Fetching todos for user: $userId');

      var response = await http
          .get(
            Uri.parse("http://localhost:5000/getUserTodoList?userId=$userId"),
            headers: {"Accept": "application/json"},
          )
          .timeout(Duration(seconds: 10));

      // print('📥 Todos response: ${response.statusCode}');

      if (_isHtmlResponse(response.body)) {
        throw FormatException(
          'Server returned HTML. Backend might not be running.',
        );
      }

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == true) {
          setState(() {
            items = jsonResponse['success'] ?? [];
            _sortTodos();
          });
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load todos');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on FormatException catch (e) {
      setState(() {
        errorMessage = 'Server error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load todos: ${e.toString()}';
      });
    } finally {
      setState(() {
        isRefreshing = false;
        isLoading = false;
      });
    }
  }

  Future<void> deleteItem(String id, String title) async {
    if (id.isEmpty) {
      _showSnackBar('Cannot delete - Something went wrong', Colors.red);
      return;
    }

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Task'),
            content: Text('Delete "$title"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Show loading
    _showSnackBar('Deleting task...', Colors.grey);

    try {
      final response = await http
          .post(
            Uri.parse("http://localhost:5000/deleteTodo"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"id": id}),
          )
          .timeout(Duration(seconds: 10));

      if (_isHtmlResponse(response.body)) {
        throw FormatException('Server returned HTML instead of JSON');
      }

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        // Remove from local list
        setState(() {
          items.removeWhere((item) => item['_id'] == id);
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('🗑️ Task deleted successfully', Colors.green);

        // ✅ REFRESH LIST AFTER DELETE
        await getTodoList(userId!);
      } else {
        final msg = jsonResponse['message'] ?? 'Delete failed';
        throw Exception(msg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('Failed to delete: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration ?? Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ✅ Extract username from email (text before @)
  String _getUsernameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email;

    // Capitalize first letter of each word
    String username = email.substring(0, atIndex);
    List<String> parts = username.split('.');
    parts =
        parts.map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        }).toList();

    return parts.join(' ');
  }

  // ✅ Logout function
  // ✅ Logout function - using callback
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Call the logout callback
    widget.onLogout();
  }
@override
  Widget build(BuildContext context) {
    final completedCount =
        items.where((item) => item['completed'] == true).length;
    final totalCount = items.length;
    final username = _getUsernameFromEmail(emailId);

    // ✅ ADD THIS GLOBAL KEY
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey, // ✅ ASSIGN KEY TO SCAFFOLD
      backgroundColor: Colors.lightBlueAccent,
      drawer: _buildDrawer(username),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SIMPLIFIED HEADER SECTION
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 25.0,
              right: 25.0,
              bottom: 25.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ✅ Hamburger menu icon - FIXED
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white, size: 28),
                      onPressed: () {
                        // ✅ USE THE SCAFFOLD KEY
                        scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your daily tasks',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (errorMessage != null) ...[
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ✅ SIMPLIFIED TODO LIST SECTION
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ✅ SIMPLIFIED LIST HEADER - Only shows "Your Tasks X/Y"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$completedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Todo List
                  Expanded(
                    child:
                        isLoading
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.lightBlueAccent,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    'Loading your tasks...',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                            : items.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'No tasks yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Add your first task to get started!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed:
                                        () => _displayTextInputDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightBlueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Create First Task',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : RefreshIndicator(
                              onRefresh:
                                  userId != null
                                      ? () => getTodoList(userId!)
                                      : () async {},
                              color: Colors.lightBlueAccent,
                              child: ListView.builder(
                                physics: AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, int index) {
                                  final item = items[index];
                                  final isCompleted =
                                      item['completed'] ?? false;
                                  final title =
                                      item['title']?.toString() ?? 'Untitled';
                                  final description =
                                      item['desc']?.toString() ??
                                      item['description']?.toString() ??
                                      '';
                                  final createdAt = item['createdAt'];
                                  final completedAt = item['completedAt'];

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Slidable(
                                        key: Key(
                                          item['_id']?.toString() ??
                                              '${index}_$title',
                                        ),
                                        endActionPane: ActionPane(
                                          motion: ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed: (context) async {
                                                final id =
                                                    item['_id']?.toString();
                                                if (id != null) {
                                                  await deleteItem(id, title);
                                                }
                                              },
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete,
                                              label: 'Delete',
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(12),
                                                bottomRight: Radius.circular(
                                                  12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isCompleted
                                                    ? Colors.grey[50]
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isCompleted
                                                      ? Colors.green[100]!
                                                      : Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                            leading: GestureDetector(
                                              onTap:
                                                  () => toggleTodoStatus(index),
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 300,
                                                ),
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color:
                                                      isCompleted
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                  border: Border.all(
                                                    color:
                                                        isCompleted
                                                            ? Colors.green
                                                            : Colors.grey[400]!,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow:
                                                      isCompleted
                                                          ? [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .green
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 6,
                                                              spreadRadius: 1,
                                                            ),
                                                          ]
                                                          : null,
                                                ),
                                                child: Center(
                                                  child:
                                                      isCompleted
                                                          ? Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 20,
                                                          )
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    isCompleted
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : TextDecoration.none,
                                                color:
                                                    isCompleted
                                                        ? Colors.grey[600]
                                                        : Colors.grey[800],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (description.isNotEmpty)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 4,
                                                    ),
                                                    child: Text(
                                                      description,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        decoration:
                                                            isCompleted
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : TextDecoration
                                                                    .none,
                                                        color:
                                                            isCompleted
                                                                ? Colors
                                                                    .grey[500]
                                                                : Colors
                                                                    .grey[600],
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.grey[400],
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      isCompleted &&
                                                              completedAt !=
                                                                  null
                                                          ? 'Completed ${_formatDate(completedAt)}'
                                                          : 'Created ${_formatDate(createdAt)}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            isCompleted
                                                                ? Colors
                                                                    .green[600]
                                                                : Colors
                                                                    .grey[500],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(
                                                isCompleted
                                                    ? Icons.undo
                                                    : Icons.done_all,
                                                color:
                                                    isCompleted
                                                        ? Colors.blue
                                                        : Colors.grey[600],
                                                size: 22,
                                              ),
                                              onPressed:
                                                  () => toggleTodoStatus(index),
                                              tooltip:
                                                  isCompleted
                                                      ? 'Mark as incomplete'
                                                      : 'Mark as complete',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        tooltip: 'Add New Task',
        backgroundColor: Colors.white,
        elevation: 4,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.lightBlueAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // ✅ Build Drawer with user info
  // ✅ Build Drawer with user info - UPDATED VERSION
  Widget _buildDrawer(String username) {
    return Drawer(
      child: Column(
        children: [
          // ✅ User info section - FIXED VERSION
          UserAccountsDrawerHeader(
            accountName: Text(
              username,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              emailId ?? 'No email',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ),
            decoration: BoxDecoration(color: Colors.lightBlueAccent),
          ),

          // ✅ Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.person, color: Colors.lightBlueAccent),
                  title: Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add profile navigation here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.lightBlueAccent),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add settings navigation here
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.lightBlueAccent),
                  title: Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add help navigation here
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.lightBlueAccent),
                  title: Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add about navigation here
                  },
                ),
              ],
            ),
          ),

          // ✅ Logout button
          Container(
            padding: EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.logout, size: 20),
              label: Text('Logout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add New Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _todoTitle,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Task Title *",
                      hintText: "What needs to be done?",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(
                        Icons.title,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _todoDesc,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                      hintText: "Add details (optional)...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Icon(
                        Icons.description,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : addTodo,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.lightBlueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    "Add Task",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
