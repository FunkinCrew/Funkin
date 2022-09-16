package funkin.modding.events;

import flixel.FlxState;
import flixel.FlxSubState;
import funkin.noteStuff.NoteBasic.NoteDir;
import funkin.play.Countdown.CountdownStep;
import openfl.events.EventType;
import openfl.events.KeyboardEvent;

typedef ScriptEventType = EventType<ScriptEvent>;

/**
 * This is a base class for all events that are issued to scripted classes.
 * It can be used to identify the type of event called, store data, and cancel event propagation.
 */
class ScriptEvent
{
	/**
	 * Called when the relevant object is created.
	 * Keep in mind that the constructor may be called before the object is needed,
	 * for the purposes of caching data or otherwise.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final CREATE:ScriptEventType = "CREATE";

	/**
	 * Called when the relevant object is destroyed.
	 * This should perform relevant cleanup to ensure good performance.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final DESTROY:ScriptEventType = "DESTROY";

	/**
	 * Called during the update function.
	 * This is called every frame, so be careful!
	 * 
	 * This event is not cancelable.
	 */
	public static inline final UPDATE:ScriptEventType = "UPDATE";

	/**
	 * Called when the player moves to pause the game.
	 * 
	 * This event IS cancelable! Canceling the event will prevent the game from pausing.
	 */
	public static inline final PAUSE:ScriptEventType = "PAUSE";

	/**
	 * Called when the player moves to unpause the game while paused.
	 * 
	 * This event IS cancelable! Canceling the event will prevent the game from resuming.
	 */
	public static inline final RESUME:ScriptEventType = "RESUME";

	/**
	 * Called once per step in the song. This happens 4 times per measure.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SONG_BEAT_HIT:ScriptEventType = "BEAT_HIT";

	/**
	 * Called once per step in the song. This happens 16 times per measure.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SONG_STEP_HIT:ScriptEventType = "STEP_HIT";

	/**
	 * Called when a character hits a note.
	 * Important information such as judgement/timing, note data, player/opponent, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being hit,
	 *   and will likely result in a miss later.
	 */
	public static inline final NOTE_HIT:ScriptEventType = "NOTE_HIT";

	/**
	 * Called when a character misses a note.
	 * Important information such as note data, player/opponent, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being considered missed,
	 *   avoiding a combo break and lost health.
	 */
	public static inline final NOTE_MISS:ScriptEventType = "NOTE_MISS";

	/**
	 * Called when a character presses a note when there was none there, causing them to lose health.
	 * Important information such as direction pressed, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being considered missed,
	 *   avoiding lost health/score and preventing the miss animation.
	 */
	public static inline final NOTE_GHOST_MISS:ScriptEventType = "NOTE_GHOST_MISS";

	/**
	 * Called when the song starts. This occurs as the countdown ends and the instrumental and vocals begin.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SONG_START:ScriptEventType = "SONG_START";

	/**
	 * Called when the song ends. This happens as the instrumental and vocals end.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SONG_END:ScriptEventType = "SONG_END";

	/**
	 * Called when the countdown begins. This occurs before the song starts.
	 * 
	 * This event IS cancelable! Canceling this event will prevent the countdown from starting.
	 * - The song will not start until you call Countdown.performCountdown() later.
	 * - Note that calling performCountdown() will trigger this event again, so be sure to add logic to ignore it.
	 */
	public static inline final COUNTDOWN_START:ScriptEventType = "COUNTDOWN_START";

	/**
	 * Called when a step of the countdown happens.
	 * Includes information about what step of the countdown was hit.
	 * 
	 * This event IS cancelable! Canceling this event will pause the countdown.
	 * - The countdown will not resume until you call PlayState.resumeCountdown().
	 */
	public static inline final COUNTDOWN_STEP:ScriptEventType = "COUNTDOWN_STEP";

	/**
	 * Called when the countdown is done but just before the song starts.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final COUNTDOWN_END:ScriptEventType = "COUNTDOWN_END";

	/**
	 * Called before the game over screen triggers and the death animation plays.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final GAME_OVER:ScriptEventType = "GAME_OVER";

	/**
	 * Called after the player presses a key to restart the game.
	 * This can happen from the pause menu or the game over screen.
	 * 
	 * This event IS cancelable! Canceling this event will prevent the game from restarting.
	 */
	public static inline final SONG_RETRY:ScriptEventType = "SONG_RETRY";

	/**
	 * Called when the player pushes down any key on the keyboard.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final KEY_DOWN:ScriptEventType = "KEY_DOWN";

	/**
	 * Called when the player releases a key on the keyboard.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final KEY_UP:ScriptEventType = "KEY_UP";

	/**
	 * Called when the game has finished loading the notes from JSON.
	 * This allows modders to mutate the notes before they are used in the song.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SONG_LOADED:ScriptEventType = "SONG_LOADED";

	/**
	 * Called when the game is about to switch the current FlxState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final STATE_CHANGE_BEGIN:ScriptEventType = "STATE_CHANGE_BEGIN";

	/**
	 * Called when the game has finished switching the current FlxState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final STATE_CHANGE_END:ScriptEventType = "STATE_CHANGE_END";

	/**
	 * Called when the game is about to open a new FlxSubState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SUBSTATE_OPEN_BEGIN:ScriptEventType = "SUBSTATE_OPEN_BEGIN";

	/**
	 * Called when the game has finished opening a new FlxSubState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SUBSTATE_OPEN_END:ScriptEventType = "SUBSTATE_OPEN_END";

	/**
	 * Called when the game is about to close the current FlxSubState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SUBSTATE_CLOSE_BEGIN:ScriptEventType = "SUBSTATE_CLOSE_BEGIN";

	/**
	 * Called when the game has finished closing the current FlxSubState.
	 * 
	 * This event is not cancelable.
	 */
	public static inline final SUBSTATE_CLOSE_END:ScriptEventType = "SUBSTATE_CLOSE_END";

	/**
	 * Called when the game is exiting the current FlxState.
	 * 
	 * This event is not cancelable.
	 */
	/**
	 * If true, the behavior associated with this event can be prevented.
	 * For example, cancelling COUNTDOWN_START should prevent the countdown from starting,
	 * until another script restarts it, or cancelling NOTE_HIT should cause the note to be missed.
	 */
	public var cancelable(default, null):Bool;

	/**
	 * The type associated with the event.
	 */
	public var type(default, null):ScriptEventType;

	/**
	 * Whether the event should continue to be triggered on additional targets.
	 */
	public var shouldPropagate(default, null):Bool;

	/**
	 * Whether the event has been canceled by one of the scripts that received it.
	 */
	public var eventCanceled(default, null):Bool;

	public function new(type:ScriptEventType, cancelable:Bool = false):Void
	{
		this.type = type;
		this.cancelable = cancelable;
		this.eventCanceled = false;
		this.shouldPropagate = true;
	}

	/**
	 * Call this function on a cancelable event to cancel the associated behavior.
	 * For example, cancelling COUNTDOWN_START will prevent the countdown from starting.
	 */
	public function cancelEvent():Void
	{
		if (cancelable)
		{
			eventCanceled = true;
		}
	}

	public function cancel():Void
	{
		// This typo happens enough that I just added this.
		cancelEvent();
	}

	/**
	 * Call this function to stop any other Scripteds from receiving the event.
	 */
	public function stopPropagation():Void
	{
		shouldPropagate = false;
	}

	public function toString():String
	{
		return 'ScriptEvent(type=$type, cancelable=$cancelable)';
	}
}

/**
 * SPECIFIC EVENTS
 */
/**
 * An event that is fired associated with a specific note.
 */
class NoteScriptEvent extends ScriptEvent
{
	/**
	 * The note associated with this event.
	 * You cannot replace it, but you can edit it.
	 */
	public var note(default, null):Note;

	/**
	 * The combo count as it is with this event.
	 * Will be (combo) on miss events and (combo + 1) on hit events (the stored combo count won't update if the event is cancelled).
	 */
	public var comboCount(default, null):Int;

	public function new(type:ScriptEventType, note:Note, comboCount:Int = 0, cancelable:Bool = false):Void
	{
		super(type, cancelable);
		this.note = note;
		this.comboCount = comboCount;
	}

	public override function toString():String
	{
		return 'NoteScriptEvent(type=' + type + ', cancelable=' + cancelable + ', note=' + note + ', comboCount=' + comboCount + ')';
	}
}

/**
 * An event that is fired when you press a key with no note present.
 */
class GhostMissNoteScriptEvent extends ScriptEvent
{
	/**
	 * The direction that was mistakenly pressed.
	 */
	public var dir(default, null):NoteDir;

	/**
	 * Whether there was a note within judgement range when this ghost note was pressed.
	 */
	public var hasPossibleNotes(default, null):Bool;

	/**
	 * How much health should be lost when this ghost note is pressed.
	 * Remember that max health is 2.00.
	 */
	public var healthChange(default, default):Float;

	/**
	 * How much score should be lost when this ghost note is pressed.
	 */
	public var scoreChange(default, default):Int;

	/**
	 * Whether to play the record scratch sound.
	 */
	public var playSound(default, default):Bool;

	/**
	 * Whether to play the miss animation on the player.
	 */
	public var playAnim(default, default):Bool;

	public function new(dir:NoteDir, hasPossibleNotes:Bool, healthChange:Float, scoreChange:Int):Void
	{
		super(ScriptEvent.NOTE_GHOST_MISS, true);
		this.dir = dir;
		this.hasPossibleNotes = hasPossibleNotes;
		this.healthChange = healthChange;
		this.scoreChange = scoreChange;
		this.playSound = true;
		this.playAnim = true;
	}

	public override function toString():String
	{
		return 'GhostMissNoteScriptEvent(dir=' + dir + ', hasPossibleNotes=' + hasPossibleNotes + ')';
	}
}

/**
 * An event that is fired during the update loop.
 */
class UpdateScriptEvent extends ScriptEvent
{
	/**
	 * The note associated with this event.
	 * You cannot replace it, but you can edit it.
	 */
	public var elapsed(default, null):Float;

	public function new(elapsed:Float):Void
	{
		super(ScriptEvent.UPDATE, false);
		this.elapsed = elapsed;
	}

	public override function toString():String
	{
		return 'UpdateScriptEvent(elapsed=$elapsed)';
	}
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class SongTimeScriptEvent extends ScriptEvent
{
	/**
	 * The current beat of the song.
	 */
	public var beat(default, null):Int;

	/**
	 * The current step of the song.
	 */
	public var step(default, null):Int;

	public function new(type:ScriptEventType, beat:Int, step:Int):Void
	{
		super(type, true);
		this.beat = beat;
		this.step = step;
	}

	public override function toString():String
	{
		return 'SongTimeScriptEvent(type=' + type + ', beat=' + beat + ', step=' + step + ')';
	}
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class CountdownScriptEvent extends ScriptEvent
{
	/**
	 * The current step of the countdown.
	 */
	public var step(default, null):CountdownStep;

	public function new(type:ScriptEventType, step:CountdownStep, cancelable = true):Void
	{
		super(type, cancelable);
		this.step = step;
	}

	public override function toString():String
	{
		return 'CountdownScriptEvent(type=' + type + ', step=' + step + ')';
	}
}

/**
 * An event that is fired when the player presses a key.
 */
class KeyboardInputScriptEvent extends ScriptEvent
{
	/**
	 * The associated keyboard event.
	 */
	public var event(default, null):KeyboardEvent;

	public function new(type:ScriptEventType, event:KeyboardEvent):Void
	{
		super(type, false);
		this.event = event;
	}

	public override function toString():String
	{
		return 'KeyboardInputScriptEvent(type=' + type + ', event=' + event + ')';
	}
}

/**
 * An event that is fired once the song's chart has been parsed.
 */
class SongLoadScriptEvent extends ScriptEvent
{
	/**
	 * The note associated with this event.
	 * You cannot replace it, but you can edit it.
	 */
	public var notes(default, set):Array<Note>;

	public var id(default, null):String;

	public var difficulty(default, null):String;

	function set_notes(notes:Array<Note>):Array<Note>
	{
		this.notes = notes;
		return this.notes;
	}

	public function new(id:String, difficulty:String, notes:Array<Note>):Void
	{
		super(ScriptEvent.SONG_LOADED, false);
		this.id = id;
		this.difficulty = difficulty;
		this.notes = notes;
	}

	public override function toString():String
	{
		var noteStr = notes == null ? 'null' : 'Array(' + notes.length + ')';
		return 'SongLoadScriptEvent(notes=$noteStr, id=$id, difficulty=$difficulty)';
	}
}

/**
 * An event that is fired when moving out of or into an FlxState.
 */
class StateChangeScriptEvent extends ScriptEvent
{
	/**
	 * The state the game is moving into.
	 */
	public var targetState(default, null):FlxState;

	public function new(type:ScriptEventType, targetState:FlxState, cancelable:Bool = false):Void
	{
		super(type, cancelable);
		this.targetState = targetState;
	}

	public override function toString():String
	{
		return 'StateChangeScriptEvent(type=' + type + ', targetState=' + targetState + ')';
	}
}

/**
 * An event that is fired when moving out of or into an FlxSubState.
 */
class SubStateScriptEvent extends ScriptEvent
{
	/**
	 * The state the game is moving into.
	 */
	public var targetState(default, null):FlxSubState;

	public function new(type:ScriptEventType, targetState:FlxSubState, cancelable:Bool = false):Void
	{
		super(type, cancelable);
		this.targetState = targetState;
	}

	public override function toString():String
	{
		return 'SubStateScriptEvent(type=' + type + ', targetState=' + targetState + ')';
	}
}

/**
 * An event which is called when the player attempts to pause the game.
 */
class PauseScriptEvent extends ScriptEvent
{
	/**
	 * Whether to use the Gitaroo Man pause.
	 */
	public var gitaroo(default, default):Bool;

	public function new(gitaroo:Bool):Void
	{
		super(ScriptEvent.PAUSE, true);
		this.gitaroo = gitaroo;
	}
}
