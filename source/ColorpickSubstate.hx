package;

import flixel.group.FlxGroup.FlxTypedGroup;
import shaderslmfao.ColorSwap;

class ColorpickSubstate extends MusicBeatSubstate
{
	var curSelected:Int = 0;

	var grpNotes:FlxTypedGroup<Note>;

	public function new()
	{
		super();

		grpNotes = new FlxTypedGroup<Note>();
		add(grpNotes);

		for (i in 0...4)
		{
			var note:Note = new Note(0, i);

			note.x = (100 * i) + i;
			note.screenCenter(Y);

			grpNotes.add(note);
		}
	}

	override function update(elapsed:Float)
	{
		if (controls.RIGHT_P)
			curSelected += 1;
		if (controls.LEFT_P)
			curSelected -= 1;

		if (curSelected < 0)
			curSelected = grpNotes.members.length - 1;
		if (curSelected >= grpNotes.members.length)
			curSelected = 0;

		if (controls.UP)
		{
			grpNotes.members[curSelected].colorSwap.update(elapsed * 0.3);
			Note.arrowColors[curSelected] += elapsed * 0.3;
		}

		if (controls.DOWN)
		{
			grpNotes.members[curSelected].colorSwap.update(-elapsed * 0.3);
			Note.arrowColors[curSelected] += -elapsed * 0.3;
		}

		super.update(elapsed);
	}
}
