import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:reminder/config/maps_config.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/services/places_nearby_service.dart';
import 'package:reminder/ui/widgets/primary_button.dart';

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
                  subtitle:
                      p.vicinity != null ? Text(p.vicinity!) : null,
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
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum seç'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Haritaya dokunun, yarıçapı ayarlayın; ardından alttaki '
                  '«Bu konumu kaydet» ile onaylayın. Yarıçap: ${_radius.round()} m',
                  style: theme.textTheme.bodySmall,
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 500,
                  divisions: 20,
                  label: '${_radius.round()} m',
                  onChanged: (v) => setState(() => _radius = v),
                ),
                if (isMarket)
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
                      userAgentPackageName: 'com.fabirt.reminder',
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
                  right: 12,
                  bottom: 12,
                  child: Material(
                    elevation: 2,
                    shape: const CircleBorder(),
                    color: theme.colorScheme.surface,
                    child: IconButton(
                      tooltip: 'Konumum',
                      onPressed: _goToMyLocation,
                      icon: Icon(
                        Icons.my_location,
                        color: theme.colorScheme.primary,
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
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            onPressed: _confirmAndPop,
            title: 'Bu konumu kaydet',
          ),
        ),
      ),
    );
  }
}
