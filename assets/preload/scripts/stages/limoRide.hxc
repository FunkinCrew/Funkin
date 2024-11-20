import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.play.stage.Stage;
import funkin.play.PlayState;
import funkin.graphics.shaders.OverlayBlend;

class LimoRideStage extends Stage
{
	function new()
	{
		super('limoRide');
	}

	function buildStage()
	{
		super.buildStage();

		// Apply sky shader.
		var skyOverlay:OverlayBlend = new OverlayBlend();
		var sunOverlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('limo/limoOverlay'));
		sunOverlay.setGraphicSize(Std.int(sunOverlay.width * 2));
		sunOverlay.updateHitbox();
		skyOverlay.funnyShit.input = sunOverlay.pixels;
		var limoSunset:FlxSprite = getNamedProp('limoSunset');
		if (limoSunset == null) {
			trace('[WARN] Could not retrieve limoSunset');
		} else {
			limoSunset.shader = skyOverlay;
		}

		// There's some commented-out shader BS in the original code.
		// I don't know what it's for, but it's not used in the game.
		// If you want to re-add it, go find it in version control.

		resetFastCar();
	}

	function onBeatHit(event:SongTimeScriptEvent)
	{
		// When overriding onBeatHit, make sure to call super.onBeatHit,
		// otherwise boppers will not work.
		super.onBeatHit(event);

		if (FlxG.random.bool(10) && fastCarCanDrive)
			fastCarDrive();
	}

	var fastCarCanDrive:Bool = false;

	function resetFastCar():Void
	{
		var fastCar = getNamedProp('fastCar');

		if (fastCar == null)
			return;

		// Props are inactive by default.
		// Set active to true so position is calculated based on velocity.
		fastCar.active = true;

		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive():Void
	{
		FunkinSound.playOnce(Paths.soundRandom('carPass', 0, 1), 0.7);

		var fastCar = getNamedProp('fastCar');
		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	/**
	 * If your stage uses additional assets not specified in the JSON,
	 * make sure to specify them like this, or they won't get cached in the loading screen.
	 */
	function fetchAssetPaths():Array<String>
	{
		var results:Array<String> = super.fetchAssetPaths();

		// This graphic is applied by shader to the background, so it's not included in the default stage function.
		results.push(Paths.image('limo/limoOverlay'));
		results.push(Paths.sound('carPass0'));
		results.push(Paths.sound('carPass1'));

		return results;
	}

	/**
	 * Make sure the fast car is reset when the song restarts.
	 */
	function onSongRetry(event:ScriptEvent) {
		super.onSongRetry(event);
		resetFastCar();
	}

	/**
	 * Make sure the fast car is reset when the song restarts.
	 */
	function onCountdownStart(event:ScriptEvent) {
		super.onCountdownStart(event);
		resetFastCar();
	}
}
