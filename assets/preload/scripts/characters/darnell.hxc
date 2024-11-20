import funkin.play.character.SparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;
import funkin.audio.FunkinSound;
import funkin.Conductor;
import flixel.FlxG;

class DarnellCharacter extends SparrowCharacter {
	function new() {
		super('darnell');
	}

	function onNoteHit(event:HitNoteScriptEvent)
	{
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD) {
			// Override the hit note animation.
			switch(event.note.kind) {
				case "weekend-1-lightcan":
					holdTimer = 0;
					playLightCanAnim();
				case "weekend-1-kickcan":
					holdTimer = 0;
					playKickCanAnim();
				case "weekend-1-kneecan":
					holdTimer = 0;
					playKneeCanAnim();
				default:
					super.onNoteHit(event);
			}
		}
	}

	function onNoteIncoming(event:NoteScriptEvent) {
		if (!event.note.noteData.getMustHitNote() && characterType == CharacterType.DAD) {
			// Get how long until it's time to strum the note.
			var msTilStrum = event.note.strumTime - Conductor.instance.songPosition;

			switch(event.note.kind) {
				case "weekend-1-lightcan":
					scheduleLightCanSound(msTilStrum - 65);
				case "weekend-1-kickcan":
					scheduleKickCanSound(msTilStrum - 50);
				case "weekend-1-kneecan":
					scheduleKneeCanSound(msTilStrum - 22);
				default:
					super.onNoteIncoming(event);
			}
		}
	}

	/**
	 * Play the animation where Darnell kneels down to light the can.
	 */
	function playLightCanAnim() {
		this.playAnimation('lightCan', true, true);
	}

	var lightCanSound:FunkinSound;
	var loadedLightCanSound:Bool = false;
	/**
	 * Schedule the can-lighting sound to play in X ms
	 */
	function scheduleLightCanSound(timeToPlay:Float) {
		if (!loadedLightCanSound) {
			lightCanSound = FunkinSound.load(Paths.sound('Darnell_Lighter'), 1.0);
			loadedLightCanSound = true;
		}

		lightCanSound.play(true, -timeToPlay);
	}

	/**
	 * Play the animation where Darnell kicks the can into the air.
	 */
	function playKickCanAnim() {
		this.playAnimation('kickCan', true, true);
	}

	var kickCanSound:FunkinSound;
	var loadedKickCanSound:Bool = false;
	/**
	 * Schedule the can-kicking sound to play in X ms
	 */
	function scheduleKickCanSound(timeToPlay:Float) {
		if (!loadedKickCanSound) {
			kickCanSound = FunkinSound.load(Paths.sound('Kick_Can_UP'), 1.0);
			loadedKickCanSound = true;
		}

		kickCanSound.play(true, -timeToPlay);
	}

	/**
	 * Play the animation where Darnell knees the can in Pico's direction.
	 */
	function playKneeCanAnim() {
		this.playAnimation('kneeCan', true, true);
	}

	var kneeCanSound:FunkinSound;
	var loadedKneeCanSound:Bool = false;
	/**
	 * Schedule the can-kneeing sound to play in X ms
	 */
	function scheduleKneeCanSound(timeToPlay:Float) {
		if (!loadedKneeCanSound) {
			kneeCanSound = FunkinSound.load(Paths.sound('Kick_Can_FORWARD'), 1.0);
			loadedKneeCanSound = true;
		}

		kneeCanSound.play(true, -timeToPlay);
	}
}
