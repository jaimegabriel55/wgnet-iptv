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
          builder: (context) => HomeScreen(
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
              builder: (context) => HomeScreen(baseUrl: _fixedBaseUrl, username: username, password: password),
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

// -----------------------------------------------------------------------------
// PANTALLA PRINCIPAL (DASHBOARD)
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String baseUrl;
  final String username;
  final String password;

  const HomeScreen({
    super.key,
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove('cached_channels');
    await prefs.remove('cached_movies');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _openLiveChannels() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelsScreen(
          baseUrl: widget.baseUrl,
          username: widget.username,
          password: widget.password,
        ),
      ),
    );
  }

  void _openMovies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviesScreen(
          baseUrl: widget.baseUrl,
          username: widget.username,
          password: widget.password,
        ),
      ),
    );
  }

  void _showFeatureNotice(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName estará disponible próximamente.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  String _getMonthName(int month) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final timeString = '${_formatTwoDigits(_now.hour)}:${_formatTwoDigits(_now.minute)}';
    final dateString = '${_now.day} ${_getMonthName(_now.month)} ${_now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // 1. ENCABEZADO SUPERIOR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.tv, size: 36, color: Color(0xFF007ACC)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Micanal IPTV',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),

                  // Cápsula de Info (Usuario / Servidor)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, size: 16, color: Color(0xFF007ACC)),
                        const SizedBox(width: 8),
                        Text(
                          'Usuario: ${widget.username}',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        const Text('•', style: TextStyle(color: Colors.white38)),
                        const SizedBox(width: 12),
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.greenAccent),
                        const SizedBox(width: 6),
                        const Text(
                          'Estado: Activo',
                          style: TextStyle(fontSize: 13, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),

                  // Reloj
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        dateString,
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. CUERPO DE TARJETAS PRINCIPALES
              Expanded(
                child: Row(
                  children: [
                    // Tarjeta Principal "En Vivo"
                    Expanded(
                      flex: 4,
                      child: _DashboardCard(
                        autofocus: true,
                        title: 'En vivo',
                        subtitle: 'Canales en transmisión directa',
                        icon: Icons.tv,
                        accentColor: const Color(0xFF007ACC),
                        gradientColors: [
                          const Color(0xFF007ACC).withOpacity(0.35),
                          const Color(0xFF004080).withOpacity(0.15),
                        ],
                        onTap: _openLiveChannels,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Sub-grilla para Películas y Series
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _DashboardCard(
                                    title: 'Películas',
                                    subtitle: 'Catálogo de cine bajo demanda',
                                    icon: Icons.movie_outlined,
                                    accentColor: Colors.purpleAccent,
                                    gradientColors: [
                                      Colors.purple.withOpacity(0.3),
                                      Colors.deepPurple.withOpacity(0.1),
                                    ],
                                    onTap: _openMovies,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _DashboardCard(
                                    title: 'Series',
                                    subtitle: 'Temporadas y episodios',
                                    icon: Icons.video_library_outlined,
                                    accentColor: Colors.cyanAccent,
                                    gradientColors: [
                                      Colors.cyan.withOpacity(0.25),
                                      Colors.teal.withOpacity(0.1),
                                    ],
                                    onTap: () => _showFeatureNotice('Series'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. BARRA INFERIOR DE ACCIONES
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DashboardActionButton(
                    icon: Icons.settings,
                    label: 'Configuración',
                    onTap: () => _showFeatureNotice('Configuración'),
                  ),
                  const SizedBox(width: 12),
                  _DashboardActionButton(
                    icon: Icons.switch_account,
                    label: 'Cambiar de usuario',
                    onTap: _logout,
                  ),
                  const SizedBox(width: 12),
                  _DashboardActionButton(
                    icon: Icons.refresh,
                    label: 'Recargar',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Actualizando datos del servidor...')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _DashboardActionButton(
                    icon: Icons.exit_to_app,
                    label: 'SALIR',
                    textColor: Colors.redAccent,
                    onTap: () => SystemNavigator.pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget de Tarjeta Principal con Enfoque D-Pad
class _DashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool autofocus;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
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
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: widget.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: _hasFocus ? Colors.white : Colors.white12,
            width: _hasFocus ? 2.5 : 1.0,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasFocus
                    ? widget.accentColor
                    : widget.accentColor.withOpacity(0.2),
              ),
              child: Icon(
                widget.icon,
                size: 48,
                color: _hasFocus ? Colors.white : widget.accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: _hasFocus
                    ? [Shadow(color: widget.accentColor, blurRadius: 10)]
                    : [],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de Botón Inferior con Enfoque D-Pad
class _DashboardActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const _DashboardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = Colors.white70,
  });

  @override
  State<_DashboardActionButton> createState() => _DashboardActionButtonState();
}

class _DashboardActionButtonState extends State<_DashboardActionButton> {
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
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hasFocus
              ? const Color(0xFF007ACC)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hasFocus ? Colors.white : Colors.white12,
            width: _hasFocus ? 2 : 1,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: const Color(0xFF007ACC).withOpacity(0.6),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 18, color: _hasFocus ? Colors.white : widget.textColor),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: _hasFocus ? FontWeight.bold : FontWeight.w500,
                color: _hasFocus ? Colors.white : widget.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA DE PELÍCULAS (VOD)
// -----------------------------------------------------------------------------
class MoviesScreen extends StatefulWidget {
  final String baseUrl;
  final String username;
  final String password;

  const MoviesScreen({
    super.key,
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  List<dynamic> _movies = [];
  List<dynamic> _filteredMovies = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(_filterMovies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMovies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMovies = _movies;
      } else {
        _filteredMovies = _movies.where((movie) {
          final name = (movie['name'] ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadMovies({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_movies');

    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(cached);
        setState(() {
          _movies = decoded;
          _filteredMovies = decoded;
          _isLoading = false;
        });
        return;
      } catch (e) {
        // Ignorar error de caché
      }
    }

    await _fetchMoviesFromNetwork();
  }

  Future<void> _fetchMoviesFromNetwork() async {
    final url = '${widget.baseUrl}/player_api.php?username=${widget.username}&password=${widget.password}&action=get_vod_streams';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_movies', json.encode(data));

          setState(() {
            _movies = data;
            _filteredMovies = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playMovie(dynamic movie) {
    final streamId = movie['stream_id'];
    final containerExtension = movie['container_extension'] ?? 'mp4';
    final movieUrl = '${widget.baseUrl}/movie/${widget.username}/${widget.password}/$streamId.$containerExtension';
    final movieName = movie['name'] ?? 'Película';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePlayerScreen(
          movieUrl: movieUrl,
          movieName: movieName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Películas - Catálogo VOD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Catálogo',
            onPressed: () => _loadMovies(forceRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda superior
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar película por título...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                filled: true,
                fillColor: Colors.black45,
              ),
            ),
          ),
          
          // Contenido principal (Grid de Pósters)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF007ACC)))
                : _filteredMovies.isEmpty
                    ? const Center(child: Text('No hay películas disponibles en el servidor.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 columnas de pósters para TV Box / Paisaje
                          childAspectRatio: 0.65, // Proporción de póster de cine
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredMovies.length,
                        itemBuilder: (context, index) {
                          final movie = _filteredMovies[index];
                          return _MoviePosterTile(
                            movie: movie,
                            autofocus: index == 0,
                            onTap: () => _playMovie(movie),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Tarjeta Individual de Póster con Enfoque D-Pad
class _MoviePosterTile extends StatefulWidget {
  final dynamic movie;
  final bool autofocus;
  final VoidCallback onTap;

  const _MoviePosterTile({
    required this.movie,
    required this.autofocus,
    required this.onTap,
  });

  @override
  State<_MoviePosterTile> createState() => _MoviePosterTileState();
}

class _MoviePosterTileState extends State<_MoviePosterTile> {
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
    final posterUrl = widget.movie['stream_icon'];
    final title = widget.movie['name'] ?? 'Sin título';
    final rating = widget.movie['rating']?.toString();

    return InkWell(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hasFocus ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: const Color(0xFF007ACC).withOpacity(0.8),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen del Póster
              (posterUrl != null && posterUrl.toString().isNotEmpty)
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.movie, size: 40, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.movie, size: 40, color: Colors.white54),
                    ),

              // Degradado inferior para legibilidad del título
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _hasFocus ? 13 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Indicador de calificación superior si existe
              if (rating != null && rating.isNotEmpty && rating != '0' && rating != 'null')
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REPRODUCTOR DE PELÍCULAS (VOD PLAYER)
// -----------------------------------------------------------------------------
class MoviePlayerScreen extends StatefulWidget {
  final String movieUrl;
  final String movieName;

  const MoviePlayerScreen({
    super.key,
    required this.movieUrl,
    required this.movieName,
  });

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _player = Player();
    _videoController = VideoController(_player);
    _player.open(Media(widget.movieUrl));
    _startHideTimer();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _player.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: _videoController,
                fit: BoxFit.contain,
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppBar(
                        backgroundColor: Colors.black54,
                        title: Text(widget.movieName, style: const TextStyle(fontSize: 16)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Presiona Atrás para salir',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PANTALLA DE CANALES Y REPRODUCTOR (EN VIVO)
// -----------------------------------------------------------------------------
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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
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
                  const SizedBox(width: 12),
                ],
              ),
        body: _isLoadingChannels
            ? const Center(child: CircularProgressIndicator())
            : _channels.isEmpty
                ? const Center(child: Text('No se encontraron canales'))
                : Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: Video(
                            controller: _videoController,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
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
                      if (_isFullScreen)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControlsVisibility,
                          child: const SizedBox.expand(),
                        ),
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

class _DpadButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color textColor;
  final Color? backgroundColor;
  final bool isBig;

  const _DpadButton({
    super.key,
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
