package funkin;

import funkin.play.song.Song;
import flash.text.TextField;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.Controls.Control;
import funkin.data.level.LevelRegistry;
import funkin.data.song.SongRegistry;
import funkin.freeplayStuff.BGScrollingText;
import funkin.freeplayStuff.DifficultyStars;
import funkin.freeplayStuff.DJBoyfriend;
import funkin.freeplayStuff.FreeplayScore;
import funkin.freeplayStuff.LetterSort;
import funkin.freeplayStuff.SongMenuItem;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.play.HealthIcon;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.shaderslmfao.AngleMask;
import funkin.shaderslmfao.HSVShader;
import funkin.shaderslmfao.PureColor;
import funkin.shaderslmfao.StrokeShader;
import funkin.ui.StickerSubState;
import lime.app.Future;
import lime.utils.Assets;

class FreeplayState extends MusicBeatSubState
{
  var songs:Array<Null<FreeplaySongData>> = [];

  var diffIdsCurrent:Array<String> = [];
  var diffIdsTotal:Array<String> = [];

  var curSelected:Int = 0;
  var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  var fp:FreeplayScore;
  var txtCompletion:FlxText;
  var lerpCompletion:Float = 0;
  var intendedCompletion:Float = 0;
  var lerpScore:Float = 0;
  var intendedScore:Int = 0;

  var grpDifficulties:FlxTypedSpriteGroup<DifficultySprite>;

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
  var curCapsule:SongMenuItem;
  var curPlaying:Bool = false;

  var dj:DJBoyfriend;

  var typing:FlxInputText;
  var exitMovers:Map<Array<FlxSprite>, MoveData> = new Map();

  var stickerSubState:StickerSubState;

  //
  static var rememberedDifficulty:Null<String> = "normal";
  static var rememberedSongId:Null<String> = null;

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
    }

    #if discord_rpc
    // Updating Discord Rich Presence
    DiscordClient.changePresence("In the Menus", null);
    #end

    var isDebug:Bool = false;

    #if debug
    isDebug = true;
    #end

    if (FlxG.sound.music != null)
    {
      if (!FlxG.sound.music.playing) FlxG.sound.playMusic(Paths.music('freakyMenu/freakyMenu'));
    }

    // Add a null entry that represents the RANDOM option
    songs.push(null);

    // programmatically adds the songs via LevelRegistry and SongRegistry
    for (levelId in LevelRegistry.instance.listBaseGameLevelIds())
    {
      for (songId in LevelRegistry.instance.parseEntryData(levelId).songs)
      {
        var song:Song = SongRegistry.instance.fetchEntry(songId);
        var songBaseDifficulty:SongDifficulty = song.getDifficulty(Constants.DEFAULT_DIFFICULTY);

        var songName = songBaseDifficulty.songName;
        var songOpponent = songBaseDifficulty.characters.opponent;
        var songDifficulties = song.listDifficulties();

        songs.push(new FreeplaySongData(songId, songName, levelId, songOpponent, songDifficulties));

        for (difficulty in songDifficulties)
        {
          diffIdsTotal.pushUnique(difficulty);
        }
      }
    }

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

    var orangeBackShit:FlxSprite = new FlxSprite(84, 440).makeGraphic(Std.int(pinkBack.width), 75, 0xFFfeda00);
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

    FlxG.debugger.addTrackerProfile(new TrackerProfile(BGScrollingText, ["x", "y", "speed", "size"]));

    var moreWays:BGScrollingText = new BGScrollingText(0, 160, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width, true, 43);
    moreWays.funnyColor = 0xFFfff383;
    moreWays.speed = 6.8;
    grpTxtScrolls.add(moreWays);

    exitMovers.set([moreWays],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll:BGScrollingText = new BGScrollingText(0, 220, "BOYFRIEND", FlxG.width / 2, false, 60);
    funnyScroll.funnyColor = 0xFFff9963;
    funnyScroll.speed = -3.8;
    grpTxtScrolls.add(funnyScroll);

    exitMovers.set([funnyScroll],
      {
        x: -funnyScroll.width * 2,
        y: funnyScroll.y,
        speed: 0.4,
        wait: 0
      });

    var txtNuts:BGScrollingText = new BGScrollingText(0, 285, "PROTECT YO NUTS", FlxG.width / 2, true, 43);
    txtNuts.speed = 3.5;
    grpTxtScrolls.add(txtNuts);
    exitMovers.set([txtNuts],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll2:BGScrollingText = new BGScrollingText(0, 335, "BOYFRIEND", FlxG.width / 2, false, 60);
    funnyScroll2.funnyColor = 0xFFff9963;
    funnyScroll2.speed = -3.8;
    grpTxtScrolls.add(funnyScroll2);

    exitMovers.set([funnyScroll2],
      {
        x: -funnyScroll2.width * 2,
        speed: 0.5,
      });

    var moreWays2:BGScrollingText = new BGScrollingText(0, 397, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width, true, 43);
    moreWays2.funnyColor = 0xFFfff383;
    moreWays2.speed = 6.8;
    grpTxtScrolls.add(moreWays2);

    exitMovers.set([moreWays2],
      {
        x: FlxG.width * 2,
        speed: 0.4
      });

    var funnyScroll3:BGScrollingText = new BGScrollingText(0, orangeBackShit.y + 10, "BOYFRIEND", FlxG.width / 2, 60);
    funnyScroll3.funnyColor = 0xFFfea400;
    funnyScroll3.speed = -3.8;
    grpTxtScrolls.add(funnyScroll3);

    exitMovers.set([funnyScroll3],
      {
        x: -funnyScroll3.width * 2,
        speed: 0.3
      });

    dj = new DJBoyfriend(640, 366);
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

    grpDifficulties = new FlxTypedSpriteGroup<DifficultySprite>(-300, 80);
    add(grpDifficulties);

    exitMovers.set([grpDifficulties],
      {
        x: -300,
        speed: 0.25,
        wait: 0
      });

    for (diffId in diffIdsTotal)
    {
      var diffSprite:DifficultySprite = new DifficultySprite(diffId);
      diffSprite.difficultyId = diffId;
      grpDifficulties.add(diffSprite);
    }

    grpDifficulties.group.forEach(function(spr) {
      spr.visible = false;
    });

    for (diffSprite in grpDifficulties.group.members)
    {
      if (diffSprite == null) continue;
      if (diffSprite.difficultyId == currentDifficulty) diffSprite.visible = true;
    }

    var albumArt:FlxAtlasSprite = new FlxAtlasSprite(640, 360, Paths.animateAtlas("freeplay/albumRoll"));
    albumArt.visible = false;
    add(albumArt);

    exitMovers.set([albumArt],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });

    var albumTitle:FlxSprite = new FlxSprite(947, 491).loadGraphic(Paths.image('freeplay/albumTitle-fnfvol1'));
    var albumArtist:FlxSprite = new FlxSprite(1010, 607).loadGraphic(Paths.image('freeplay/albumArtist-kawaisprite'));
    var difficultyStars:DifficultyStars = new DifficultyStars(140, 39);

    difficultyStars.stars.visible = false;
    albumTitle.visible = false;
    albumArtist.visible = false;

    exitMovers.set([albumTitle],
      {
        x: FlxG.width,
        speed: 0.2,
        wait: 0.1
      });

    exitMovers.set([albumArtist],
      {
        x: FlxG.width * 1.1,
        speed: 0.2,
        wait: 0.2
      });
    exitMovers.set([difficultyStars],
      {
        x: FlxG.width * 1.2,
        speed: 0.2,
        wait: 0.3
      });

    add(albumTitle);
    add(albumArtist);
    add(difficultyStars);

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

    var letterSort:LetterSort = new LetterSort(400, 75);
    add(letterSort);
    letterSort.visible = false;

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
          generateSongList({filterType: REGEXP, filterData: str}, true);
      }
    };

    exitMovers.set([fp, txtCompletion, fnfHighscoreSpr],
      {
        x: FlxG.width,
        speed: 0.3
      });

    dj.onIntroDone.add(function() {
      // when boyfriend hits dat shiii

      albumArt.visible = true;
      albumArt.anim.play("");
      albumArt.anim.onComplete = function() {
        albumArt.anim.pause();
      };

      new FlxTimer().start(1, function(_) {
        albumTitle.visible = true;
      });

      new FlxTimer().start(35 / 24, function(_) {
        albumArtist.visible = true;
        difficultyStars.stars.visible = true;
      });

      FlxTween.tween(grpDifficulties, {x: 90}, 0.6, {ease: FlxEase.quartOut});

      var diffSelLeft = new DifficultySelector(20, grpDifficulties.y - 10, false, controls);
      var diffSelRight = new DifficultySelector(325, grpDifficulties.y - 10, true, controls);

      add(diffSelLeft);
      add(diffSelRight);

      letterSort.visible = true;

      exitMovers.set([diffSelLeft, diffSelRight],
        {
          x: -diffSelLeft.width * 2,
          speed: 0.26
        });

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
          changeSelection();
        });
      });

      pinkBack.color = 0xFFffd863;
      bgDad.visible = true;
      orangeBackShit.visible = true;
      alsoOrangeLOL.visible = true;
      grpTxtScrolls.visible = true;
    });

    generateSongList(null, false);

    var swag:Alphabet = new Alphabet(1, 0, "swag");

    var funnyCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
    funnyCam.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(funnyCam);

    typing = new FlxInputText(100, 100);

    typing.callback = function(txt, action) {
      trace(action);
    };

    forEach(function(bs) {
      bs.cameras = [funnyCam];
    });
  }

  public function generateSongList(?filterStuff:SongFilter, force:Bool = false)
  {
    curSelected = 1;

    for (cap in grpCapsules.members)
      cap.kill();

    var tempSongs:Array<FreeplaySongData> = songs;

    if (filterStuff != null)
    {
      switch (filterStuff.filterType)
      {
        case REGEXP:
          // filterStuff.filterData has a string with the first letter of the sorting range, and the second one
          // this creates a filter to return all the songs that start with a letter between those two
          var filterRegexp = new EReg("^[" + filterStuff.filterData + "].*", "i");
          tempSongs = tempSongs.filter(str -> {
            if (str == null) return true; // Random
            return filterRegexp.match(str.songName);
          });
        case STARTSWITH:
          tempSongs = tempSongs.filter(str -> {
            if (str == null) return true; // Random
            return str.songName.toLowerCase().startsWith(filterStuff.filterData);
          });
        case ALL:
        // no filter!
        case FAVORITE:
          tempSongs = tempSongs.filter(str -> {
            if (str == null) return true; // Random
            return str.isFav;
          });
        default:
          // return all on default
      }
    }

    var hsvShader:HSVShader = new HSVShader();

    var randomCapsule:SongMenuItem = grpCapsules.recycle(SongMenuItem);
    randomCapsule.init(FlxG.width, 0, null);
    randomCapsule.onConfirm = function() {
      capsuleOnConfirmRandom(randomCapsule);
    };
    randomCapsule.y = randomCapsule.intendedY(0) + 10;
    randomCapsule.targetPos.x = randomCapsule.x;
    randomCapsule.alpha = 0.5;
    randomCapsule.songText.visible = false;
    randomCapsule.favIcon.visible = false;
    randomCapsule.initJumpIn(0, force);
    randomCapsule.hsvShader = hsvShader;
    grpCapsules.add(randomCapsule);

    for (i in 0...tempSongs.length)
    {
      if (tempSongs[i] == null) continue;

      var funnyMenu:SongMenuItem = grpCapsules.recycle(SongMenuItem);

      funnyMenu.init(FlxG.width, 0, tempSongs[i]);
      funnyMenu.onConfirm = function() {
        capsuleOnConfirmDefault(funnyMenu);
      };
      funnyMenu.y = funnyMenu.intendedY(i + 1) + 10;
      funnyMenu.targetPos.x = funnyMenu.x;
      funnyMenu.ID = i;
      funnyMenu.capsule.alpha = 0.5;
      funnyMenu.songText.visible = false;
      funnyMenu.favIcon.visible = tempSongs[i].isFav;
      funnyMenu.hsvShader = hsvShader;

      if (i < 8) funnyMenu.initJumpIn(Math.min(i, 4), force);
      else
        funnyMenu.forcePosition();

      grpCapsules.add(funnyMenu);
    }

    FlxG.console.registerFunction("changeSelection", changeSelection);

    rememberSelection();

    changeSelection();
    changeDiff();
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

  var busy:Bool = false; // Set to true once the user has pressed enter to select a song.

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.F)
    {
      if (songs[curSelected] != null)
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

    handleInputs(elapsed);
  }

  function handleInputs(elapsed:Float):Void
  {
    if (busy) return;

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
        }
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
      });
    }

    if (accepted)
    {
      grpCapsules.members[curSelected].onConfirm();
    }
  }

  @:haxe.warning("-WDeprecated")
  override function switchTo(nextState:FlxState):Bool
  {
    var daSong = songs[curSelected];
    if (daSong != null)
    {
      clearDaCache(daSong.songName);
    }
    return super.switchTo(nextState);
  }

  function changeDiff(change:Int = 0)
  {
    touchTimer = 0;

    var currentDifficultyIndex = diffIdsCurrent.indexOf(currentDifficulty);

    if (currentDifficultyIndex == -1) currentDifficultyIndex = diffIdsCurrent.indexOf(Constants.DEFAULT_DIFFICULTY);

    currentDifficultyIndex += change;

    if (currentDifficultyIndex < 0) currentDifficultyIndex = diffIdsCurrent.length - 1;
    if (currentDifficultyIndex >= diffIdsCurrent.length) currentDifficultyIndex = 0;

    currentDifficulty = diffIdsCurrent[currentDifficultyIndex];

    var daSong = songs[curSelected];
    if (daSong != null)
    {
      var songScore:SaveScoreData = Save.get().getSongScore(songs[curSelected].songId, currentDifficulty);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore?.accuracy ?? 0.0;
      rememberedDifficulty = currentDifficulty;
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
    }

    grpDifficulties.group.forEach(function(diffSprite) {
      diffSprite.visible = false;
    });

    for (diffSprite in grpDifficulties.group.members)
    {
      if (diffSprite == null) continue;
      if (diffSprite.difficultyId == currentDifficulty)
      {
        if (change != 0)
        {
          diffSprite.visible = true;
          diffSprite.offset.y += 5;
          diffSprite.alpha = 0.5;
          new FlxTimer().start(1 / 24, function(swag) {
            diffSprite.alpha = 1;
            diffSprite.updateHitbox();
          });
        }
        else
        {
          diffSprite.visible = true;
        }
      }
    }
  }

  // Clears the cache of songs, frees up memory, they' ll have to be loaded in later tho function clearDaCache(actualSongTho:String)
  function clearDaCache(actualSongTho:String)
  {
    for (song in songs)
    {
      if (song == null) continue;
      if (song.songName != actualSongTho)
      {
        trace('trying to remove: ' + song.songName);
        // openfl.Assets.cache.clear(Paths.inst(song.songName));
      }
    }
  }

  function capsuleOnConfirmRandom(randomCapsule:SongMenuItem):Void
  {
    trace("RANDOM SELECTED");

    busy = true;

    var availableSongCapsules:Array<SongMenuItem> = grpCapsules.members.filter(function(cap:SongMenuItem) {
      // Dead capsules are ones which were removed from the list when changing filters.
      return cap.alive && cap.songData != null;
    });

    trace('Available songs: ${availableSongCapsules.map(function(cap) {
      return cap.songData.songName;
    })}');

    var targetSong:SongMenuItem = FlxG.random.getObject(availableSongCapsules);

    // Seeing if I can do an animation...
    curSelected = grpCapsules.members.indexOf(targetSong);
    changeSelection(0); // Trigger an update.

    // Act like we hit Confirm on that song.
    capsuleOnConfirmDefault(targetSong);
  }

  function capsuleOnConfirmDefault(cap:SongMenuItem):Void
  {
    busy = true;

    PlayStatePlaylist.isStoryMode = false;

    var songId:String = cap.songTitle.toLowerCase();
    var targetSong:Song = SongRegistry.instance.fetchEntry(songId);
    var targetDifficulty:String = currentDifficulty;

    // TODO: Implement Pico into the interface properly.
    var targetCharacter:String = 'bf';
    if (FlxG.keys.pressed.P)
    {
      targetCharacter = 'pico';
    }

    PlayStatePlaylist.campaignId = cap.songData.levelId;

    // Visual and audio effects.
    FlxG.sound.play(Paths.sound('confirmMenu'));
    dj.confirm();

    // Load and cache the song's charts.
    // TODO: Do this in the loading state.
    targetSong.cacheCharts(true);

    new FlxTimer().start(1, function(tmr:FlxTimer) {
      Paths.setCurrentLevel(cap.songData.levelId);
      LoadingState.loadAndSwitchState(new PlayState(
        {
          targetSong: targetSong,
          targetDifficulty: targetDifficulty,
          targetCharacter: targetCharacter,
        }), true);
    });
  }

  function rememberSelection():Void
  {
    if (rememberedSongId != null)
    {
      curSelected = songs.findIndex(function(song) {
        if (song == null) return false;
        return song.songId == rememberedSongId;
      });
    }

    if (rememberedDifficulty != null)
    {
      currentDifficulty = rememberedDifficulty;
    }
  }

  function changeSelection(change:Int = 0)
  {
    // NGio.logEvent('Fresh');
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    // FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName));

    var prevSelected = curSelected;

    curSelected += change;

    if (curSelected < 0) curSelected = grpCapsules.countLiving() - 1;
    if (curSelected >= grpCapsules.countLiving()) curSelected = 0;

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

    var daSongCapsule = grpCapsules.members[curSelected];
    if (daSongCapsule.songData != null)
    {
      var songScore:SaveScoreData = Save.get().getSongScore(daSongCapsule.songData.songId, targetDifficulty);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore?.accuracy ?? 0.0;
      diffIdsCurrent = daSong.songDifficulties;
      rememberedSongId = daSong.songId;
      changeDiff();
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      rememberedSongId = null;
      rememberedDifficulty = null;
    }

    for (index => capsule in grpCapsules.members)
    {
      index += 1;

      capsule.selected = index == curSelected + 1;

      capsule.targetPos.y = capsule.intendedY(index - curSelected);
      capsule.targetPos.x = 270 + (60 * (Math.sin(index - curSelected)));

      if (index < curSelected) capsule.targetPos.y -= 100; // another 100 for good measure
    }

    if (grpCapsules.countLiving() > 0)
    {
      if (curSelected == 0)
      {
        FlxG.sound.playMusic(Paths.music('freeplay/freeplayRandom'), 0);
        FlxG.sound.music.fadeIn(2, 0, 0.8);
      }
      else
      {
        // TODO: Stream the instrumental of the selected song?
        if (prevSelected == 0)
        {
          FlxG.sound.playMusic(Paths.music('freakyMenu/freakyMenu'));
          FlxG.sound.music.fadeIn(2, 0, 0.8);
        }
      }
      grpCapsules.members[curSelected].selected = true;
    }
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

    scale.x = scale.y = 0.5;

    new FlxTimer().start(2 / 24, function(tmr) {
      scale.x = scale.y = 1;
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
  var REGEXP;
  var FAVORITE;
  var ALL;
}

class FreeplaySongData
{
  public var isFav:Bool = false;

  public var songId:String = "";
  public var songName:String = "";
  public var levelId:String = "";
  public var songCharacter:String = "";
  public var songDifficulties:Array<String> = [];

  public function new(songId:String, songName:String, levelId:String, songCharacter:String, songDifficulties:Array<String>)
  {
    this.songId = songId;
    this.songName = songName;
    this.levelId = levelId;
    this.songCharacter = songCharacter;
    this.songDifficulties = songDifficulties;
  }
}

typedef MoveData =
{
  var ?x:Float;
  var ?y:Float;
  var ?speed:Float;
  var ?wait:Float;
}

class DifficultySprite extends FlxSprite
{
  public var difficultyId:String;

  public function new(diffId:String)
  {
    super();

    difficultyId = diffId;

    loadGraphic(Paths.image('freeplay/freeplay' + diffId));
  }
}
