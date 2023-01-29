package ui;

import flixel.FlxSprite;

class Checkbox extends FlxSprite
{
	public var checked(default, set):Bool;

	public function new(?x, ?y, isChecked:Bool = false) {
		super(x, y);

		var tex = Paths.getSparrowAtlas('checkboxThingie');
		frames = tex;

		animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
		animation.addByPrefix('static', 'Check Box unselected', 24, false);

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		checked = isChecked;
	}

	function set_checked(value:Bool):Bool {
		if (value)
			animation.play("checked", true);
		else 
			animation.play("static");
		return checked = value;
	}

	override public function update(dt:Float) {
		super.update(dt);

		switch (this.animation.curAnim.name) {
			case "checked":
				this.offset.set(17, 70);
			case "static":
				this.offset.set();
		}
		
	}
}