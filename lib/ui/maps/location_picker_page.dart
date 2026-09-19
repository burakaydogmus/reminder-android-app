import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:reminder/config/app_links.dart';
import 'package:reminder/config/maps_config.dart';
import 'package:reminder/domain/model/reminder_category.dart';
import 'package:reminder/l10n/l10n.dart';
import 'package:reminder/services/permission_service.dart';
import 'package:reminder/services/places_nearby_service.dart';
import 'package:reminder/ui/maps/osm_attribution.dart';
import 'package:reminder/ui/permissions/permission_scope.dart';
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

  /// Opens the OSM copyright page from the attribution; injectable for tests.
  final LinkOpener linkOpener;

  const LocationPickerPage({
    super.key,
    required this.categoryId,
    this.initialPoint,
    this.initialRadiusMeters = 150,
    this.initialLabel,
    this.linkOpener = openExternalLink,
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

  /// Centres on the current position only when location is already granted;
  /// never asks here (F1.6 — the editor explains and asks first).
  Future<void> _initCenter() async {
    if (widget.initialPoint != null) return;
    try {
      final state = (await PermissionScope.read(context).refresh()).location;
      if (state != LocationPermissionState.always &&
          state != LocationPermissionState.whileInUse) {
        return;
      }
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
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
            SnackBar(content: Text(context.l10n.mapsServicesOff)),
          );
        }
        return;
      }
      if (!mounted) return;
      // User-initiated: asking here is in context.
      final permissions = PermissionScope.read(context);
      var state = (await permissions.refresh()).location;
      if (state == LocationPermissionState.notRequested) {
        state = await permissions.service.requestLocationWhenInUse();
        await permissions.refresh();
      }
      if (state != LocationPermissionState.always &&
          state != LocationPermissionState.whileInUse) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.mapsPermissionOff),
              action: SnackBarAction(
                label: context.l10n.permissionOpenSettings,
                onPressed: permissions.service.openAppSettings,
              ),
            ),
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
          SnackBar(content: Text(context.l10n.mapsLocationFailed)),
        );
      }
    }
  }

  Future<void> _loadNearbyMarkets() async {
    if (!mapsConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mapsPlacesKeyMissing)),
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
        SnackBar(content: Text(context.l10n.mapsNoMarkets)),
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
              ListTile(
                title: Text(ctx.l10n.mapsNearbyMarkets),
                subtitle: Text(ctx.l10n.mapsTapToPick),
              ),
              for (final p in list)
                ListTile(
                  title: Text(_placeName(p, ctx.l10n)),
                  subtitle: p.vicinity != null ? Text(p.vicinity!) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _markerPos = p.location;
                      _label = _placeName(p, ctx.l10n);
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

  Future<void> _openOsmCopyright() async {
    final opened = await widget.linkOpener(AppLinks.osmCopyright);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsLinkFailed)),
    );
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
        title: Text(context.l10n.mapsTitle),
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
                  label != null && label.isNotEmpty
                      ? label
                      : context.l10n.editorLocationChosen,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  context.l10n.mapsHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: KorSpacing.s3),
                Row(
                  children: [
                    Text(
                      context.l10n.mapsRadius,
                      style: theme.textTheme.labelLarge,
                    ),
                    const Spacer(),
                    Text(
                      context.l10n.mapsRadiusMeters(_radius.round()),
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
                  label: context.l10n.mapsRadiusMeters(_radius.round()),
                  semanticFormatterCallback: (v) =>
                      context.l10n.mapsRadiusSpoken(v.round()),
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
                    label: Text(context.l10n.mapsShowMarkets),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // The map's gesture node needs a name (§3.6 rule 4); the
                // marker also moves with "Konumuma git".
                Semantics(
                  label: context.l10n.mapsMap,
                  hint: context.l10n.mapsMapHint,
                  child: FlutterMap(
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
                      // OSMF tile policy: visible "© OpenStreetMap
                      // contributors" linking to the copyright page (F6.2b).
                      // Bottom left keeps it clear of "Konumuma git".
                      OsmAttribution(onTap: _openOsmCopyright),
                    ],
                  ),
                ),
                Positioned(
                  right: KorSpacing.s4,
                  bottom: KorSpacing.s4,
                  child: Material(
                    elevation: 2,
                    shape: const CircleBorder(),
                    color: scheme.surfaceContainerHigh,
                    child: IconButton(
                      tooltip: context.l10n.mapsMyLocation,
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
          child: Text(context.l10n.mapsSave),
        ),
      ),
    );
  }
}

/// A nearby place's name, or "İşletme" / "Business" when it has none.
String _placeName(NearbyPlaceResult place, AppLocalizations l10n) =>
    place.name.isEmpty ? l10n.mapsBusiness : place.name;
