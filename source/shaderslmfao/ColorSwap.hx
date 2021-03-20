package shaderslmfao;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class ColorSwap
{
	public var shader(default, null):ColorSwapShader;
	public var colorToReplace(default, set):FlxColor;
	public var newColor(default, set):FlxColor;

	public function new():Void
	{
		shader = new ColorSwapShader();
		shader.colorOld.value = [];
		shader.colorNew.value = [];
	}

	function set_colorToReplace(color:FlxColor):FlxColor
	{
		colorToReplace = color;

		shader.colorOld.value[0] = color.red;
		shader.colorOld.value[1] = color.green;
		shader.colorOld.value[2] = color.blue;

		return color;
	}

	function set_newColor(color:FlxColor):FlxColor
	{
		newColor = color;

		shader.colorNew.value[0] = color.red;
		shader.colorNew.value[1] = color.green;
		shader.colorNew.value[2] = color.blue;

		return color;
	}
}

class ColorSwapShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform vec3 colorOld;
        uniform vec3 colorNew;
        uniform float u_time;

        vec3 normalizeColor(vec3 color)
        {
            return vec3(
                color[0] / 255.0,
                color[1] / 255.0,
                color[2] / 255.0
            );
        }

        vec3 hueShift(vec3 color, float hue) {
            const vec3 k = vec3(0.57735, 0.57735, 0.57735);
            float cosAngle = cos(hue);
            return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
        }


        void main()
        {
            vec4 pixel = texture2D(bitmap, openfl_TextureCoordv);

            vec3 eps = vec3(0.02, 0.02, 0.02);

            vec3 colorOldNormalized = normalizeColor(colorOld);
            vec3 colorNewNormalized = normalizeColor(colorNew);

            if (all(greaterThanEqual(pixel, vec4(colorOldNormalized - eps, 1.0)) ) && all(lessThanEqual(pixel, vec4(colorOldNormalized + eps, 1.0)) )
            )
            {
                pixel = vec4(hueShift(colorOldNormalized, 0.7), 1.0);
            }

            gl_FragColor = pixel;
        }

    ')
	public function new()
	{
		super();
	}
}
