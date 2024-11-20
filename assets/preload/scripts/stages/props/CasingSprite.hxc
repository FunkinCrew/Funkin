import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import funkin.Conductor;
import funkin.util.BezierUtil;

// We have to use FlxBasePoint in scripts because FlxPoint is inlined and not available in scripts
import flixel.math.FlxBasePoint;

/**
 * A sprite which represents a bullet flying through the air after Pico reloads.
 */
class CasingSprite extends FunkinSprite
{
	function new()
	{
		super(0, 0);

		zIndex = 1900;

		loadSparrow('PicoBullet');

		// Active needs to be true to enable updates.
		// This includes velocity/acceleration and frame animations.
		active = true;

		animation.addByPrefix('pop', "Pop0", 24, false);
		animation.addByPrefix('idle', "Bullet0", 24, true);
		animation.play('pop');
		animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
			if (name == 'pop' && frameNumber == 40) {
				startRoll();
			}
		};
	}

	function startRoll() {
		this.animation.callback = null; // Save performance.

		// Get the end position of the bullet dynamically.
		this.x = this.x + this.frame.offset.x - 1;
		this.y = this.y + this.frame.offset.y + 1;

		this.angle = 125.1; // Copied from FLA

		// Okay this is the neat part, we can set the velocity and angular acceleration to make it roll without editing update().
		var randomFactorA = FlxG.random.float(3, 10);
		var randomFactorB = FlxG.random.float(1.0, 2.0);
		this.velocity.x = 20 * randomFactorB;
		this.drag.x = randomFactorA * randomFactorB;


		this.angularVelocity = 100;
		// Calculated to ensure angular acceleration is maintained through the whole roll.
		this.angularDrag = (this.drag.x / this.velocity.x) * 100;

		animation.play('idle');
	}
}

