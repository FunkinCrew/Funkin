package ui;

import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;

class StageBuilderState extends MusicBeatState
{
	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();

		var bg:FlxSprite = FlxGridOverlay.create(10, 10);
		add(bg);
	}
}
