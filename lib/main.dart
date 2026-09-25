import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const WgnetIptvApp());
}

class WgnetIptvApp extends StatelessWidget {
  const WgnetIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WGNet IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121824),
      ),
      home: const PantallaConexion(),
    );
  }
}

class PantallaConexion extends StatefulWidget {
  const PantallaConexion({super.key});

  @override
  State<PantallaConexion> createState() => _PantallaConexionState();
}

class _PantallaConexionState extends State<PantallaConexion> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _conectar() async {
    final url = _urlController.text.trim();
    final usuario = _userController.text.trim();
    final password = _passController.text.trim();

    if (url.isEmpty || usuario.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos obligatorios.')),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final uri = Uri.parse('$url/player_api.php?username=$usuario&password=$password');
      final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        final userInfo = datos['user_info'];

        if (userInfo != null && userInfo['auth'] == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaCanales(serverUrl: url, username: usuario, password: password),
            ),
          );
        } else {
          _mostrarError('Credenciales incorrectas o cuenta inactiva.');
        }
      } else {
        _mostrarError('No se pudo conectar con el servidor (Error ${respuesta.statusCode})');
      }
    } catch (e) {
      _mostrarError('Error de conexión: Verifica la URL del servidor.');
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WGNet - Xtream IPTV'),
        backgroundColor: const Color(0xFF1B2230),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2230),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Xtream credentials',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Introduce los datos de tu servidor IPTV.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Playlist title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'Server URL* (ej: http://tu-servidor:8080)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Username*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password*', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _conectar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Añadir Lista y Ver Canales', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PantallaCanales extends StatefulWidget {
  final String serverUrl;
  final String username;
  final String password;

  const PantallaCanales({super.key, required this.serverUrl, required this.username, required this.password});

  @override
  State<PantallaCanales> createState() => _PantallaCanalesState();
}

class _PantallaCanalesState extends State<PantallaCanales> {
  List canales = [];
  bool cargandoCanales = true;

  @override
  void initState() {
    super.initState();
    _cargarCanalesEnVivo();
  }

  Future<void> _cargarCanalesEnVivo() async {
    try {
      final uri = Uri.parse('${widget.serverUrl}/player_api.php?username=${widget.username}&password=${widget.password}&action=get_live_streams');
      final respuesta = await http.get(uri);

      if (respuesta.statusCode == 200) {
        final List datos = jsonDecode(respuesta.body);
        setState(() {
          canales = datos;
          cargandoCanales = false;
        });
      }
    } catch (e) {
      setState(() {
        cargandoCanales = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canales en Vivo - WGNet'),
        backgroundColor: const Color(0xFF1B2230),
      ),
      body: cargandoCanales
          ? const Center(child: CircularProgressIndicator())
          : canales.isEmpty
              ? const Center(child: Text('No se encontraron canales disponibles.'))
              : ListView.builder(
                  itemCount: canales.length,
                  itemBuilder: (context, index) {
                    final canal = canales[index];
                    final streamId = canal['stream_id'];
                    final nombreCanal = canal['name'] ?? 'Sin nombre';

                    return ListTile(
                      leading: const Icon(Icons.tv, color: Colors.blueAccent),
                      title: Text(nombreCanal),
                      subtitle: Text('ID: $streamId'),
                      trailing: const Icon(Icons.play_arrow, color: Colors.green),
                      onTap: () {
                        // Construimos la URL del stream en vivo de Xtream Codes
                        final urlStream = '${widget.serverUrl}/live/${widget.username}/${widget.password}/$streamId.m3u8';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaReproductor(nombreCanal: nombreCanal, urlStream: urlStream),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class PantallaReproductor extends StatefulWidget {
  final String nombreCanal;
  final String urlStream;

  const PantallaReproductor({super.key, required this.nombreCanal, required this.urlStream});

  @override
  State<PantallaReproductor> createState() => _PantallaReproductorState();
}

class _PantallaReproductorState extends State<PantallaReproductor> {
  late VideoPlayerController _controller;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.urlStream))
      ..initialize().then((_) {
        setState(() {
          _inicializado = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreCanal),
        backgroundColor: const Color(0xFF1B2230),
      ),
      body: Center(
        child: _inicializado
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
