package ui;

import flixel.FlxSprite;

class MenuCharacter extends FlxSprite
{
	public var character:String;

	private static var characters:Array<Dynamic> = [
		["bf"],
		["bfConfirm", true],
		["gf"],
		["dad"],
		["spooky"],
		["pico"],
		["mom"],
		["parents"],
		["senpai"]
	];

	public function new(x:Float, character:String = 'bf', ?looped:Bool = true)
	{
		super(x);

		this.character = character;

		frames = Paths.getSparrowAtlas('campaign_menu_UI_characters');

		for(x in characters)
		{
			animation.addByPrefix(x[0], x[0] + "0", 24, !x[1]);
		}

		animation.play(character);

		updateHitbox();
	}
}

class MenuCharacterData
{
	public var Animation_Name:String = "bf";
	public var FPS:Int = 24;
	public var Animation_Looped:Bool = false;
	public var Offsets:Array<Int> = [0, 0];

	public function new(_Animation_Name:String = "bf", _Animation_Looped:Bool = false, _Offsets:Array<Int>, ?_FPS:Int = 24)
	{
		this.Animation_Name = _Animation_Name;
		this.Animation_Looped = _Animation_Looped;
		this.Offsets = _Offsets;
		this.FPS = _FPS;
	}
}