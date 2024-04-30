package funkin.play;

import funkin.util.MathUtil;
import funkin.ui.story.StoryMenuState;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import funkin.ui.MusicBeatSubState;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import funkin.ui.freeplay.FreeplayScore;
import flixel.tweens.FlxEase;
import funkin.ui.freeplay.FreeplayState;
import flixel.tweens.FlxTween;
import funkin.audio.FunkinSound;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.graphics.shaders.LeftMaskShader;
import funkin.play.components.TallyCounter;

/**
 * The state for the results screen after a song or week is finished.
 */
class ResultState extends MusicBeatSubState
{
  final params:ResultsStateParams;

  var resultsVariation:ResultVariations;
  var songName:FlxBitmapText;
  var difficulty:FlxSprite;

  var maskShaderSongName:LeftMaskShader = new LeftMaskShader();
  var maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

  public function new(params:ResultsStateParams)
  {
    super();

    this.params = params;
  }

  override function create():Void
  {
    /*
      if (params.scoreData.sick == params.scoreData.totalNotesHit
        && params.scoreData.maxCombo == params.scoreData.totalNotesHit) resultsVariation = PERFECT;
      else if (params.scoreData.missed + params.scoreData.bad + params.scoreData.shit >= params.scoreData.totalNotes * 0.50)
        resultsVariation = SHIT; // if more than half of your song was missed, bad, or shit notes, you get shit ending!
      else
        resultsVariation = NORMAL;
     */
    resultsVariation = NORMAL;

    FunkinSound.playMusic('results$resultsVariation',
      {
        startingVolume: 1.0,
        overrideExisting: true,
        restartTrack: true,
        loop: resultsVariation != SHIT
      });

    // Reset the camera zoom on the results screen.
    FlxG.camera.zoom = 1.0;

    // TEMP-ish, just used to sorta "cache" the 3000x3000 image!
    var cacheBullShit:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/soundSystem"));
    add(cacheBullShit);

    var dumb:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/scorePopin"));
    add(dumb);

    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    add(bg);

    var bgFlash:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFEB69, 0xFFFFE66A], 90);
    bgFlash.scrollFactor.set();
    bgFlash.visible = false;
    add(bgFlash);

    // var bfGfExcellent:FlxAtlasSprite = new FlxAtlasSprite(380, -170, Paths.animateAtlas("resultScreen/resultsBoyfriendExcellent", "shared"));
    // bfGfExcellent.visible = false;
    // add(bfGfExcellent);
    //
    // var bfPerfect:FlxAtlasSprite = new FlxAtlasSprite(370, -180, Paths.animateAtlas("resultScreen/resultsBoyfriendPerfect", "shared"));
    // bfPerfect.visible = false;
    // add(bfPerfect);
    //
    // var bfSHIT:FlxAtlasSprite = new FlxAtlasSprite(0, 20, Paths.animateAtlas("resultScreen/resultsBoyfriendSHIT", "shared"));
    // bfSHIT.visible = false;
    // add(bfSHIT);
    //
    // bfGfExcellent.anim.onComplete = () -> {
    // bfGfExcellent.anim.curFrame = 28;
    // bfGfExcellent.anim.play(); // unpauses this anim, since it's on PlayOnce!
    // };
    //
    // bfPerfect.anim.onComplete = () -> {
    //  bfPerfect.anim.curFrame = 136;
    //  bfPerfect.anim.play(); // unpauses this anim, since it's on PlayOnce!
    // };
    //
    // bfSHIT.anim.onComplete = () -> {
    //  bfSHIT.anim.curFrame = 150;
    //  bfSHIT.anim.play(); // unpauses this anim, since it's on PlayOnce!
    // };

    var gf:FlxSprite = FunkinSprite.createSparrow(625, 325, 'resultScreen/resultGirlfriendGOOD');
    gf.animation.addByPrefix("clap", "Girlfriend Good Anim", 24, false);
    gf.visible = false;
    gf.animation.finishCallback = _ -> {
      gf.animation.play('clap', true, false, 9);
    };
    add(gf);

    var boyfriend:FlxSprite = FunkinSprite.createSparrow(640, -200, 'resultScreen/resultBoyfriendGOOD');
    boyfriend.animation.addByPrefix("fall", "Boyfriend Good Anim0", 24, false);
    boyfriend.visible = false;
    boyfriend.animation.finishCallback = function(_) {
      boyfriend.animation.play('fall', true, false, 14);
    };

    add(boyfriend);

    var soundSystem:FlxSprite = FunkinSprite.createSparrow(-15, -180, 'resultScreen/soundSystem');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(0.4, _ -> {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    add(soundSystem);

    difficulty = new FlxSprite(555);

    var diffSpr:String = switch (PlayState.instance.currentDifficulty)
    {
      case 'easy':
        'difEasy';
      case 'normal':
        'difNormal';
      case 'hard':
        'difHard';
      case 'erect':
        'difErect';
      case 'nightmare':
        'difNightmare';
      case _:
        'difNormal';
    }

    difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
    add(difficulty);

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    songName.text = params.title;
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    add(songName);

    var angleRad = songName.angle * Math.PI / 180;
    speedOfTween.x = -1.0 * Math.cos(angleRad);
    speedOfTween.y = -1.0 * Math.sin(angleRad);

    timerThenSongName();

    songName.shader = maskShaderSongName;
    difficulty.shader = maskShaderDifficulty;

    // maskShaderSongName.swagMaskX = difficulty.x - 15;
    maskShaderDifficulty.swagMaskX = difficulty.x - 15;

    var blackTopBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image("resultScreen/topBarBlack"));
    blackTopBar.y = -blackTopBar.height;
    FlxTween.tween(blackTopBar, {y: 0}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.5});
    add(blackTopBar);

    var resultsAnim:FunkinSprite = FunkinSprite.createSparrow(-200, -10, "resultScreen/results");
    resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
    resultsAnim.animation.play("result");
    add(resultsAnim);

    var ratingsPopin:FunkinSprite = FunkinSprite.createSparrow(-150, 120, "resultScreen/ratingsPopin");
    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.visible = false;
    add(ratingsPopin);

    var scorePopin:FunkinSprite = FunkinSprite.createSparrow(-180, 520, "resultScreen/scorePopin");
    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.visible = false;
    add(scorePopin);

    var highscoreNew:FlxSprite = new FlxSprite(310, 570);
    highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
    highscoreNew.animation.addByPrefix("new", "NEW HIGHSCORE", 24);
    highscoreNew.visible = false;
    highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    add(highscoreNew);

    var hStuf:Int = 50;

    var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
    add(ratingGrp);

    /**
     * NOTE: We display how many notes were HIT, not how many notes there were in total.
     *
     */
    var totalHit:TallyCounter = new TallyCounter(375, hStuf * 3, params.scoreData.tallies.totalNotesHit);
    ratingGrp.add(totalHit);

    var maxCombo:TallyCounter = new TallyCounter(375, hStuf * 4, params.scoreData.tallies.maxCombo);
    ratingGrp.add(maxCombo);

    hStuf += 2;
    var extraYOffset:Float = 5;
    var tallySick:TallyCounter = new TallyCounter(230, (hStuf * 5) + extraYOffset, params.scoreData.tallies.sick, 0xFF89E59E);
    ratingGrp.add(tallySick);

    var tallyGood:TallyCounter = new TallyCounter(210, (hStuf * 6) + extraYOffset, params.scoreData.tallies.good, 0xFF89C9E5);
    ratingGrp.add(tallyGood);

    var tallyBad:TallyCounter = new TallyCounter(190, (hStuf * 7) + extraYOffset, params.scoreData.tallies.bad, 0xFFE6CF8A);
    ratingGrp.add(tallyBad);

    var tallyShit:TallyCounter = new TallyCounter(220, (hStuf * 8) + extraYOffset, params.scoreData.tallies.shit, 0xFFE68C8A);
    ratingGrp.add(tallyShit);

    var tallyMissed:TallyCounter = new TallyCounter(260, (hStuf * 9) + extraYOffset, params.scoreData.tallies.missed, 0xFFC68AE6);
    ratingGrp.add(tallyMissed);

    var score:ResultScore = new ResultScore(35, 305, 10, params.scoreData.score);
    score.visible = false;
    add(score);

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
        scorePopin.animation.finishCallback = anim -> {
          score.visible = true;
          score.animateNumbers();
        };
        scorePopin.visible = true;

        if (params.isNewHighscore)
        {
          highscoreNew.visible = true;
          highscoreNew.animation.play("new");
          FlxTween.tween(highscoreNew, {y: highscoreNew.y + 10}, 0.8, {ease: FlxEase.quartOut});
        }
        else
        {
          highscoreNew.visible = false;
        }
      };

      switch (resultsVariation)
      {
        // case SHIT:
        // bfSHIT.visible = true;
        // bfSHIT.playAnimation("");

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
        // case PERFECT:
        //          bfPerfect.visible = true;
        //          bfPerfect.playAnimation("");

        // bfGfExcellent.visible = true;
        // bfGfExcellent.playAnimation("");
        default:
      }
    });

    super.create();
  }

  function timerThenSongName():Void
  {
    movingSongStuff = false;

    difficulty.x = 555;

    var diffYTween:Float = 122;

    difficulty.y = -difficulty.height;
    FlxTween.tween(difficulty, {y: diffYTween}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});

    songName.y = -songName.height;
    var fuckedupnumber = (10) * (songName.text.length / 15);
    FlxTween.tween(songName, {y: diffYTween - 35 - fuckedupnumber}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
    songName.x = (difficulty.x + difficulty.width) + 20;

    new FlxTimer().start(3, _ -> {
      var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);

      speedOfTween.set(0, 0);
      FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});

      movingSongStuff = true;
    });
  }

  var movingSongStuff:Bool = false;
  var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);

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

  override function update(elapsed:Float):Void
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

    if (controls.PAUSE)
    {
      FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8);
      FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1,
        {
          onComplete: _ -> {
            FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
          }
        });
      if (params.storyMode)
      {
        openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> new StoryMenuState(sticker)));
      }
      else
      {
        openSubState(new funkin.ui.transition.StickerSubState(null, (sticker) -> FreeplayState.build(null, sticker)));
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

typedef ResultsStateParams =
{
  /**
   * True if results are for a level, false if results are for a single song.
   */
  var storyMode:Bool;

  /**
   * Either "Song Name by Artist Name" or "Week Name"
   */
  var title:String;

  /**
   * Whether the displayed score is a new highscore
   */
  var isNewHighscore:Bool;

  /**
   * The score, accuracy, and judgements.
   */
  var scoreData:SaveScoreData;
};
