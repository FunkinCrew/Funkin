package funkin.util;

import flixel.FlxG;
import flixel.FlxCamera;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

enum abstract ColorblindMode(String) from String to String
{
  var OFF = 'Off';
  var PROTAN = 'Protan';
  var DEUTAN = 'Deutan';
  var TRITAN = 'Tritan';
}

/**
 * Player-aid color filter applied to every camera.
 * Pick a deficiency type and tune assist strength (1-10). Off is the no-effect state.
 *
 * Manually rendered cameras outside `FlxG.cameras` should call `applyToCamera()`.
 */
class ColorblindFilter
{
  // Daltonization-style RGB correction matrices: pre-combined `I + Shift * (I - Sim)` so
  // the unperceived axis gets redistributed onto channels the viewer still sees.
  static final MATRIX_PROTAN:Array<Float> = [
       1.0000,  0.0000,  0.0000,
      -0.2549,  1.2549,  0.0000,
       0.3031, -0.5451,  1.2420
  ];

  static final MATRIX_DEUTAN:Array<Float> = [
       0.8850,  0.1150,  0.0000,
       0.0000,  1.0000,  0.0000,
      -0.4900,  0.1900,  1.3000
  ];

  static final MATRIX_TRITAN:Array<Float> = [
       1.0500, -0.3825,  0.3325,
       0.0000,  1.2345, -0.2345,
       0.0000,  0.0000,  1.0000
  ];

  static final IDENTITY_MATRIX:Array<Float> = [
      1.0, 0.0, 0.0,
      0.0, 1.0, 0.0,
      0.0, 0.0, 1.0
  ];

  public static final STRENGTH_MIN:Int = 1;
  public static final STRENGTH_MAX:Int = 10;

  static var attached:Bool = false;

  public static function attach():Void
  {
    if (attached) return;
    attached = true;
    FlxG.signals.postStateSwitch.add(reapply);
    FlxG.signals.preDraw.add(reapply);
    FlxG.cameras.cameraAdded.add((camera:FlxCamera) -> applyToCamera(camera));
    reapply();
  }

  public static function apply():Void
  {
    reapply();
  }

  public static function normalizeMode(value:Null<String>):ColorblindMode
  {
    return switch (value)
    {
      case 'Protan' | 'Protanopia' | 'Protanomaly':
        PROTAN;
      case 'Deutan' | 'Deuteranopia' | 'Deuteranomaly':
        DEUTAN;
      case 'Tritan' | 'Tritanopia' | 'Tritanomaly':
        TRITAN;
      default:
        OFF;
    };
  }

  static function reapply():Void
  {
    for (camera in FlxG.cameras.list)
    {
      applyToCamera(camera);
    }
  }

  public static function applyToCamera(camera:Null<FlxCamera>):Void
  {
    if (camera == null) return;

    var mode:ColorblindMode = funkin.Preferences.colorblindMode;
    var strength:Int = funkin.Preferences.colorblindStrength;
    final filterActive:Bool = mode != OFF;
    final targetMatrix:Null<Array<Float>> = filterActive ? buildBlendedMatrix(mode, strength) : null;

    final cameraFilters:Array<BitmapFilter> = camera.filters ?? [];
    var hasCurrentFilter:Bool = false;
    var hasStaleFilter:Bool = false;
    var currentFilterIsLast:Bool = false;
    var colorblindFilterCount:Int = 0;

    for (index => filter in cameraFilters)
    {
      if (!isColorblindFilter(filter)) continue;

      colorblindFilterCount++;
      if (targetMatrix != null && matrixEquals(cast(filter, ColorMatrixFilter).matrix, targetMatrix))
      {
        hasCurrentFilter = true;
        currentFilterIsLast = index == cameraFilters.length - 1;
      }
      else
      {
        hasStaleFilter = true;
      }
    }

    if (!filterActive && colorblindFilterCount == 0) return;
    if (filterActive && hasCurrentFilter && currentFilterIsLast && !hasStaleFilter && colorblindFilterCount == 1)
    {
      if (!camera.filtersEnabled) camera.filtersEnabled = true;
      return;
    }

    var existing:Array<BitmapFilter> = [for (filter in cameraFilters) if (!isColorblindFilter(filter)) filter];

    if (filterActive)
    {
      existing.push(new ColorMatrixFilter(targetMatrix));
      camera.filtersEnabled = true;
    }

    if (existing.length == 0 && cameraFilters.length == 0) return;
    camera.filters = existing.length > 0 ? existing : null;
  }

  static function buildBlendedMatrix(mode:ColorblindMode, strength:Int):Array<Float>
  {
    if (strength < STRENGTH_MIN) strength = STRENGTH_MIN;
    if (strength > STRENGTH_MAX) strength = STRENGTH_MAX;

    final correction:Array<Float> = rgbMatrixFor(mode);
    final t:Float = strength / STRENGTH_MAX;
    final inv:Float = 1.0 - t;
    final r:Array<Float> = [];
    for (i in 0...9) r.push(IDENTITY_MATRIX[i] * inv + correction[i] * t);
    return [
      r[0], r[1], r[2], 0, 0,
      r[3], r[4], r[5], 0, 0,
      r[6], r[7], r[8], 0, 0,
      0, 0, 0, 1, 0
    ];
  }

  static function rgbMatrixFor(mode:ColorblindMode):Array<Float>
  {
    return switch (mode)
    {
      case PROTAN: MATRIX_PROTAN;
      case DEUTAN: MATRIX_DEUTAN;
      case TRITAN: MATRIX_TRITAN;
      default: IDENTITY_MATRIX;
    };
  }

  static function isColorblindFilter(filter:BitmapFilter):Bool
  {
    if (!Std.isOfType(filter, ColorMatrixFilter)) return false;

    final matrix:Array<Float> = cast(filter, ColorMatrixFilter).matrix;
    for (mode in [PROTAN, DEUTAN, TRITAN])
    {
      for (strength in STRENGTH_MIN...(STRENGTH_MAX + 1))
      {
        if (matrixEquals(matrix, buildBlendedMatrix(mode, strength))) return true;
      }
    }

    return false;
  }

  static function matrixEquals(a:Array<Float>, b:Array<Float>):Bool
  {
    if (a == null || b == null || a.length != b.length) return false;

    for (i in 0...a.length)
    {
      if (Math.abs(a[i] - b[i]) > 0.0001) return false;
    }

    return true;
  }
}
