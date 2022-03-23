package funkin.play.character;

import flixel.math.FlxPoint;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.Note.NoteDir;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.play.stage.Bopper;

using StringTools;

/**
 * A Character is a stage prop which bops to the music as well as controlled by the strumlines.
 * 
 * Remember: The character's origin is at its FEET. (horizontal center, vertical bottom)
 */
class BaseCharacter extends Bopper
{
	// Metadata about a character.
	public var characterId(default, null):String;
	public var characterName(default, null):String;

	/**
	 * Whether the player is an active character (Boyfriend) or not.
	 */
	public var characterType:CharacterType = OTHER;

	/**
	 * Tracks how long, in seconds, the character has been playing the current `sing` animation.
	 * This is used to ensure that characters play the `sing` animations for at least one beat,
	 *   preventing them from reverting to the `idle` animation between notes.
	 */
	public var holdTimer:Float = 0;

	public var isDead:Bool = false;
	public var debugMode:Bool = false;

	final _data:CharacterData;
	final singTimeCrochet:Float;

	/**
	 * The x and y position to subtract from the stage's X value to get the character's proper rendering position.
	 */
	public var characterOrigin(get, null):FlxPoint;

	function get_characterOrigin():FlxPoint
	{
		var xPos = (width / 2); // Horizontal center
		var yPos = (height); // Vertical bottom
		trace('Origin: ${characterId} (${xPos}, ${yPos})');
		return new FlxPoint(xPos, yPos);
	}

	override function set_x(value:Float):Float
	{
		return super.set_x(value);
	}

	public function new(id:String)
	{
		super();
		this.characterId = id;

		_data = CharacterDataParser.fetchCharacterData(this.characterId);
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

		// Reset hold timer for each note pressed.
		if (justPressedNote())
		{
			holdTimer = 0;
		}

		if (isDead)
		{
			playDeathAnimation();
		}

		if (hasAnimation('idle-end') && getCurrentAnimation() == "idle" && isAnimationFinished())
			playAnimation('idle-end');
		if (hasAnimation('singLEFT-end') && getCurrentAnimation() == "singLEFT" && isAnimationFinished())
			playAnimation('singLEFT-end');
		if (hasAnimation('singDOWN-end') && getCurrentAnimation() == "singDOWN" && isAnimationFinished())
			playAnimation('singDOWN-end');
		if (hasAnimation('singUP-end') && getCurrentAnimation() == "singUP" && isAnimationFinished())
			playAnimation('singUP-end');
		if (hasAnimation('singRIGHT-end') && getCurrentAnimation() == "singRIGHT" && isAnimationFinished())
			playAnimation('singRIGHT-end');

		// Handle character note hold time.
		if (getCurrentAnimation().startsWith("sing"))
		{
			holdTimer += event.elapsed;
			var singTimeMs:Float = singTimeCrochet * (Conductor.crochet * 0.001); // x beats, to ms.
			// Without this check here, the player character would only play the `sing` animation
			// for one beat, as opposed to holding it as long as the player is holding the button.
			var shouldStopSinging:Bool = (this.characterType == BF) ? !isHoldingNote() : true;

			FlxG.watch.addQuick('singTimeMs-${characterId}', singTimeMs);
			if (holdTimer > singTimeMs && shouldStopSinging)
			{
				trace('holdTimer reached ${holdTimer}sec (> ${singTimeMs}), stopping sing animation');
				holdTimer = 0;
				dance(true);
			}
		}
		else
		{
			holdTimer = 0;
			// super.onBeatHit handles the regular `dance()` calls.
		}
		FlxG.watch.addQuick('holdTimer-${characterId}', holdTimer);
	}

	/**
	 * Since no `onBeatHit` or `dance` calls happen in GameOverSubstate,
	 * this regularly gets called instead.
	 */
	public function playDeathAnimation(force:Bool = false):Void
	{
		if (force || (getCurrentAnimation().startsWith("firstDeath") && isAnimationFinished()))
		{
			playAnimation("deathLoop");
		}
	}

	override function dance(force:Bool = false)
	{
		// Prevent default dancing behavior.
		if (debugMode)
			return;

		if (!force)
		{
			if (getCurrentAnimation().startsWith("sing"))
			{
				return;
			}
			if (["hey", "cheer"].contains(getCurrentAnimation()) && !isAnimationFinished())
			{
				return;
			}
		}

		// Prevent dancing while another animation is playing.
		if (!force && getCurrentAnimation().startsWith("sing"))
		{
			return;
		}

		// Otherwise, fallback to the super dance() method, which handles playing the idle animation.
		super.dance();
	}

	/**
	 * Returns true if the player just pressed a note.
	 * Used when determing whether a the player character should revert to the `idle` animation.
	 * On non-player characters, this should be ignored.
	 */
	function justPressedNote(player:Int = 1):Bool
	{
		// Returns true if at least one of LEFT, DOWN, UP, or RIGHT is being held.
		switch (player)
		{
			case 1:
				return [
					PlayerSettings.player1.controls.NOTE_LEFT_P,
					PlayerSettings.player1.controls.NOTE_DOWN_P,
					PlayerSettings.player1.controls.NOTE_UP_P,
					PlayerSettings.player1.controls.NOTE_RIGHT_P,
				].contains(true);
			case 2:
				return [
					PlayerSettings.player2.controls.NOTE_LEFT_P,
					PlayerSettings.player2.controls.NOTE_DOWN_P,
					PlayerSettings.player2.controls.NOTE_UP_P,
					PlayerSettings.player2.controls.NOTE_RIGHT_P,
				].contains(true);
		}
		return false;
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

		trace('HIT NOTE: ${event.note.data.dir} : ${event.note.isSustainNote}');

		holdTimer = 0;

		if (event.note.mustPress && characterType == BF)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, false, event.note.data.altNote);
		}
		else if (!event.note.mustPress && characterType == DAD)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, false, event.note.data.altNote);
		}
	}

	/**
	 * Every time a note is missed, check if the note is from the same strumline.
	 * If it is, then play the sing animation.
	 */
	public override function onNoteMiss(event:NoteScriptEvent)
	{
		super.onNoteMiss(event);

		if (event.note.mustPress && characterType == BF)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, true, event.note.data.altNote);
		}
		else if (!event.note.mustPress && characterType == DAD)
		{
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.note.data.dir, true, event.note.data.altNote);
		}
	}

	/**
	 * Every time a wrong key is pressed, play the miss animation if we are Boyfriend.
	 */
	public override function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
	{
		super.onNoteGhostMiss(event);

		if (event.eventCanceled || !event.playAnim)
		{
			// Skipping...
			return;
		}

		if (characterType == BF)
		{
			trace('Playing ghost miss animation...');
			// If the note is from the same strumline, play the sing animation.
			this.playSingAnimation(event.dir, true, null);
		}
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
	public function playSingAnimation(dir:NoteDir, miss:Bool = false, suffix:String = ""):Void
	{
		var anim:String = 'sing${dir.nameUpper}${miss ? 'miss' : ''}${suffix != "" ? '-${suffix}' : ''}';

		// restart even if already playing, because the character might sing the same note twice.
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
