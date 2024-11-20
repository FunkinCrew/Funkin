import flixel.FlxG;
import flixel.math.FlxAngle;
import funkin.play.PlayState;
import funkin.play.stage.Stage;

class TankmanBattlefieldStage extends Stage
{
	function new()
	{
		super('tankmanBattlefield');
	}

	function onCreate(event:ScriptEvent):Void
	{
			super.onCreate(event);
	}

	override function buildStage()
	{
		super.buildStage();

		// Give the clouds a random position, and a velocity to make them move.
		var clouds = getNamedProp('clouds');
		clouds.active = true;
		clouds.x = FlxG.random.int(-700, -100);
		clouds.y = FlxG.random.int(-20, 20);
		clouds.velocity.x = FlxG.random.float(5, 15);

		tankAngle = FlxG.random.int(-90, 45);
		tankSpeed = FlxG.random.float(5, 7);
	}

	function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);
		moveTank(event.elapsed);
	}

	var tankMoving:Bool = false;
	var tankAngle:Float = FlxG.random.int(-90, 45);
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankX:Float = 400;

	function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
	}

	function moveTank(elapsed:Float):Void
	{
		var daAngleOffset:Float = 1;
		tankAngle += elapsed * tankSpeed;

		var tankRolling = getNamedProp('tankRolling');
		tankRolling.angle = tankAngle - 90 + 15;
		tankRolling.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
		tankRolling.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
	}

	function onSongRetry(event:ScriptEvent)
	{
		super.onSongRetry(event);

		// resets the clouds!
		var clouds = getNamedProp('clouds');
		clouds.active = true;
		clouds.x = FlxG.random.int(-700, -100);
		clouds.y = FlxG.random.int(-20, 20);
		clouds.velocity.x = FlxG.random.float(5, 15);
	}
}
