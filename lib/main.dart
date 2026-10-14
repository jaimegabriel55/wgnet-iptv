import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
      },
      child: MaterialApp(
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
          focusColor: const Color(0xFF007ACC).withOpacity(0.5),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
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
                  autofocus: true,
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
  List<dynamic> _filteredChannels = [];
  bool _isLoadingChannels = true;
  dynamic _selectedChannel;
  final TextEditingController _searchController = TextEditingController();

  late final Player _player;
  late final VideoController _videoController;
  bool _isFullScreen = false;

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);
    _loadChannels();
    _searchController.addListener(_filterChannels);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    _hideTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterChannels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChannels = _channels;
      } else {
        _filteredChannels = _channels.where((channel) {
          final name = (channel['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

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
          _filteredChannels = decodedData;
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
            _filteredChannels = data;
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

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
      _showControls = true;
    });
    _startHideTimer();
  }

  void _exitFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
    _hideTimer?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullScreen) {
          _exitFullScreen();
        }
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                title: Text(
                  _selectedChannel != null ? 'Reproduciendo: ${_selectedChannel['name']}' : 'Micanal IPTV - Canales',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  _DpadButton(
                    onPressed: () => _loadChannels(forceRefresh: true),
                    icon: Icons.refresh,
                    label: 'Actualizar',
                    textColor: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  _DpadButton(
                    onPressed: _enterFullScreen,
                    icon: Icons.fullscreen,
                    label: 'Pantalla completa',
                    textColor: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  _DpadButton(
                    onPressed: _logout,
                    icon: Icons.logout,
                    label: 'Cerrar Sesión',
                    textColor: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                ],
              ),
        body: _isLoadingChannels
            ? const Center(child: CircularProgressIndicator())
            : _channels.isEmpty
                ? const Center(child: Text('No se encontraron canales'))
                : Stack(
                    children: [
                      // 1. REPRODUCTOR AL FONDO
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: Video(
                            controller: _videoController,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // 2. LISTA DE CANALES FLOTANTE Y NAVEGABLE CON D-PAD
                      if (!_isFullScreen)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          width: MediaQuery.of(context).size.width * 0.38,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              border: const Border(right: BorderSide(color: Colors.white12)),
                            ),
                            child: Column(
                              children: [
                                // Barra de Búsqueda
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar canal...',
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            )
                                          : null,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.white24),
                                      ),
                                      filled: true,
                                      fillColor: Colors.black38,
                                    ),
                                  ),
                                ),
                                // Lista filtrada con enfoque de D-Pad
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _filteredChannels.length,
                                    itemBuilder: (context, index) {
                                      final channel = _filteredChannels[index];
                                      final isSelected = _selectedChannel != null && _selectedChannel['stream_id'] == channel['stream_id'];

                                      return _ChannelTileDpad(
                                        key: ValueKey(channel['stream_id']),
                                        channel: channel,
                                        isSelected: isSelected,
                                        isFirst: index == 0,
                                        onTap: () => _selectChannel(channel),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // 3. CAPA DE GESTOS EN PANTALLA COMPLETA
                      if (_isFullScreen)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControlsVisibility,
                          child: const SizedBox.expand(),
                        ),

                      // 4. BOTÓN VOLVER EN PANTALLA COMPLETA
                      if (_isFullScreen && _showControls)
                        Positioned(
                          top: 24,
                          right: 24,
                          child: _DpadButton(
                            onPressed: _exitFullScreen,
                            icon: Icons.arrow_back,
                            label: 'Volver a Canales',
                            textColor: Colors.white,
                            backgroundColor: Colors.black87,
                            isBig: true,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

// Widget individual para los canales con soporte D-Pad
class _ChannelTileDpad extends StatefulWidget {
  final dynamic channel;
  final bool isSelected;
  final bool isFirst;
  final VoidCallback onTap;

  const _ChannelTileDpad({
    super.key,
    required this.channel,
    required this.isSelected,
    required this.isFirst,
    required this.onTap,
  });

  @override
  State<_ChannelTileDpad> createState() => _ChannelTileDpadState();
}

class _ChannelTileDpadState extends State<_ChannelTileDpad> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = widget.channel['stream_icon'];

    return InkWell(
      focusNode: _focusNode,
      autofocus: widget.isFirst,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: _hasFocus
              ? const Color(0xFF007ACC).withOpacity(0.85)
              : widget.isSelected
                  ? const Color(0xFF007ACC).withOpacity(0.4)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hasFocus ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: const Color(0xFF007ACC).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: (iconUrl != null && iconUrl.toString().isNotEmpty)
                ? Image.network(
                    iconUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.black38,
                      child: const Icon(Icons.tv, size: 22, color: Colors.white54),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: Colors.black38,
                    child: const Icon(Icons.tv, size: 22, color: Colors.white54),
                  ),
          ),
          title: Text(
            widget.channel['name'] ?? 'Canal sin nombre',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _hasFocus ? 15 : 14,
              color: Colors.white,
            ),
          ),
          trailing: _hasFocus
              ? const Icon(Icons.play_arrow, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}

// Widget de Botón Optimizado para Control Remoto / D-Pad
class _DpadButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color textColor;
  final Color? backgroundColor;
  final bool isBig;

  const _DpadButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.textColor,
    this.backgroundColor,
    this.isBig = false,
  });

  @override
  State<_DpadButton> createState() => _DpadButtonState();
}

class _DpadButtonState extends State<_DpadButton> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: _focusNode,
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hasFocus
              ? const Color(0xFF007ACC)
              : (widget.backgroundColor ?? Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hasFocus ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: const Color(0xFF007ACC).withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isBig ? 16 : 10,
          vertical: widget.isBig ? 12 : 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: widget.isBig ? 20 : 18,
              color: _hasFocus ? Colors.white : widget.textColor,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: _hasFocus ? Colors.white : widget.textColor,
                fontSize: widget.isBig ? 14 : 13,
                fontWeight: _hasFocus ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
