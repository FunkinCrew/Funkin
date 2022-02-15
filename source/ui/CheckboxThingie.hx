package ui;

import flixel.FlxSprite;

class CheckboxThingie extends FlxSprite
{
	public var daValue(default, set):Bool;

	override public function new(x:Float, y:Float, state:Bool = false)
	{
		super(x, y);
		frames = Paths.getSparrowAtlas('checkboxThingie');
		animation.addByPrefix('static', 'Check Box unselected', 24, false);
		animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
		antialiasing = true;
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		daValue = state;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		switch (animation.curAnim.name)
		{
			case 'checked':
				offset.set(17, 70);
			case 'static':
				offset.set();
		}
	}

	function set_daValue(state:Bool)
	{
		if (state)
			animation.play('checked', true);
		else
			animation.play('static');
		return state;
	}
}