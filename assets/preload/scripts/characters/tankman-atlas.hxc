import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;

/**
 * A prototype variant of Tankman that uses the Adobe Animate Texture Atlas animation system.
 */
class TankmanAtlasCharacter extends AnimateAtlasCharacter {
	function new() {
		super('tankman-atlas');
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD) {
			// Override the hit note animation.
			switch(event.note.kind) {
				case "ugh":
					holdTimer = 0;
					this.playAnimFbfation('ugh');
					return;
				case "hehPrettyGood":
					holdTimer = 0;
					this.playAnimation('hehPrettyGood');
					return;
			}
		}

		super.onNoteHit(event);
	}
}
