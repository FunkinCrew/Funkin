package ui;

import flixel.FlxSprite;

using StringTools;

class MenuItem extends FlxSprite
{
	public var fireInstantly:Bool;
	public var name:String;
	public var callback:Dynamic;

	public function new(X:Float = 0, Y:Float = 0, name:String = "", callback:Dynamic = null)
	{
		fireInstantly = false;
		super(X, Y);
		antialiasing = true;
		setData(name, callback);
		idle();
	}

	public function get_selected()
	{
		return this.alpha == 1;
	}

	public function setData(name:String, callback:Dynamic = null)
	{
		this.name = name;
		if (callback != null) this.callback = callback;
	}

	public function setItem(name:String, callback:Dynamic = null)
	{
		setData(name, callback);
		get_selected() ? select() : idle();
	}

	public function idle()
	{
		this.set_alpha(0.6);
	}

	public function select()
	{
		this.set_alpha(1);
	}
}