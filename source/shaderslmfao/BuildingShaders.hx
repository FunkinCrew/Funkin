package shaderslmfao;

class BuildingShaders
{
	public var shader(default, null):BuildingShader = new BuildingShader();

	public function new():Void
	{
		shader.alphaShit.value = [0];
	}
	
	public function update(elapsed:Float):Void
	{
		shader.alphaShit.value[0] += elapsed;
	}

	public function reset():Void
	{
		shader.alphaShit.value[0] = 0;
	}
}