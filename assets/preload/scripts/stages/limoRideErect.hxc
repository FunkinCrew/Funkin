import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.play.stage.Stage;
import funkin.play.PlayState;
import funkin.graphics.shaders.OverlayBlend;
import funkin.graphics.shaders.AdjustColorShader;
import flixel.addons.display.FlxBackdrop;

class LimoRideErectStage extends Stage
{
	function new()
	{
		super('limoRideErect');
	}

  var colorShader:AdjustColorShader;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;
	var mist3:FlxBackdrop;
	var mist4:FlxBackdrop;
	var mist5:FlxBackdrop;

	var shootingStarBeat:Int = 0;
	var shootingStarOffset:Int = 2;

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
			//limoSunset.shader = skyOverlay;
		}

		// There's some commented-out shader BS in the original code.
		// I don't know what it's for, but it's not used in the game.
		// If you want to re-add it, go find it in version control.

    colorShader = new AdjustColorShader();

    mist1 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), 0x01);
		mist1.setPosition(-650, -100);
		mist1.scrollFactor.set(1.1, 1.1);
		mist1.zIndex = 400;
    mist1.blend = 0;
		mist1.color = 0xFFc6bfde;
		mist1.alpha = 0.4;
		mist1.velocity.x = 1700;

		PlayState.instance.currentStage.add(mist1);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist2 = new FlxBackdrop(Paths.image('limo/erect/mistBack'), 0x01);
		mist2.setPosition(-650, -100);
		mist2.scrollFactor.set(1.2, 1.2);
		mist2.zIndex = 401;
    mist2.blend = 0;
		mist2.color = 0xFF6a4da1;
		mist2.alpha = 1;
		mist2.velocity.x = 2100;
		mist1.scale.set(1.3, 1.3);

		PlayState.instance.currentStage.add(mist2);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist3 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), 0x01);
		mist3.setPosition(-650, -100);
		mist3.scrollFactor.set(0.8, 0.8);
		mist3.zIndex = 99;
   	mist3.blend = 0;
		mist3.color = 0xFFa7d9be;
		mist3.alpha = 0.5;
		mist3.velocity.x = 900;
		mist3.scale.set(1.5, 1.5);

		PlayState.instance.currentStage.add(mist3);
		PlayState.instance.currentStage.refresh(); // Apply z-index.


		mist4 = new FlxBackdrop(Paths.image('limo/erect/mistBack'), 0x01);
		mist4.setPosition(-650, -380);
		mist4.scrollFactor.set(0.6, 0.6);
		mist4.zIndex = 98;
    mist4.blend = 0;
		mist4.color = 0xFF9c77c7;
		mist4.alpha = 1;
		mist4.velocity.x = 700;
		mist4.scale.set(1.5, 1.5);

		PlayState.instance.currentStage.add(mist4);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist5 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), 0x01);
		mist5.setPosition(-650, -400);
		mist5.scrollFactor.set(0.2, 0.2);
		mist5.zIndex = 15;
   	mist5.blend = 0;
		mist5.color = 0xFFE7A480;
		mist5.alpha = 1;
		mist5.velocity.x = 100;
		mist5.scale.set(1.5, 1.5);

		PlayState.instance.currentStage.add(mist5);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		getNamedProp('shootingStar').blend = 0;

		resetFastCar();
	}

	var _timer:Float = 0;

  function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		_timer += event.elapsed;
		mist1.y = 100 + (Math.sin(_timer)*200);
		mist2.y = 0 + (Math.sin(_timer*0.8)*100);
		mist3.y = -20 + (Math.sin(_timer*0.5)*200);
		mist4.y = -180 + (Math.sin(_timer*0.4)*300);
		mist5.y = -450 + (Math.sin(_timer*0.2)*150);
		//trace(mist1.y);

    if(PlayState.instance.currentStage.getBoyfriend() != null && PlayState.instance.currentStage.getBoyfriend().shader == null){
      PlayState.instance.currentStage.getBoyfriend().shader = colorShader;
		  PlayState.instance.currentStage.getGirlfriend().shader = colorShader;
		  PlayState.instance.currentStage.getDad().shader = colorShader;
		  getNamedProp('limoDancer1').shader = colorShader;
      getNamedProp('limoDancer2').shader = colorShader;
  	  getNamedProp('limoDancer3').shader = colorShader;
      getNamedProp('limoDancer4').shader = colorShader;
      getNamedProp('limoDancer5').shader = colorShader;
      getNamedProp('fastCar').shader = colorShader;

			// PlayState.instance.currentStage.getBoyfriend().visible = false;
		  // PlayState.instance.currentStage.getGirlfriend().visible = false;
		  // PlayState.instance.currentStage.getDad().visible = false;
		 	// getNamedProp('limo').visible = false;
			// getNamedProp('limoDancer1').visible = false;
      // getNamedProp('limoDancer2').visible = false;
  	  // getNamedProp('limoDancer3').visible = false;
      // getNamedProp('limoDancer4').visible = false;
      // getNamedProp('limoDancer5').visible = false;
      // getNamedProp('fastCar').visible = false;
			// getNamedProp('bgLimo').visible = false;
			// getNamedProp('limoSunset').visible = false;
			// getNamedProp('shootingStar').visible = false;

		  colorShader.hue = -30;
		  colorShader.saturation = -20;
		  colorShader.contrast = 0;
		  colorShader.brightness = -30;
    }
  }

	function doShootingStar(beat:Int):Void
	{
		getNamedProp('shootingStar').x = FlxG.random.int(50,900);
		getNamedProp('shootingStar').y = FlxG.random.int(-10,20);
		getNamedProp('shootingStar').flipX = FlxG.random.bool(50);
		getNamedProp('shootingStar').animation.play('shooting star');

		shootingStarBeat = beat;
		shootingStarOffset = FlxG.random.int(4, 8);

	}

	function onBeatHit(event:SongTimeScriptEvent)
	{
		// When overriding onBeatHit, make sure to call super.onBeatHit,
		// otherwise boppers will not work.
		super.onBeatHit(event);

		if (FlxG.random.bool(10) && fastCarCanDrive)
			fastCarDrive();

		if (FlxG.random.bool(10) && event.beat > (shootingStarBeat + shootingStarOffset))
		{
			doShootingStar(event.beat);
		}
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
		shootingStarBeat = 0;
		shootingStarOffset = 2;
	}

	/**
	 * Make sure the fast car is reset when the song restarts.
	 */
	function onCountdownStart(event:ScriptEvent) {
		super.onCountdownStart(event);
		resetFastCar();
	}
}
