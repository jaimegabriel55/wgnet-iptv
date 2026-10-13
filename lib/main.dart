import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Necesario para el Timer
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const WgnetIptvApp());
}

class WgnetIptvApp extends StatelessWidget {
  const WgnetIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micanal IPTV',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007ACC),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _fixedBaseUrl = 'http://160.238.185.88:25461';

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('saved_username');
    final password = prefs.getString('saved_password');

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (username != null && username.isNotEmpty && password != null && password.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChannelsScreen(
            baseUrl: _fixedBaseUrl,
            username: username,
            password: password,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF007ACC)),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String _fixedBaseUrl = 'http://160.238.185.88:25461';
  
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _userController.text.trim();
    final password = _passController.text.trim();
    final apiLoginUrl = '$_fixedBaseUrl/player_api.php?username=$username&password=$password';

    try {
      final response = await http.get(Uri.parse(apiLoginUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['user_info'] != null && data['user_info']['auth'] == 1) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_username', username);
          await prefs.setString('saved_password', password);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChannelsScreen(baseUrl: _fixedBaseUrl, username: username, password: password),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Credenciales inválidas o cuenta inactiva.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error de conexión (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo conectar al servidor.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo.jpg',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, size: 50, color: Color(0xFF007ACC)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Micanal IPTV',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007ACC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChannelsScreen extends StatefulWidget {
  final String baseUrl;
  final String username;
  final String password;

  const ChannelsScreen({super.key, required this.baseUrl, required this.username, required this.password});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<dynamic> _channels = [];
  bool _isLoadingChannels = true;
  dynamic _selectedChannel;

  late final Player _player;
  late final VideoController _videoController;
  bool _isFullScreen = false;

  // NUEVO: Variables para controlar la visibilidad del botón en pantalla completa
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);
    _loadChannels();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    _hideTimer?.cancel(); // Cancelamos el timer al cerrar la pantalla
    super.dispose();
  }

  // NUEVO: Función para mostrar controles e iniciar el temporizador de ocultado
  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  // NUEVO: Temporizador que oculta los controles tras 3 segundos de inactividad
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isFullScreen) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _loadChannels({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingChannels = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final cachedChannels = prefs.getString('cached_channels');

    if (!forceRefresh && cachedChannels != null && cachedChannels.isNotEmpty) {
      try {
        final List<dynamic> decodedData = json.decode(cachedChannels);
        setState(() {
          _channels = decodedData;
          _isLoadingChannels = false;
          if (_channels.isNotEmpty) {
            _selectChannel(_channels[0]);
          }
        });
        return;
      } catch (e) {
        // Error en caché
      }
    }

    await _fetchChannelsFromNetwork();
  }

  Future<void> _fetchChannelsFromNetwork() async {
    final url = '${widget.baseUrl}/player_api.php?username=${widget.username}&password=${widget.password}&action=get_live_streams';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_channels', json.encode(data));

          setState(() {
            _channels = data;
            _isLoadingChannels = false;
            if (_channels.isNotEmpty) {
              _selectChannel(_channels[0]);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingChannels = false;
      });
    }
  }

  void _selectChannel(dynamic channel) async {
    setState(() {
      _selectedChannel = channel;
    });
    await _player.stop();
    
    final streamId = channel['stream_id'];
    final streamUrl = '${widget.baseUrl}/live/${widget.username}/${widget.password}/$streamId.m3u8';
    _player.open(Media(streamUrl));
  }

  Future<void> _logout() async {
    await _player.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove('cached_channels');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Modificada: Al entrar en pantalla completa, forzamos que se muestren los controles inicialmente
  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
      _showControls = true; // Forzamos mostrar al entrar
    });
    _startHideTimer(); // Iniciamos el timer para ocultarlo
  }

  // Modificada: Al salir, cancelamos el timer
  void _exitFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
    _hideTimer?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullScreen) {
          _exitFullScreen(); // Usamos la función modificada
        }
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                title: Text(_selectedChannel != null ? 'Reproduciendo: ${_selectedChannel['name']}' : 'Micanal IPTV - Canales'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadChannels(forceRefresh: true),
                    tooltip: 'Actualizar lista de canales',
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: _enterFullScreen, // Usamos la función modificada
                    tooltip: 'Pantalla completa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _logout,
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
        body: _isLoadingChannels
            ? const Center(child: CircularProgressIndicator())
            : _channels.isEmpty
                ? const Center(child: Text('No se encontraron canales'))
                : Stack(
                    children: [
                      Row(
                        children: [
                          if (!_isFullScreen)
                            Expanded(
                              flex: 4,
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: Colors.white12)),
                                ),
                                child: ListView.builder(
                                  itemCount: _channels.length,
                                  itemBuilder: (context, index) {
                                    final channel = _channels[index];
                                    final isSelected = _selectedChannel != null && _selectedChannel['stream_id'] == channel['stream_id'];
                                    return ListTile(
                                      selected: isSelected,
                                      selectedTileColor: const Color(0xFF007ACC).withOpacity(0.3),
                                      leading: channel['stream_icon'] != null && channel['stream_icon'].toString().isNotEmpty
                                          ? Image.network(
                                              channel['stream_icon'],
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.tv, size: 40),
                                            )
                                          : const Icon(Icons.tv, size: 40),
                                      title: Text(
                                        channel['name'] ?? 'Canal sin nombre',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _selectChannel(channel),
                                    );
                                  },
                                ),
                              ),
                            ),
                          Expanded(
                            flex: 6,
                            child: Container(
                              color: Colors.black,
                              child: Video(
                                controller: _videoController,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // NUEVO: Capa transparente para detectar toques en modo pantalla completa
                      if (_isFullScreen)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControlsVisibility, // Muestra/oculta controles al tocar
                          child: const SizedBox.expand(),
                        ),

                      // Botón flotante modificado con visibilidad controlada
                      if (_isFullScreen && _showControls) // Solo se muestra si ambos son verdaderos
                        Positioned(
                          top: 24,
                          right: 24,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54, // Más sutil
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.white12),
                              ),
                            ),
                            onPressed: _exitFullScreen, // Usamos la función modificada
                            icon: const Icon(Icons.arrow_back, color: Colors.white), // Cambiado a flecha de volver
                            label: const Text(
                              'Volver a Canales', // Texto más descriptivo
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
