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
	public var xOffset:Float = 0;

	override function set_x(value:Float):Float
	{
		this.x = value + this.xOffset;
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
		this.y = value + this.yOffset;
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
		if (this.animation.getByName('danceLeft') != null)
		{
			this.shouldAlternate = true;
		}
	}

	/**
	 * Called once every beat of the song.
	 */
	public function onBeatHit(event:SongTimeScriptEvent):Void
	{
		if (event.beat % danceEvery == 0)
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
				this.animation.play('danceRight$idleSuffix');
			}
			else
			{
				this.animation.play('danceLeft$idleSuffix');
			}
			hasDanced = !hasDanced;
		}
		else
		{
			this.animation.play('idle$idleSuffix');
		}
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
