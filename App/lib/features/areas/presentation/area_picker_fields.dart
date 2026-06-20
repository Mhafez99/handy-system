import 'package:flutter/material.dart';
import 'package:handy_app/features/areas/data/areas_repository.dart';
import 'package:handy_app/features/areas/domain/area.dart';

class AreaPickerFields extends StatefulWidget {
  const AreaPickerFields({
    required this.selectedArea,
    required this.onAreaChanged,
    this.initialAreaId,
    this.initialGovernorate,
    this.initialAreaName,
    this.enabled = true,
    super.key,
  });

  final Area? selectedArea;
  final ValueChanged<Area?> onAreaChanged;
  final int? initialAreaId;
  final String? initialGovernorate;
  final String? initialAreaName;
  final bool enabled;

  @override
  State<AreaPickerFields> createState() => _AreaPickerFieldsState();
}

class _AreaPickerFieldsState extends State<AreaPickerFields> {
  final repository = AreasRepository();
  late Future<List<Area>> areasFuture;
  String? selectedGovernorate;
  bool didApplyInitialSelection = false;

  @override
  void initState() {
    super.initState();
    areasFuture = repository.loadAreas();
    selectedGovernorate = widget.selectedArea?.governorate;
  }

  void reloadAreas() {
    setState(() {
      areasFuture = repository.loadAreas();
      didApplyInitialSelection = false;
    });
  }

  void applyInitialSelection(List<Area> areas) {
    if (didApplyInitialSelection || widget.selectedArea != null) {
      return;
    }

    Area? initialArea;
    final initialAreaId = widget.initialAreaId;
    if (initialAreaId != null) {
      for (final area in areas) {
        if (area.id == initialAreaId) {
          initialArea = area;
          break;
        }
      }
    } else {
      final governorate = widget.initialGovernorate?.trim();
      final areaName = widget.initialAreaName?.trim();
      if (governorate != null &&
          governorate.isNotEmpty &&
          areaName != null &&
          areaName.isNotEmpty) {
        for (final area in areas) {
          if (area.governorate == governorate && area.name == areaName) {
            initialArea = area;
            break;
          }
        }
      }
    }

    didApplyInitialSelection = true;
    if (initialArea == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => selectedGovernorate = initialArea!.governorate);
      widget.onAreaChanged(initialArea);
    });
  }

  List<String> governoratesFor(List<Area> areas) {
    return areas.map((area) => area.governorate).toSet().toList()..sort();
  }

  List<Area> areasForGovernorate(List<Area> areas, String governorate) {
    return areas
        .where((area) => area.governorate == governorate)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Area>>(
      future: areasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('تعذر تحميل المناطق.'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.enabled ? reloadAreas : null,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          );
        }

        final areas = snapshot.data ?? [];
        if (areas.isEmpty) {
          return const Text('لا توجد مناطق متاحة حاليًا.');
        }

        applyInitialSelection(areas);

        final governorates = governoratesFor(areas);
        final currentGovernorate =
            selectedGovernorate ??
            widget.selectedArea?.governorate ??
            governorates.first;
        final availableAreas = areasForGovernorate(areas, currentGovernorate);
        final currentArea = widget.selectedArea != null &&
                widget.selectedArea!.governorate == currentGovernorate
            ? widget.selectedArea
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: currentGovernorate,
              decoration: const InputDecoration(
                labelText: 'المحافظة',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: governorates
                  .map(
                    (governorate) => DropdownMenuItem(
                      value: governorate,
                      child: Text(governorate),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled
                  ? (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => selectedGovernorate = value);
                      widget.onAreaChanged(null);
                    }
                  : null,
              validator: (value) => value == null ? 'اختر المحافظة' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Area>(
              initialValue: currentArea,
              decoration: const InputDecoration(
                labelText: 'المنطقة',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              items: availableAreas
                  .map(
                    (area) => DropdownMenuItem(
                      value: area,
                      child: Text(area.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled
                  ? (value) => widget.onAreaChanged(value)
                  : null,
              validator: (value) => value == null ? 'اختر المنطقة' : null,
            ),
          ],
        );
      },
    );
  }
}
