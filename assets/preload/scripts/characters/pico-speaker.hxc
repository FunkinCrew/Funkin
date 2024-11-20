
import funkin.play.character.SparrowCharacter;
import funkin.play.character.CharacterType;
import funkin.play.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxTypedSpriteGroup;
import flixel.util.FlxSort;
import funkin.Conductor;
import funkin.util.SortUtil;
import Lambda;

class PicoSpeakerCharacter extends SparrowCharacter {
	var shootTimes:Array<Float> = [];
	var shootDirs:Array<Int> = [];

	function new() {
		super('pico-speaker');

    ignoreExclusionPref.push("shoot1");
		ignoreExclusionPref.push("shoot2");
		ignoreExclusionPref.push("shoot3");
		ignoreExclusionPref.push("shoot4");
	}

	override function onCreate(event:ScriptEvent):Void
  {
		super.onCreate(event);

		this.playAnimation('idle', true, true);

		initTimemap();
	}

	override function dance(force:Bool):Void
  {
		super.dance(force);
	}

	function reset():Void
	{
		initTimemap();
	}

	function initTimemap():Void
	{
		trace('Initializing Pico timings...');
		shootTimes = [];
		// The tankmen's timings and directions are determined
		// by the chart, specifically the internal "picospeaker" difficulty.
		var animChart:SongDifficulty = PlayState.instance.currentSong.getDifficulty('picospeaker');
		if (animChart == null)
		{
			trace('Initializing Pico (speaker) failed; no `picospeaker` chart found for this song.');
			return;
		} else {
			trace('Initializing Pico (speaker); found `picospeaker` chart, continuing...');
		}
		var animNotes:Array<SongNoteData> = animChart.notes;

		// turns out sorting functions are completely useless in polymod right now and do nothing
		// i had to sort the whole pico chart by hand im gonna go insane
		animNotes.sort(function(a:SongNoteData, b:SongNoteData):Int
  	{
    	return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
  	});

		for (note in animNotes)
		{
			shootTimes.push(note.time);
			shootDirs.push(note.data);
		}
	}

	override function onUpdate(event:UpdateScriptEvent):Void
	{
		super.onUpdate(event);

    // Each Pico animation is shifted from the array when it's time to play it.
		if (shootTimes.length > 0 && shootTimes[0] <= Conductor.instance.songPosition) {
			var nextTime:Float = shootTimes.shift();
			var nextDir:Int = shootDirs.shift();

			if(nextDir == 3){
				nextDir -= FlxG.random.int(0, 1);
			}else{
				nextDir += FlxG.random.int(0, 1);
			}
			playPicoAnimation(nextDir);
		}
	}

	function playPicoAnimation(direction:Int):Void
  {
		switch (direction) {
			case 0: this.playAnimation('shoot1', true, true);
			case 1: this.playAnimation('shoot2', true, true);
			case 2: this.playAnimation('shoot3', true, true);
			case 3: this.playAnimation('shoot4', true, true);
		}
	}
}
