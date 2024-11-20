import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.play.PlayState;
import funkin.play.stage.Stage;

class SpookyMansionStage extends Stage
{
	function new()
	{
		super('spookyMansion');
	}

	var lightningStrikeBeat:Int = 0;
	var lightningStrikeOffset:Int = 8;

	function doLightningStrike(playSound:Bool, beat:Int):Void
	{
		if (playSound)
		{
			FunkinSound.playOnce(Paths.soundRandom('thunder_', 1, 2), 1.0);
		}

		getNamedProp('halloweenBG').animation.play('lightning');

		lightningStrikeBeat = beat;
		lightningStrikeOffset = FlxG.random.int(8, 24);

		if (getBoyfriend() != null && getBoyfriend().hasAnimation('scared')) {
			getBoyfriend().playAnimation('scared', true, true);
		}

		if (getGirlfriend() != null && getGirlfriend().hasAnimation('scared')) {
			getGirlfriend().playAnimation('scared', true, true);
		}
	}

	/**
	 * If your stage uses additional assets not specified in the JSON,
	 * make sure to specify them like this, or they won't get cached in the loading screen.
	 */
	function fetchAssetPaths():Array<String>
	{
		var results:Array<String> = super.fetchAssetPaths();
		results.push(Paths.sound('thunder_1'));
		results.push(Paths.sound('thunder_2'));
		return results;
	}

	function onBeatHit(event:SongTimeScriptEvent)
	{
		super.onBeatHit(event);

		// Play lightning on sync at the start of this specific song.
		// TODO: Rework this after chart format redesign.
		if (PlayState.instance.currentSong != null) {
			if (event.beat == 4 && PlayState.instance.currentSong.id == "spookeez")
			{
				doLightningStrike(false, event.beat);
			}
		}

		// Play lightning at random intervals.
		if (FlxG.random.bool(10) && event.beat > (lightningStrikeBeat + lightningStrikeOffset))
		{
			doLightningStrike(true, event.beat);
		}
	}

	function onSongRetry(event:ScriptEvent)
	{
		super.onSongRetry(event);

		// Properly reset lightning when restarting the song.
		lightningStrikeBeat = 0;
		lightningStrikeOffset = 8;
	}
}
