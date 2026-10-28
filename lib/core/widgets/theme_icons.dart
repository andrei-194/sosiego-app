import 'package:flutter/material.dart';

/// Traduce el nombre de icono de `themes.icon` y `moments.icon` (nombres de
/// Material Icons) a un icono. Un nombre desconocido cae en un icono neutro.
IconData contentIcon(String name) => switch (name) {
  'waves' => Icons.waves_outlined,
  'water_drop' => Icons.water_drop_outlined,
  'favorite' => Icons.favorite_border,
  'shield' => Icons.shield_outlined,
  'person' => Icons.person_outline,
  'handshake' => Icons.handshake_outlined,
  'wb_sunny' => Icons.wb_sunny_outlined,
  'bedtime' => Icons.bedtime_outlined,
  'local_fire_department' => Icons.local_fire_department_outlined,
  'help_outline' => Icons.help_outline,
  'volunteer_activism' => Icons.volunteer_activism_outlined,
  'spa' => Icons.spa_outlined,
  'auto_awesome' => Icons.auto_awesome_outlined,
  'lightbulb' => Icons.lightbulb_outline,
  'security' => Icons.security_outlined,
  'wb_twilight' => Icons.wb_twilight_outlined,
  'nights_stay' => Icons.nights_stay_outlined,
  'restaurant' => Icons.restaurant_outlined,
  'flight_takeoff' => Icons.flight_takeoff_outlined,
  'medical_services' => Icons.medical_services_outlined,
  'school' => Icons.school_outlined,
  'savings' => Icons.savings_outlined,
  'cake' => Icons.cake_outlined,
  _ => Icons.auto_stories_outlined,
};
