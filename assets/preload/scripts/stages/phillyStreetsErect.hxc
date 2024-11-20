import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.audio.FunkinSound;
import funkin.Conductor;
import funkin.graphics.framebuffer.BitmapDataUtil;
import funkin.graphics.framebuffer.FixedBitmapData;
import funkin.graphics.shaders.OverlayBlend;
import funkin.graphics.shaders.RuntimeRainShader;
import funkin.modding.base.ScriptedFlxRuntimeShader;
import funkin.play.PlayState;
import funkin.play.stage.Stage;
import openfl.filters.BlurFilter;
import openfl.filters.ShaderFilter;
import funkin.util.FlxTweenUtil;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxBackdrop;
import funkin.graphics.shaders.AdjustColorShader;
import StringTools;

class PhillyStreetsErectStage extends Stage
{
	var rainShader:RuntimeRainShader = new RuntimeRainShader();
	var rainShaderFilter:ShaderFilter;
	var blurFilter:BlurFilter = new BlurFilter(6, 6);

	// as song goes on, these are used to make the rain more intense throught the song
	// these values are also used for the rain sound effect volume intensity!
	var rainShaderStartIntensity:Float;
	var rainShaderEndIntensity:Float;

	// var rainSndAmbience:FunkinSound;
	// var carSndAmbience:FunkinSound;

	var lightsStop:Bool = false; // state of the traffic lights
	var lastChange:Int = 0;
	var changeInterval:Int = 8; // make sure it doesnt change until AT LEAST this many beats

	var carWaiting:Bool = false; // if the car is waiting at the lights and is ready to go on green
	var carInterruptable:Bool = true; // if the car can be reset
	var car2Interruptable:Bool = true;

	var paperInterruptable:Bool = true;

	var scrollingSky:FlxTiledSprite;

	var colorShader:AdjustColorShader;

	function new()
	{
		super('phillyStreetsErect');
	}

	/**
  * Changes the current state of the traffic lights.
	* Updates the next change accordingly and will force cars to move when ready
  */
	function changeLights(beat:Int):Void{

		lastChange = beat;
		lightsStop = !lightsStop;

		if(lightsStop){
			getNamedProp('phillyTraffic').animation.play('tored');
			changeInterval = 20;
		} else {
			getNamedProp('phillyTraffic').animation.play('togreen');
			changeInterval = 30;

			if(carWaiting == true) finishCarLights(getNamedProp('phillyCars'));
		}
	}

	/**
  * Resets every value of a car and hides it from view.
  */
	function resetCar(left:Bool, right:Bool){
		if(left){
			carWaiting = false;
			carInterruptable = true;
			var cars = getNamedProp('phillyCars');
			if (cars != null) {
				FlxTween.cancelTweensOf(cars);
				cars.x = 1200;
				cars.y = 818;
				cars.angle = 0;
			}
		}

		if(right){
			car2Interruptable = true;
			var cars2 = getNamedProp('phillyCars2');
			if (cars2 != null) {
				FlxTween.cancelTweensOf(cars2);
				getNamedProp('phillyCars2').x = 1200;
				getNamedProp('phillyCars2').y = 818;
				getNamedProp('phillyCars2').angle = 0;
			}
		}
	}

	override function onCountdownStart(event:ScriptEvent) {
		super.onCountdownStart(event);

		resetCar(true, true);
		resetStageValues();
	}

	override function onCountdownEnd(event:ScriptEvent) {
		super.onCountdownEnd(event);
		// carSndAmbience.volume = 0.1;
	}

	override function onCreate(event:ScriptEvent):Void
	{
		super.onCreate(event);

		// rainSndAmbience = FunkinSound.load(Paths.sound("rainAmbience", "weekend1"), true, false, true);
		// rainSndAmbience.volume = 0;
		// rainSndAmbience.play(false, FlxG.random.float(0, rainSndAmbience.length));

		// carSndAmbience = FunkinSound.load(Paths.sound("carAmbience", "weekend1"), true, false, true);
		// carSndAmbience.volume = 0;
		// carSndAmbience.play(false, FlxG.random.float(0, carSndAmbience.length));

		// rainShader.puddleMap = Assets.getBitmapData(Paths.image("phillyStreets/puddle"));
		rainShader.scale = FlxG.height / 200; // adjust this value so that the rain looks nice

		FlxG.console.registerObject("rainShader", rainShader);
		switch (PlayState.instance.currentSong.id)
		{
			case "darnell":
				rainShaderStartIntensity = 0;
				rainShaderEndIntensity = 0.01;
			case "lit-up":
				rainShaderStartIntensity = 0.01;
				rainShaderEndIntensity = 0.02;
			case "2hot":
				rainShaderStartIntensity = 0.02;
				rainShaderEndIntensity = 0.04;
		}

		rainShader.intensity = rainShaderStartIntensity;
		rainShader.rainColor = 0xFFa8adb5;

		// set the shader input
		//rainShader.mask = frameBufferMan.getFrameBuffer("mask");
		//rainShader.lightMap = frameBufferMan.getFrameBuffer("lightmap");

		rainShaderFilter = new ShaderFilter(rainShader);
		FlxG.camera.filters = [rainShaderFilter];
		//FlxG.camera.setFilters([new openfl.filters.BlurFilter(16,16)]);

		resetCar(true, true);
		resetStageValues();
	}

	var mist0:FlxBackdrop;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;
	var mist3:FlxBackdrop;
	var mist4:FlxBackdrop;
	var mist5:FlxBackdrop;

	override function buildStage()
	{
		super.buildStage();

		scrollingSky = new FlxTiledSprite(Paths.image('phillyStreets/erect/phillySkybox'), 2922, 718, true, false);
		scrollingSky.setPosition(-650, -375);
		scrollingSky.scrollFactor.set(0.1, 0.1);
		scrollingSky.zIndex = 10;
		scrollingSky.scale.set(0.65, 0.65);

		PlayState.instance.currentStage.add(scrollingSky);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		colorShader = new AdjustColorShader();

		mist0 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), 0x01);
		mist0.setPosition(-650, -100);
		mist0.scrollFactor.set(1.2, 1.2);
		mist0.zIndex = 1000;
    mist0.blend = 0;
		mist0.color = 0xFF5c5c5c;
		mist0.alpha = 0.6;
		mist0.velocity.x = 172;

		PlayState.instance.currentStage.add(mist0);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist1 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), 0x01);
		mist1.setPosition(-650, -100);
		mist1.scrollFactor.set(1.1, 1.1);
		mist1.zIndex = 1000;
    mist1.blend = 0;
		mist1.color = 0xFF5c5c5c;
		mist1.alpha = 0.6;
		mist1.velocity.x = 150;

		PlayState.instance.currentStage.add(mist1);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist2 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistBack'), 0x01);
		mist2.setPosition(-650, -100);
		mist2.scrollFactor.set(1.2, 1.2);
		mist2.zIndex = 1001;
    mist2.blend = 0;
		mist2.color = 0xFF5c5c5c;
		mist2.alpha = 0.8;
		mist2.velocity.x = -80;

		PlayState.instance.currentStage.add(mist2);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist3 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), 0x01);
		mist3.setPosition(-650, -100);
		mist3.scrollFactor.set(0.95, 0.95);
		mist3.zIndex = 99;
   	mist3.blend = 0;
		mist3.color = 0xFF5c5c5c;
		mist3.alpha = 0.5;
		mist3.velocity.x = -50;
		mist3.scale.set(0.8, 0.8);

		PlayState.instance.currentStage.add(mist3);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist4 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistBack'), 0x01);
		mist4.setPosition(-650, -100);
		mist4.scrollFactor.set(0.8, 0.8);
		mist4.zIndex = 88;
   	mist4.blend = 0;
		mist4.color = 0xFF5c5c5c;
		mist4.alpha = 1;
		mist4.velocity.x = 40;
		mist4.scale.set(0.7, 0.7);

		PlayState.instance.currentStage.add(mist4);
		PlayState.instance.currentStage.refresh(); // Apply z-index.

		mist5 = new FlxBackdrop(Paths.image('phillyStreets/erect/mistMid'), 0x01);
		mist5.setPosition(-650, -100);
		mist5.scrollFactor.set(0.5, 0.5);
		mist5.zIndex = 39;
   	mist5.blend = 0;
		mist5.color = 0xFF5c5c5c;
		mist5.alpha = 1;
		mist5.velocity.x = 20;
		mist5.scale.set(1.1, 1.1);

		PlayState.instance.currentStage.add(mist5);
		PlayState.instance.currentStage.refresh(); // Apply z-index.
	}

	override function onDestroy(event:ScriptEvent) {
		super.onDestroy();

		var cars = getNamedProp('phillyCars');
		if (cars != null) FlxTween.cancelTweensOf(cars);
		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) FlxTween.cancelTweensOf(cars2);

		// Fully stop ambiance.
		// if (rainSndAmbience != null) rainSndAmbience.stop();
		// if (carSndAmbience != null) carSndAmbience.stop();
	}

	/**
  * Drive the car away from the lights to the end of the road.
	* Used when the lights turn green and the car is waiting in position.
  */
	function finishCarLights(sprite:FlxSprite):Void{
		carWaiting = false;
		var duration:Float = FlxG.random.float(1.8, 3);
		var rotations:Array<Int> = [-5, 18];
		var offset:Array<Float> = [306.6, 168.3];
		var startdelay:Float = FlxG.random.float(0.2, 1.2);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
			FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
			FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay} );
		FlxTween.quadPath(sprite, path, duration, true,
    {
      ease: FlxEase.sineIn,
			startDelay: startdelay,
			onComplete: function(_) {
            carInterruptable = true;
      }
    });
	}

	/**
  * Drives a car towards the lights and stops.
	* Used when a car tries to drive while the lights are red.
  */
	function driveCarLights(sprite:FlxSprite):Void{
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);
		var extraOffset = [0, 0];
		var duration:Float = 2;

		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.9, 1.5);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}
		var rotations:Array<Int> = [-7, -5];
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var path:Array<FlxPoint> = [
			FlxPoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
			FlxPoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
			FlxPoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
		];
		// debug shit!!! keeping it here just in case
		// for(point in path){
		// 	var debug:FlxSprite = new FlxSprite(point.x - 5, point.y - 5).makeGraphic(10, 10, 0xFFFF0000);
    // 	add(debug);
		// }
		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut} );
		FlxTween.quadPath(sprite, path, duration, true,
    {
      ease: FlxEase.cubeOut,
			onComplete: function(_) {
            carWaiting = true;
						if(lightsStop == false) finishCarLights(getNamedProp('phillyCars'));
      }
    });
	}

	/**
  * Drives a car across the screen without stopping.
	* Used when the lights are green.
  */
	function driveCar(sprite:FlxSprite):Void{
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);
		// setting an offset here because the current implementation of stage prop offsets was not working at all for me
		// if possible id love to not have to do this but im keeping this for now
		var extraOffset = [0, 0];
		var duration:Float = 2;
		// set different values of speed for the car types (and the offset)
		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}
		// random arbitrary values for getting the cars in place
		// could just add them to the points but im LAZY!!!!!!
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);
		// start/end rotation
		var rotations:Array<Int> = [-8, 18];
		// the path to move the car on
		var path:Array<FlxPoint> = [
				FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 30),
				FlxPoint.get(2400 - offset[0], 980 - offset[1] - 50),
				FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
		FlxTween.quadPath(sprite, path, duration, true,
      {
        ease: null,
				onComplete: function(_) {
      	  carInterruptable = true;
      	}
    });
	}

	function driveCarBack(sprite:FlxSprite):Void{
		car2Interruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1,4);
		sprite.animation.play('car' + variant);
		// setting an offset here because the current implementation of stage prop offsets was not working at all for me
		// if possible id love to not have to do this but im keeping this for now
		var extraOffset = [0, 0];
		var duration:Float = 2;
		// set different values of speed for the car types (and the offset)
		switch(variant){
			case 1:
				duration = FlxG.random.float(1, 1.7);
			case 2:
				extraOffset = [20, -15];
				duration = FlxG.random.float(0.6, 1.2);
			case 3:
				extraOffset = [30, 50];
				duration = FlxG.random.float(1.5, 2.5);
			case 4:
				extraOffset = [10, 60];
				duration = FlxG.random.float(1.5, 2.5);
		}
		// random arbitrary values for getting the cars in place
		// could just add them to the points but im LAZY!!!!!!
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);
		// start/end rotation
		var rotations:Array<Int> = [18, -8];
		// the path to move the car on
		var path:Array<FlxPoint> = [
				FlxPoint.get(3102 - offset[0], 1127 - offset[1] + 60),
				FlxPoint.get(2400 - offset[0], 980 - offset[1] - 30),
				FlxPoint.get(1570 - offset[0], 1049 - offset[1] - 10)

		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, null );
		FlxTween.quadPath(sprite, path, duration, true,
      {
        ease: null,
				onComplete: function(_) {
      	  car2Interruptable = true;
      	}
    });
	}

	/**
  * Resets the values tied to the lights that need to be accounted for on a restart.
  */
	function resetStageValues():Void{
		lastChange = 0;
		changeInterval = 8;
		var traffic = getNamedProp('phillyTraffic');
		if (traffic != null) {
			traffic.animation.play('togreen');
		}
		lightsStop = false;
	}

	var rainDropTimer:Float = 0;
	var rainDropWait:Float = 6;

	var _timer:Float = 0;

	override function onUpdate(event:UpdateScriptEvent)
	{
		super.onUpdate(event);

		_timer += event.elapsed;
		mist0.y = 660 + (Math.sin(_timer*0.35)*70);
		mist1.y = 500 + (Math.sin(_timer*0.3)*80);
		mist2.y = 540 + (Math.sin(_timer*0.4)*60);
		mist3.y = 230 + (Math.sin(_timer*0.3)*70);
		mist4.y = 170 + (Math.sin(_timer*0.35)*50);
		mist5.y = -80 + (Math.sin(_timer*0.08)*100);
		// mist3.y = -20 + (Math.sin(_timer*0.5)*200);
		// mist4.y = -180 + (Math.sin(_timer*0.4)*300);
		// mist5.y = -450 + (Math.sin(_timer*0.2)*1xxx50);
		//trace(mist1.y);

		var remappedIntensityValue:Float = FlxMath.remapToRange(Conductor.instance.songPosition, 0, FlxG.sound.music != null ? FlxG.sound.music.length : 0.0, rainShaderStartIntensity, rainShaderEndIntensity);
		rainShader.intensity = remappedIntensityValue;
		rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
		rainShader.update(event.elapsed);

		if(scrollingSky != null) scrollingSky.scrollX -= FlxG.elapsed * 22;

		if(PlayState.instance.currentStage.getBoyfriend() != null && PlayState.instance.currentStage.getBoyfriend().shader == null){
      PlayState.instance.currentStage.getBoyfriend().shader = colorShader;
		  PlayState.instance.currentStage.getGirlfriend().shader = colorShader;
		  PlayState.instance.currentStage.getDad().shader = colorShader;

		  colorShader.hue = -5;
		  colorShader.saturation = -40;
		  colorShader.contrast = -25;
		  colorShader.brightness = -20;
    }

		// if (rainSndAmbience != null) {
		// 	rainSndAmbience.volume = Math.min(0.3, remappedIntensityValue * 2);
		// }
	}

	function onBeatHit(event:SongTimeScriptEvent)
	{
		super.onBeatHit(event);

		// Try driving a car when its possible
		if (FlxG.random.bool(10) && event.beat != (lastChange + changeInterval) && carInterruptable == true)
		{
			if(lightsStop == false){
				driveCar(getNamedProp('phillyCars'));
			}else{
				driveCarLights(getNamedProp('phillyCars'));
			}
		}

		// var paper = getNamedProp('paper');
		// if (FlxG.random.bool(0.6) && paperInterruptable == true)
		// {
		// 	paper.alpha = 1;
		// 	paper.animation.play('paperBlow');
		// 	paper.y = 608 + FlxG.random.float(-150,150);
		// 	paperInterruptable = false;
		// 	new FlxTimer().start(2, function(tmr:FlxTimer)
		// 	{
		// 		paperInterruptable = true;
		// 		paper.alpha = 0;
		// 	});
		// }

		// try driving one on the right too. in this case theres no red light logic, it just can only spawn on green lights
		if(FlxG.random.bool(10) && event.beat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false) driveCarBack(getNamedProp('phillyCars2'));

		// After the interval has been hit, change the light state.
		if (event.beat == (lastChange + changeInterval)) changeLights(event.beat);
	}

	override function setupFrameBuffers()
	{
		//frameBufferMan.createFrameBuffer("mask", 0xFF000000);
		//frameBufferMan.createFrameBuffer("lightmap", 0xFF000000);
	}

	var screen:FixedBitmapData;
	override function draw()
	{
		super.draw();

		//screen = grabScreen(false);
		//BitmapDataUtil.applyFilter(screen, blurFilter);
		//rainShader.blurredScreen = screen;
	}

	public override function onPause(event:PauseScriptEvent) {
		super.onPause(event);

		pauseCars();

		// Temporarily stop ambiance.
		// if (rainSndAmbience != null) {
		// 	rainSndAmbience.pause();
		// }
		// if (carSndAmbience != null) {
		// 	carSndAmbience.pause();
		// }
	}

	public override function onResume(event:ScriptEvent) {
		super.onResume(event);

		resumeCars();

		// Temporarily stop ambiance.
		// if (rainSndAmbience != null) rainSndAmbience.resume();
		// if (carSndAmbience != null) carSndAmbience.resume();
	}

	function pauseCars():Void {
		var cars = getNamedProp('phillyCars');
		if (cars != null) {
			FlxTweenUtil.pauseTweensOf(cars);
		}

		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) {
			FlxTweenUtil.pauseTweensOf(cars2);
		}
	}

	function resumeCars():Void {
		var cars = getNamedProp('phillyCars');
		if (cars != null) {
			FlxTweenUtil.resumeTweensOf(cars);
		}

		var cars2 = getNamedProp('phillyCars2');
		if (cars2 != null) {
			FlxTweenUtil.resumeTweensOf(cars2);
		}
	}

	override function onGameOver(event:ScriptEvent):Void {
		super.onGameOver(event);
		// Make it so the rain shader doesn't show over the game over screen
		FlxG.camera.filters = [];
	}

	override function onSongRetry(event:ScriptEvent):Void {
		super.onSongRetry(event);
		// Make it so the rain shader doesn't show over the game over screen
		// FlxG.camera.setFilters([rainShaderFilter]);

		resetCar(true, true);
		resetStageValues();
		FlxG.camera.filters = [rainShaderFilter];
	}

	override function addProp(prop:StageProp, ?name:String = null)
	{
		super.addProp(prop, name);
		if (StringTools.endsWith(name, "_lightmap"))
		{
			prop.blend = 0; // 0 means ADD (see openfl.display.BlendMode)
			prop.alpha = 0.6;
			//frameBufferMan.moveSpriteTo("lightmap", prop);
		}
		else if (name == "grey1")
		{
			prop.blend = 0;
			//frameBufferMan.copySpriteTo("mask", prop, 0xFFFFFF);
		}
		else if (name == "grey2")
		{
			prop.blend = 9;
			//frameBufferMan.copySpriteTo("mask", prop, 0xFFFFFF);
		}
		else
		{
			//frameBufferMan.copySpriteTo("mask", prop, 0x000000);
		}
	}

  override function addCharacter(character:BaseCharacter, charType:CharacterType)
	{
		super.addCharacter(character, charType);
		// add to the mask so that characters hide puddles
		// frameBufferMan.copySpriteTo("mask", character, 0x000000);
	}
}
