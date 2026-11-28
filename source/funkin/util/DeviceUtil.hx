package funkin.util;

import funkin.ui.FullScreenScaleMode;
import lime.system.System;

class DeviceUtil
{
  public static var hasNotch(get, never):Bool;

  static function get_hasNotch():Bool
  {
    #if !mobile
    var hasPhysicalNotch:Bool = false;
    #elseif ios
    var hasPhysicalNotch:Bool = switch (model)
    {
      case 'iPhone12,8': // iPhone SE (2020)
        false; // Still using old iPhone 8 body so no notch
      case 'iPhone14,6': // iPhone SE (2022)
        false; // Still using old iPhone 8 body so no notch
      case 'iPhone19,4': // iPhone Duo
        false; // Hole punch doesn't count as a notch
      default:
        true;
    };
    if (!model.startsWith('iPhone') || iPhoneNumber < 10)
    {
      hasPhysicalNotch = false; // Not an iPhone, then no notch or notch wasn't invented back then
    }
    #elseif android
    var hasPhysicalNotch:Bool = true; // give it the benefit of the doubt
    #end
    // dont need to consider notch if aspect ratio doesn't overlap it
    return hasPhysicalNotch && FullScreenScaleMode.gameNotchSize.x > 0;
  }

  // --- iPhone Number Detection ---
  #if ios
  public static var iPhoneNumber(get, never):Int;

  private static function get_iPhoneNumber():Int
  {
    // TODO: Add ipad detection gah
    if (!model.startsWith('iPhone')) return 0; // Not an iPhone, must be an ipad!!

    return switch (model)
    {
      // iPhone 8 Series
      case 'iPhone10,1': // iPhone 8 (Global)
        8;
      case 'iPhone10,4': // iPhone 8 (GSM)
        8;
      case 'iPhone10,2': // iPhone 8 Plus (Global)
        8;
      case 'iPhone10,5': // iPhone 8 Plus (GSM)
        8;

      // iPhone X Series
      case 'iPhone10,3': // iPhone X (Global)
        10;
      case 'iPhone10,6': // iPhone X (GSM)
        10;
      case 'iPhone11,2': // iPhone XS
        10;
      case 'iPhone11,6': // iPhone XS Max
        10;
      case 'iPhone11,4': // iPhone XS Max (China)
        10;
      case 'iPhone11,8': // iPhone XR
        10;

      // iPhone 11 Series
      case 'iPhone12,1': // iPhone 11
        11;
      case 'iPhone12,3': // iPhone 11 Pro
        11;
      case 'iPhone12,5': // iPhone 11 Pro Max
        11;

      // iPhone 12 Series
      case 'iPhone13,1': // iPhone 12 Mini
        12;
      case 'iPhone13,2': // iPhone 12
        12;
      case 'iPhone13,3': // iPhone 12 Pro
        12;
      case 'iPhone13,4': // iPhone 12 Pro Max
        12;

      // iPhone 13 Series
      case 'iPhone14,4': // iPhone 13 Mini
        13;
      case 'iPhone14,5': // iPhone 13
        13;
      case 'iPhone14,2': // iPhone 13 Pro
        13;
      case 'iPhone14,3': // iPhone 13 Pro Max
        13;

      // iPhone 14 Series
      case 'iPhone14,7': // iPhone 14
        14;
      case 'iPhone14,8': // iPhone 14 Plus
        14;
      case 'iPhone15,2': // iPhone 14 Pro
        14;
      case 'iPhone15,3': // iPhone 14 Pro Max
        14;

      // iPhone 15 Series
      case 'iPhone15,4': // iPhone 15
        15;
      case 'iPhone15,5': // iPhone 15 Plus
        15;
      case 'iPhone16,1': // iPhone 15 Pro
        15;
      case 'iPhone16,2': // iPhone 15 Pro Max
        15;

      // iPhone 16 Series
      case 'iPhone17,1': // iPhone 16 Pro
        16;
      case 'iPhone17,5': // iPhone 16e
        16;
      case 'iPhone17,4': // iPhone 16 Plus
        16;
      case 'iPhone17,3': // iPhone 16
        16;
      case 'iPhone17,2': // iPhone 16 Pro Max
        16;

      // iPhone 17 Series
      case 'iPhone18,1': // iPhone 17 Pro
        17;
      case 'iPhone18,2': // iPhone 17 Pro Max
        17;
      case 'iPhone18,3': // iPhone 17
        17;
      case 'iPhone18,5': // iPhone 17e
        17;

      // iPhone 18 Series
      case 'iPhone19,2': // iPhone 18 Pro
        18;
      case 'iPhone19,3': // iPhone 18 Pro Max (US)
        18;
      case 'iPhone19,7': // iPhone 18 Pro Max
        18;
      // Unreleased as of writing this so I might be wrong
      case 'iPhone19,1': // iPhone 18
        18;
      case 'iPhone19,5': // iPhone 18e
        18;

      // Other iPhone Models
      case 'iPhone12,8': // iPhone SE (2020)
        11;
      case 'iPhone14,6': // iPhone SE (2022)
        13;
      case 'iPhone18,4': // iPhone Air
        17; // same chip as 17 Pro
      case 'iPhone19,4': // iPhone Duo
        18; // same chip as 18 Pro

      // Unknown or newer model fallback
      default:
        final parts = model.substr(6).split(',');
        if (parts.length == 2)
        {
          final major = Std.parseInt(parts[0]);
          final minor = Std.parseInt(parts[1]);
          if (major != null && minor != null)
          {
            if (major > 19 || (major == 19 && minor > 5))
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

  static function get_osVersion():String
  {
    return System.platformVersion;
  }

  public static var vendor(get, null):String;

  static function get_vendor():String
  {
    return System.deviceVendor;
  }

  public static var model(get, null):String;

  static function get_model():String
  {
    return System.deviceModel;
  }
}
