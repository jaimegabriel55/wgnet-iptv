import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
      title: 'WGNet IPTV',
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
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final String _fixedBaseUrl = 'http://iptv.networkpy.com:25461';
  
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
                // Logo de la app en la pantalla de login
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
                  'WGNet IPTV',
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

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);
    _fetchChannels();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels() async {
    final url = '${widget.baseUrl}/player_api.php?username=${widget.username}&password=${widget.password}&action=get_live_streams';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
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

  void _selectChannel(dynamic channel) {
    setState(() {
      _selectedChannel = channel;
    });
    final streamId = channel['stream_id'];
    final streamUrl = '${widget.baseUrl}/live/${widget.username}/${widget.password}/$streamId.m3u8';
    _player.open(Media(streamUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(_selectedChannel != null ? 'Reproduciendo: ${_selectedChannel['name']}' : 'WGNet IPTV - Canales'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = true;
                    });
                  },
                  tooltip: 'Pantalla completa',
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
                          child: GestureDetector(
                            onDoubleTap: () {
                              setState(() {
                                _isFullScreen = !_isFullScreen;
                              });
                            },
                            child: Container(
                              color: Colors.black,
                              child: Video(
                                controller: _videoController,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isFullScreen)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                          onPressed: () {
                            setState(() {
                              _isFullScreen = false;
                            });
                          },
                          child: const Icon(Icons.fullscreen_exit),
                        ),
                      ),
                  ],
                ),
    );
  }
}
