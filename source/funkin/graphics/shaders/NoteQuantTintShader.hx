package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxColor;

/**
 * Replaces every visible pixel of a sprite with `targetColor`, preserving alpha.
 * Used by NoteQuantColors so hold sustains and end caps render as a single
 * uniform quant color regardless of the underlying atlas tile.
 */
class NoteQuantTintShader extends FlxRuntimeShader
{
  static inline final FRAGMENT:String = "#pragma header\n"
    + "uniform vec3 targetColor;\n"
    + "void main() {\n"
    + "  vec4 src = texture2D(bitmap, openfl_TextureCoordv);\n"
    + "  float luma = (src.r + src.g + src.b) / 3.0;\n"
    + "  gl_FragColor = vec4(targetColor * luma * src.a, src.a);\n"
    + "}";

  public function new()
  {
    super(FRAGMENT);
  }

  public function setColor(c:FlxColor):Void
  {
    this.setFloatArray('targetColor', [c.redFloat, c.greenFloat, c.blueFloat]);
  }
}
