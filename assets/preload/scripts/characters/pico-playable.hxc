import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;
import funkin.play.GameOverSubState;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.util.FlxTimer;
import funkin.graphics.FunkinSprite;
import funkin.audio.FunkinSound;
import flixel.FlxSprite;
import flixel.FlxG;
import funkin.modding.base.ScriptedFunkinSprite;
import flixel.group.FlxTypedSpriteGroup;
import flixel.effects.FlxFlicker;
import funkin.play.PauseSubState;
import funkin.modding.module.ModuleHandler;
import flixel.tweens.FlxTween;


class PicoPlayerCharacter extends MultiSparrowCharacter {
	function new() {
		super('pico-playable');

    ignoreExclusionPref.push("shoot");
	}

	function onCreate(event:ScriptEvent) {
		super.onCreate(event);

		// NOTE: this.x and this.y are not properly set here.

		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico';

		PauseSubState.musicSuffix = '-pico';
	}

	var deathSpriteRetry:FunkinSprite;
	var deathSpriteNene:FunkinSprite;

	var picoFade:FunkinSprite;

	/**
     * Initialize and cache sprites used for the death animation,
	 * for use later.
	 */
	function createDeathSprites() {
		deathSpriteRetry = FunkinSprite.createSparrow(0, 0, "characters/Pico_Death_Retry");
		deathSpriteRetry.animation.addByPrefix('idle', "Retry Text Loop0", 24, true);
		deathSpriteRetry.animation.addByPrefix('confirm', "Retry Text Confirm0", 24, false);

		deathSpriteRetry.visible = false;

		//FlxG.debugger.track(deathSpriteRetry);

		deathSpriteNene = FunkinSprite.createSparrow(0, 0, "characters/NeneKnifeToss");
		var gf = PlayState.instance.currentStage.getGirlfriend();
		deathSpriteNene.x = gf.originalPosition.x + 120;// + 280;
		deathSpriteNene.y = gf.originalPosition.y - 200;// + 70;
		deathSpriteNene.animation.addByPrefix('throw', "knife toss0", 24, false);
		deathSpriteNene.visible = true;
		deathSpriteNene.animation.finishCallback = function(name:String) {
			deathSpriteNene.visible = false;
		}
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (event.eventCanceled) {
			// onNoteHit event was cancelled by the gameplay module.
			return;
		}

		if (event.note.noteData.getMustHitNote() && characterType == CharacterType.BF) {
			// Override the hit note animation.
			switch(event.note.kind) {
				case "censor":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'censor');
					return;
				case "weekend-1-cockgun": // HE'S PULLING HIS COCK OUT
					holdTimer = 0;
					playCockGunAnim();
				case "weekend-1-firegun":
					holdTimer = 0;
					playFireGunAnim();
				default:
					super.onNoteHit(event);
			}
		}
	}

	function onNoteMiss(event:NoteScriptEvent)
	{
		// Override the miss note animation.
		switch(event.note.kind) {
			case "weekend-1-cockgun":
				//playCockMissAnim();
			case "weekend-1-firegun":
				playCanExplodeAnim();
			default:
				super.onNoteMiss(event);
		}
	}

	function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
		// restore vocal volume to ensure burps always play
		// not needed on the dark variant because this one always exists anyway..
		if(name == "burpSmile" || name == "burpSmileLong") PlayState.instance.vocals.playerVolume = 1;

		if (name == "firstDeath") {
			if (GameOverSubState.blueBallSuffix == '-pico-explode') {
				// Explosion death animation.
				doExplosionDeath();
			} else {
				// Standard death animation.
				createDeathSprites();

				GameOverSubState.instance.add(deathSpriteRetry);
				GameOverSubState.instance.add(deathSpriteNene);
				deathSpriteNene.animation.play("throw");
			}
		} else if (name == "deathConfirm") {
			if (picoDeathExplosion != null) {
				doExplosionConfirm();
			} else {
				deathSpriteRetry.animation.play('confirm');
				// I think the glow makes the overall animation larger,
				// but a plain FlxSprite doesn't have an animation offset option so we do it manually.
				deathSpriteRetry.x -= 250;
				deathSpriteRetry.y -= 200;

				// Skip playing the animation.
				return;
			}
		}

		super.playAnimation(name, restart, ignoreOther);
	}

	var picoFlicker:FlxFlicker = null;

	override function onAnimationFinished(name:String) {
		super.onAnimationFinished(name);

		if (name == 'shootMISS' && PlayState.instance.health > 0.0 && !PlayState.instance.isPlayerDying) {
			// ERIC: You have to use super instead of this or it breaks.
			// This is because typeof(this) is PolymodAbstractClass.
      picoFlicker = FlxFlicker.flicker(super, 1, 1 / 30, true, true, function(_) {
        picoFlicker = FlxFlicker.flicker(super, 0.5, 1 / 60, true, true, function(_) {
					picoFlicker = null;
				});
      });
		}
	}

	public override function onPause(event:PauseScriptEvent) {
		super.onPause(event);

		if (picoFlicker != null) {
			picoFlicker.pause();
			this.visible = true;
		}
	}

  public override function onResume(event:ScriptEvent) {
		super.onResume(event);

		if (picoFlicker != null) {
			picoFlicker.resume();
		}
	}

	public override function getDeathCameraOffsets():Array<Float> {
		var result = super.getDeathCameraOffsets();

		if (GameOverSubState.blueBallSuffix == '-pico-explode') {
			return [result[0], result[1] + 100];
		}

		return [result[0], result[1]];
	}

	var picoDeathExplosion:FlxAtlasSprite;

	function doExplosionDeath() {

		if (picoFlicker != null) {
			picoFlicker.stop(); // this sets visible to true, but we make it false a few lines down anyways
		}

		// Suffixed death sound will already play.
		GameOverSubState.instance.resetCameraZoom();

		// Move the camera up.
		GameOverSubState.instance.cameraFollowPoint.y -= 100;

		var picoDeathExplosionPath = Paths.animateAtlas("characters/picoExplosionDeath", "weekend1");
		picoDeathExplosion = new FlxAtlasSprite(this.x - 640, this.y - 340, picoDeathExplosionPath);
    PlayState.instance.subState.add(picoDeathExplosion);
		picoDeathExplosion.zIndex = 1000;
    picoDeathExplosion.onAnimationFinish.add(onExplosionFinishAnim);
    picoDeathExplosion.visible = true;
		this.visible = false;

		new FlxTimer().start(3.0, afterPicoDeathExplosionIntro);

    picoDeathExplosion.playAnimation('intro');

	}

	var singed:FunkinSound;
	function afterPicoDeathExplosionIntro(timer:FlxTimer) {
		// Start the (standard) death music, 3.5 seconds after the explosion starts,
		// not when the explosion sound finishes or when the loop starts.
		GameOverSubState.instance.startDeathMusic(1.0, false);
		singed = FunkinSound.load(Paths.sound('singed_loop'), true, false, true);
		// singed.fadeIn(0.5, 0.3, 1.0);
	}

	function doExplosionConfirm() {
		// Suffixed confirm music will already play.
		picoDeathExplosion.playAnimation('Confirm');
		if (singed != null) {
			singed.stop();
			singed = null;
		}
	}

	function onExplosionFinishAnim(animLabel:String) {
		if (animLabel == 'intro') {
      picoDeathExplosion.playAnimation('Loop Start', true, false, true);
		} else if (animLabel == 'Confirm') {
			// Do nothing, the animation will just play.
		}
	}

	override function onGameOver(event:ScriptEvent):Void {
		super.onGameOver(event);
	}

	override function onSongRetry(event:ScriptEvent):Void {
		super.onSongRetry(event);

		// Don't let these pile up.
		clearCasings();

		// Reset to standard death animation.
		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico';

		PauseSubState.musicSuffix = '-pico';

		picoDeathExplosion = null;
		this.visible = true;
	}

	function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int) {
		super.onAnimationFrame(name, frameNumber, frameIndex);

		if (name == "firstDeath" && frameNumber == 36 - 1) {
			deathSpriteRetry.animation.play('idle');
			deathSpriteRetry.visible = true;
			GameOverSubState.instance.startDeathMusic(1.0, false);
			// force the deathloop to play in here, since we are starting the music early it
			// doesn't check this in gameover substate !
			// also no animation suffix 🤔
			GameOverSubState.instance.boyfriend.playAnimation('deathLoop');

			deathSpriteRetry.x = this.x + 195;
			deathSpriteRetry.y = this.y - 70;
		}

		if (name == "cock" && frameNumber == 3) {
			createCasing();
		}
	}

	var casingGroup:FlxTypedSpriteGroup;

	function createCasing() {
		if (casingGroup == null) {
			casingGroup = new FlxTypedSpriteGroup();
			casingGroup.x = this.x + 250;
			casingGroup.y = this.y + 100;
			casingGroup.zIndex = 1000;
			addToStage(casingGroup);
		}

		var casing = ScriptedFunkinSprite.init('CasingSprite', 0, 0);
		if (casing != null)
			casingGroup.add(casing);
	}

	function clearCasings() {
		// Clear the casing group.
		if (casingGroup != null) {
			casingGroup.clear();
			casingGroup = null;
		}
	}

	/**
	 * Play the animation where Pico readies his gun to shoot the can.
	 */
	function playCockGunAnim() {
		this.playAnimation('cock', true, true);

		picoFade = new FlxSprite(0, 0);
		picoFade.frames = this.frames;
		picoFade.frame = this.frame;
		picoFade.updateHitbox();
		picoFade.x = this.x;
		picoFade.y = this.y;
		// picoFade.stamp(this, 0, 0);
		picoFade.alpha = 0.3;
		picoFade.zIndex = this.zIndex - 3;
		addToStage(picoFade);
		FlxTween.tween(picoFade.scale, {x: 1.3, y: 1.3}, 0.4);
		FlxTween.tween(picoFade, {alpha: 0}, 0.4);


		FunkinSound.playOnce(Paths.sound('Gun_Prep'), 1.0);
	}
	/**
	 * Play the animation where Pico shoots the can successfully.
	 */
	function playFireGunAnim(hip:Bool) {
		this.playAnimation('shoot', true, true);
		FunkinSound.playOnce(Paths.soundRandom('shot', 1, 4));
	}
	/**
	 * Play the animation where Pico is hit by the exploding can.
	 */
	function playCanExplodeAnim() {

		this.playAnimation('shootMISS', true, true);
		// Donk.
		FunkinSound.playOnce(Paths.sound('Pico_Bonk'), 1.0);
	}

	function addToStage(sprite:FlxSprite) {
		if (this.debug) {
			// We are in the chart editor or something.
			// TODO: Make this work properly.
		} else if (PlayState.instance != null && PlayState.instance.currentStage != null) {
			PlayState.instance.currentStage.add(sprite);
		} else {
			trace('Could not add Pico sprite to stage.');
		}
	}
}
