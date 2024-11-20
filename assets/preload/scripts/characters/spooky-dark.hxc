import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.play.character.SparrowCharacter;
import funkin.play.GameOverSubState;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterDataParser;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;

class SpookyDarkCharacter extends SparrowCharacter {
	function new() {
		super('spooky-dark');
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
			super.playAnimation(name, restart, ignoreOther);
      if(normalChar != null){
        normalChar.playAnimation(name, restart, ignoreOther);
        normalChar.setPosition(this.x, this.y);
      }
	}

  function onCreate(event:ScriptEvent) {
		super.onCreate(event);
	  normalChar = CharacterDataParser.fetchCharacter('spooky');
    normalChar.zIndex = 199;
		normalChar.alpha = 0;
    normalChar.flipX = false;

		PlayState.instance.currentStage.add(normalChar);
		PlayState.instance.currentStage.refresh(); // Apply z-index.
	}

}
