package funkin.play;

import funkin.ui.story.StoryMenuState;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import funkin.shaderslmfao.LeftMaskShader;
import funkin.ui.TallyCounter;
import flxanimate.FlxAnimate.Settings;

class ResultState extends MusicBeatSubState
{
  var resultsVariation:ResultVariations;
  var songName:FlxBitmapText;
  var difficulty:FlxSprite;

  var maskShaderSongName = new LeftMaskShader();
  var maskShaderDifficulty = new LeftMaskShader();

  override function create():Void
  {
    if (Highscore.tallies.sick == Highscore.tallies.totalNotesHit
      && Highscore.tallies.maxCombo == Highscore.tallies.totalNotesHit) resultsVariation = PERFECT;
    else if (Highscore.tallies.missed
      + Highscore.tallies.bad
      + Highscore.tallies.shit >= Highscore.tallies.totalNotes * 0.50)
      resultsVariation = SHIT; // if more than half of your song was missed, bad, or shit notes, you get shit ending!
    else
      resultsVariation = NORMAL;

    var loops = resultsVariation != SHIT;

    FlxG.sound.playMusic(Paths.music("results" + resultsVariation), 1, loops);

    // TEMP-ish, just used to sorta "cache" the 3000x3000 image!
    var cacheBullShit = new FlxSprite().loadGraphic(Paths.image("resultScreen/soundSystem"));
    add(cacheBullShit);

    var dumb = new FlxSprite().loadGraphic(Paths.image("resultScreen/scorePopin"));
    add(dumb);

    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    add(bg);

    var bgFlash:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFffeb69, 0xFFffe66a], 90);
    bgFlash.scrollFactor.set();
    bgFlash.visible = false;
    add(bgFlash);

    var bfGfExcellent:FlxAtlasSprite = new FlxAtlasSprite(380, -170, Paths.animateAtlas("resultScreen/resultsBoyfriendExcellent", "shared"));
    bfGfExcellent.visible = false;
    add(bfGfExcellent);

    var bfPerfect:FlxAtlasSprite = new FlxAtlasSprite(370, -180, Paths.animateAtlas("resultScreen/resultsBoyfriendPerfect", "shared"));
    bfPerfect.visible = false;
    add(bfPerfect);

    var bfSHIT:FlxAtlasSprite = new FlxAtlasSprite(0, 20, Paths.animateAtlas("resultScreen/resultsBoyfriendSHIT", "shared"));
    bfSHIT.visible = false;
    add(bfSHIT);

    bfGfExcellent.anim.onComplete = () -> {
      bfGfExcellent.anim.curFrame = 28;
      bfGfExcellent.anim.play(); // unpauses this anim, since it's on PlayOnce!
    };

    bfPerfect.anim.onComplete = () -> {
      bfPerfect.anim.curFrame = 136;
      bfPerfect.anim.play(); // unpauses this anim, since it's on PlayOnce!
    };

    bfSHIT.anim.onComplete = () -> {
      bfSHIT.anim.curFrame = 150;
      bfSHIT.anim.play(); // unpauses this anim, since it's on PlayOnce!
    };

    var gf:FlxSprite = new FlxSprite(500, 300);
    gf.frames = Paths.getSparrowAtlas('resultScreen/resultGirlfriendGOOD');
    gf.animation.addByPrefix("clap", "Girlfriend Good Anim", 24, false);
    gf.visible = false;
    gf.animation.finishCallback = _ -> {
      gf.animation.play('clap', true, false, 9);
    };
    add(gf);

    var boyfriend:FlxSprite = new FlxSprite(640, -200);
    boyfriend.frames = Paths.getSparrowAtlas('resultScreen/resultBoyfriendGOOD');
    boyfriend.animation.addByPrefix("fall", "Boyfriend Good", 24, false);
    boyfriend.visible = false;
    boyfriend.animation.finishCallback = function(_) {
      boyfriend.animation.play('fall', true, false, 14);
    };

    add(boyfriend);

    var soundSystem:FlxSprite = new FlxSprite(-15, -180);
    soundSystem.frames = Paths.getSparrowAtlas("resultScreen/soundSystem");
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(0.4, _ -> {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    soundSystem.antialiasing = true;
    add(soundSystem);

    difficulty = new FlxSprite(555);

    var diffSpr:String = switch (PlayState.instance.currentDifficulty)
    {
      case 'EASY':
        'difEasy';
      case 'NORMAL':
        'difNormal';
      case 'HARD':
        'difHard';
      case _:
        'difNormal';
    }

    difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
    difficulty.antialiasing = true;
    add(difficulty);

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));

    // stole this from PauseSubState, I think eric wrote it!!
    if (PlayState.instance.currentChart != null)
    {
      songName.text += '${PlayState.instance.currentChart.songName}:${PlayState.instance.currentChart.songArtist}';
    }
    else
    {
      songName.text += PlayState.instance.currentSong.songId;
    }

    songName.antialiasing = true;
    songName.letterSpacing = -15;
    songName.angle = -4.1;
    add(songName);

    timerThenSongName();

    songName.shader = maskShaderSongName;
    difficulty.shader = maskShaderDifficulty;

    // maskShaderSongName.swagMaskX = difficulty.x - 15;
    maskShaderDifficulty.swagMaskX = difficulty.x - 15;

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

    var highscoreNew:FlxSprite = new FlxSprite(280, 580);
    highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
    highscoreNew.animation.addByPrefix("new", "NEW HIGHSCORE", 24);
    highscoreNew.visible = false;
    highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    add(highscoreNew);

    var hStuf:Int = 50;

    var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
    add(ratingGrp);

    var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, Highscore.tallies.totalNotesHit);
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
      new FlxTimer().start((0.3 * ind) + 0.55, _ -> {
        rating.visible = true;
        FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
      });
    }

    new FlxTimer().start(0.5, _ -> {
      ratingsPopin.animation.play("idle");
      ratingsPopin.visible = true;

      ratingsPopin.animation.finishCallback = anim -> {
        scorePopin.animation.play("score");
        scorePopin.visible = true;

        highscoreNew.visible = true;
        highscoreNew.animation.play("new");
        FlxTween.tween(highscoreNew, {y: highscoreNew.y + 10}, 0.8, {ease: FlxEase.quartOut});
      };

      switch (resultsVariation)
      {
        case SHIT:
          bfSHIT.visible = true;
          bfSHIT.playAnimation("");

        case NORMAL:
          boyfriend.animation.play('fall');
          boyfriend.visible = true;

          new FlxTimer().start((1 / 24) * 12, _ -> {
            bgFlash.visible = true;
            FlxTween.tween(bgFlash, {alpha: 0}, 0.4);
            new FlxTimer().start((1 / 24) * 2, _ ->
              {
                // bgFlash.alpha = 0.5;

                // bgFlash.visible = false;
              });
          });

          new FlxTimer().start((1 / 24) * 22, _ -> {
            // plays about 22 frames (at 24fps timing) after bf spawns in
            gf.animation.play('clap', true);
            gf.visible = true;
          });
        case PERFECT:
          bfPerfect.visible = true;
          bfPerfect.playAnimation("");

        // bfGfExcellent.visible = true;
        // bfGfExcellent.playAnimation("");
        default:
      }
    });

    if (Highscore.tallies.isNewHighscore) trace("ITS A NEW HIGHSCORE!!!");

    super.create();
  }

  function timerThenSongName()
  {
    movingSongStuff = false;

    difficulty.x = 555;

    var diffYTween = 122;

    difficulty.y = -difficulty.height;
    FlxTween.tween(difficulty, {y: diffYTween}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.8});

    songName.y = diffYTween - 30;
    songName.x = (difficulty.x + difficulty.width) + 20;

    new FlxTimer().start(3, _ -> {
      movingSongStuff = true;
    });
  }

  var movingSongStuff:Bool = false;
  var speedOfTween:FlxPoint = FlxPoint.get(-1, 0.1);

  override function draw():Void
  {
    super.draw();

    if (songName != null)
    {
      songName.clipRect = FlxRect.get(Math.max(0, 540 - songName.x), 0, FlxG.width, songName.height);
      // PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!
    }

    // if (songName != null && songName.frame != null)
    // maskShaderSongName.frameUV = songName.frame.uv;
  }

  override function update(elapsed:Float)
  {
    // maskShaderSongName.swagSprX = songName.x;
    maskShaderDifficulty.swagSprX = difficulty.x;

    if (movingSongStuff)
    {
      songName.x += speedOfTween.x;
      difficulty.x += speedOfTween.x;
      songName.y += speedOfTween.y;
      difficulty.y += speedOfTween.y;

      if (songName.x + songName.width < 100)
      {
        timerThenSongName();
      }
    }

    if (FlxG.keys.justPressed.RIGHT) speedOfTween.x += 0.1;

    if (FlxG.keys.justPressed.LEFT)
    {
      speedOfTween.x -= 0.1;
    }

    if (FlxG.keys.justPressed.UP) speedOfTween.y -= 0.1;

    if (FlxG.keys.justPressed.DOWN) speedOfTween.y += 0.1;

    if (FlxG.keys.justPressed.PERIOD) songName.angle += 0.1;

    if (FlxG.keys.justPressed.COMMA) songName.angle -= 0.1;

    if (controls.PAUSE)
    {
      if (PlayStatePlaylist.isStoryMode)
      {
        FlxG.switchState(new StoryMenuState());
      }
      else
      {
        FlxG.switchState(new FreeplayState());
      }
    }

    super.update(elapsed);
  }
}

enum abstract ResultVariations(String)
{
  var PERFECT;
  var EXCELLENT;
  var NORMAL;
  var SHIT;
}
