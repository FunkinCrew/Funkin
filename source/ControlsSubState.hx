package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;

class ControlsSubState extends MusicBeatSubstate
{
	public function new()
	{
		super();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.state.closeSubState();
			FlxG.state.openSubState(new OptionsSubState());
			return;
		}
	}
}
