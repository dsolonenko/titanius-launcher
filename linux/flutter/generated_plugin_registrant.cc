//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_volume_controller/flutter_volume_controller_plugin.h>
#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
#include <system_date_time_format/system_date_time_format_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_volume_controller_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterVolumeControllerPlugin");
  flutter_volume_controller_plugin_register_with_registrar(flutter_volume_controller_registrar);
  g_autoptr(FlPluginRegistrar) isar_flutter_libs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "IsarFlutterLibsPlugin");
  isar_flutter_libs_plugin_register_with_registrar(isar_flutter_libs_registrar);
  g_autoptr(FlPluginRegistrar) system_date_time_format_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "SystemDateTimeFormatPlugin");
  system_date_time_format_plugin_register_with_registrar(system_date_time_format_registrar);
}
