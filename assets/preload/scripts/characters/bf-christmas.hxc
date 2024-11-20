import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.GameOverSubState;

class BoyfriendChristmasCharacter extends MultiSparrowCharacter {
	function new() {
		super('bf-christmas');
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
				default:
					super.onNoteHit(event);
			}
		}
	}
}
