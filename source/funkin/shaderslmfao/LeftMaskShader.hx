package funkin.shaderslmfao;

import flixel.system.FlxAssets.FlxShader;

class LeftMaskShader extends FlxShader
{
	public var swagMaskX(default, set):Float = 0;
	public var swagSprX(default, set):Float = 0;

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

	@:glFragmentSource('
        #pragma header

        uniform float sprX;
        uniform float maskX;

        void main()
        {

            float cutOff = maskX - sprX;
            float sprPos = cutOff / openfl_TextureSize.x;

            vec2 uv = openfl_TextureCoordv.xy;

            vec4 color = flixel_texture2D(bitmap, uv);

            if (uv.x < sprPos)
            {
                color = vec4(0.0, 0.0, 0.0, 0.0);
            }

            gl_FragColor = color;
        }
    ')
	public function new()
	{
		super();

		sprX.value = [0];
		maskX.value = [0];
	}
}
