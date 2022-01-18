package ui;

import flixel.FlxSprite;

using StringTools;

class MenuItem extends FlxSprite
{
	public var fireInstantly:Bool = false;
	public var name:String;
	public var callback:Dynamic;
	public var selected(get, never):Bool;

	function get_selected()
		return alpha == 1;

	public function new(X:Float = 0, Y:Float = 0, name:String = "", callback:Dynamic = null)
	{
		super(X, Y);
		antialiasing = true;
		setData(name, callback);
		idle();
	}

	public function setData(name:String, callback:Dynamic = null)
	{
		this.name = name;
		if (callback != null)
		{
			this.callback = callback;
		}
	}

	public function setItem(name:String, callback:Dynamic = null)
	{
		setData(name, callback);
		selected ? select() : idle();
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