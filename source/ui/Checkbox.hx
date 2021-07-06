package ui;

import flixel.FlxSprite;

class Checkbox extends FlxSprite
{
	public var checked:Bool;

	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(?x, ?y, isChecked:Bool = false) {
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();

		checked = isChecked;

		var tex = Paths.getSparrowAtlas('checkboxThingie');
		frames = tex;

		animation.addByPrefix('selected', 'Check Box Selected Static', 24, false);
		animation.addByPrefix('animation', 'Check Box selecting animation', 24, false);
		animation.addByPrefix('unselected', 'Check Box unselected', 24, false);

		addOffset('unselected');
		addOffset('animation', 15, 133);
		addOffset('selected', 15, 133);
		

		change(checked);

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	public function change(?isChecked:Bool) {
		if (isChecked != null)
			checked = isChecked;
		else
			checked = !checked;
		trace(checked);
		if (checked)
			playAnim('animation');
		else
			playAnim('unselected');

		return checked;
	}

	override public function update(dt:Float) {
		super.update(dt);

		switch (this.animation.curAnim.name) {
			case "animation":
				this.offset.set(17, 70);
			case "unselected":
				this.offset.set();
		}
		
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else{
			offset.set(0, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

}