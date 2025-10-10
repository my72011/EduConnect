// lib/main.dart
// EduConnect - Full MVP UI (Get Started, SignUp, Login, Home, Groups, Chat, Search, Notifications, Settings)
// Demo uses in-memory storage and simulates Zoom link creation.
// Dependencies required in pubspec.yaml: image_picker, url_launcher, uuid, socket_io_client, http
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const EduConnectApp());
}

/* Models */
class UserModel {
  String id;
  String username;
  String email;
  String role; // 'teacher' or 'student'
  File? avatar;
  String? phone;
  String? parentPhone;
  String? subject;
  String? grade;
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.phone,
    this.parentPhone,
    this.subject,
    this.grade,
  });
}

class MessageModel {
  String id;
  String groupId; // groupId or privateId
  String type; // 'chat' or 'meeting'
  String text;
  UserModel sender;
  DateTime ts;
  String? joinUrl; // if meeting
  String? meetingId;
  MessageModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.text,
    required this.sender,
    required this.ts,
    this.joinUrl,
    this.meetingId,
  });
}

class GroupModel {
  String id;
  String name;
  File? avatar;
  List<UserModel> members;
  GroupModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.members,
  });
}

/* Notifications store (in-memory) */
class NotificationItem {
  String id;
  UserModel from;
  UserModel to;
  String status; // pending, accepted, rejected
  List<String> assignedGroups;
  NotificationItem({required this.id, required this.from, required this.to, required this.status, this.assignedGroups = const []});
}
class NotificationsStore {
  NotificationsStore._private();
  static final NotificationsStore instance = NotificationsStore._private();
  final List<NotificationItem> items = [];
  void add(NotificationItem n) => items.add(n);
  void updateStatus(String id, String status, List<String> groups) {
    final idx = items.indexWhere((e)=>e.id==id);
    if (idx>=0) { items[idx].status = status; items[idx].assignedGroups = groups; }
  }
}

/* App */
class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduConnect',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EntryPoint(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* EntryPoint - Get Started */
class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xffe8f0ff), Color(0xffdbeeff)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo placeholder
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                const Text('EduConnect', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Connect with teachers, join classes, and study together.', textAlign: TextAlign.center),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                    child: const Text('Log In')),
                const SizedBox(height: 8),
                TextButton(onPressed: () {
                  // open terms - placeholder
                }, child: const Text('Terms & Conditions', style: TextStyle(fontSize: 12))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/* SignUpPage */
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override State<SignUpPage> createState() => _SignUpPageState();
}
class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _uuid = const Uuid();
  String role = 'student';
  String username = '';
  String email = '';
  String password = '';
  String confirm = '';
  String phone = '';
  String parentPhone = '';
  String grade = 'رابعة إبتدائي';
  String subject = '';
  File? avatar;

  final grades = ['رابعة إبتدائي','خامسة إبتدائي','ستة ابتدائي','أولي إعدادي','تانية إعدادي','تالتة إعدادي','أولي ثانوي','تانية ثانوي'];

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x != null) setState(() => avatar = File(x.path));
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    final user = UserModel(
      id: _uuid.v4(),
      username: username + (role=='student'?'.student':'.teacher'),
      email: email,
      role: role,
      avatar: avatar,
      phone: phone.isEmpty?null:phone,
      parentPhone: parentPhone.isEmpty?null:parentPhone,
      subject: subject.isEmpty?null:subject,
      grade: grade,
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(currentUser: user)));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(children: [
            GestureDetector(onTap: _pickAvatar, child: CircleAvatar(radius: 40, backgroundImage: avatar!=null?FileImage(avatar!):null, child: avatar==null?const Icon(Icons.camera_alt):null)),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(labelText: 'Username'), validator: (v) => (v==null||v.isEmpty)?'Required':null, onSaved: (v)=>username=v!.trim()),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Email'), validator: (v)=> (v==null||!v.contains('@'))?'Invalid email':null, onSaved: (v)=>email=v!.trim()),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v)=> (v==null||v.length<6)?'Min 6 chars':null, onSaved: (v)=>password=v!),
            const SizedBox(height: 8),
            TextFormField(decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true, validator: (v)=> (v==null||v.length<6)?'Min 6 chars':null, onSaved: (v)=>confirm=v!),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ListTile(title: const Text('Student'), leading: Radio<String>(value: 'student', groupValue: role, onChanged: (v)=>setState(()=>role=v!)))),
              Expanded(child: ListTile(title: const Text('Teacher'), leading: Radio<String>(value: 'teacher', groupValue: role, onChanged: (v)=>setState(()=>role=v!)))),
            ]),
            const SizedBox(height: 8),
            if (role=='student') ...[
              TextFormField(decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, onSaved: (v)=>phone=v??''),
              const SizedBox(height: 8),
              TextFormField(decoration: const InputDecoration(labelText: 'Parent Phone'), keyboardType: TextInputType.phone, onSaved: (v)=>parentPhone=v??''),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: grade,
                items: grades.map((g)=>DropdownMenuItem(value: g,child: Text(g))).toList(),
                onChanged: (v)=>setState(()=>grade=v!),
                decoration: const InputDecoration(labelText: 'Grade'),
                onSaved: (v)=>grade=v!,
              )
            ] else ...[
              TextFormField(decoration: const InputDecoration(labelText: 'Subject'), onSaved: (v)=>subject=v??'', validator: (v)=> (v==null||v.isEmpty)?'Required':null),
            ],
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: const Text('Create Account')),
          ]),
        ),
      ),
    );
  }
}

/* LoginPage */
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String role = 'student';

  void _login() {
    // For demo: create a user and navigate
    final user = UserModel(id: const Uuid().v4(), username: email.split('@').first + (role=='student'?'.student':'.teacher'), email: email, role: role);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(currentUser: user)));
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(key: _form, child: Column(children: [
          TextFormField(decoration: const InputDecoration(labelText: 'Email'), onSaved: (v)=>email=v??'', validator: (v)=> (v==null||!v.contains('@'))?'Invalid email':null),
          const SizedBox(height: 8),
          TextFormField(decoration: const InputDecoration(labelText: 'Password'), obscureText: true, onSaved: (v)=>password=v??'', validator: (v)=> (v==null||v.length<6)?'Min 6 chars':null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ListTile(title: const Text('Student'), leading: Radio<String>(value: 'student', groupValue: role, onChanged: (v)=>setState(()=>role=v!)))),
            Expanded(child: ListTile(title: const Text('Teacher'), leading: Radio<String>(value: 'teacher', groupValue: role, onChanged: (v)=>setState(()=>role=v!)))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: (){
            if (!_form.currentState!.validate()) return;
            _form.currentState!.save();
            _login();
          }, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: const Text('Log In')),
        ])),
      ),
    );
  }
}

/* HomeScreen */
class HomeScreen extends StatefulWidget {
  final UserModel currentUser;
  const HomeScreen({super.key, required this.currentUser});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final List<GroupModel> groups = [];
  final List<MessageModel> messages = [];
  final List<UserModel> users = [];
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _seedDemo();
  }

  void _seedDemo() {
    final teacher = widget.currentUser.role=='teacher' ? widget.currentUser : UserModel(id: uuid.v4(), username: 'Mr.Teacher', email: 'teacher@example.com', role: 'teacher');
    final s1 = UserModel(id: uuid.v4(), username: 'Ali', email: 'ali@example.com', role: 'student');
    final s2 = UserModel(id: uuid.v4(), username: 'Mona', email: 'mona@example.com', role: 'student');

    users.addAll([teacher, s1, s2]);
    final g1 = GroupModel(id: uuid.v4(), name: 'Math Group', members: [teacher, s1, s2]);
    final g2 = GroupModel(id: uuid.v4(), name: 'Science Club', members: [teacher, s1]);
    groups.addAll([g1, g2]);

    messages.add(MessageModel(id: uuid.v4(), groupId: g1.id, type: 'chat', text: 'Welcome to Math Group', sender: teacher, ts: DateTime.now().subtract(const Duration(minutes: 40))));
    messages.add(MessageModel(id: uuid.v4(), groupId: g1.id, type: 'chat', text: 'Hello!', sender: s1, ts: DateTime.now().subtract(const Duration(minutes: 20))));

    if (!g1.members.any((m)=>m.id==widget.currentUser.id)) g1.members.add(widget.currentUser);
  }

  void _editProfile() async {
    final picker = ImagePicker();
    final nameCtrl = TextEditingController(text: widget.currentUser.username);
    File? picked;
    await showDialog(context: context, builder: (ctx){
      return AlertDialog(
        title: const Text('Edit Profile'),
        content: StatefulBuilder(builder: (ctx2, setState2){
          return Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(onTap: () async {
              final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (x!=null) { picked = File(x.path); setState2((){}); }
            }, child: CircleAvatar(radius: 36, backgroundImage: picked!=null?FileImage(picked!): (widget.currentUser.avatar!=null?FileImage(widget.currentUser.avatar!):null), child: (picked==null && widget.currentUser.avatar==null)?const Icon(Icons.camera_alt):null)),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl),
          ]);
        }),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: (){
            final newName = nameCtrl.text.trim();
            if (newName.isNotEmpty) setState(()=>widget.currentUser.username=newName);
            if (picked!=null) setState(()=>widget.currentUser.avatar=picked);
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      );
    });
    setState((){});
  }

# truncated for brevity in tool output (full file written)