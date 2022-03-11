package modding.module;

import openfl.events.EventType;

typedef ModuleEventType = EventType<ModuleEvent>;

class ModuleEvent
{
	public static inline var SONG_START:ModuleEventType = "SONG_START";
	public static inline var SONG_END:ModuleEventType = "SONG_END";
	public static inline var COUNTDOWN_BEGIN:ModuleEventType = "COUNTDOWN_BEGIN";
	public static inline var COUNTDOWN_STEP:ModuleEventType = "COUNTDOWN_STEP";
	public static inline var SONG_BEAT_HIT:ModuleEventType = "SONG_BEAT_HIT";
	public static inline var SONG_STEP_HIT:ModuleEventType = "SONG_STEP_HIT";

	public static inline var PAUSE:ModuleEventType = "PAUSE";
	public static inline var RESUME:ModuleEventType = "RESUME";
	public static inline var UPDATE:ModuleEventType = "UPDATE";

	/**
	 * Note hit success, health gained, note data, player vs opponent, etc
	 * are all provided as event parameters.
	 * 
	 * Event is cancelable, which will cause the press to be ignored and the note to be missed.
	 */
	public static inline var NOTE_HIT:ModuleEventType = "NOTE_HIT";

	public static inline var NOTE_MISS:ModuleEventType = "NOTE_MISS";
	public static inline var GAME_OVER:ModuleEventType = "GAME_OVER";
	public static inline var RETRY:ModuleEventType = "RETRY";

	/**
	 * If true, the behavior associated with this event can be prevented.
	 * For example, cancelling COUNTDOWN_BEGIN should prevent the countdown from starting,
	 * until another script restarts it, or cancelling NOTE_HIT should cause the note to be missed.
	 */
	public var cancelable(default, null):Bool;

	/**
	 * The type associated with the event.
	 */
	public var type(default, null):ModuleEventType;

	@:noCompletion private var __eventCanceled:Bool;
	@:noCompletion private var __shouldPropagate:Bool;

	public function new(type:ModuleEventType, cancelable:Bool = false):Void
	{
		this.type = type;
		this.cancelable = cancelable;
		this.__eventCanceled = false;
		this.__shouldPropagate = true;
	}

	/**
	 * Call this function on a cancelable event to cancel the associated behavior.
	 * For example, cancelling COUNTDOWN_BEGIN will prevent the countdown from starting.
	 */
	public function cancelEvent():Void
	{
		if (cancelable)
		{
			__eventCanceled = true;
		}
	}

	/**
	 * Call this function to stop any other modules from receiving the event.
	 */
	public function stopPropagation():Void
	{
		__shouldPropagate = false;
	}

	public function toString():String
	{
		return 'ModuleEvent(type=$type, cancelable=$cancelable)';
	}
}

/**
 * SPECIFIC EVENTS
 */
/**
 * An event that is fired associated with a specific note.
 */
class NoteModuleEvent extends ModuleEvent
{
	/**
	 * The note associated with this event.
	 * You cannot replace it, but you can edit it.
	 */
	public var note(default, null):Note;

	public function new(type:ModuleEventType, note:Note, cancelable:Bool = false):Void
	{
		super(type, cancelable);
		this.note = note;
	}

	public override function toString():String
	{
		return 'NoteModuleEvent(type=' + type + ', cancelable=' + cancelable + ', note=' + note + ')';
	}
}

/**
 * An event that is fired during the update loop.
 */
class UpdateModuleEvent extends ModuleEvent
{
	/**
	 * The note associated with this event.
	 * You cannot replace it, but you can edit it.
	 */
	public var elapsed(default, null):Float;

	public function new(elapsed:Float):Void
	{
		super(ModuleEvent.UPDATE, false);
		this.elapsed = elapsed;
	}

	public override function toString():String
	{
		return 'UpdateModuleEvent(elapsed=$elapsed)';
	}
}
