package ui;

import flixel.util.FlxColor;

using StringTools;

class MenuTypedItem extends MenuItem
{
	var label:Dynamic;

	override public function new(x:Float, y:Float, object:AtlasText, text:String, callback:Dynamic = null)
	{
		super(x, y, text, callback);
		set_label(object);
	}

	public function setEmptyBackground()
	{
		var prevWidth = width;
		var prevHeight = height;
		makeGraphic(1, 1, FlxColor.TRANSPARENT);
		width = prevWidth;
		height = prevHeight;
	}

	public function set_label(a:AtlasText)
	{
		if (a != null)
		{
			a.set_x(x);
			a.set_y(y);
			a.set_alpha(alpha);
		}
		return label = a;
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
			label.set_cameras(get_cameras());
			label.scrollFactor.x = scrollFactor.x;
			label.scrollFactor.y = scrollFactor.y;
			scrollFactor.putWeak();
			label.draw();
		}
	}

	override public function set_alpha(Alpha:Float)
	{
		super.set_alpha(Alpha);
		if (label != null)
			label.set_alpha(alpha);
		return alpha;
	}

	override public function set_x(NewX:Float)
	{
		super.set_x(NewX);
		if (label != null)
			label.set_x(x);
		return x;
	}

	override public function set_y(NewY:Float)
	{
		super.set_y(NewY);
		if (label != null)
			label.set_y(y);
		return y;
	}
}