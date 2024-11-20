import flixel.addons.display.FlxRuntimeShader;

class AddColorShader extends FlxRuntimeShader
{
	// ARGB = FlxColor
	public var color:Int = 0xFFFFFFFF;

	function new(color:Int = 0xFFFFFFFF)
	{
		var fragText:String = Assets.getText(Paths.frag('addColor'));
		super(fragText);
		setColor(color);
	}

	function setColor(value:Int):Void
	{
		this.color = value;

		this.setFloat('colorAlpha', ((this.color >> 24) & 0xff) / 255.0);
		this.setFloat('colorRed', ((this.color >> 16) & 0xff) / 255.0);
		this.setFloat('colorGreen', ((this.color >> 8) & 0xff) / 255.0);
		this.setFloat('colorBlue', ((this.color) & 0xff) / 255.0);
	}
}
