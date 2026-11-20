package funkin.util.mobile;

#if ios
import funkin.external.apple.MemoryUtil;
#elseif android
import funkin.external.android.DeviceUtil;
#end
import lime.graphics.opengl.GL;

enum abstract DeviceTier(Int) from Int to Int
{
  var LOW = 0;
  var MID = 1;
  var HIGH = 2;
}

/**
 * A utility class to detect the device's performance tier based on its GPU and RAM.
 *
 * iOS
 * - HIGH - A15 and up, any M chip - 3.5GB+ RAM
 * - MID - A12 to A14 - 2.5GB+ RAM
 * - LOW - A11 and below - under 2.5GB RAM
 *
 * Android
 * - HIGH - Adreno 650 to 699 and 725+, Mali-G710+, Immortalis, Xclipse - 5GB+ RAM
 * - MID - Adreno 616 to 649 and 700 to 724, Mali-G76 to G78 and G610 to G699, Maleoon - 3.5GB+ RAM
 * - LOW - older Adreno, other Mali, PowerVR - under 3.5GB RAM
 */
@:unreflective
class DeviceTierUtil
{
  /**
   * The current device's performance tier.
   * Detected based on the GPU and RAM of the device.
   */
  public static var tier(get, never):DeviceTier;

  static var cachedTier:Null<DeviceTier> = null;

  static function get_tier():DeviceTier
  {
    if (cachedTier != null) return cachedTier;

    // Before the window exists there is no GL context, so only cache once the GPU is known.
    final renderer:String = getRenderer();
    final detected:DeviceTier = detect(renderer);
    if (renderer.length > 0) cachedTier = detected;
    return detected;
  }

  static function detect(renderer:String):DeviceTier
  {
    #if ios
    return capTier(appleGpuTier(renderer), ramTier(MemoryUtil.getPhysicalMemory(), 2500, 3500));
    #elseif android
    final gpu:Null<DeviceTier> = androidGpuTier(renderer);
    return capTier(gpu ?? performanceClassTier(DeviceUtil.getPerformanceClass()), ramTier(DeviceUtil.getTotalMemory(), 3500, 5000));
    #else
    return HIGH;
    #end
  }

  static function getRenderer():String
  {
    if (GL.context == null) return '';
    return GL.getString(GL.RENDERER) ?? '';
  }

  static function capTier(tier:DeviceTier, cap:DeviceTier):DeviceTier
  {
    return (tier:Int) < (cap:Int) ? tier : cap;
  }

  static function ramTier(memoryMB:Int, midFrom:Int, highFrom:Int):DeviceTier
  {
    if (memoryMB <= 0 || memoryMB >= highFrom) return HIGH;
    if (memoryMB >= midFrom) return MID;
    return LOW;
  }

  static function appleGpuTier(renderer:String):DeviceTier
  {
    final chip:EReg = ~/Apple (A|M)(\d+)/;
    if (!chip.match(renderer)) return MID;
    if (chip.matched(1) == 'M') return HIGH;

    final generation:Int = Std.parseInt(chip.matched(2)) ?? 0;
    if (generation >= 15) return HIGH;
    if (generation >= 12) return MID;
    return LOW;
  }

  static function androidGpuTier(renderer:String):Null<DeviceTier>
  {
    final adreno:EReg = ~/Adreno[^\d]*(\d{3})/i;
    if (adreno.match(renderer))
    {
      final model:Int = Std.parseInt(adreno.matched(1)) ?? 0;
      if (model >= 725 || (model >= 650 && model < 700)) return HIGH;
      if (model >= 616) return MID;
      return LOW;
    }

    if (~/Immortalis|Xclipse/i.match(renderer)) return HIGH;

    final mali:EReg = ~/Mali-G(\d+)/i;
    if (mali.match(renderer))
    {
      final model:Int = Std.parseInt(mali.matched(1)) ?? 0;
      if (model >= 700) return HIGH;
      if (model >= 600 || (model >= 76 && model < 100)) return MID;
      return LOW;
    }

    if (~/Mali|PowerVR/i.match(renderer)) return LOW;
    if (~/Maleoon/i.match(renderer)) return MID;

    return null;
  }

  static function performanceClassTier(performanceClass:Int):DeviceTier
  {
    return performanceClass >= 33 ? HIGH : MID;
  }
}
