import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../models/contact.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _photoPath;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

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

  void _saveContact() async {
    String name = _nameController.text;
    String phone = _phoneController.text;
    String? photo = _photoPath;

    Contact newContact = Contact(name: name, phone: phone, photo: photo);
    // salva no banco de dados
    await _dbHelper.saveContact(newContact);
    // envia para o servidor
    await _apiService.sendContact(newContact);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato salvo com sucesso!')));
    _clearScreen();
  }

  void _clearScreen() {
    setState(() {
      _nameController.clear();
      _phoneController.clear();
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
              return Text('Home - Bem-vindo ${state.username}');
            }
            return const Text('Home');
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
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
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
                onPressed: _photoPath != null ? _saveContact : null,
                child: const Text('Salvar Contato'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/about'),
                child: const Text('Acessar Sobre'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/user'),
                child: const Text('Acessar Usuários'),
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
