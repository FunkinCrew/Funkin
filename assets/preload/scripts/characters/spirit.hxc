import funkin.play.character.PackerCharacter;
import funkin.play.PlayState;
import flixel.addons.effects.FlxTrail;
import funkin.effects.FunkTrail;

class SpiritCharacter extends PackerCharacter {
	function new() {
		super('spirit');
	}

	function onCreate(event:ScriptEvent) {
		super.onCreate(event);

		// Weird workaround because `this` is a PolymodScriptClass and not a ScriptedPackerCharacter.
		var evilTrail = new FunkTrail(this.superClass, null, 4, 24, 0.3, 0.069);

		// Go behind Spirit.
		evilTrail.zIndex = 190;
		addToStage(evilTrail);
	}

	function addToStage(sprite:FlxSprite) {
		if (this.debug) {
			// We are in the chart editor or something.
			FlxG.stage.add(sprite);
		} else {
			PlayState.instance.currentStage.add(sprite);
		}
	}
}
