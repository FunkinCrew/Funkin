package shaders;

import flixel.system.FlxAssets;

using StringTools;

class Shaders
{
    public static function newEffect(?name:String = "3d"):Dynamic
    {
        switch(name.toLowerCase())
        {
            case "3d":
                return new ThreeDEffect();
        }

        return new ThreeDEffect();
    }
}

class ShaderEffect
{
    public function update(elapsed:Float)
    {
        // nothing yet
    }
}

class ThreeDEffect extends ShaderEffect
{
    public var shader(default,null):ThreeDShader = new ThreeDShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new():Void
	{
		shader.uTime.value = [0];
	}

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;
    }

    function set_waveSpeed(v:Float):Float
    {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float
    {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float
    {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }
}

class ThreeDShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header
    //uniform float tx, ty; // x,y waves phase

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = texture2D(bitmap, uv);
    }')

    public function new()
    {
       super();
    }
}