import funkin.play.character.SparrowCharacter;
import funkin.play.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxTypedSpriteGroup;
import funkin.graphics.FunkinSprite;
import funkin.modding.base.ScriptedFlxAtlasSprite;
import funkin.modding.base.ScriptedFlxSprite;
import funkin.modding.base.ScriptedFlxSpriteGroup;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.visualize.ABotVis;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterDataParser;
import funkin.play.character.CharacterType;
import funkin.graphics.shaders.TextureSwap;
import openfl.display.BitmapData;
import funkin.util.FlxColorUtil;
import funkin.graphics.shaders.AdjustColorShader;

class NeneDarkCharacter extends SparrowCharacter {
	function new() {
		super('nene-dark');
	}

	var pupilState:Int = 0;

	var PUPIL_STATE_NORMAL = 0;
	var PUPIL_STATE_LEFT = 1;

	var abot:FlxAtlasSprite;
	var abotViz:ABotVis;
	var stereoBG:FlxSprite;
	var eyeWhites:FlxSprite;
	var pupil:FlxAtlasSprite;

	var testShader:TextureSwap;

	var normalChar:BaseCharacter;


  var vizAdjustColor:AdjustColorShader;

	override function set_alpha(val:Float):Float{
		super.set_alpha(val);
		testShader.amount = val;
		if(val != 1)
			normalChar.alpha = 1;
		else
			normalChar.alpha = 0;

		eyeWhites.color = FlxColorUtil.interpolate(0xFFFFFFFF, 0xFF6F96CE, val);

    return val;
	}

	function onCreate(event:ScriptEvent) {
		super.onCreate(event);

		stereoBG = new FlxSprite(0, 0, Paths.image('characters/abot/stereoBG'));
		stereoBG.color = 0xFF616785;

		eyeWhites = new FunkinSprite().makeSolidColor(160, 60);

		pupil = new FlxAtlasSprite(0, 0, Paths.animateAtlas("characters/abot/systemEyes", "shared"));
		pupil.x = this.x;
		pupil.y = this.y;
		pupil.zIndex = this.zIndex - 5;

		testShader = new TextureSwap();
		testShader.swappedImage = BitmapData.fromFile('assets/shared/images/characters/abot/dark/abotSystem/spritemap1.png');
		abot = ScriptedFlxAtlasSprite.init('ABotAtlasSprite', 0, 0);
		abot.x = this.x;
		abot.y = this.y;
		abot.zIndex = this.zIndex - 1;
		abot.shader = testShader;

		abotViz = new ABotVis(FlxG.sound.music);
		abotViz.x = this.x;
		abotViz.y = this.y;
		abotViz.zIndex = abot.zIndex + 1;
		FlxG.debugger.track(abotViz);

		vizAdjustColor = new AdjustColorShader();

    vizAdjustColor.brightness = -12;
    vizAdjustColor.hue = -26;
    vizAdjustColor.contrast = 0;
		vizAdjustColor.saturation = -45;

		for(spr in abotViz.members){
			spr.shader = vizAdjustColor;
		}

		normalChar = CharacterDataParser.fetchCharacter('nene');
    normalChar.zIndex = this.zIndex - 1;
		normalChar.alpha = 0;
    normalChar.flipX = false;
	}

	/**
	 * At this amount of life, Nene will raise her knife.
	 */
	var VULTURE_THRESHOLD = 0.25 * 2;

	/**
	 * Nene is in her default state. 'danceLeft' or 'danceRight' may be playing right now,
	 * or maybe her 'combo' or 'drop' animations are active.
	 *
	 * Transitions:
	 * If player health <= VULTURE_THRESHOLD, transition to STATE_PRE_RAISE.
	 */
	var STATE_DEFAULT = 0;

	/**
	 * Nene has recognized the player is at low health,
	 * but has to wait for the appropriate point in the animation to move on.
	 *
	 * Transitions:
	 * If player health > VULTURE_THRESHOLD, transition back to STATE_DEFAULT without changing animation.
	 * If current animation is combo or drop, transition when animation completes.
	 * If current animation is danceLeft, wait until frame 14 to transition to STATE_RAISE.
	 * If current animation is danceRight, wait until danceLeft starts.
	 */
	var STATE_PRE_RAISE = 1;

	/**
	 * Nene is raising her knife.
	 * When moving to this state, immediately play the 'raiseKnife' animation.
	 *
	 * Transitions:
	 * Once 'raiseKnife' animation completes, transition to STATE_READY.
	 */
	var STATE_RAISE = 2;

	/**
	 * Nene is holding her knife ready to strike.
	 * During this state, hold the animation on the first frame, and play it at random intervals.
	 * This makes the blink look less periodic.
	 *
	 * Transitions:
	 * If the player runs out of health, move to the GameOverSubState. No transition needed.
	 * If player health > VULTURE_THRESHOLD, transition to STATE_LOWER.
	 */
	var STATE_READY = 3;

	/**
	 * Nene is raising her knife.
	 * When moving to this state, immediately play the 'lowerKnife' animation.
	 *
	 * Transitions:
	 * Once 'lowerKnife' animation completes, transition to STATE_DEFAULT.
	 */
	var STATE_LOWER = 4;

	/**
	 * Nene's animations are tracked in a simple state machine.
	 * Given the current state and an incoming event, the state changes.
	 */
	var currentState:Int = STATE_DEFAULT;

	/**
	 * Nene blinks every X beats, with X being randomly generated each time.
	 * This keeps the animation from looking too periodic.
	 */
	var MIN_BLINK_DELAY:Int = 3;
	var MAX_BLINK_DELAY:Int = 7;
	var blinkCountdown:Int = MIN_BLINK_DELAY;

	override function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
			super.playAnimation(name, restart, ignoreOther);
      if(normalChar != null){
        normalChar.playAnimation(name, restart, ignoreOther);
        normalChar.setPosition(this.x, this.y);
      }
	}

	function dance(forceRestart:Bool) {
		if (abot != null)
		{
			abot.playAnimation("");
    	abot.anim.curFrame = 1; // we start on this frame, since from Flash the symbol has a non-bumpin frame on frame 0
		}

		// Then, perform the appropriate animation for the current state.
		switch(currentState) {
			case STATE_DEFAULT:
				if (hasDanced) {
					playAnimation('danceRight', forceRestart);
				} else {
					playAnimation('danceLeft', forceRestart);
				}
				hasDanced = !hasDanced;
			case STATE_PRE_RAISE:
				playAnimation('danceLeft', false);
				hasDanced = false;
			case STATE_READY:
				if (blinkCountdown == 0) {
					playAnimation('idleKnife', false);
					blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
				} else {
					blinkCountdown--;
				}
			default:
				// In other states, don't interrupt the existing animation.
		}
	}

	var refershedLol:Bool = false;

	/**
	 * Called when the chart hits a song event.
	 */
	public override function onSongEvent(scriptEvent:SongEventScriptEvent)
	{
		super.onSongEvent(scriptEvent);
		if (scriptEvent.eventData.eventKind == "FocusCamera")
		{
			var eventProps = scriptEvent.eventData.value;
			switch (Std.parseInt(eventProps.char)) {
				case 0:
					movePupilsRight();
				case 1:
					movePupilsLeft();
				default:
			}
		}

	}

	function movePupilsLeft():Void {
		if (pupilState == PUPIL_STATE_LEFT) return;
		trace('Move pupils left');
		pupil.playAnimation('');
		pupil.anim.curFrame = 0;
		// pupilState = PUPIL_STATE_LEFT;
	}

	function movePupilsRight():Void {
		if (pupilState == PUPIL_STATE_NORMAL) return;
		trace('Move pupils right');
		pupil.playAnimation('');
		pupil.anim.curFrame = 17;
		// pupilState = PUPIL_STATE_NORMAL;
	}

	function moveByNoteKind(kind:String) {
		// Force ABot to look where the action is happening.
		switch(event.note.kind) {
			case "weekend-1-lightcan":
				movePupilsLeft();
			case "weekend-1-kickcan":
				// movePupilsLeft();
			case "weekend-1-kneecan":
				// movePupilsLeft();
			case "weekend-1-cockgun":
				movePupilsRight();
			case "weekend-1-firegun":
				// movePupilsRight();
			default: // Nothing
		}
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		super.onNoteHit(event);
		moveByNoteKind(event.note.kind);
	}

	function onNoteMiss(event:NoteScriptEvent)
	{
		super.onNoteMiss(event);
		moveByNoteKind(event.note.kind);
	}

	function onUpdate(event:UpdateScriptEvent) {
		super.onUpdate(event);

		// Set the visibility of ABot to match Nene's.
		abot.visible = this.visible;
		pupil.visible = this.visible;
		eyeWhites.visible = this.visible;
		stereoBG.visible = this.visible;

		if (pupil?.anim?.isPlaying)
		{
			switch (pupilState)
			{
				case PUPIL_STATE_NORMAL:
					if (pupil.anim.curFrame >= 17)
					{
						trace('Done moving pupils left');
						pupilState = PUPIL_STATE_LEFT;
						pupil.anim.pause();
					}

				case PUPIL_STATE_LEFT:
					if (pupil.anim.curFrame >= 30)
					{
						trace('Done moving pupils right');
						pupilState = PUPIL_STATE_NORMAL;
						pupil.anim.pause();
					}
			}
		}

		// refreshes just for the zIndex shit!
		if (!refershedLol)
		{
			abot.x = this.x - 100;
			abot.y = this.y + 216; // 764 - 740
			abot.zIndex = this.zIndex - 10;

			PlayState.instance.currentStage.add(abot);

			abotViz.x = abot.x + 200;
			abotViz.y = abot.y + 84;
			abotViz.zIndex = abot.zIndex - 1;
			PlayState.instance.currentStage.add(abotViz);

			eyeWhites.x = abot.x + 40;
			eyeWhites.y = abot.y + 250;
			eyeWhites.zIndex = abot.zIndex - 10;
			PlayState.instance.currentStage.add(eyeWhites);

			pupil.x = abot.x - 507;
			pupil.y = abot.y - 492;
			pupil.zIndex = eyeWhites.zIndex + 5;
			PlayState.instance.currentStage.add(pupil);

			stereoBG.x = abot.x + 150;
			stereoBG.y = abot.y + 30;
			stereoBG.zIndex = abot.zIndex - 8;
			PlayState.instance.currentStage.add(stereoBG);

			normalChar.zIndex = this.zIndex - 3;
    	normalChar.flipX = false;

			PlayState.instance.currentStage.add(normalChar);

			PlayState.instance.currentStage.refresh();
			refershedLol = true;
		}

		if (shouldTransitionState()) {
			transitionState();
		}
	}

	public function onScriptEvent(event:ScriptEvent):Void {
		if (event.type == "SONG_START")
		{
			abotViz.snd = FlxG.sound.music;
			abotViz.initAnalyzer();
		}
	}

	var animationFinished:Bool = false;

	function onAnimationFinished(name:String) {
		super.onAnimationFinished(name);

		switch(currentState) {
			case STATE_RAISE:
				if (name == "raiseKnife") {
					animationFinished = true;
					transitionState();
				}
			case STATE_LOWER:
				if (name == "lowerKnife") {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}

	function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int) {
		super.onAnimationFrame(name, frameNumber, frameIndex);

		switch(currentState) {
			case STATE_PRE_RAISE:
				if (name == "danceLeft" && frameNumber == 13) {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}

	function shouldTransitionState():Bool {
		return PlayState.instance.currentStage.getBoyfriend().characterId != "pico-blazin";
	}

	function transitionState() {
		switch (currentState) {
			case STATE_DEFAULT:
				if (PlayState.instance.health <= VULTURE_THRESHOLD) {
					// trace('NENE: Health is low, transitioning to STATE_PRE_RAISE');
					currentState = STATE_PRE_RAISE;
				} else {
					currentState = STATE_DEFAULT;
				}
			case STATE_PRE_RAISE:
				if (PlayState.instance.health > VULTURE_THRESHOLD) {
					// trace('NENE: Health went back up, transitioning to STATE_DEFAULT');
					currentState = STATE_DEFAULT;
				} else if (animationFinished) {
					// trace('NENE: Animation finished, transitioning to STATE_RAISE');
					currentState = STATE_RAISE;
					playAnimation('raiseKnife');
					animationFinished = false;
				}
			case STATE_RAISE:
				if (animationFinished) {
					// trace('NENE: Animation finished, transitioning to STATE_READY');
					currentState = STATE_READY;
					animationFinished = false;
				}
			case STATE_READY:
				if (PlayState.instance.health > VULTURE_THRESHOLD) {
					// trace('NENE: Health went back up, transitioning to STATE_LOWER');
					currentState = STATE_LOWER;
					playAnimation('lowerKnife');
				}
			case STATE_LOWER:
				if (animationFinished) {
					// trace('NENE: Animation finished, transitioning to STATE_DEFAULT');
					currentState = STATE_DEFAULT;
					animationFinished = false;
				}
			default:
				// trace('UKNOWN STATE ' + currentState);
				currentState = STATE_DEFAULT;
		}
	}
}
