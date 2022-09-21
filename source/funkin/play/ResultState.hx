package funkin.play;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;

class ResultState extends MusicBeatSubstate
{
	var resultsVariation:ResultVariations;

	override function create()
	{
		if (Highscore.tallies.sick == Highscore.tallies.totalNotes && Highscore.tallies.maxCombo == Highscore.tallies.totalNotes)
			resultsVariation = PERFECT;
		else if (Highscore.tallies.missed + Highscore.tallies.bad + Highscore.tallies.shit >= Highscore.tallies.totalNotes * 0.50)
			resultsVariation = SHIT; // if more than half of your song was missed, bad, or shit notes, you get shit ending!
		else
			resultsVariation = NORMAL;

		FlxG.sound.playMusic(Paths.music("results" + resultsVariation));

		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
		bg.scrollFactor.set();
		add(bg);

		var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/topBarBlack"));
		blackTopBar.y = -blackTopBar.height;
		FlxTween.tween(blackTopBar, {y: 0}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.5});
		add(blackTopBar);

		var resultsAnim:FlxSprite = new FlxSprite(-200);
		resultsAnim.frames = Paths.getSparrowAtlas("resultScreen/results");
		resultsAnim.animation.addByPrefix("result", "results", 24, false);
		resultsAnim.animation.play("result");
		add(resultsAnim);

		var ratingsPopin:FlxSprite = new FlxSprite(-100, 150);
		ratingsPopin.frames = Paths.getSparrowAtlas("resultScreen/ratingsPopin");
		ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
		// ratingsPopin.animation.play("idle");
		ratingsPopin.visible = false;
		add(ratingsPopin);

		new FlxTimer().start(0.5, _ ->
		{
			ratingsPopin.animation.play("idle");
			ratingsPopin.visible = true;
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.PAUSE)
			FlxG.switchState(new FreeplayState());

		super.update(elapsed);
	}
}

enum abstract ResultVariations(String)
{
	var PERFECT;
	var NORMAL;
	var SHIT;
}
