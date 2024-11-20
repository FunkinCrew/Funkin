import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxRuntimeShader;
import flixel.sound.FlxSound;
import funkin.audio.FunkinSound;
import funkin.Conductor;
import funkin.modding.base.ScriptedFlxRuntimeShader;
import funkin.play.PlayState;
import funkin.play.stage.Stage;

class PhillyTrainStage extends Stage
{
	function new()
	{
		super('phillyTrain');
	}

	var LIGHT_COUNT:Int = 5;

	var lightShader:FlxRuntimeShader;
	var trainSound:FunkinSound;

	function buildStage()
	{
		super.buildStage();

		// NOTE: You pass the constructor variables directly, not as an array.
		lightShader = ScriptedFlxRuntimeShader.init('BuildingEffectShader', 1.0);
		trainSound = FunkinSound.load(Paths.sound('train_passes'), 1.0, false, false, false);
		PlayState.instance.add(trainSound); // Sounds need to be added to the scene for update() to work

		for (i in 0...LIGHT_COUNT)
		{
			var light:FlxSprite = getNamedProp('lights' + i);
			light.shader = lightShader;
			light.visible = false;
		}
	}

	function fetchAssetPaths():Array<String>
	{
		var results:Array<String> = super.fetchAssetPaths();
		results.push(Paths.sound('train_passes'));
		return results;
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);
		// Update beat lights
		var shaderInput:Float = (Conductor.instance.beatLengthMs / 1000) * event.elapsed * 1.5;
		lightShader.scriptCall('update', [shaderInput]);

		// Update train
		if (trainMoving)
		{
			trainFrameTiming += event.elapsed;

			if (trainFrameTiming >= 1 / 24)
			{
				updateTrainPos();
				trainFrameTiming = 0;
			}
		}
	}

	function onBeatHit(event:SongTimeScriptEvent):Void
	{
		super.onBeatHit(event);
		// Update train cooldown
		if (!trainMoving)
			trainCooldown += 1;

		// Start train
		if (event.beat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
		{
			trainCooldown = FlxG.random.int(-4, 0);
			trainStart();
		}

		// Update lights
		if (event.beat % 4 == 0)
		{
			// Reset opacity
			lightShader.scriptCall('reset');

			// Switch to a different light
			curLight = FlxG.random.int(0, LIGHT_COUNT - 1);
			for (i in 0...LIGHT_COUNT)
			{
				getNamedProp('lights' + i).visible = (i == curLight);
			}
		}
	}

	public override function onSongEnd(event:CountdownScriptEvent):Void {
		super.onSongEnd(event);
		// Disable lightning during ending cutscene.
		trainMoving = false;
		if (trainSound != null) {
			trainSound.stop();
			trainSound = null;
		}
	}

	public override function onPause(event:PauseScriptEvent) {
		super.onPause(event);

		// Temporarily stop ambiance.
		if (trainSound != null) trainSound.pause();
	}

	public override function onResume(event:ScriptEvent) {
		super.onResume(event);

		// Temporarily stop ambiance.
		if (trainSound != null) trainSound.resume();
	}

	function trainStart():Void
	{
		trainMoving = true;
		trainSound.play();
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			getGirlfriend().playAnimation('hairBlow');
		}

		if (startedMoving)
		{
			var train:FlxSprite = getNamedProp('train');
			train.x -= 400;

			if (train.x < -2000 && !trainFinishing)
			{
				train.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (train.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		getGirlfriend().playAnimation('hairFall');
		getNamedProp('train').x = FlxG.width + 200;

		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function kill()
	{
		super.kill();
		lightShader = null;
	}
}
