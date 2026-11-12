import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/services/auth_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/features/auth/providers/auth_provider.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/core/services/sample_data_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _locationRefresh = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final vehicles = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        children: [
          const _SectionHeader('Profile'),
          ListTile(
            title: const Text('Name'),
            subtitle: Text(settings.name.isEmpty ? 'Not set' : settings.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editText(context, 'Name', settings.name, (v) {
              ref.read(settingsProvider.notifier).update(settings.copyWith(name: v));
            }),
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(settings.email.isEmpty ? 'Not set' : settings.email),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editText(context, 'Email', settings.email, (v) {
              ref.read(settingsProvider.notifier).update(settings.copyWith(email: v));
            }),
          ),

          const _SectionHeader('Account'),
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).value;
              if (user == null) {
                return ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Sign in'),
                  subtitle: const Text('Back up your drives to the cloud'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/login'),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: Text('Signed in as ${user.email ?? 'your account'}'),
                    subtitle: const Text('Tap to sign out'),
                    onTap: () => AuthService.instance.signOut(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
                    title: const Text('Delete account', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Removes your sign-in and the cloud copy of your data'),
                    onTap: () => _deleteAccount(context),
                  ),
                ],
              );
            },
          ),

          const _SectionHeader('Mileage Rate'),
          ListTile(
            title: const Text('Rate per mile'),
            subtitle: Text(settings.usesIrsRate
                ? '${IrsRates.formattedRate} today  • ${AppStrings.irsRateNote}'
                : '${IrsRates.format(settings.mileageRate)}  • Custom rate'),
            trailing: const Icon(Icons.edit),
            onTap: () => _editRate(context, ref, settings.mileageRate),
          ),

          const _SectionHeader('Vehicles'),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Manage Vehicles'),
            subtitle: Text('${vehicles.length} vehicle(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/vehicles'),
          ),

          const _SectionHeader('Places & purposes'),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Places'),
            subtitle: const Text('Named locations that label your drives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/places'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Trip purposes'),
            subtitle: const Text('Presets for classifying drives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/purposes'),
          ),

          const _SectionHeader('Reports'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.reports),
            subtitle: const Text('IRS-ready PDF and CSV exports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reports'),
          ),

          // Hidden until real StoreKit subscriptions exist (see AppConfig).
          if (AppConfig.monetizationEnabled) ...[
            const _SectionHeader('Subscription'),
            Consumer(
              builder: (context, ref, _) {
                final settings = ref.watch(settingsProvider);
                return ListTile(
                  leading: Icon(settings.isPro ? Icons.workspace_premium : Icons.lock),
                  title: Text(settings.isPro ? 'Pro / Premium active' : 'Free plan'),
                  subtitle: Text(settings.isPro
                      ? 'Thank you for supporting MileMaid!'
                      : 'Upgrade for unlimited exports and full professional reports'),
                  trailing: settings.isPro
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    if (!settings.isPro) context.push('/upgrade');
                  },
                );
              },
            ),
          ],

          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseThemeMode(context, ref, settings),
          ),

          const _SectionHeader('Tracking'),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text(AppStrings.locationPermission),
            subtitle: FutureBuilder<LocationAccess>(
              key: ValueKey(_locationRefresh),
              future: LocationService().getCurrentAccess(),
              builder: (context, snapshot) {
                final access = snapshot.data ?? LocationAccess.denied;
                return Text(LocationService.accessLabel(access));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _fixLocationPermission(context),
          ),
          SwitchListTile(
            title: const Text(AppStrings.notifications),
            value: settings.notificationsEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).toggleNotifications(v),
          ),
          SwitchListTile(
            title: const Text('Record addresses'),
            subtitle: const Text('Resolve trip start/end addresses via an online service (OpenStreetMap)'),
            value: settings.geocodingEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setGeocodingEnabled(v),
          ),
          ListTile(
            title: const Text(AppStrings.trackingSensitivity),
            subtitle: Text(settings.trackingSensitivity),
            onTap: () => _chooseSensitivity(context, ref, settings),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Custom categories'),
            subtitle: const Text('Label and color-code your drives'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/custom-categories'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Auto-classification'),
            subtitle: const Text('Work hours and named locations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/auto-classify'),
          ),

          const _SectionHeader('Privacy & Data'),
          // Demo data is a development aid only; hidden in release builds.
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text(AppStrings.loadSampleData),
              subtitle: const Text(AppStrings.loadSampleDataSubtitle),
              onTap: () => _loadSampleTrips(context),
            ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text(AppStrings.exportData),
            onTap: () async {
              final data = await DatabaseService().exportAllDataAsJson();
              await Share.share(const JsonEncoder.withIndent('  ').convert(data));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(AppStrings.deleteAllData, style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDeleteAll(context, ref),
          ),

          const _SectionHeader('Legal & Privacy'),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy & Legal'),
            subtitle: const Text('How we handle your data + tax disclaimers'),
            onTap: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Privacy & Legal'),
                content: const SingleChildScrollView(
                  child: Text(
                    'MileMaid records your drives so you can build mileage reports.\n\n'
                    'Location stays on this iPhone until you sign in. If you sign in with Apple, Google, or email, your trips, saved places, vehicles, and trip purposes are saved to your account so you can restore them on another phone. That links your email address to your trip history.\n\n'
                    'If you turn on “Record addresses,” start and end coordinates are sent to OpenStreetMap to look up a street address.\n\n'
                    'We do not sell your data, and we do not use it to track you across other companies’ apps or websites.\n\n'
                    'You can export your data, delete it from this phone, or delete your account (which removes the cloud copy) from Settings.\n\n'
                    'MileMaid is a record-keeping tool, not tax advice. You are responsible for the accuracy of any report you submit.',
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text('MileMaid • v1.0 • Not tax or legal advice. Consult a professional.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _editText(BuildContext ctx, String label, String current, ValueChanged<String> onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            onSave(ctrl.text.trim());
            Navigator.pop(c);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _editRate(BuildContext ctx, WidgetRef ref, double current) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(3) : '');
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Set Custom Rate'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Rate per mile',
            prefixText: '\$',
            hintText: IrsRates.formattedRate.substring(1),
            helperText: 'Leave empty to use the IRS rate for each trip date',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            // Empty or invalid: follow the IRS rate by trip date (stored as 0).
            final v = double.tryParse(ctrl.text.trim()) ?? 0.0;
            ref.read(settingsProvider.notifier).setRate(v > 0 ? v : 0.0);
            Navigator.pop(c);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _fixLocationPermission(BuildContext ctx) async {
    final location = LocationService();
    var access = await location.requestFullLocationAccess();

    if (access == LocationAccess.whenInUse && ctx.mounted) {
      await LocationService.showAlwaysPermissionGuide(ctx);
      access = await location.getCurrentAccess();
    } else if (access == LocationAccess.denied && ctx.mounted) {
      await LocationService.showAlwaysPermissionGuide(ctx);
    } else if (access == LocationAccess.servicesDisabled && ctx.mounted) {
      await Geolocator.openLocationSettings();
    }

    if (access == LocationAccess.always || access == LocationAccess.whenInUse) {
      await TrackingService().startTracking();
    }

    if (ctx.mounted) {
      setState(() => _locationRefresh++);
    }
  }

  void _chooseSensitivity(BuildContext ctx, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: ctx,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['High', 'Balanced', 'Battery Saver'].map((s) => ListTile(
          title: Text(s),
          onTap: () {
            ref.read(settingsProvider.notifier).setSensitivity(s);
            Navigator.pop(c);
          },
        )).toList(),
      ),
    );
  }

  String _themeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _chooseThemeMode(BuildContext ctx, WidgetRef ref, settings) {
    showModalBottomSheet(
      context: ctx,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['system', 'light', 'dark'].map((mode) {
          final label = _themeModeLabel(mode);
          final selected = settings.themeMode == mode;
          return ListTile(
            title: Text(label),
            trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
              Navigator.pop(c);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadSampleTrips(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text(AppStrings.loadSampleData),
        content: const Text(
          'This adds 9 demo trips from the past 10 days (business, personal, and commute). '
          'Your existing trips are kept. Use this to preview the dashboard and reports without driving.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Load Samples')),
        ],
      ),
    );
    if (ok != true || !ctx.mounted) return;

    final count = await SampleDataService().seedSampleTrips();
    ref.read(tripsProvider.notifier).refresh();
    ref.read(dashboardProvider.notifier).refresh();

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Added $count sample trips. Check the home screen.')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your sign-in and the cloud copy of your drives, '
          'saved places, vehicles, and trip purposes. '
          'What is stored on this iPhone stays here until you use Delete All Data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !ctx.mounted) return;
    try {
      await AuthService.instance.deleteAccount();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Account deleted.')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyMessage(e))),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext ctx, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text('All trips, vehicles and settings will be erased. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService().clearAllData();
      ref.invalidate(settingsProvider);
      ref.invalidate(vehiclesProvider);
      if (ctx.mounted) ctx.pop();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }
}
