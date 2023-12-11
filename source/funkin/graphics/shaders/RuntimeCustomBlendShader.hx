package funkin.shaderslmfao;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.utils.Assets;

class RuntimeCustomBlendShader extends RuntimePostEffectShader
{
	public var source(default, set):BitmapData;

	function set_source(value:BitmapData):BitmapData
	{
		this.setBitmapData("source", value);
		return source = value;
	}

	public var blend(default, set):BlendMode;

	function set_blend(value:BlendMode):BlendMode
	{
		this.setInt("blendMode", cast value);
		return blend = value;
	}

	public function new()
	{
		super(Assets.getText("assets/shaders/customBlend.frag"));
	}
}
