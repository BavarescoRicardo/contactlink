import 'package:contactlink/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _photoPath;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _takePicture() async {
    if (_cameraController.value.isInitialized) {
      XFile picture = await _cameraController.takePicture();
      setState(() {
        _photoPath = picture.path;
      });
      _scrollToBottom();
    }
  }

  void _saveUser() async {
    String name = _nameController.text;
    String pass = _passController.text;
    String? photo = _photoPath;

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
      _photoPath = null;
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
              _isCameraInitialized
                  ? AspectRatio(
                      aspectRatio: _cameraController.value.aspectRatio,
                      child: CameraPreview(_cameraController),
                    )
                  : Container(),
              const SizedBox(height: 20),
              _photoPath != null ? Image.file(File(_photoPath!)) : Container(),
              ElevatedButton(
                  onPressed: _takePicture, child: const Text('Capturar Foto')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _photoPath != null ? _saveUser : null,
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
    _cameraController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // TODO: adicionar um botão e chamar uma tela sobre com informações de vocês
}
