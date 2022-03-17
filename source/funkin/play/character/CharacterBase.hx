package funkin.play.character;

import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.Note.NoteDir;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.play.stage.Bopper;

/**
 * A Character is a stage prop which bops to the music as well as controlled by the strumlines.
 * 
 * Remember: The character's origin is at its FEET. (horizontal center, vertical bottom)
 */
class CharacterBase extends Bopper
{
	public var characterId(default, null):String;
	public var characterName(default, null):String;

	/**
	 * Whether the player is an active character (Boyfriend) or not.
	 */
	public var characterType:CharacterType = OTHER;

	public var attachedStrumlines(default, null):Array<Int>;

	final _data:CharacterData;

	/**
	 * Tracks how long, in seconds, the character has been playing the current `sing` animation.
	 * This is used to ensure that characters play the `sing` animations for at least one beat,
	 *   preventing them from reverting to the `idle` animation between notes.
	 */
	public var holdTimer:Float = 0;

	final singTimeCrochet:Float;

	public function new(id:String)
	{
		super();
		this.characterId = id;
		this.attachedStrumlines = [];

		_data = CharacterDataParser.parseCharacterData(this.characterId);
		if (_data == null)
		{
			throw 'Could not find character data for characterId: $characterId';
		}
		else
		{
			this.characterName = _data.name;
			this.singTimeCrochet = _data.singTime;
		}
	}

	public override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

		// Handle character note hold time.
		holdTimer += event.elapsed;
		var singTimeMs:Float = singTimeCrochet * Conductor.crochet;
		// Without this check here, the player character would only play the `sing` animation
		// for one beat, as opposed to holding it as long as the player is holding the button.
		var shouldStopSinging:Bool = (this.characterType == BF) ? !isHoldingNote() : true;

		if (holdTimer > singTimeMs && shouldStopSinging)
		{
			holdTimer = 0;
			dance();
		}
	}

	/**
	 * Returns true if the player is holding a note.
	 * Used when determing whether a the player character should revert to the `idle` animation.
	 * On non-player characters, this should be ignored.
	 */
	function isHoldingNote(player:Int = 1):Bool
	{
		// Returns true if at least one of LEFT, DOWN, UP, or RIGHT is being held.
		switch (player)
		{
			case 1:
				return [
					PlayerSettings.player1.controls.NOTE_LEFT,
					PlayerSettings.player1.controls.NOTE_DOWN,
					PlayerSettings.player1.controls.NOTE_UP,
					PlayerSettings.player1.controls.NOTE_RIGHT,
				].contains(true);
			case 2:
				return [
					PlayerSettings.player2.controls.NOTE_LEFT,
					PlayerSettings.player2.controls.NOTE_DOWN,
					PlayerSettings.player2.controls.NOTE_UP,
					PlayerSettings.player2.controls.NOTE_RIGHT,
				].contains(true);
		}
		return false;
	}

	/**
	 * Every time a note is hit, check if the note is from the same strumline.
	 * If it is, then play the sing animation.
	 */
	public override function onNoteHit(event:NoteScriptEvent)
	{
		super.onNoteHit(event);
		// If event.note is from the same strumline as this character, then sing.
		// if (this.attachedStrumlines.indexOf(event.note.strumline) != -1)
		// {
		//	this.playSingAnimation(event.note.dir, false, note.alt);
		// }
	}

	public override function onDestroy(event:ScriptEvent):Void
	{
		this.characterType = OTHER;
	}

	/**
	 * Play the appropriate singing animation, for the given note direction.
	 * @param dir The direction of the note.
	 * @param miss If true, play the miss animation instead of the sing animation.
	 * @param suffix A suffix to append to the animation name, like `alt`.
	 */
	function playSingAnimation(dir:NoteDir, miss:Bool = false, suffix:String = ""):Void
	{
		var anim:String = 'sing${dir.nameUpper}${miss ? 'miss' : ''}${suffix != "" ? '-${suffix}' : ''}';
		playAnimation(anim, true);
	}
}

enum CharacterType
{
	BF;
	DAD;
	GF;
	OTHER;
}
