import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import funkin.Conductor;
import flixel.effects.FlxFlicker;

/**
 * A sprite which plays the 'run' animation while moving in the specified direction.
 * It then plays the 'shot' animation at a specific time in the song, then destroys itself.
 */
class TankmanSprite extends FunkinSprite
{
	// Randomize the horizontal position of the tankman when 'shot' plays.
	public var endingOffset:Float = 0;
	// Randomize the speed that the tankman moves to where it will be shot.
	public var runSpeed:Float = 0;
	// The time in milliseconds when the 'shot' animation should play.
	public var strumTime:Float = 0;
	// the side the tankman is running from
	public var goingRight:Bool = false;

	function new()
	{
		super();

		loadSparrow('tankmanKilled1');
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);

		initAnim();

		setGraphicSize(Std.int(width * 0.4));

		updateHitbox();
	}

	// shamelessly stolen from pico thank u ericc
	var tankmanFlicker:FlxFlicker = null;

	function deathFlicker() {
			// ERIC: You have to use super instead of this or it breaks.
			// This is because typeof(this) is PolymodAbstractClass.
     tankmanFlicker = FlxFlicker.flicker(super, 0.3, 1 / 10, true, true, function(_) {
      tankmanFlicker = FlxFlicker.flicker(super, 0.3, 1 / 20, false, true, function(_) {
				tankmanFlicker = null;
				kill();
			});
    });
	}

	function initAnim()
	{
		// Called when the sprite is created as well as when it is revived.

		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.numFrames - 1);

		offset.y = 0;
		offset.x = 0;
	}

	function revive()
	{
		// Sprite has been revived! This allows it to be reused without reinstantiating.
		super.revive();
		visible = true;
		initAnim();
	}

	function update(elapsed:Float):Void
	{
		super.update(elapsed);


		if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= 10 && tankmanFlicker == null)
		{
			deathFlicker();
		}
		// Check if we've reached the time when the tankman should be shot.
		if (Conductor.instance.songPosition >= strumTime && animation.curAnim.name == 'run')
		{
			animation.play('shot');

			offset.y = 200;
			offset.x = 300;
		}

		// Move the sprite while it is running.
		if (animation.curAnim.name == 'run')
		{
			// Here, the position is set to the target position where it will be shot.
			// Then, we move the sprite away from that position in the direction it's coming from.
			// songPosition - strumTime will get smaller over time until it reaches 0, when the 'shot' anim plays.
			if (!goingRight)
			{
				x = (FlxG.width * 0.02 - endingOffset) + ((Conductor.instance.songPosition - strumTime) * runSpeed);
			}
			else
			{
				x = (FlxG.width * 0.74 + endingOffset) - ((Conductor.instance.songPosition - strumTime) * runSpeed);
			}
		}

		// Hide this sprite if it is out of view.
		// if (x >= FlxG.width * 1.2 || x <= FlxG.width * -0.5)
		// 	visible = false;
		// else
		// 	visible = true;
	}
}
