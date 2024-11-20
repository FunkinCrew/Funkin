import funkin.play.character.SparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;

class ParentsChristmasCharacter extends SparrowCharacter {
	function new() {
		super('parents-christmas');
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD) {
			// Override the hit note animation.
			switch(event.note.kind) {
				case "mom":
					holdTimer = 0;
					this.playSingAnimation(event.note.noteData.getDirection(), false, 'alt');
					return;
			}
		}

		super.onNoteHit(event);
	}
}
