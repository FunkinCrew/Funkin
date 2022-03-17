package funkin.play.stage;

import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEvent.NoteScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.CountdownScriptEvent;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import flixel.FlxSprite;

/**
 * A Bopper is a stage prop which plays a dance animation.
 * Y'know, a thingie that bops. A bopper.
 */
class Bopper extends FlxSprite implements IPlayStateScriptedClass
{
	/**
	 * The bopper plays the dance animation once every `danceEvery` beats.
	 * Set to 0 to disable idle animation.
	 */
	public var danceEvery:Int = 1;

	/**
	 * Whether the bopper should dance left and right.
	 * - If true, alternate playing `danceLeft` and `danceRight`.
	 * - If false, play `idle` every time.
	 * 
	 * You can manually set this value, or you can leave it as `null` to determine it automatically.
	 */
	public var shouldAlternate:Null<Bool> = null;

	/**
	 * Set this value to define an additional horizontal offset to this sprite's position.
	 */
	public var xOffset(default, set):Float = 0;

	override function set_x(value:Float):Float
	{
		this.x = this.xOffset + value;
		return this.x;
	}

	function set_xOffset(value:Float):Float
	{
		var diff = value - this.xOffset;
		this.xOffset = value;
		this.x += diff;
		return value;
	}

	public var idleSuffix(default, set):String = "";

	function set_idleSuffix(value:String):String
	{
		this.idleSuffix = value;
		this.dance();
		return value;
	}

	/**
	 * Set this value to define an additional vertical offset to this sprite's position.
	 */
	public var yOffset:Float = 0;

	override function set_y(value:Float):Float
	{
		this.y = this.yOffset + value;
		return this.y;
	}

	function set_yOffset(value:Float):Float
	{
		var diff = value - this.yOffset;
		this.yOffset = value;
		this.y += diff;
		return value;
	}

	/**
	 * Whether to play `danceRight` next iteration.
	 * Only used when `shouldAlternate` is true.
	 */
	var hasDanced:Bool = false;

	public function new(danceEvery:Int = 1)
	{
		super();
		this.danceEvery = danceEvery;
	}

	function update_shouldAlternate():Void
	{
		if (hasAnimation('danceLeft'))
		{
			this.shouldAlternate = true;
		}
	}

	/**
	 * Called once every beat of the song.
	 */
	public function onBeatHit(event:SongTimeScriptEvent):Void
	{
		if (danceEvery > 0 && event.beat % danceEvery == 0)
		{
			dance();
		}
	}

	/**
	 * Called every `danceEvery` beats of the song.
	 */
	function dance():Void
	{
		if (this.animation == null)
		{
			return;
		}

		if (shouldAlternate == null)
		{
			update_shouldAlternate();
		}

		if (shouldAlternate)
		{
			if (hasDanced)
			{
				playAnimation('danceRight$idleSuffix');
			}
			else
			{
				playAnimation('danceLeft$idleSuffix');
			}
			hasDanced = !hasDanced;
		}
		else
		{
			playAnimation('idle$idleSuffix');
		}
	}

	public function hasAnimation(id:String):Bool
	{
		return this.animation.getByName(id) != null;
	}

	/*
	 * @param   AnimName   The string name of the animation you want to play.
	 * @param   Force      Whether to force the animation to restart.
	 */
	public function playAnimation(name:String, force:Bool = false):Void
	{
		this.animation.play(name, force, false, 0);
	}

	/**
	 * Returns the name of the animation that is currently playing.
	 */
	public function getCurrentAnimation():String
	{
		return this.animation.curAnim.name;
	}

	public function onScriptEvent(event:ScriptEvent) {}

	public function onCreate(event:ScriptEvent) {}

	public function onDestroy(event:ScriptEvent) {}

	public function onUpdate(event:UpdateScriptEvent) {}

	public function onPause(event:ScriptEvent) {}

	public function onResume(event:ScriptEvent) {}

	public function onSongStart(event:ScriptEvent) {}

	public function onSongEnd(event:ScriptEvent) {}

	public function onSongReset(event:ScriptEvent) {}

	public function onGameOver(event:ScriptEvent) {}

	public function onGameRetry(event:ScriptEvent) {}

	public function onNoteHit(event:NoteScriptEvent) {}

	public function onNoteMiss(event:NoteScriptEvent) {}

	public function onStepHit(event:SongTimeScriptEvent) {}

	public function onCountdownStart(event:CountdownScriptEvent) {}

	public function onCountdownStep(event:CountdownScriptEvent) {}

	public function onCountdownEnd(event:CountdownScriptEvent) {}

	public function onSongLoaded(eent:SongLoadScriptEvent) {}
}
