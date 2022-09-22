package funkin.play;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import funkin.ui.TallyCounter;

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

		// TEMP-ish, just used to sorta "cache" the 3000x3000 image!
		var cacheBullShit = new FlxSprite().loadGraphic(Paths.image("resultScreen/soundSystem"));
		add(cacheBullShit);

		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
		bg.scrollFactor.set();
		add(bg);

		var soundSystem:FlxSprite = new FlxSprite(-15, -180);
		soundSystem.frames = Paths.getSparrowAtlas("resultScreen/soundSystem");
		soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
		soundSystem.visible = false;
		new FlxTimer().start(0.4, _ ->
		{
			soundSystem.animation.play("idle");
			soundSystem.visible = true;
		});
		soundSystem.antialiasing = true;
		add(soundSystem);

		var difficulty:FlxSprite = new FlxSprite(680);

		var diffSpr:String = switch (CoolUtil.difficultyString())
		{
			case "EASY":
				"difEasy";
			case "NORMAL":
				"difNormal";
			case "HARD":
				"difHard";
			case _:
				"difNormal";
		}

		difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
		difficulty.y = -difficulty.height;
		FlxTween.tween(difficulty, {y: 110}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.8});
		difficulty.antialiasing = true;
		add(difficulty);

		var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/topBarBlack"));
		blackTopBar.y = -blackTopBar.height;
		FlxTween.tween(blackTopBar, {y: 0}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.5});
		blackTopBar.antialiasing = true;
		add(blackTopBar);

		var resultsAnim:FlxSprite = new FlxSprite(-200, -10);
		resultsAnim.frames = Paths.getSparrowAtlas("resultScreen/results");
		resultsAnim.animation.addByPrefix("result", "results", 24, false);
		resultsAnim.animation.play("result");
		resultsAnim.antialiasing = true;
		add(resultsAnim);

		var ratingsPopin:FlxSprite = new FlxSprite(-150, 120);
		ratingsPopin.frames = Paths.getSparrowAtlas("resultScreen/ratingsPopin");
		ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
		// ratingsPopin.animation.play("idle");
		ratingsPopin.visible = false;
		ratingsPopin.antialiasing = true;
		add(ratingsPopin);

		var hStuf:Int = 50;

		var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, Highscore.tallies.totalNotes);
		add(totalHit);

		var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, Highscore.tallies.maxCombo);
		add(maxCombo);

		var tallySick:TallyCounter = new TallyCounter(230, hStuf * 5, Highscore.tallies.sick, 0xFF89E59E);
		add(tallySick);

		var tallyGood:TallyCounter = new TallyCounter(230, hStuf * 6, Highscore.tallies.good, 0xFF89C9E5);
		add(tallyGood);

		var tallyBad:TallyCounter = new TallyCounter(230, hStuf * 7, Highscore.tallies.bad, 0xffE6CF8A);
		add(tallyBad);

		var tallyShit:TallyCounter = new TallyCounter(230, hStuf * 8, Highscore.tallies.shit, 0xFFE68C8A);
		add(tallyShit);

		var tallyMissed:TallyCounter = new TallyCounter(230, hStuf * 9, Highscore.tallies.missed, 0xFFC68AE6);
		add(tallyMissed);

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
