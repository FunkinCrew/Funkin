package ui;

import flixel.FlxSprite;

class MenuItem extends FlxSprite
{
	public var fireInstantly:Bool = false;
	public var name:String;
	public var callback:Dynamic;
	public var selected(get, never):Bool;

	function get_selected()
		return alpha == 1;

	public function new(?x:Float = 0, ?y:Float = 0, name:String, ?callback:Dynamic)
	{
		super(x, y);
		antialiasing = true;
		setData(name, callback);
		idle();
	}

	public function setData(name:String, ?callback:Dynamic)
	{
		this.name = name;
		if (callback != null)
		{
			this.callback = callback;
		}
	}

	public function setItem(name:String, ?callback:Dynamic)
	{
		setData(name, callback);
		if (selected)
		{
			select();
		}
		else
		{
			idle();
		}
	}

	public function idle()
	{
		alpha = 0.6;
	}

	public function select()
	{
		alpha = 1;
	}
}