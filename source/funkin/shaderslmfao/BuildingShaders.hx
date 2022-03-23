package funkin.shaderslmfao;

import flixel.system.FlxAssets.FlxShader;

class BuildingShaders
{
	public var shader(default, null):BuildingShaderLegacy;

	public function new():Void
	{
		shader = new BuildingShaderLegacy();
		shader.buildingAlpha = 0;
	}

	public function update(elapsed:Float):Void
	{
		shader.buildingAlpha += elapsed;
	}

	public function reset()
	{
		shader.buildingAlpha = 0;
	}
}

class BuildingShader extends FlxRuntimeShader
{
	public var buildingAlpha(get, set):Float;

	function get_buildingAlpha():Float
	{
		return getFloat('alphaShit');
	}

	function set_buildingAlpha(value:Float):Float
	{
		// Every time buildingAlpha is changed, update the property of the shader.
		setFloat('alphaShit', value);
		return value;
	}

	static final FRAGMENT_SHADER = "
		#pragma header

    uniform float alphaShit;

    void main()
    {
        vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

        if (color.a > 0.0)
            color -= alphaShit;
        
        gl_FragColor = color;
    }
	";

	public function new()
	{
		super(FRAGMENT_SHADER, null, true);
	}
}

class BuildingShaderLegacy extends FlxShader
{
	public var buildingAlpha(get, set):Float;

	function get_buildingAlpha():Float
	{
		return alphaShit.value[0];
	}

	function set_buildingAlpha(value:Float):Float
	{
		// Every time buildingAlpha is changed, update the property of the shader.
		alphaShit.value = [value];
		return value;
	}

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
