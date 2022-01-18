package;

import flixel.FlxG;
import flixel.FlxSprite;

class NoteSplash extends FlxSprite
{
	public function new(x:Float, y:Float, ?notedata:Int = 0)
	{
		super(x, y);
		frames = Paths.getSparrowAtlas('noteSplashes');
		animation.addByPrefix('note1-0', 'note impact 1  blue', 24, false);
		animation.addByPrefix('note2-0', 'note impact 1 green', 24, false);
		animation.addByPrefix('note0-0', 'note impact 1 purple', 24, false);
		animation.addByPrefix('note3-0', 'note impact 1 red', 24, false);
		animation.addByPrefix('note1-1', 'note impact 2 blue', 24, false);
		animation.addByPrefix('note2-1', 'note impact 2 green', 24, false);
		animation.addByPrefix('note0-1', 'note impact 2 purple', 24, false);
		animation.addByPrefix('note3-1', 'note impact 2 red', 24, false);
		setupNoteSplash(x, y, notedata);
	}

	public function setupNoteSplash(x:Float, y:Float, ?notedata:Int = 0)
	{
		setPosition(x, y);
		alpha = 0.6;
		animation.play('note' + notedata + '-' + FlxG.random.int(0, 1), true);
		animation.curAnim.frameRate += FlxG.random.int(-2, 2);
		updateHitbox();
		offset.set(width * 0.3, height * 0.3);
	}

	override public function update(elapsed:Float)
	{
		if (animation.curAnim.finished)
			kill();
		
		super.update(elapsed);
	}
}