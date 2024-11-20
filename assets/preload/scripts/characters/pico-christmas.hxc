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


class PicoChristmasCharacter extends MultiSparrowCharacter {
	function new() {
		super('pico-christmas');
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
		//trace('PICO: Creating death sprites');
		deathSpriteRetry = FunkinSprite.createSparrow(0, 0, "characters/Pico_Death_Retry");
		deathSpriteRetry.animation.addByPrefix('idle', "Retry Text Loop0", 24, true);
		deathSpriteRetry.animation.addByPrefix('confirm', "Retry Text Confirm0", 24, false);

		deathSpriteRetry.zIndex = this.zIndex + 5;

		deathSpriteRetry.visible = false;

		//FlxG.debugger.track(deathSpriteRetry);

		deathSpriteNene = FunkinSprite.createSparrow(0, 0, "characters/neneChristmas/neneChristmasKnife");
		var gf = PlayState.instance.currentStage.getGirlfriend();
		deathSpriteNene.x = gf.originalPosition.x; // + 280;
		deathSpriteNene.y = gf.originalPosition.y; // + 70;
		deathSpriteNene.zIndex = this.zIndex - 5;
		deathSpriteNene.animation.addByPrefix('throw', "knife toss xmas0", 24, false);
		deathSpriteNene.visible = true;
		deathSpriteNene.animation.finishCallback = function(name:String) {
			deathSpriteNene.visible = false;
		}
	}

	function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
		if (name == "firstDeath") {
			// Standard death animation.
			createDeathSprites();

			trace('Adding death sprites...');
			GameOverSubState.instance.add(deathSpriteRetry);
			GameOverSubState.instance.add(deathSpriteNene);
			GameOverSubState.instance.refresh();
			deathSpriteNene.animation.play("throw");
		} else if (name == "deathConfirm") {
			deathSpriteRetry.animation.play('confirm');
			// I think the glow makes the overall animation larger,
			// but a plain FlxSprite doesn't have an animation offset option so we do it manually.
			deathSpriteRetry.x -= 250;
			deathSpriteRetry.y -= 200;
			// Skip playing the animation.
			return;
		}

		super.playAnimation(name, restart, ignoreOther);
	}

	override function onGameOver(event:ScriptEvent):Void {
		super.onGameOver(event);
	}

	override function onSongRetry(event:ScriptEvent):Void {
		super.onSongRetry(event);

		// Reset to standard death animation.
		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico';

		PauseSubState.musicSuffix = '-pico';

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

			deathSpriteRetry.x = this.x + 416;
			deathSpriteRetry.y = this.y + 42;
		}
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
