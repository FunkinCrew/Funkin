package shaderslmfao;

class BuildingShaders
{
	public var shader(default, null):BuildingShader = new BuildingShader();

	public function new()
	{
		shader.alphaShit.value = [0];
	}
	
	public function update(elapsed)
	{
		shader.alphaShit.value[0] += elapsed;
	}

	public function reset()
	{
		shader.alphaShit.value[0] = 0;
	}
}