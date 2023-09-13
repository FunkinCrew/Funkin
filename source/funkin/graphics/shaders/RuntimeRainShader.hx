package funkin.shaderslmfao;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;

typedef Light =
{
  var position:Array<Float>;
  var color:Array<Float>;
  var radius:Float;
}

class RuntimeRainShader extends RuntimePostEffectShader
{
  static final MAX_LIGHTS:Int = 8;

  public var lights:Array<
    {
      position:ShaderParameter<Float>,
      color:ShaderParameter<Float>,
      radius:ShaderParameter<Float>,
    }>;

  public var time(default, set):Float = 1;

  function set_time(value:Float):Float
  {
    this.setFloat('uTime', value);
    return time = value;
  }

  // The scale of the rain depends on the world coordinate system, so higher resolution makes
  // the raindrops smaller. This parameter can be used to adjust the total scale of the scene.
  // The size of the raindrops is proportional to the value of this parameter.
  public var scale(default, set):Float = 1;

  function set_scale(value:Float):Float
  {
    this.setFloat('uScale', value);
    return scale = value;
  }

  // The intensity of the rain. Zero means no rain and one means the maximum amount of rain.
  public var intensity(default, set):Float = 1;

  function set_intensity(value:Float):Float
  {
    this.setFloat('uIntensity', value);
    return intensity = value;
  }

  public var puddleMap(default, set):BitmapData;

  public var groundMap(default, set):BitmapData;

  function set_groundMap(value:BitmapData):BitmapData
  {
    trace('groundmap set');
    this.setBitmapData('uGroundMap', value);
    // this.setFloat2('uPuddleTextureSize', value.width, value.height);
    return groundMap = value;
  }

  function set_puddleMap(value:BitmapData):BitmapData
  {
    this.setBitmapData('uPuddleMap', value);
    return puddleMap = value;
  }

  public var lightMap(default, set):BitmapData;

  function set_lightMap(value:BitmapData):BitmapData
  {
    trace('lightmap set');
    this.setBitmapData('uLightMap', value);
    return lightMap = value;
  }

  public var numLights(default, set):Int = 0;

  function set_numLights(value:Int):Int
  {
    this.setInt('numLights', value);
    return numLights = value;
  }

  public function new()
  {
    super(Assets.getText(Paths.frag('rain')));
  }

  public function update(elapsed:Float):Void
  {
    time += elapsed;
  }

  override function __processGLData(source:String, storageType:String):Void
  {
    super.__processGLData(source, storageType);
    if (storageType == 'uniform')
    {
      lights = [
        for (i in 0...MAX_LIGHTS)
          {
            position: addFloatUniform('lights[$i].position', 2),
            color: addFloatUniform('lights[$i].color', 3),
            radius: addFloatUniform('lights[$i].radius', 1),
          }
      ];
    }
  }

  @:access(openfl.display.ShaderParameter)
  function addFloatUniform(name:String, length:Int):ShaderParameter<Float>
  {
    final res = new ShaderParameter<Float>();
    res.name = name;
    res.type = [null, FLOAT, FLOAT2, FLOAT3, FLOAT4][length];
    res.__arrayLength = 1;
    res.__isFloat = true;
    res.__isUniform = true;
    res.__length = length;
    __paramFloat.push(res);
    return res;
  }
}
