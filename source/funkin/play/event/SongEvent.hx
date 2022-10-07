package funkin.play.event;

import flixel.FlxSprite;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.play.song.SongData.RawSongEventData;
import haxe.DynamicAccess;

typedef RawSongEvent =
{
	> RawSongEventData,

	/**
	 * Whether the event has been activated or not.
	 */
	var a:Bool;
}

@:forward
abstract SongEvent(RawSongEvent)
{
	public function new(time:Float, event:String, value:Dynamic = null)
	{
		this = {
			t: time,
			e: event,
			v: value,
			a: false
		};
	}

	public var time(get, set):Float;

	public function get_time():Float
	{
		return this.t;
	}

	public function set_time(value:Float):Float
	{
		return this.t = value;
	}

	public var event(get, set):String;

	public function get_event():String
	{
		return this.e;
	}

	public function set_event(value:String):String
	{
		return this.e = value;
	}

	public var value(get, set):Dynamic;

	public function get_value():Dynamic
	{
		return this.v;
	}

	public function set_value(value:Dynamic):Dynamic
	{
		return this.v = value;
	}

	public inline function getBool():Bool
	{
		return cast this.v;
	}

	public inline function getInt():Int
	{
		return cast this.v;
	}

	public inline function getFloat():Float
	{
		return cast this.v;
	}

	public inline function getString():String
	{
		return cast this.v;
	}

	public inline function getArray():Array<Dynamic>
	{
		return cast this.v;
	}

	public inline function getMap():DynamicAccess<Dynamic>
	{
		return cast this.v;
	}

	public inline function getBoolArray():Array<Bool>
	{
		return cast this.v;
	}
}

typedef SongEventCallback = SongEvent->Void;

class SongEventHandler
{
	private static final eventCallbacks:Map<String, SongEventCallback> = new Map<String, SongEventCallback>();

	public static function registerCallback(event:String, callback:SongEventCallback):Void
	{
		eventCallbacks.set(event, callback);
	}

	public static function unregisterCallback(event:String):Void
	{
		eventCallbacks.remove(event);
	}

	public static function clearCallbacks():Void
	{
		eventCallbacks.clear();
	}

	/**
	 * Register each of the event callbacks provided by the base game.
	 */
	public static function registerBaseEventCallbacks():Void
	{
		// TODO: Add a system for mods to easily add their own event callbacks.
		// Should be easy as creating character or stage scripts.
		registerCallback('FocusCamera', VanillaEventCallbacks.focusCamera);
		registerCallback('PlayAnimation', VanillaEventCallbacks.playAnimation);
	}

	/**
	 * Given a list of song events and the current timestamp,
	 * return a list of events that should be activated.
	 */
	public static function queryEvents(events:Array<SongEvent>, currentTime:Float):Array<SongEvent>
	{
		return events.filter(function(event:SongEvent):Bool
		{
			// If the event is already activated, don't activate it again.
			if (event.a)
				return false;

			// If the event is in the future, don't activate it.
			if (event.time > currentTime)
				return false;

			return true;
		});
	}

	public static function activateEvents(events:Array<SongEvent>):Void
	{
		for (event in events)
		{
			activateEvent(event);
		}
	}

	public static function activateEvent(event:SongEvent):Void
	{
		if (event.a)
		{
			trace('Event already activated: ' + event);
			return;
		}

		// Prevent the event from being activated again.
		event.a = true;

		// Perform the action.
		if (eventCallbacks.exists(event.event))
		{
			eventCallbacks.get(event.event)(event);
		}
	}

	public static function resetEvents(events:Array<SongEvent>):Void
	{
		for (event in events)
		{
			resetEvent(event);
		}
	}

	public static function resetEvent(event:SongEvent):Void
	{
		// TODO: Add a system for mods to easily add their reset callbacks.
		event.a = false;
	}
}

class VanillaEventCallbacks
{
	/**
	 * Event Name: "FocusCamera"
	 * Event Value: Int
	 *   0: Focus on the player.
	 *   1: Focus on the opponent.
	 *   2: Focus on the girlfriend.
	 */
	public static function focusCamera(event:SongEvent):Void
	{
		// Does nothing if there is no PlayState camera or stage.
		if (PlayState.instance == null || PlayState.instance.currentStage == null)
			return;

		switch (event.getInt())
		{
			case 0: // Boyfriend
				// Focus the camera on the player.
				trace('[EVENT] Focusing camera on player.');
				PlayState.instance.cameraFollowPoint.setPosition(PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.x,
					PlayState.instance.currentStage.getBoyfriend().cameraFocusPoint.y);
			case 1: // Dad
				// Focus the camera on the dad.
				trace('[EVENT] Focusing camera on dad.');
				PlayState.instance.cameraFollowPoint.setPosition(PlayState.instance.currentStage.getDad().cameraFocusPoint.x,
					PlayState.instance.currentStage.getDad().cameraFocusPoint.y);
			case 2: // Girlfriend
				// Focus the camera on the girlfriend.
				trace('[EVENT] Focusing camera on girlfriend.');
				PlayState.instance.cameraFollowPoint.setPosition(PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.x,
					PlayState.instance.currentStage.getGirlfriend().cameraFocusPoint.y);
			default:
				trace('[EVENT] Unknown camera focus: ' + event.value);
		}
	}

	/**
	 * Event Name: "playAnimation"
	 * Event Value: Object
	 *   {
	 *     target: String, // "player", "dad", "girlfriend", or <stage prop id>
	 * 	   animation: String,
	 *     force: Bool // optional
	 *   }
	 */
	public static function playAnimation(event:SongEvent):Void
	{
		// Does nothing if there is no PlayState camera or stage.
		if (PlayState.instance == null || PlayState.instance.currentStage == null)
			return;

		var data:Dynamic = event.value;

		var targetName:String = Reflect.field(data, 'target');
		var anim:String = Reflect.field(data, 'anim');
		var force:Null<Bool> = Reflect.field(data, 'force');
		if (force == null)
			force = false;

		var target:FlxSprite = null;

		switch (targetName)
		{
			case 'boyfriend':
				trace('[EVENT] Playing animation $anim on boyfriend.');
				target = PlayState.instance.currentStage.getBoyfriend();
			case 'bf':
				trace('[EVENT] Playing animation $anim on boyfriend.');
				target = PlayState.instance.currentStage.getBoyfriend();
			case 'player':
				trace('[EVENT] Playing animation $anim on boyfriend.');
				target = PlayState.instance.currentStage.getBoyfriend();
			case 'dad':
				trace('[EVENT] Playing animation $anim on dad.');
				target = PlayState.instance.currentStage.getDad();
			case 'opponent':
				trace('[EVENT] Playing animation $anim on dad.');
				target = PlayState.instance.currentStage.getDad();
			case 'girlfriend':
				trace('[EVENT] Playing animation $anim on girlfriend.');
				target = PlayState.instance.currentStage.getGirlfriend();
			case 'gf':
				trace('[EVENT] Playing animation $anim on girlfriend.');
				target = PlayState.instance.currentStage.getGirlfriend();
			default:
				target = PlayState.instance.currentStage.getNamedProp(targetName);
				if (target == null)
					trace('[EVENT] Unknown animation target: $targetName');
				else
					trace('[EVENT] Fetched animation target $targetName from stage.');
		}

		if (target != null)
		{
			if (Std.isOfType(target, BaseCharacter))
			{
				var targetChar:BaseCharacter = cast target;
				targetChar.playAnimation(anim, force, force);
			}
			else
			{
				target.animation.play(anim, force);
			}
		}
	}
}
