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
import flixel.text.FlxText;
import flixel.util.FlxColor;
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
@:nullSafety
class ResultState extends MusicBeatSubState
{
  final params:ResultsStateParams;

  final rank:ResultRank;
  final songName:FlxBitmapText;
  final difficulty:FlxSprite;

  final maskShaderSongName:LeftMaskShader = new LeftMaskShader();
  final maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

  final resultsAnim:FunkinSprite;
  final ratingsPopin:FunkinSprite;
  final scorePopin:FunkinSprite;

  final bgFlash:FlxSprite;

  final highscoreNew:FlxSprite;
  final score:ResultScore;

  var bfPerfect:Null<FlxAtlasSprite> = null;
  var bfExcellent:Null<FlxAtlasSprite> = null;
  var bfGood:Null<FlxSprite> = null;
  var gfGood:Null<FlxSprite> = null;
  var bfShit:Null<FlxAtlasSprite> = null;

  public function new(params:ResultsStateParams)
  {
    super();

    this.params = params;

    rank = calculateRank(params);
    // rank = SHIT;

    // We build a lot of this stuff in the constructor, then place it in create().
    // This prevents having to do `null` checks everywhere.

    var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
    songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 62)));
    songName.text = params.title;
    songName.letterSpacing = -15;
    songName.angle = -4.4;
    songName.zIndex = 1000;

    difficulty = new FlxSprite(555);
    difficulty.zIndex = 1000;

    bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFEB69, 0xFFFFE66A], 90);

    resultsAnim = FunkinSprite.createSparrow(-200, -10, "resultScreen/results");

    ratingsPopin = FunkinSprite.createSparrow(-150, 120, "resultScreen/ratingsPopin");

    scorePopin = FunkinSprite.createSparrow(-180, 520, "resultScreen/scorePopin");

    highscoreNew = new FlxSprite(310, 570);

    score = new ResultScore(35, 305, 10, params.scoreData.score);
  }

  override function create():Void
  {
    // Reset the camera zoom on the results screen.
    FlxG.camera.zoom = 1.0;

    var bg:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
    bg.scrollFactor.set();
    bg.zIndex = 10;
    add(bg);

    bgFlash.scrollFactor.set();
    bgFlash.visible = false;
    bgFlash.zIndex = 20;
    add(bgFlash);

    // The sound system which falls into place behind the score text. Plays every time!
    var soundSystem:FlxSprite = FunkinSprite.createSparrow(-15, -180, 'resultScreen/soundSystem');
    soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
    soundSystem.visible = false;
    new FlxTimer().start(0.4, _ -> {
      soundSystem.animation.play("idle");
      soundSystem.visible = true;
    });
    soundSystem.zIndex = 1100;
    add(soundSystem);

    switch (rank)
    {
      case PERFECT | PERFECT_GOLD | PERFECT_PLATINUM:
        bfPerfect = new FlxAtlasSprite(370, -180, Paths.animateAtlas("resultScreen/results-bf/resultsPERFECT", "shared"));
        bfPerfect.visible = false;
        bfPerfect.zIndex = 500;
        add(bfPerfect);

        bfPerfect.anim.onComplete = () -> {
          if (bfPerfect != null)
          {
            bfPerfect.anim.curFrame = 137;
            bfPerfect.anim.play(); // unpauses this anim, since it's on PlayOnce!
          }
        };

      case EXCELLENT:
        bfExcellent = new FlxAtlasSprite(380, -170, Paths.animateAtlas("resultScreen/results-bf/resultsEXCELLENT", "shared"));
        bfExcellent.visible = false;
        bfExcellent.zIndex = 500;
        add(bfExcellent);

        bfExcellent.onAnimationFinish.add((animName) -> {
          if (bfExcellent != null)
          {
            bfExcellent.playAnimation('Loop Start');
          }
        });

      case GOOD | GREAT:
        gfGood = FunkinSprite.createSparrow(625, 325, 'resultScreen/results-bf/resultsGOOD/resultGirlfriendGOOD');
        gfGood.animation.addByPrefix("clap", "Girlfriend Good Anim", 24, false);
        gfGood.visible = false;
        gfGood.zIndex = 500;
        gfGood.animation.finishCallback = _ -> {
          if (gfGood != null)
          {
            gfGood.animation.play('clap', true, false, 9);
          }
        };
        add(gfGood);

        bfGood = FunkinSprite.createSparrow(640, -200, 'resultScreen/results-bf/resultsGOOD/resultBoyfriendGOOD');
        bfGood.animation.addByPrefix("fall", "Boyfriend Good Anim0", 24, false);
        bfGood.visible = false;
        bfGood.zIndex = 501;
        bfGood.animation.finishCallback = function(_) {
          if (bfGood != null)
          {
            bfGood.animation.play('fall', true, false, 14);
          }
        };
        add(bfGood);

      case SHIT:
        bfShit = new FlxAtlasSprite(0, 20, Paths.animateAtlas("resultScreen/results-bf/resultsSHIT", "shared"));
        bfShit.visible = false;
        bfShit.zIndex = 500;
        add(bfShit);
        bfShit.onAnimationFinish.add((animName) -> {
          if (bfShit != null)
          {
            bfShit.playAnimation('Loop Start');
          }
        });
    }

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
    blackTopBar.zIndex = 1010;
    add(blackTopBar);

    resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
    resultsAnim.animation.play("result");
    resultsAnim.zIndex = 1200;
    add(resultsAnim);

    ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
    ratingsPopin.visible = false;
    ratingsPopin.zIndex = 1200;
    add(ratingsPopin);

    scorePopin.animation.addByPrefix("score", "tally score", 24, false);
    scorePopin.visible = false;
    scorePopin.zIndex = 1200;
    add(scorePopin);

    highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
    highscoreNew.animation.addByPrefix("new", "NEW HIGHSCORE", 24);
    highscoreNew.visible = false;
    highscoreNew.setGraphicSize(Std.int(highscoreNew.width * 0.8));
    highscoreNew.updateHitbox();
    highscoreNew.zIndex = 1200;
    add(highscoreNew);

    var hStuf:Int = 50;

    var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
    ratingGrp.zIndex = 1200;
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

    score.visible = false;
    score.zIndex = 1200;
    add(score);

    for (ind => rating in ratingGrp.members)
    {
      rating.visible = false;
      new FlxTimer().start((0.3 * ind) + 0.55, _ -> {
        rating.visible = true;
        FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
      });
    }

    startRankTallySequence();

    refresh();

    super.create();
  }

  var rankTallyTimer:Null<FlxTimer> = null;
  var clearPercentTarget:Int = 100;
  var clearPercentLerp:Int = 0;

  function startRankTallySequence():Void
  {
    clearPercentTarget = Math.floor((params.scoreData.tallies.totalNotesHit) / params.scoreData.tallies.totalNotes * 100);
    // clearPercentTarget = 97;

    var clearPercentText = new FlxText(FlxG.width / 2, FlxG.height / 2, 0, 'CLEAR: ${clearPercentLerp}%');
    clearPercentText.setFormat(Paths.font('vcr.ttf'), 64, FlxColor.BLACK, FlxTextAlign.RIGHT);
    clearPercentText.zIndex = 1000;
    add(clearPercentText);

    rankTallyTimer = new FlxTimer().start(1 / 24, _ -> {
      // Tick up.
      if (clearPercentLerp < clearPercentTarget)
      {
        clearPercentLerp++;

        clearPercentText.text = 'CLEAR: ${clearPercentLerp}%';
        FunkinSound.playOnce(Paths.sound('scrollMenu'));
      }

      // Don't overshoot.
      if (clearPercentLerp > clearPercentTarget)
      {
        clearPercentLerp = clearPercentTarget;
      }

      if (clearPercentLerp == clearPercentTarget)
      {
        if (rankTallyTimer != null)
        {
          rankTallyTimer.destroy();
          rankTallyTimer = null;
        }

        // Play confirm sound.
        FunkinSound.playOnce(Paths.sound('confirmMenu'));

        new FlxTimer().start(1.0, _ -> {
          remove(clearPercentText);

          afterRankTallySequence();
        });
      }
    }, 0); // 0 = Loop until stopped

    if (ratingsPopin == null)
    {
      trace("Could not build ratingsPopin!");
    }
    else
    {
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
    }

    refresh();
  }

  function afterRankTallySequence():Void
  {
    FunkinSound.playMusic(rank.getMusicPath(),
      {
        startingVolume: 1.0,
        overrideExisting: true,
        restartTrack: true,
        loop: rank.shouldMusicLoop()
      });

    FlxG.sound.music.onComplete = () -> {
      if (rank == SHIT)
      {
        FunkinSound.playMusic('bluu',
          {
            startingVolume: 0.0,
            overrideExisting: true,
            restartTrack: true,
            loop: true
          });
        FlxG.sound.music.fadeIn(10.0, 0.0, 1.0);
      }
    }

    switch (rank)
    {
      case PERFECT | PERFECT_GOLD | PERFECT_PLATINUM:
        if (bfPerfect == null)
        {
          trace("Could not build PERFECT animation!");
        }
        else
        {
          bfPerfect.visible = true;
          bfPerfect.playAnimation('');

          new FlxTimer().start((1 / 24) * 12, _ -> {
            bgFlash.visible = true;
            FlxTween.tween(bgFlash, {alpha: 0}, 0.4);
            new FlxTimer().start((1 / 24) * 2, _ ->
              {
                // bgFlash.alpha = 0.5;

                // bgFlash.visible = false;
              });
          });
        }

      case EXCELLENT:
        if (bfExcellent == null)
        {
          trace("Could not build EXCELLENT animation!");
        }
        else
        {
          bfExcellent.visible = true;
          bfExcellent.playAnimation('Intro');

          new FlxTimer().start((1 / 24) * 12, _ -> {
            bgFlash.visible = true;
            FlxTween.tween(bgFlash, {alpha: 0}, 0.4);
            new FlxTimer().start((1 / 24) * 2, _ ->
              {
                // bgFlash.alpha = 0.5;

                // bgFlash.visible = false;
              });
          });
        }

      case SHIT:
        if (bfShit == null)
        {
          trace("Could not build SHIT animation!");
        }
        else
        {
          bfShit.visible = true;
          bfShit.playAnimation('Intro');

          new FlxTimer().start((1 / 24) * 12, _ -> {
            bgFlash.visible = true;
            FlxTween.tween(bgFlash, {alpha: 0}, 0.4);
            new FlxTimer().start((1 / 24) * 2, _ ->
              {
                // bgFlash.alpha = 0.5;

                // bgFlash.visible = false;
              });
          });
        }

      case GREAT | GOOD:
        if (bfGood == null)
        {
          trace("Could not build GOOD animation!");
        }
        else
        {
          bfGood.animation.play('fall');
          bfGood.visible = true;

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
            if (gfGood != null)
            {
              gfGood.animation.play('clap', true);
              gfGood.visible = true;
            }
            else
            {
              trace("Could not build GOOD animation!");
            }
          });
        }
      default:
    }
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

    songName.clipRect = FlxRect.get(Math.max(0, 540 - songName.x), 0, FlxG.width, songName.height);
    // PROBABLY SHOULD FIX MEMORY FREE OR WHATEVER THE PUT() FUNCTION DOES !!!! FEELS LIKE IT STUTTERS!!!

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

  public static function calculateRank(params:ResultsStateParams):ResultRank
  {
    // Perfect (Platinum) is a Sick Full Clear
    var isPerfectPlat = (params.scoreData.tallies.sick + params.scoreData.tallies.good) == params.scoreData.tallies.totalNotes
      && params.scoreData.tallies.sick / params.scoreData.tallies.totalNotes >= Constants.RANK_PERFECT_PLAT_THRESHOLD;
    if (isPerfectPlat) return ResultRank.PERFECT_PLATINUM;

    // Perfect (Gold) is an 85% Sick Full Clear
    var isPerfectGold = (params.scoreData.tallies.sick + params.scoreData.tallies.good) == params.scoreData.tallies.totalNotes
      && params.scoreData.tallies.sick / params.scoreData.tallies.totalNotes >= Constants.RANK_PERFECT_GOLD_THRESHOLD;
    if (isPerfectGold) return ResultRank.PERFECT_GOLD;

    // Else, use the standard grades

    // Clear % (including bad and shit). 1.00 is a full clear but not a full combo
    var clear = (params.scoreData.tallies.totalNotesHit) / params.scoreData.tallies.totalNotes;

    if (clear == Constants.RANK_PERFECT_THRESHOLD)
    {
      return ResultRank.PERFECT;
    }
    else if (clear >= Constants.RANK_EXCELLENT_THRESHOLD)
    {
      return ResultRank.EXCELLENT;
    }
    else if (clear >= Constants.RANK_GREAT_THRESHOLD)
    {
      return ResultRank.GREAT;
    }
    else if (clear >= Constants.RANK_GOOD_THRESHOLD)
    {
      return ResultRank.GOOD;
    }
    else
    {
      return ResultRank.SHIT;
    }
  }
}

enum abstract ResultRank(String)
{
  var PERFECT_PLATINUM;
  var PERFECT_GOLD;
  var PERFECT;
  var EXCELLENT;
  var GREAT;
  var GOOD;
  var SHIT;

  public function getMusicPath():String
  {
    switch (abstract)
    {
      case PERFECT_PLATINUM:
        return 'resultsPERFECT';
      case PERFECT_GOLD:
        return 'resultsPERFECT';
      case PERFECT:
        return 'resultsPERFECT';
      case EXCELLENT:
        return 'resultsNORMAL';
      case GREAT:
        return 'resultsNORMAL';
      case GOOD:
        return 'resultsNORMAL';
      case SHIT:
        return 'resultsSHIT';
    }
  }

  public function shouldMusicLoop():Bool
  {
    switch (abstract)
    {
      case PERFECT_PLATINUM:
        return true;
      case PERFECT_GOLD:
        return true;
      case PERFECT:
        return true;
      case EXCELLENT:
        return true;
      case GREAT:
        return true;
      case GOOD:
        return true;
      case SHIT:
        return false;
      default:
        return false;
    }
  }
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
