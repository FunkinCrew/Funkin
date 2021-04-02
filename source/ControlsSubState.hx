package;

import flixel.input.keyboard.FlxKey;
import flixel.input.keyboard.FlxKeyboard;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ControlsSubState extends MusicBeatSubstate
{
	var entryMap:Map<String, Controls.Control> = [
		"Up" => Controls.Control.UP,
		"Down" => Controls.Control.DOWN,
		"Left" => Controls.Control.LEFT,
		"Right" => Controls.Control.RIGHT,
		"Reset" => Controls.Control.RESET,
		"Accept" => Controls.Control.ACCEPT,
		"Back" => Controls.Control.BACK,
		"Cheat" => Controls.Control.CHEAT		// should this be rebindable?
	];
	var id2NameMap:Map<Int, String> = [];

	var selector:FlxSprite;
	var curSelected:Int = 0;

	var grpOptionsTexts:FlxTypedGroup<FlxText>;
	var grpControlValues:FlxTypedGroup<FlxText>;

	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<FlxText>();
		add(grpOptionsTexts);
		grpControlValues = new FlxTypedGroup<FlxText>();
		add(grpControlValues);

		selector = new FlxSprite().makeGraphic(4, 4, FlxColor.RED);
		add(selector);

		var i:Int = 0;
		for (name in entryMap.keys()) {
			var control:Controls.Control = entryMap[name];
			id2NameMap[i] = name;
			var optionText:FlxText = new FlxText(20, 20 + (i * 50), 0, name, 32);
			optionText.ID = i;
			grpOptionsTexts.add(optionText);
			var controlsText:FlxText = new FlxText(240, 20 + (i * 50), 0, "<NOT BOUND>", 32);
			for (keyID in controls.getInputsFor(control, Controls.Device.Keys)) { // TODO gamepad support??
				// ugly 2-line cast, ugh
				var flxKey:FlxKey = keyID;
				if (controlsText.text == "<NOT BOUND>")
					controlsText.text = flxKey.toString();
				else
					controlsText.text += " or " + flxKey.toString();
			}
			controlsText.ID = i;
			grpControlValues.add(controlsText);
			i++;
		}
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

		if (controls.UP_P)
			curSelected -= 1;

		if (controls.DOWN_P)
			curSelected += 1;

		if (curSelected < 0)
			curSelected = grpOptionsTexts.length - 1;

		if (curSelected >= grpOptionsTexts.length)
			curSelected = 0;

		grpOptionsTexts.forEach(function(txt:FlxText)
		{
			txt.color = FlxColor.WHITE;

			if (txt.ID == curSelected) {
				txt.color = FlxColor.YELLOW;
				selector.x = txt.x - selector.width - 2;
				selector.y = txt.y + (txt.height / 2) - (selector.height / 2);
			}
		});
		grpControlValues.forEach(function(txt:FlxText)
		{
			txt.color = FlxColor.WHITE;

			if (txt.ID == curSelected)
				txt.color = FlxColor.YELLOW;
		});
	}
}
