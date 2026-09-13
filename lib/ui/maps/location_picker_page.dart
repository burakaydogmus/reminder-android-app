import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:reminder/config/maps_config.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/services/places_nearby_service.dart';
import 'package:reminder/ui/theme/tokens/kor_spacing.dart';

class LocationPickResult {
  final LatLng point;
  final double radiusMeters;
  final String? label;

  const LocationPickResult({
    required this.point,
    required this.radiusMeters,
    this.label,
  });
}

/// Haritadan konum ve yarıçap seçimi. [categoryId] market ise yakındaki market araması sunulur (isteğe bağlı API anahtarı).
class LocationPickerPage extends StatefulWidget {
  final String categoryId;
  final LatLng? initialPoint;
  final double initialRadiusMeters;
  final String? initialLabel;

  const LocationPickerPage({
    super.key,
    required this.categoryId,
    this.initialPoint,
    this.initialRadiusMeters = 150,
    this.initialLabel,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _markerPos;
  late double _radius;
  String? _label;
  bool _loadingPlaces = false;
  final _places = const PlacesNearbyService();

  static const _fallback = LatLng(41.0082, 28.9784);

  @override
  void initState() {
    super.initState();
    _markerPos = widget.initialPoint ?? _fallback;
    _radius = widget.initialRadiusMeters.clamp(100, 500);
    _label = widget.initialLabel;
    _initCenter();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCenter() async {
    if (widget.initialPoint != null) return;
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _markerPos = ll;
      });
      _mapController.move(ll, 15);
    } catch (_) {}
  }

  Future<void> _goToMyLocation() async {
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum servisleri kapalı.')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni gerekli.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _markerPos = ll;
        _label = null;
      });
      _mapController.move(ll, 15);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı.')),
        );
      }
    }
  }

  Future<void> _loadNearbyMarkets() async {
    if (!mapsConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Yakındaki marketler için Google Places anahtarı gerekir '
              '(isteğe bağlı: --dart-define=GOOGLE_MAPS_KEY=...).',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _loadingPlaces = true);
    final list = await _places.searchNearbyMarkets(_markerPos);
    if (!mounted) return;
    setState(() => _loadingPlaces = false);
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yakında market bulunamadı.')),
      );
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text('Yakındaki marketler'),
                subtitle: Text('Seçmek için dokunun'),
              ),
              for (final p in list)
                ListTile(
                  title: Text(p.name),
                  subtitle: p.vicinity != null ? Text(p.vicinity!) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _markerPos = p.location;
                      _label = p.name;
                    });
                    _mapController.move(p.location, 16);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng p) {
    setState(() {
      _markerPos = p;
      _label = null;
    });
  }

  void _confirmAndPop() {
    Navigator.pop(
      context,
      LocationPickResult(
        point: _markerPos,
        radiusMeters: _radius,
        label: _label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMarket = widget.categoryId == ReminderCategoryIds.market;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final label = _label?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum seç'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KorSpacing.s5,
              KorSpacing.s2,
              KorSpacing.s5,
              KorSpacing.s2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label != null && label.isNotEmpty ? label : 'Seçilen konum',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'Haritaya dokun, yarıçapı ayarla ve «Bu konumu kaydet» ile '
                  'onayla.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KorSpacing.s3),
                Row(
                  children: [
                    Text('Yarıçap', style: theme.textTheme.labelLarge),
                    const Spacer(),
                    Text(
                      '${_radius.round()} m',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 500,
                  divisions: 20,
                  label: '${_radius.round()} m',
                  semanticFormatterCallback: (v) =>
                      'Yarıçap ${v.round()} metre',
                  onChanged: (v) => setState(() => _radius = v),
                ),
                // No developer hint without an API key (§3.3.10).
                if (isMarket && mapsConfigured)
                  OutlinedButton.icon(
                    onPressed: _loadingPlaces ? null : _loadNearbyMarkets,
                    icon: _loadingPlaces
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.store_mall_directory_outlined),
                    label: const Text('Yakındaki marketleri göster'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _markerPos,
                    initialZoom: 15,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.burakaydogmus.reminder',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _markerPos,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: primary.withValues(alpha: 0.22),
                          borderStrokeWidth: 2,
                          borderColor: primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPos,
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.place,
                            color: primary,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                    SimpleAttributionWidget(
                      source: const Text('OpenStreetMap'),
                      backgroundColor:
                          theme.colorScheme.surface.withValues(alpha: 0.92),
                    ),
                  ],
                ),
                Positioned(
                  right: KorSpacing.s4,
                  bottom: KorSpacing.s4,
                  child: Material(
                    elevation: 2,
                    shape: const CircleBorder(),
                    color: scheme.surfaceContainerHigh,
                    child: IconButton(
                      tooltip: 'Konumuma git',
                      onPressed: _goToMyLocation,
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          KorSpacing.s5,
          KorSpacing.s3,
          KorSpacing.s5,
          KorSpacing.s4,
        ),
        child: FilledButton(
          onPressed: _confirmAndPop,
          child: const Text('Bu konumu kaydet'),
        ),
      ),
    );
  }
}
