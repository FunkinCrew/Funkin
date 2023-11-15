package funkin.graphics.shaders;

import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;

class LeftMaskShader extends FlxShader
{
  public var swagMaskX(default, set):Float = 0;
  public var swagSprX(default, set):Float = 0;
  public var frameUV(default, set):FlxRect;

  function set_swagSprX(x:Float):Float
  {
    sprX.value[0] = x;

    return x;
  }

  function set_swagMaskX(x:Float):Float
  {
    maskX.value[0] = x;

    return x;
  }

  function set_frameUV(uv:FlxRect):FlxRect
  {
    trace("SETTING FRAMEUV");
    trace(uv);

    uvFrameX.value[0] = uv.x;
    uvFrameY.value[0] = uv.y;

    return uv;
  }

  @:glFragmentSource('
        #pragma header

        uniform float sprX;
        uniform float maskX;

		uniform float uvFrameX;
		uniform float uvFrameY;

        void main()
        {

            float cutOff = maskX - sprX;
            float sprPos = cutOff / openfl_TextureSize.x;

            vec2 uv = openfl_TextureCoordv.xy;

            vec4 color = flixel_texture2D(bitmap, uv);

            if (uv.x < sprPos + uvFrameX)
            {
                color = vec4(0.0, 0.0, 0.0, 0.0);
            }

            gl_FragColor = color;
			// vec4 testCol = vec4(openfl_Position.x, openfl_Position.y, openfl_Position.z, 1.0);
			//gl_FragColor = vec4(1.0, openfl_TextureSize.x, 1.0, 1.0);

        }
    ')
  public function new()
  {
    super();

    sprX.value = [0];
    maskX.value = [0];
    uvFrameX.value = [0];
    uvFrameY.value = [0];
  }
}
