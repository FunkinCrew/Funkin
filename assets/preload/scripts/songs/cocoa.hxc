import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxBasePoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.Conductor;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.modding.base.ScriptedFlxAtlasSprite;
import funkin.play.cutscene.CutsceneType;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.GameOverSubState;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.play.stage.StageProp;
import funkin.save.Save;

// We have to use FlxBasePoint in scripts because FlxPoint is inlined and not available in scripts

class CocoaSong extends Song
{
	function new()
	{
		super('cocoa');
	}

	public override function isSongNew(currentDifficulty:String, currentVariation:String):Bool
	{
		if (currentDifficulty == 'erect' || currentDifficulty == 'nightmare')
			return !Save.instance.hasBeatenSong(this.id, ['erect', 'nightmare']);

		return false;
	}

	public override function onCountdownStart(event:CountdownScriptEvent):Void {
		super.onCountdownStart(event);
		trace(PlayState.instance.currentVariation);
	}

	function onSongRetry(event:ScriptEvent)
	{
		super.onSongRetry(event);

	}

	function onUpdate(event:UpdateScriptEvent) {
		super.onUpdate(event);
	}

	/**
   * Replay the cutscene after leaving the song.
   */
  function onCreate(event:ScriptEvent):Void
  {
    super.onCreate(event);
  }
}
