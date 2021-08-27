package shaderslmfao;

import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;

class TitleOutline extends FlxShader
{
	// these r copypaste
	public var funnyX(default, set):Float = 0;
	public var funnyY(default, set):Float = 0;

	function set_funnyX(x:Float):Float
	{
		xPos.value[0] = x;

		return x;
	}

	function set_funnyY(y:Float):Float
	{
		yPos.value[0] = y;

		return y;
	}

	@:glFragmentSource('
        #pragma header

        uniform float alphaShit;

		uniform sampler2D funnyShit;


		vec3 blendOverlay(vec3 base, vec3 blend)
		{
			return mix(1.0 - 2.0 * (1.0 - base) * (1.0 - blend), 2.0 * base * blend, step(base, vec3(0.5)));
		}

        void main()
        {
			vec2 funnyUv = openfl_TextureCoordv;
            vec4 color = flixel_texture2D(bitmap, funnyUv);
            
			vec4 gf = flixel_texture2D(funnyShit, openfl_TextureCoordv);


			vec3 mixedCol = blendOverlay(color.rgb, gf.rgb);

            gl_FragColor = vec4(mixedCol, color.a);
        }

    ')
	public function new()
	{
		super();

		xPos.value = [0];
		yPos.value = [0];
	}
}
