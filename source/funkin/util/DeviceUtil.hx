package funkin.util;

import lime.system.System;

class DeviceUtil
{
  // --- iPhone Number Detection ---
  #if ios
  public static var iPhoneNumber(get, never):Int;

  private static function get_iPhoneNumber():Int
  {
    // TODO: Add ipad detection gah
    if (!model.startsWith("iPhone")) return 0; // Not an iPhone, must be an ipad!!

    return switch (model)
    {
      // iPhone 12 Series
      case "iPhone13,1": 12;
      case "iPhone13,2": 12;
      case "iPhone13,3": 12;
      case "iPhone13,4": 12;

      // iPhone 13 Series
      case "iPhone14,4": 13;
      case "iPhone14,5": 13;
      case "iPhone14,2": 13;
      case "iPhone14,3": 13;

      // iPhone 14 Series
      case "iPhone14,7": 14;
      case "iPhone14,8": 14;
      case "iPhone15,2": 14;
      case "iPhone15,3": 14;

      // iPhone 15 Series
      case "iPhone15,4": 15;
      case "iPhone15,5": 15;
      case "iPhone16,1": 15;
      case "iPhone16,2": 15;

      // iPhone 16 Series
      case "iPhone17,1": 16;
      case "iPhone17,5": 16;
      case "iPhone17,4": 16;
      case "iPhone17,3": 16;
      case "iPhone17,2": 16;

      // Unknown or newer model fallback
      default:
        final parts = model.substr(6).split(",");
        if (parts.length == 2)
        {
          final major = Std.parseInt(parts[0]);
          final minor = Std.parseInt(parts[1]);
          if (major != null && minor != null)
          {
            if (major > 17 || (major == 17 && minor > 5))
            {
              return 100; // future device
            }
          }
        }
        return 0; // obsolete or unknown
    }
  }
  #end

  // --- General Device Info ---
  public static var osVersion(get, null):String;

  private static function get_osVersion():String
  {
    return System.platformVersion;
  }

  public static var vendor(get, null):String;

  private static function get_vendor():String
  {
    return System.deviceVendor;
  }

  public static var model(get, null):String;

  private static function get_model():String
  {
    return System.deviceModel;
  }
}
