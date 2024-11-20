import funkin.play.character.SparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;
import flixel.addons.effects.FlxTrail;

class GirlfriendCharacter extends SparrowCharacter {
	function new() {
		super('gf');
	}

	override function onAdd() {
		if (!debug && this.characterType == CharacterType.DAD) {
      // If Girlfriend is the opponent, set her position to the stage's assigned Girlfriend position,
      // while maintaining her status as an opponent. This allows the Girlfriend character to use a shared
      // character file without weird offsets.

			var pos:FlxPoint = PlayState.instance.currentStage.getGirlfriendPosition();

			this.originalPosition.x = pos.x - this.characterOrigin.x;
			this.originalPosition.y = pos.y - this.characterOrigin.y;

			this.resetPosition();
		}
	}

	override function dance(force:Bool) {
		// Fix animation glitches with Week 3.
		// Wait for 'hairBlow' to play, preventing dancing from interrupting it.
		if (!force && ['hairBlow'].contains(getCurrentAnimation())) return;
		// Wait for 'hairFall' to finish, preventing dancing from interrupting it.
		if (!force && ['hairFall'].contains(getCurrentAnimation()) && !isAnimationFinished()) return;

		super.dance(force);
	}
}