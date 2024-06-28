import 'package:contactlink/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../services/database_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _arquivoPath;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _arquivoPath = result.files.single.path;
      });
      _scrollToBottom();
    }
  }

  void _saveUser() async {
    String name = _nameController.text;
    String pass = _passController.text;
    String? photo = _arquivoPath;

    User newUser = User(name: name, pass: pass, photo: photo);
    // salva no banco de dados
    await _dbHelper.saveUser(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário salvo com sucesso!')));
    _clearScreen();
  }

  void _clearScreen() {
    setState(() {
      _nameController.clear();
      _passController.clear();
      _arquivoPath = null;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return Text('Usuários - Adicionar ou Remover login ${state.username}');
            }
            return const Text('Usuários');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _arquivoPath != null
                  ? AnimatedBuilder(
                      animation: _animation,
                      child: Container(
                        width: 200.0,
                        height: 200.0,
                        color: Colors.green,
                        child: Image.file(
                          File(_arquivoPath!),
                          width: 350,
                          height: 350,
                        ),
                      ),
                      builder: (BuildContext context, Widget? child) {
                        return Transform.rotate(
                          angle: _animation.value * math.pi,
                          child: child,
                        );
                      },
                    )
                  : Container(),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Selecione o arquivo de imagem'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _arquivoPath != null ? _saveUser : null,
                child: const Text('Salvar Usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
