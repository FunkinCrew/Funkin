package shaderslmfao;

class ColorSwap
{
	public var hueShit:Float = 0;
	public var hasOutline:Bool = false;
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();

	public function new()
	{
		shader.uTime.value = [0];
		shader.money.value = [0];
		shader.awesomeOutline.value = [this.hasOutline];
	}

	public function update(elapsed:Float)
	{
		shader.uTime.value[0] += elapsed;
		hueShit += elapsed;
	}
}