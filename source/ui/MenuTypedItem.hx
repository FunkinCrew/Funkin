package ui;

import flixel.util.FlxColor;

class MenuTypedItem extends MenuItem
{
	public var label(default, set):AtlasText;

	override public function new(?x:Float = 0, ?y:Float = 0, atlasText:AtlasText, text:String, ?callback:Dynamic)
	{
		super(x, y, text, callback);
		label = atlasText;
	}

	public function setEmptyBackground()
	{
		var prevWidth:Float = width;
		var prevHeight:Float = height;
		makeGraphic(1, 1, FlxColor.TRANSPARENT);
		width = prevWidth;
		height = prevHeight;
	}

	function set_label(atlasText:AtlasText)
	{
		if (atlasText != null)
		{
			atlasText.x = x;
			atlasText.y = y;
			atlasText.alpha = alpha;
		}
		return label = atlasText;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (label != null)
			label.update(elapsed);
	}

	override public function draw()
	{
		super.draw();
		if (label != null)
		{
			label.cameras = cameras;
			label.scrollFactor.copyFrom(scrollFactor);
			label.draw();
		}
	}

	override public function set_alpha(Alpha:Float)
	{
		super.set_alpha(Alpha);
		if (label != null)
			label.alpha = alpha;
		return alpha;
	}

	override public function set_x(NewX:Float)
	{
		super.set_x(NewX);
		if (label != null)
			label.x = x;
		return x;
	}

	override public function set_y(NewY:Float)
	{
		super.set_y(NewY);
		if (label != null)
			label.y = y;
		return y;
	}
}