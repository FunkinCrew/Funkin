package shaderslmfao;

import flixel.system.FlxAssets.FlxShader;

class BuildingShaders
{
	public var shader(default, null):BuildingShader;
	public var daAlpha:Float = 1;

	public function new():Void
	{
		shader = new BuildingShader();
		shader.alphaShit.value = [0];
	}

	public function update(elapsed:Float):Void
	{
		shader.alphaShit.value[0] += elapsed;
	}

	public function reset()
	{
		shader.alphaShit.value[0] = 0;
	}
}

class BuildingShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform float alphaShit;

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

            if (color.a > 0.0)
                color -= alphaShit;
            
            gl_FragColor = color;
        }

    ')
	public function new()
	{
		super();
	}
}
