package funkin.play.notes;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.graphics.shaders.NoteQuantTintShader;
import funkin.util.Constants;

/**
 * Note quantization color palette and helpers.
 */
class NoteQuantColors
{
  public static final QUANT_COLOR_4TH:FlxColor = 0xFFFF3030;
  public static final QUANT_COLOR_8TH:FlxColor = 0xFF3080FF;
  public static final QUANT_COLOR_12TH:FlxColor = 0xFFC050FF;
  public static final QUANT_COLOR_16TH:FlxColor = 0xFFFFD030;
  public static final QUANT_COLOR_24TH:FlxColor = 0xFFFF80C0;
  public static final QUANT_COLOR_32ND:FlxColor = 0xFFFF9030;
  public static final QUANT_COLOR_48TH:FlxColor = 0xFF40E0E0;
  public static final QUANT_COLOR_64TH:FlxColor = 0xFF50FF80;
  public static final QUANT_COLOR_OTHER:FlxColor = 0xFFB0B0B0;

  public static function getQuantColor(stepTime:Float):FlxColor
  {
    var beatNotes:Float = Constants.STEPS_PER_BEAT * 4;
    if (alignsTo(stepTime, beatNotes / 4)) return QUANT_COLOR_4TH;
    if (alignsTo(stepTime, beatNotes / 8)) return QUANT_COLOR_8TH;
    if (alignsTo(stepTime, beatNotes / 12)) return QUANT_COLOR_12TH;
    if (alignsTo(stepTime, beatNotes / 16)) return QUANT_COLOR_16TH;
    if (alignsTo(stepTime, beatNotes / 24)) return QUANT_COLOR_24TH;
    if (alignsTo(stepTime, beatNotes / 32)) return QUANT_COLOR_32ND;
    if (alignsTo(stepTime, beatNotes / 48)) return QUANT_COLOR_48TH;
    if (alignsTo(stepTime, beatNotes / 64)) return QUANT_COLOR_64TH;
    return QUANT_COLOR_OTHER;
  }

  public static function apply(sprite:FlxSprite, enable:Bool, stepTime:Float, flat:Bool = false):Void
  {
    if (!enable || stepTime < 0)
    {
      if (Std.isOfType(sprite.shader, NoteQuantTintShader)) sprite.shader = null;
      sprite.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
      return;
    }
    var c:FlxColor = getQuantColor(stepTime);
    if (flat)
    {
      sprite.shader = sharedShaderFor(c);
    }
    else
    {
      if (Std.isOfType(sprite.shader, NoteQuantTintShader)) sprite.shader = null;
      sprite.setColorTransform(0.3, 0.3, 0.3, 1, Std.int(c.red * 0.7), Std.int(c.green * 0.7), Std.int(c.blue * 0.7), 0);
    }
  }

  static var shaderCache:Map<Int, NoteQuantTintShader> = new Map();

  static function sharedShaderFor(c:FlxColor):NoteQuantTintShader
  {
    var key:Int = c;
    var s:Null<NoteQuantTintShader> = shaderCache.get(key);
    if (s == null)
    {
      s = new NoteQuantTintShader();
      s.setColor(c);
      shaderCache.set(key, s);
    }
    return s;
  }

  static inline function alignsTo(stepTime:Float, gridSteps:Float):Bool
  {
    var ratio:Float = stepTime / gridSteps;
    return Math.abs(ratio - Math.round(ratio)) < 0.01;
  }
}
