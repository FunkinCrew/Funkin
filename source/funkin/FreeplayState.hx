package funkin;

import funkin.ui.StickerSubState;
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.Controls.Control;
import funkin.freeplayStuff.BGScrollingText;
import funkin.freeplayStuff.DJBoyfriend;
import funkin.freeplayStuff.FreeplayScore;
import funkin.freeplayStuff.LetterSort;
import funkin.freeplayStuff.SongMenuItem;
import funkin.play.HealthIcon;
import funkin.play.PlayState;
import funkin.play.song.SongData.SongDataParser;
import funkin.shaderslmfao.AngleMask;
import funkin.shaderslmfao.PureColor;
import funkin.shaderslmfao.StrokeShader;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import lime.app.Future;
import lime.utils.Assets;

class FreeplayState extends MusicBeatSubState
{
  var songs:Array<FreeplaySongData> = [];

  // var selector:FlxText;
  var curSelected:Int = 0;
  var curDifficulty:Int = 1;

  var fp:FreeplayScore;
  var txtCompletion:FlxText;
  var lerpCompletion:Float = 0;
  var intendedCompletion:Float = 0;
  var lerpScore:Float = 0;
  var intendedScore:Int = 0;

  var grpDifficulties:FlxSpriteGroup;

  var coolColors:Array<Int> = [
    0xff9271fd,
    0xff9271fd,
    0xff223344,
    0xFF941653,
    0xFFfc96d7,
    0xFFa0d1ff,
    0xffff78bf,
    0xfff6b604
  ];

  var grpSongs:FlxTypedGroup<Alphabet>;
  var grpCapsules:FlxTypedGroup<SongMenuItem>;
  var curPlaying:Bool = false;

  var dj:DJBoyfriend;

  var typing:FlxInputText;
  var exitMovers:Map<Array<FlxSprite>, MoveData> = new Map();

  var stickerSubState:StickerSubState;

  public function new(?stickers:StickerSubState = null)
  {
    if (stickers != null)
    {
      stickerSubState = stickers;
    }

    super();
  }

  override function create():Void
  {
    super.create();

    FlxTransitionableState.skipNextTransIn = true;

    if (stickerSubState != null)
    {
      this.persistentUpdate = true;
      this.persistentDraw = true;

      openSubState(stickerSubState);
      stickerSubState.degenStickers();

      // resetSubState();
    }

    #if discord_rpc
    // Updating Discord Rich Presence
    DiscordClient.changePresence("In the Menus", null);
    #end

    var isDebug:Bool = false;

    #if debug
    isDebug = true;
    addSong('Test', 'tutorial', 'bf-pixel');
    addSong('Pyro', 'weekend1', 'darnell');
    #end

    var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

    for (i in 0...initSonglist.length)
    {
      songs.push(new FreeplaySongData(initSonglist[i], 'tutorial', 'gf'));
    }

    if (FlxG.sound.music != null)
    {
      if (!FlxG.sound.music.playing) FlxG.sound.playMusic(Paths.music('freakyMenu/freakyMenu'));
    }

    // if (StoryMenuState.weekUnlocked[2] || isDebug)
    addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 'week1', ['dad']);

    // if (StoryMenuState.weekUnlocked[2] || isDebug)
    addWeek(['Spookeez', 'South', 'Monster'], 'week2', ['spooky', 'spooky', 'monster']);

    // if (StoryMenuState.weekUnlocked[3] || isDebug)
    addWeek(['Pico', 'Philly-Nice', 'Blammed'], 'week3', ['pico']);

    // if (StoryMenuState.weekUnlocked[4] || isDebug)
    addWeek(['Satin-Panties', 'High', 'MILF'], 'week4', ['mom']);

    // if (StoryMenuState.weekUnlocked[5] || isDebug)
    addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 'week5', ['parents-christmas', 'parents-christmas', 'monster-christmas']);

    // if (StoryMenuState.weekUnlocked[6] || isDebug)
    addWeek(['Senpai', 'Roses', 'Thorns'], 'week6', ['senpai', 'senpai', 'spirit']);

    // if (StoryMenuState.weekUnlocked[7] || isDebug)
    addWeek(['Ugh', 'Guns', 'Stress'], 'week7', ['tankman']);

    addWeek(["Darnell", "lit-up", "2hot", "blazin"], 'weekend1', ['darnell']);

    // LOAD MUSIC

    // LOAD CHARACTERS

    trace(FlxG.width);
    trace(FlxG.camera.zoom);
    trace(FlxG.camera.initialZoom);
    trace(FlxCamera.defaultZoom);

    var pinkBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/pinkBack'));
    pinkBack.color = 0xFFffd4e9; // sets it to pink!
    pinkBack.x -= pinkBack.width;

    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    var orangeBackShit:FlxSprite = new FlxSprite(84, FlxG.height * 0.68).makeGraphic(Std.int(pinkBack.width), 50, 0xFFffd400);
    add(orangeBackShit);

    var alsoOrangeLOL:FlxSprite = new FlxSprite(0, orangeBackShit.y).makeGraphic(100, Std.int(orangeBackShit.height), 0xFFffd400);
    add(alsoOrangeLOL);

    exitMovers.set([pinkBack, orangeBackShit, alsoOrangeLOL],
      {
        x: -pinkBack.width,
        y: pinkBack.y,
        speed: 0.4,
        wait: 0
      });

    FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
    orangeBackShit.visible = false;
    alsoOrangeLOL.visible = false;

    var grpTxtScrolls:FlxGroup = new FlxGroup();
    add(grpTxtScrolls);
    grpTxtScrolls.visible = false;

    var moreWays:BGScrollingText = new BGScrollingText(0, 200, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
    moreWays.funnyColor = 0xFFfff383;
    moreWays.speed = 4;
    grpTxtScrolls.add(moreWays);

    exitMovers.set([moreWays],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll:BGScrollingText = new BGScrollingText(0, 250, "BOYFRIEND", FlxG.width / 2);
    funnyScroll.funnyColor = 0xFFff9963;
    funnyScroll.speed = -1;
    grpTxtScrolls.add(funnyScroll);

    exitMovers.set([funnyScroll],
      {
        x: -funnyScroll.width * 2,
        y: funnyScroll.y,
        speed: 0.4,
        wait: 0
      });

    var txtNuts:BGScrollingText = new BGScrollingText(0, 300, "PROTECT YO NUTS", FlxG.width / 2);
    grpTxtScrolls.add(txtNuts);
    exitMovers.set([txtNuts],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll2:BGScrollingText = new BGScrollingText(0, 340, "BOYFRIEND", FlxG.width / 2);
    funnyScroll2.funnyColor = 0xFFff9963;
    funnyScroll2.speed = -1.2;
    grpTxtScrolls.add(funnyScroll2);

    exitMovers.set([funnyScroll2],
      {
        x: -funnyScroll2.width * 2,
        speed: 0.5,
      });

    var moreWays2:BGScrollingText = new BGScrollingText(0, 400, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
    moreWays2.funnyColor = 0xFFfff383;
    moreWays2.speed = 4.4;
    grpTxtScrolls.add(moreWays2);

    exitMovers.set([moreWays2],
      {
        x: FlxG.width * 2,
        speed: 0.4
      });

    var funnyScroll3:BGScrollingText = new BGScrollingText(0, orangeBackShit.y, "BOYFRIEND", FlxG.width / 2);
    funnyScroll3.funnyColor = 0xFFff9963;
    funnyScroll3.speed = -0.8;
    grpTxtScrolls.add(funnyScroll3);

    exitMovers.set([funnyScroll3],
      {
        x: -funnyScroll3.width * 2,
        speed: 0.3
      });

    dj = new DJBoyfriend(0, -100);
    exitMovers.set([dj],
      {
        x: -dj.width * 1.6,
        speed: 0.5
      });
    add(dj);

    var bgDad:FlxSprite = new FlxSprite(pinkBack.width * 0.75, 0).loadGraphic(Paths.image('freeplay/freeplayBGdad'));
    bgDad.setGraphicSize(0, FlxG.height);
    bgDad.updateHitbox();
    bgDad.shader = new AngleMask();
    bgDad.visible = false;

    var blackOverlayBullshitLOLXD:FlxSprite = new FlxSprite(FlxG.width).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
    add(blackOverlayBullshitLOLXD); // used to mask the text lol!

    exitMovers.set([blackOverlayBullshitLOLXD, bgDad],
      {
        x: FlxG.width * 1.5,
        y: bgDad.height,
        speed: 0.4,
        wait: 0
      });

    add(bgDad);
    FlxTween.tween(blackOverlayBullshitLOLXD, {x: pinkBack.width * 0.75}, 1, {ease: FlxEase.quintOut});

    blackOverlayBullshitLOLXD.shader = bgDad.shader;

    grpSongs = new FlxTypedGroup<Alphabet>();
    add(grpSongs);

    grpCapsules = new FlxTypedGroup<SongMenuItem>();
    add(grpCapsules);

    grpDifficulties = new FlxSpriteGroup(-300, 80);
    add(grpDifficulties);

    exitMovers.set([grpDifficulties],
      {
        x: -300,
        speed: 0.25,
        wait: 0
      });

    grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayEasy')));
    grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayNorm')));
    grpDifficulties.add(new FlxSprite().loadGraphic(Paths.image('freeplay/freeplayHard')));

    grpDifficulties.group.forEach(function(spr) {
      spr.visible = false;
    });

    grpDifficulties.group.members[curDifficulty].visible = true;

    var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
    overhangStuff.y -= overhangStuff.height;
    add(overhangStuff);
    FlxTween.tween(overhangStuff, {y: 0}, 0.3, {ease: FlxEase.quartOut});

    var fnfFreeplay:FlxText = new FlxText(0, 12, 0, "FREEPLAY", 48);
    fnfFreeplay.font = "VCR OSD Mono";
    fnfFreeplay.visible = false;

    exitMovers.set([overhangStuff, fnfFreeplay],
      {
        y: -overhangStuff.height,
        x: 0,
        speed: 0.2,
        wait: 0
      });

    var sillyStroke = new StrokeShader(0xFFFFFFFF, 2, 2);
    fnfFreeplay.shader = sillyStroke;
    add(fnfFreeplay);

    var fnfHighscoreSpr:FlxSprite = new FlxSprite(890, 70);
    fnfHighscoreSpr.frames = Paths.getSparrowAtlas('freeplay/highscore');
    fnfHighscoreSpr.animation.addByPrefix("highscore", "highscore", 24, false);
    fnfHighscoreSpr.visible = false;
    fnfHighscoreSpr.setGraphicSize(0, Std.int(fnfHighscoreSpr.height * 1));
    fnfHighscoreSpr.updateHitbox();
    add(fnfHighscoreSpr);

    new FlxTimer().start(FlxG.random.float(12, 50), function(tmr) {
      fnfHighscoreSpr.animation.play("highscore");
      tmr.time = FlxG.random.float(20, 60);
    }, 0);

    fp = new FreeplayScore(460, 60, 100);
    fp.visible = false;
    add(fp);

    txtCompletion = new FlxText(1200, 77, 0, "0", 32);
    txtCompletion.font = "VCR OSD Mono";
    txtCompletion.visible = false;
    add(txtCompletion);

    exitMovers.set([fp, txtCompletion, fnfHighscoreSpr],
      {
        x: FlxG.width,
        speed: 0.3
      });

    dj.onIntroDone.add(function() {
      FlxTween.tween(grpDifficulties, {x: 90}, 0.6, {ease: FlxEase.quartOut});

      var diffSelLeft = new DifficultySelector(20, grpDifficulties.y - 10, false, controls);
      var diffSelRight = new DifficultySelector(325, grpDifficulties.y - 10, true, controls);

      add(diffSelLeft);
      add(diffSelRight);

      exitMovers.set([diffSelLeft, diffSelRight],
        {
          x: -diffSelLeft.width * 2,
          speed: 0.26
        });

      var letterSort:LetterSort = new LetterSort(300, 100);
      add(letterSort);

      exitMovers.set([letterSort],
        {
          y: -100,
          speed: 0.3
        });

      letterSort.changeSelectionCallback = (str) -> {
        switch (str)
        {
          case "fav":
            generateSongList({filterType: FAVORITE}, true);
          case "ALL":
            generateSongList(null, true);
          default:
            generateSongList({filterType: STARTSWITH, filterData: str}, true);
        }
      };

      new FlxTimer().start(1 / 24, function(handShit) {
        fnfHighscoreSpr.visible = true;
        fnfFreeplay.visible = true;
        fp.visible = true;
        fp.updateScore(0);

        txtCompletion.visible = true;
        intendedCompletion = 0;

        new FlxTimer().start(1.5 / 24, function(bold) {
          sillyStroke.width = 0;
          sillyStroke.height = 0;
        });
      });

      pinkBack.color = 0xFFffd863;
      // fnfFreeplay.visible = true;
      bgDad.visible = true;
      orangeBackShit.visible = true;
      alsoOrangeLOL.visible = true;
      grpTxtScrolls.visible = true;
    });

    generateSongList();

    // FlxG.sound.playMusic(Paths.music('title'), 0);
    // FlxG.sound.music.fadeIn(2, 0, 0.8);
    // selector = new FlxText();

    // selector.size = 40;
    // selector.text = ">";
    // add(selector);

    var swag:Alphabet = new Alphabet(1, 0, "swag");

    // JUST DOIN THIS SHIT FOR TESTING!!!
    /*
      var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

      var texFel:TextField = new TextField();
      texFel.width = FlxG.width;
      texFel.height = FlxG.height;
      // texFel.
      texFel.htmlText = md;

      FlxG.stage.addChild(texFel);

      trace(md);
     */

    var funnyCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
    funnyCam.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(funnyCam);

    typing = new FlxInputText(100, 100);
    // add(typing);

    typing.callback = function(txt, action) {
      // generateSongList(new EReg(txt.trim(), "ig"));
      trace(action);
    };

    forEach(function(bs) {
      bs.cameras = [funnyCam];
    });
  }

  public function generateSongList(?filterStuff:SongFilter, ?force:Bool = false)
  {
    curSelected = 0;

    grpCapsules.clear();

    // var regexp:EReg = regexp;
    var tempSongs:Array<FreeplaySongData> = songs;

    if (filterStuff != null)
    {
      switch (filterStuff.filterType)
      {
        case STARTSWITH:
          tempSongs = tempSongs.filter(str -> {
            return str.songName.toLowerCase().startsWith(filterStuff.filterData);
          });
        case ALL:
        // no filter!
        case FAVORITE:
          tempSongs = tempSongs.filter(str -> {
            return str.isFav;
          });
        default:
          // return all on default
      }
    }

    // if (regexp != null)
    // 	tempSongs = songs.filter(item -> regexp.match(item.songName));

    // tempSongs.sort(function(a, b):Int
    // {
    // 	var tempA = a.songName.toUpperCase();
    // 	var tempB = b.songName.toUpperCase();

    // 	if (tempA < tempB)
    // 		return -1;
    // 	else if (tempA > tempB)
    // 		return 1;
    // 	else
    // 		return 0;
    // });

    for (i in 0...tempSongs.length)
    {
      var funnyMenu:SongMenuItem = new SongMenuItem(FlxG.width, (i * 150) + 160, tempSongs[i].songName);
      funnyMenu.targetPos.x = funnyMenu.x;
      funnyMenu.ID = i;
      funnyMenu.alpha = 0.5;
      funnyMenu.songText.visible = false;
      funnyMenu.favIcon.visible = tempSongs[i].isFav;

      // fp.updateScore(0);

      var maxTimer:Float = Math.min(i, 4);

      new FlxTimer().start((1 / 24) * maxTimer, function(doShit) {
        funnyMenu.doJumpIn = true;
      });

      new FlxTimer().start((0.09 * maxTimer) + 0.85, function(lerpTmr) {
        funnyMenu.doLerp = true;
      });

      if (!force)
      {
        new FlxTimer().start(((0.20 * maxTimer) / (1 + maxTimer)) + 0.75, function(swagShi) {
          funnyMenu.songText.visible = true;
          funnyMenu.alpha = 1;
        });
      }
      else
      {
        funnyMenu.songText.visible = true;
        funnyMenu.alpha = 1;
      }

      grpCapsules.add(funnyMenu);

      var songText:Alphabet = new Alphabet(0, (70 * i) + 30, tempSongs[i].songName, true, false);
      songText.x += 100;
      songText.isMenuItem = true;
      songText.targetY = i;

      // grpSongs.add(songText);

      // songText.x += 40;
      // DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
      // songText.screenCenter(X);
    }

    changeSelection();
    changeDiff();
  }

  public function addSong(songName:String, levelId:String, songCharacter:String)
  {
    songs.push(new FreeplaySongData(songName, levelId, songCharacter));
  }

  public function addWeek(songs:Array<String>, levelId:String, ?songCharacters:Array<String>)
  {
    if (songCharacters == null) songCharacters = ['bf'];

    var num:Int = 0;
    for (song in songs)
    {
      addSong(song, levelId, songCharacters[num]);

      if (songCharacters.length != 1) num++;
    }
  }

  var touchY:Float = 0;
  var touchX:Float = 0;
  var dxTouch:Float = 0;
  var dyTouch:Float = 0;
  var velTouch:Float = 0;

  var veloctiyLoopShit:Float = 0;
  var touchTimer:Float = 0;

  var initTouchPos:FlxPoint = new FlxPoint();

  var spamTimer:Float = 0;
  var spamming:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.F)
    {
      var realShit = curSelected;
      songs[curSelected].isFav = !songs[curSelected].isFav;
      if (songs[curSelected].isFav)
      {
        FlxTween.tween(grpCapsules.members[realShit], {angle: 360}, 0.4,
          {
            ease: FlxEase.elasticOut,
            onComplete: _ -> {
              grpCapsules.members[realShit].favIcon.visible = true;
              grpCapsules.members[realShit].favIcon.animation.play("fav");
            }
          });
      }
      else
      {
        grpCapsules.members[realShit].favIcon.animation.play('fav', false, true);
        new FlxTimer().start((1 / 24) * 14, _ -> {
          grpCapsules.members[realShit].favIcon.visible = false;
        });
        new FlxTimer().start((1 / 24) * 24, _ -> {
          FlxTween.tween(grpCapsules.members[realShit], {angle: 0}, 0.4, {ease: FlxEase.elasticOut});
        });
      }
    }

    if (FlxG.keys.justPressed.T) typing.hasFocus = true;

    if (FlxG.sound.music != null)
    {
      if (FlxG.sound.music.volume < 0.7)
      {
        FlxG.sound.music.volume += 0.5 * elapsed;
      }
    }

    lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.2);
    lerpCompletion = CoolUtil.coolLerp(lerpCompletion, intendedCompletion, 0.9);

    fp.updateScore(Std.int(lerpScore));

    txtCompletion.text = Math.floor(lerpCompletion * 100) + "%";
    // trace(Highscore.getCompletion(songs[curSelected].songName, curDifficulty));

    // trace(intendedScore);
    // trace(lerpScore);
    // Highscore.getAllScores();

    var upP = controls.UI_UP_P;
    var downP = controls.UI_DOWN_P;
    var accepted = controls.ACCEPT;

    if (FlxG.onMobile)
    {
      for (touch in FlxG.touches.list)
      {
        if (touch.justPressed)
        {
          initTouchPos.set(touch.screenX, touch.screenY);
        }
        if (touch.pressed)
        {
          var dx = initTouchPos.x - touch.screenX;
          var dy = initTouchPos.y - touch.screenY;

          var angle = Math.atan2(dy, dx);
          var length = Math.sqrt(dx * dx + dy * dy);

          FlxG.watch.addQuick("LENGTH", length);
          FlxG.watch.addQuick("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
          // trace("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
        }

        /* switch (inputID)
          {
            case FlxObject.UP:
              return
            case FlxObject.DOWN:
          }
         */
      }

      if (FlxG.touches.getFirst() != null)
      {
        if (touchTimer >= 1.5) accepted = true;

        touchTimer += elapsed;
        var touch:FlxTouch = FlxG.touches.getFirst();

        velTouch = Math.abs((touch.screenY - dyTouch)) / 50;

        dyTouch = touch.screenY - touchY;
        dxTouch = touch.screenX - touchX;

        if (touch.justPressed)
        {
          touchY = touch.screenY;
          dyTouch = 0;
          velTouch = 0;

          touchX = touch.screenX;
          dxTouch = 0;
        }

        if (Math.abs(dxTouch) >= 100)
        {
          touchX = touch.screenX;
          if (dxTouch != 0) dxTouch < 0 ? changeDiff(1) : changeDiff(-1);
        }

        if (Math.abs(dyTouch) >= 100)
        {
          touchY = touch.screenY;

          if (dyTouch != 0) dyTouch < 0 ? changeSelection(1) : changeSelection(-1);
          // changeSelection(1);
        }
      }
      else
      {
        touchTimer = 0;
      }
    }

    #if mobile
    for (touch in FlxG.touches.list)
    {
      if (touch.justPressed)
      {
        // accepted = true;
      }
    }
    #end

    if (controls.UI_UP || controls.UI_DOWN)
    {
      spamTimer += elapsed;

      if (spamming)
      {
        if (spamTimer >= 0.07)
        {
          spamTimer = 0;

          if (controls.UI_UP) changeSelection(-1);
          else
            changeSelection(1);
        }
      }
      else if (spamTimer >= 0.9) spamming = true;
    }
    else
    {
      spamming = false;
      spamTimer = 0;
    }

    if (upP)
    {
      dj.resetAFKTimer();
      changeSelection(-1);
    }
    if (downP)
    {
      dj.resetAFKTimer();
      changeSelection(1);
    }

    if (FlxG.mouse.wheel != 0)
    {
      dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel / 4));
    }

    if (controls.UI_LEFT_P)
    {
      dj.resetAFKTimer();
      changeDiff(-1);
    }
    if (controls.UI_RIGHT_P)
    {
      dj.resetAFKTimer();
      changeDiff(1);
    }

    if (controls.BACK && !typing.hasFocus)
    {
      FlxTween.globalManager.clear();
      FlxTimer.globalManager.clear();
      dj.onIntroDone.removeAll();

      FlxG.sound.play(Paths.sound('cancelMenu'));

      // FlxTween.tween(dj, {x: -dj.width}, 0.2, {ease: FlxEase.quartOut});

      var longestTimer:Float = 0;

      for (grpSpr in exitMovers.keys())
      {
        var moveData:MoveData = exitMovers.get(grpSpr);

        for (spr in grpSpr)
        {
          var funnyMoveShit:MoveData = moveData;

          if (moveData.x == null) funnyMoveShit.x = spr.x;
          if (moveData.y == null) funnyMoveShit.y = spr.y;
          if (moveData.speed == null) funnyMoveShit.speed = 0.2;
          if (moveData.wait == null) funnyMoveShit.wait = 0;

          FlxTween.tween(spr, {x: funnyMoveShit.x, y: funnyMoveShit.y}, funnyMoveShit.speed, {ease: FlxEase.expoIn});

          longestTimer = Math.max(longestTimer, funnyMoveShit.speed + funnyMoveShit.wait);
        }
      }

      for (caps in grpCapsules.members)
      {
        caps.doJumpIn = false;
        caps.doLerp = false;
        caps.doJumpOut = true;
      }

      if (Type.getClass(FlxG.state) == MainMenuState)
      {
        FlxG.state.persistentUpdate = true;
        FlxG.state.persistentDraw = true;
      }

      new FlxTimer().start(longestTimer, (_) -> {
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        if (Type.getClass(FlxG.state) == MainMenuState)
        {
          close();
        }
        else
        {
          FlxG.switchState(new MainMenuState());
        }
        //
        // close();
      });
    }

    if (accepted)
    {
      // if (Assets.exists())

      var poop:String = songs[curSelected].songName.toLowerCase();

      // does not work properly, always just accidentally sets it to normal anyways!
      /* if (!Assets.exists(Paths.json(songs[curSelected].songName + '/' + poop)))
        {
          // defaults to normal if HARD / EASY doesn't exist
          // does not account if NORMAL doesn't exist!
          FlxG.log.warn("CURRENT DIFFICULTY IS NOT CHARTED, DEFAULTING TO NORMAL!");
          poop = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), 1);
          curDifficulty = 1;
      }*/

      PlayStatePlaylist.isStoryMode = false;
      var targetSong:Song = SongDataParser.fetchSong(songs[curSelected].songName.toLowerCase());
      var targetDifficulty:String = switch (curDifficulty)
      {
        case 0:
          'easy';
        case 1:
          'normal';
        case 2:
          'hard';
        default: 'normal';
      };

      // TODO: Implement additional difficulties into the interface properly.
      if (FlxG.keys.pressed.E)
      {
        targetDifficulty = 'erect';
      }

      // TODO: Implement Pico into the interface properly.
      var targetCharacter:String = 'bf';
      if (FlxG.keys.pressed.P)
      {
        targetCharacter = 'pico';
      }

      PlayStatePlaylist.campaignId = songs[curSelected].levelId;

      // Visual and audio effects.
      FlxG.sound.play(Paths.sound('confirmMenu'));
      dj.confirm();

      if (targetSong != null)
      {
        // Load and cache the song's charts.
        // TODO: Do this in the loading state.
        targetSong.cacheCharts(true);
      }

      new FlxTimer().start(1, function(tmr:FlxTimer) {
        LoadingState.loadAndSwitchState(new PlayState(
          {
            targetSong: targetSong,
            targetDifficulty: targetDifficulty,
            targetCharacter: targetCharacter,
          }), true);
      });
    }
  }

  override function switchTo(nextState:FlxState):Bool
  {
    clearDaCache(songs[curSelected].songName);
    return super.switchTo(nextState);
  }

  function changeDiff(change:Int = 0)
  {
    touchTimer = 0;

    curDifficulty += change;

    if (curDifficulty < 0) curDifficulty = 2;
    if (curDifficulty > 2) curDifficulty = 0;

    // intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
    intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
    intendedCompletion = Highscore.getCompletion(songs[curSelected].songName, curDifficulty);

    grpDifficulties.group.forEach(function(spr) {
      spr.visible = false;
    });

    var curShit:FlxSprite = grpDifficulties.group.members[curDifficulty];

    curShit.visible = true;
    curShit.offset.y += 5;
    curShit.alpha = 0.5;
    new FlxTimer().start(1 / 24, function(swag) {
      curShit.alpha = 1;
      curShit.updateHitbox();
    });
  }

  // Clears the cache of songs, frees up memory, they' ll have to be loaded in later tho function clearDaCache(actualSongTho:String)
  function clearDaCache(actualSongTho:String)
  {
    for (song in songs)
    {
      if (song.songName != actualSongTho)
      {
        trace('trying to remove: ' + song.songName);
        // openfl.Assets.cache.clear(Paths.inst(song.songName));
      }
    }
  }

  function changeSelection(change:Int = 0)
  {
    // fp.updateScore(12345);

    NGio.logEvent('Fresh');

    // NGio.logEvent('Fresh');
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

    curSelected += change;

    if (curSelected < 0) curSelected = grpCapsules.members.length - 1;
    if (curSelected >= grpCapsules.members.length) curSelected = 0;

    // selector.y = (70 * curSelected) + 30;

    // intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
    intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
    intendedCompletion = Highscore.getCompletion(songs[curSelected].songName, curDifficulty);
    // lerpScore = 0;

    #if PRELOAD_ALL
    // FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
    #end

    var bullShit:Int = 0;

    for (index => capsule in grpCapsules.members)
    {
      capsule.selected = false;

      capsule.targetPos.y = ((index - curSelected) * 150) + 160;
      capsule.targetPos.x = 270 + (60 * (Math.sin(index - curSelected)));
      // capsule.targetPos.x = 320 + (40 * (index - curSelected));

      if (index < curSelected) capsule.targetPos.y -= 100; // another 100 for good measure
    }

    if (grpCapsules.members.length > 0) grpCapsules.members[curSelected].selected = true;
  }
}

class DifficultySelector extends FlxSprite
{
  var controls:Controls;
  var whiteShader:PureColor;

  public function new(x:Float, y:Float, flipped:Bool, controls:Controls)
  {
    super(x, y);

    this.controls = controls;

    frames = Paths.getSparrowAtlas('freeplay/freeplaySelector');
    animation.addByPrefix('shine', "arrow pointer loop", 24);
    animation.play('shine');

    whiteShader = new PureColor(FlxColor.WHITE);

    shader = whiteShader;

    flipX = flipped;
  }

  override function update(elapsed:Float)
  {
    if (flipX && controls.UI_RIGHT_P) moveShitDown();
    if (!flipX && controls.UI_LEFT_P) moveShitDown();

    super.update(elapsed);
  }

  function moveShitDown()
  {
    offset.y -= 5;

    whiteShader.colorSet = true;

    new FlxTimer().start(2 / 24, function(tmr) {
      whiteShader.colorSet = false;
      updateHitbox();
    });
  }
}

typedef SongFilter =
{
  var filterType:FilterType;
  var ?filterData:Dynamic;
}

enum abstract FilterType(String)
{
  var STARTSWITH;
  var FAVORITE;
  var ALL;
}

class FreeplaySongData
{
  public var songName:String = "";
  public var levelId:String = "";
  public var songCharacter:String = "";
  public var isFav:Bool = false;

  public function new(song:String, levelId:String, songCharacter:String, ?isFav:Bool = false)
  {
    this.songName = song;
    this.levelId = levelId;
    this.songCharacter = songCharacter;
    this.isFav = isFav;
  }
}

typedef MoveData =
{
  var ?x:Float;
  var ?y:Float;
  var ?speed:Float;
  var ?wait:Float;
}
