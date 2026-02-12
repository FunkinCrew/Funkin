package funkin.util;

import flixel.FlxG;

// Detects a basic hardware profile from renderer and driver strings.
@:nullSafety
class HardwareProfileUtil
{
  public static final MB:Float = 1024.0 * 1024.0;
  public static final GB:Float = 1024.0 * MB;
  public static final HIGH_VRAM_THRESHOLD_BYTES:Float = 4.0 * GB;

  public static function snapshot():HardwareSnapshot
  {
    var driverInfo:String = FlxG?.stage?.context3D?.driverInfo ?? "unknown";
    var rendererType:String = Std.string(FlxG?.stage?.window?.context?.type ?? "unknown");
    var driverInfoLower:String = driverInfo.toLowerCase();

    var softwareRenderer:Bool = containsAny(driverInfoLower, ["software", "swiftshader", "llvmpipe", "warp"]);
    var hasHardwareGpu:Bool = FlxG?.stage?.context3D != null && !softwareRenderer;
    var dedicatedGpu:Bool = hasHardwareGpu && containsAny(driverInfoLower, ["nvidia", "geforce", "radeon", "amd", "rtx", "gtx"])
      && !containsAny(driverInfoLower, ["intel", "uhd", "iris", "xe"]);

    // Estimates VRAM because OpenFL does not expose exact VRAM.
    var estimatedVramBytes:Float = hasHardwareGpu ? (dedicatedGpu ? 6.0 * GB : 2.0 * GB) : 0.5 * GB;

    return {
      driverInfo: driverInfo,
      rendererType: rendererType,
      hasHardwareGpu: hasHardwareGpu,
      dedicatedGpu: dedicatedGpu,
      estimatedVramBytes: estimatedVramBytes
    };
  }

  public static function chooseCacheProfile(snapshot:HardwareSnapshot):RuntimeCacheProfile
  {
    if (!snapshot.hasHardwareGpu) return RAM_SAVER;
    if (snapshot.estimatedVramBytes >= HIGH_VRAM_THRESHOLD_BYTES) return GPU_HEAVY;
    return BALANCED;
  }

  static function containsAny(input:String, needles:Array<String>):Bool
  {
    for (needle in needles)
    {
      if (input.contains(needle)) return true;
    }
    return false;
  }
}

typedef HardwareSnapshot =
{
  var driverInfo:String;
  var rendererType:String;
  var hasHardwareGpu:Bool;
  var dedicatedGpu:Bool;
  var estimatedVramBytes:Float;
}

enum abstract RuntimeCacheProfile(String) from String to String
{
  var GPU_HEAVY;
  var BALANCED;
  var RAM_SAVER;
}
