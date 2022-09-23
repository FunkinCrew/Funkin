package funkin.play;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
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

		var dumb = new FlxSprite().loadGraphic(Paths.image("resultScreen/scorePopin"));
		add(dumb);

		var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
		bg.scrollFactor.set();
		add(bg);

		var gf:FlxSprite = new FlxSprite(500, 300);
		gf.frames = Paths.getSparrowAtlas('resultScreen/resultGirlfriendGOOD');
		gf.animation.addByPrefix("clap", "Girlfriend Good Anim", 24, false);
		gf.visible = false;
		gf.animation.finishCallback = _ ->
		{
			gf.animation.play('clap', true, false, 9);
		};
		add(gf);

		var boyfriend:FlxSprite = new FlxSprite(640, -200);
		boyfriend.frames = Paths.getSparrowAtlas('resultScreen/resultBoyfriendGOOD');
		boyfriend.animation.addByPrefix("fall", "Boyfriend Good", 24, false);
		boyfriend.visible = false;
		boyfriend.animation.finishCallback = function(_)
		{
			boyfriend.animation.play('fall', true, false, 14);
		};

		add(boyfriend);

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

		var scorePopin:FlxSprite = new FlxSprite(-180, 520);
		scorePopin.frames = Paths.getSparrowAtlas("resultScreen/scorePopin");
		scorePopin.animation.addByPrefix("score", "tally score", 24, false);
		scorePopin.visible = false;
		add(scorePopin);

		var hStuf:Int = 50;

		var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
		add(ratingGrp);

		var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, Highscore.tallies.totalNotes);
		ratingGrp.add(totalHit);

		var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, Highscore.tallies.maxCombo);
		ratingGrp.add(maxCombo);

		hStuf += 2;
		var extraYOffset:Float = 5;
		var tallySick:TallyCounter = new TallyCounter(230, (hStuf * 5) + extraYOffset, Highscore.tallies.sick, 0xFF89E59E);
		ratingGrp.add(tallySick);

		var tallyGood:TallyCounter = new TallyCounter(210, (hStuf * 6) + extraYOffset, Highscore.tallies.good, 0xFF89C9E5);
		ratingGrp.add(tallyGood);

		var tallyBad:TallyCounter = new TallyCounter(190, (hStuf * 7) + extraYOffset, Highscore.tallies.bad, 0xffE6CF8A);
		ratingGrp.add(tallyBad);

		var tallyShit:TallyCounter = new TallyCounter(220, (hStuf * 8) + extraYOffset, Highscore.tallies.shit, 0xFFE68C8A);
		ratingGrp.add(tallyShit);

		var tallyMissed:TallyCounter = new TallyCounter(260, (hStuf * 9) + extraYOffset, Highscore.tallies.missed, 0xFFC68AE6);
		ratingGrp.add(tallyMissed);

		for (ind => rating in ratingGrp.members)
		{
			rating.visible = false;
			new FlxTimer().start((0.3 * ind) + 0.55, _ ->
			{
				rating.visible = true;
				FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
			});
		}

		new FlxTimer().start(0.5, _ ->
		{
			ratingsPopin.animation.play("idle");
			ratingsPopin.visible = true;

			ratingsPopin.animation.finishCallback = anim ->
			{
				scorePopin.animation.play("score");
				scorePopin.visible = true;
			};

			boyfriend.animation.play('fall');
			boyfriend.visible = true;

			new FlxTimer().start((1 / 24) * 22, _ ->
			{
				// plays about 22 frames (at 24fps timing) after bf spawns in
				gf.animation.play('clap', true);
				gf.visible = true;
			});
		});

		if (Highscore.tallies.isNewHighscore)
			trace("ITS A NEW HIGHSCORE!!!");

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
