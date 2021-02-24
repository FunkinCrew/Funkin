package;

import flixel.FlxSprite;
import flixel.FlxSubState;

class ControlsSubState extends FlxSubState
{
	public function new()
	{
		super();

		var bullshit = new FlxSprite().makeGraphic(100, 100);
		add(bullshit);
	}
}
