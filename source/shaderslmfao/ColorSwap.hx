package shaderslmfao;

class ColorSwap
{
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hasOutline:Bool = false;
	public var hueShit:Float = 0;

	public function new():Void
	{
		shader.uTime.value = [0];
		shader.money.value = [0];
		shader.awesomeOutline.value = [hasOutline];
	}

	public function update(elapsed:Float):Void
	{
		shader.uTime.value[0] += elapsed;
		hueShit += elapsed;
	}
}