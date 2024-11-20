import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxG;
import funkin.play.character.MultiSparrowCharacter;
import funkin.audio.FunkinSound;
import funkin.play.character.SparrowCharacter;
import funkin.play.GameOverSubState;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterDataParser;
import funkin.play.character.CharacterType;
import funkin.graphics.FunkinSprite;
import funkin.play.PauseSubState;
import funkin.play.PlayState;

class PicoDarkCharacter extends MultiSparrowCharacter {
	function new() {
		super('pico-dark');
	}

  var normalChar:BaseCharacter;

	override function set_alpha(val:Float):Float{
		super.set_alpha(val);
		if(val != 1)
			normalChar.alpha = 1;
		else
			normalChar.alpha = 0;

    return val;
	}

	override function playAnimation(name:String, restart:Bool, ignoreOther:Bool) {
		if (name == "firstDeath") {
			createDeathSprites();

			GameOverSubState.instance.add(deathSpriteRetry);
			GameOverSubState.instance.add(deathSpriteNene);
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
      if(normalChar != null){
        normalChar.playAnimation(name, restart, ignoreOther);
        normalChar.setPosition(this.x, this.y);
      }
	}

  function onCreate(event:ScriptEvent) {
		super.onCreate(event);
	  normalChar = CharacterDataParser.fetchCharacter('pico-playable');
    normalChar.zIndex = 199;
		normalChar.alpha = 0;
    normalChar.flipX = false;

		GameOverSubState.musicSuffix = '-pico';
		GameOverSubState.blueBallSuffix = '-pico';

		PauseSubState.musicSuffix = '-pico';

		PlayState.instance.currentStage.add(normalChar);
		PlayState.instance.currentStage.refresh(); // Apply z-index.
	}

	var deathSpriteRetry:FunkinSprite;
	var deathSpriteNene:FunkinSprite;

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
	}
}
