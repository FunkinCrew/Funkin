package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;

class MenuItem extends FlxSpriteGroup
{
	public function new(x:Float, y:Float, week:Int = 0, unlocked:Bool = false)
	{
		super(x, y);

		var tex = FlxAtlasFrames.fromSparrow(AssetPaths.campaign_menu_UI_assets__png, AssetPaths.campaign_menu_UI_assets__xml);

		var week:FlxSprite = new FlxSprite();
		week.frames = tex;
		week.animation.addByPrefix('week0', "WEEK1 select", 24);
		week.animation.addByPrefix('week1', "week2 select", 24);
		add(week);

		week.animation.play('week' + week);
		week.updateHitbox();

		if (!unlocked)
		{
			week.alpha = 0.6;

			var lock:FlxSprite = new FlxSprite(week.frameWidth + 5);
			lock.frames = tex;
			lock.animation.addByPrefix('lock', 'lock');
			lock.animation.play('lock');
			add(lock);
		}
	}
}
