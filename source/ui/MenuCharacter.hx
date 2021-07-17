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
