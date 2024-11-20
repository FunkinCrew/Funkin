import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;

class TankmanCharacter extends MultiSparrowCharacter {
	function new() {
		super('tankman');
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		super.onNoteHit(event);

		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD) {
			// Override the hit note animation.
			switch(event.note.kind) {
				case "ugh":
					holdTimer = 0;
					this.playAnimation('ugh', true, true);
					return;
				case "hehPrettyGood":
					holdTimer = 0;
					this.playAnimation('hehPrettyGood', true, true);
					return;
			}
		}
	}
}
