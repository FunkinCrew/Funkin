package funkin.shaderslmfao;

import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import flixel.system.FlxAssets.FlxShader;
import haxe.CallStack;
import lime.graphics.opengl.GLProgram;
import lime.utils.Log;

class RuntimePostEffectShader extends FlxRuntimeShader
{
  @:glVertexHeader("
		varying vec2 fragCoord; // normalized texture coord
		varying vec2 screenPos; // y: always between 0 and 1, x: between 0 and (width/height)
		uniform vec2 screenResolution;
	", true)
  @:glVertexBody("
		fragCoord = vec2(
			openfl_TextureCoord.x > 0.0 ? 1.0 : 0.0,
			openfl_TextureCoord.y > 0.0 ? 1.0 : 0.0
		);
		screenPos = fragCoord * vec2(screenResolution.x / screenResolution.y, 1.0);
	")
  @:glFragmentHeader("
		varying vec2 fragCoord;
		varying vec2 screenPos;

		vec2 texCoordSize() { // hack
			return openfl_TextureCoordv / fragCoord;
		}
	", true)
  public function new(fragmentSource:String = null, glVersion:String = null)
  {
    super(fragmentSource, null, glVersion);
    screenResolution.value = [FlxG.width, FlxG.height];
  }

  override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
  {
    try
    {
      final res = super.__createGLProgram(vertexSource, fragmentSource);
      return res;
    }
    catch (error)
    {
      Log.warn(error);
      return null;
    }
  }
}
