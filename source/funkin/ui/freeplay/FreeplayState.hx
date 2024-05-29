package funkin.ui.freeplay;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxInputText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.story.level.LevelRegistry;
import funkin.data.song.SongRegistry;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.AngleMask;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.shaders.PureColor;
import funkin.graphics.shaders.StrokeShader;
import funkin.input.Controls;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.ui.story.Level;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.ui.AtlasText;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.LoadingState;
import funkin.ui.transition.StickerSubState;
import funkin.util.MathUtil;
import lime.utils.Assets;

/**
 * Parameters used to initialize the FreeplayState.
 */
typedef FreeplayStateParams =
{
  ?character:String,
};

/**
 * The state for the freeplay menu, allowing the player to select any song to play.
 */
class FreeplayState extends MusicBeatSubState
{
  //
  // Params
  //

  /**
   * The current character for this FreeplayState.
   * You can't change this without transitioning to a new FreeplayState.
   */
  final currentCharacter:String;

  /**
   * For the audio preview, the duration of the fade-in effect.
   */
  public static final FADE_IN_DURATION:Float = 0.5;

  /**
   * For the audio preview, the duration of the fade-out effect.
   */
  public static final FADE_OUT_DURATION:Float = 0.25;

  /**
   * For the audio preview, the volume at which the fade-in starts.
   */
  public static final FADE_IN_START_VOLUME:Float = 0.25;

  /**
   * For the audio preview, the volume at which the fade-in ends.
   */
  public static final FADE_IN_END_VOLUME:Float = 1.0;

  /**
   * For the audio preview, the volume at which the fade-out starts.
   */
  public static final FADE_OUT_END_VOLUME:Float = 0.0;

  var songs:Array<Null<FreeplaySongData>> = [];

  var diffIdsCurrent:Array<String> = [];
  var diffIdsTotal:Array<String> = [];

  var curSelected:Int = 0;
  var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  var fp:FreeplayScore;
  var txtCompletion:AtlasText;
  var lerpCompletion:Float = 0;
  var intendedCompletion:Float = 0;
  var lerpScore:Float = 0;
  var intendedScore:Int = 0;

  var grpDifficulties:FlxTypedSpriteGroup<DifficultySprite>;

  var coolColors:Array<Int> = [
    0xFF9271FD,
    0xFF9271FD,
    0xFF223344,
    0xFF941653,
    0xFFFC96D7,
    0xFFA0D1FF,
    0xFFFF78BF,
    0xFFF6B604
  ];

  var grpSongs:FlxTypedGroup<Alphabet>;
  var grpCapsules:FlxTypedGroup<SongMenuItem>;
  var curCapsule:SongMenuItem;
  var curPlaying:Bool = false;

  var displayedVariations:Array<String>;

  var dj:DJBoyfriend;

  var ostName:FlxText;
  var albumRoll:AlbumRoll;

  var letterSort:LetterSort;
  var exitMovers:ExitMoverData = new Map();

  var stickerSubState:StickerSubState;

  public static var rememberedDifficulty:Null<String> = Constants.DEFAULT_DIFFICULTY;
  public static var rememberedSongId:Null<String> = 'tutorial';

  public function new(?params:FreeplayStateParams, ?stickers:StickerSubState)
  {
    currentCharacter = params?.character ?? Constants.DEFAULT_CHARACTER;

    if (stickers != null)
    {
      stickerSubState = stickers;
    }

    super(FlxColor.TRANSPARENT);
  }

  override function create():Void
  {
    super.create();

    FlxG.state.persistentUpdate = false;

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
    DiscordClient.changePresence('In the Menus', null);
    #end

    var isDebug:Bool = false;

    #if debug
    isDebug = true;
    #end

    FunkinSound.playMusic('freakyMenu',
      {
        overrideExisting: true,
        restartTrack: false
      });

    // Add a null entry that represents the RANDOM option
    songs.push(null);

    // TODO: This makes custom variations disappear from Freeplay. Figure out a better solution later.
    // Default character (BF) shows default and Erect variations. Pico shows only Pico variations.
    displayedVariations = (currentCharacter == 'bf') ? [Constants.DEFAULT_VARIATION, 'erect'] : [currentCharacter];

    // programmatically adds the songs via LevelRegistry and SongRegistry
    for (levelId in LevelRegistry.instance.listSortedLevelIds())
    {
      var level:Level = LevelRegistry.instance.fetchEntry(levelId);

      if (level == null)
      {
        trace('[WARN] Could not find level with id (${levelId})');
        continue;
      }

      for (songId in level.getSongs())
      {
        var song:Song = SongRegistry.instance.fetchEntry(songId);

        if (song == null)
        {
          trace('[WARN] Could not find song with id (${songId})');
          continue;
        }

        // Only display songs which actually have available charts for the current character.
        var availableDifficultiesForSong:Array<String> = song.listDifficulties(displayedVariations, false);
        if (availableDifficultiesForSong.length == 0) continue;

        songs.push(new FreeplaySongData(levelId, songId, song, displayedVariations));
        for (difficulty in availableDifficultiesForSong)
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

    var pinkBack:FunkinSprite = FunkinSprite.create('freeplay/pinkBack');
    pinkBack.color = 0xFFFFD4E9; // sets it to pink!
    pinkBack.x -= pinkBack.width;

    FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
    add(pinkBack);

    var orangeBackShit:FunkinSprite = new FunkinSprite(84, 440).makeSolidColor(Std.int(pinkBack.width), 75, 0xFFFEDA00);
    add(orangeBackShit);

    var alsoOrangeLOL:FunkinSprite = new FunkinSprite(0, orangeBackShit.y).makeSolidColor(100, Std.int(orangeBackShit.height), 0xFFFFD400);
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

    FlxG.debugger.addTrackerProfile(new TrackerProfile(BGScrollingText, ['x', 'y', 'speed', 'size']));

    var moreWays:BGScrollingText = new BGScrollingText(0, 160, 'HOT BLOODED IN MORE WAYS THAN ONE', FlxG.width, true, 43);
    moreWays.funnyColor = 0xFFFFF383;
    moreWays.speed = 6.8;
    grpTxtScrolls.add(moreWays);

    exitMovers.set([moreWays],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll:BGScrollingText = new BGScrollingText(0, 220, 'BOYFRIEND', FlxG.width / 2, false, 60);
    funnyScroll.funnyColor = 0xFFFF9963;
    funnyScroll.speed = -3.8;
    grpTxtScrolls.add(funnyScroll);

    exitMovers.set([funnyScroll],
      {
        x: -funnyScroll.width * 2,
        y: funnyScroll.y,
        speed: 0.4,
        wait: 0
      });

    var txtNuts:BGScrollingText = new BGScrollingText(0, 285, 'PROTECT YO NUTS', FlxG.width / 2, true, 43);
    txtNuts.speed = 3.5;
    grpTxtScrolls.add(txtNuts);
    exitMovers.set([txtNuts],
      {
        x: FlxG.width * 2,
        speed: 0.4,
      });

    var funnyScroll2:BGScrollingText = new BGScrollingText(0, 335, 'BOYFRIEND', FlxG.width / 2, false, 60);
    funnyScroll2.funnyColor = 0xFFFF9963;
    funnyScroll2.speed = -3.8;
    grpTxtScrolls.add(funnyScroll2);

    exitMovers.set([funnyScroll2],
      {
        x: -funnyScroll2.width * 2,
        speed: 0.5,
      });

    var moreWays2:BGScrollingText = new BGScrollingText(0, 397, 'HOT BLOODED IN MORE WAYS THAN ONE', FlxG.width, true, 43);
    moreWays2.funnyColor = 0xFFFFF383;
    moreWays2.speed = 6.8;
    grpTxtScrolls.add(moreWays2);

    exitMovers.set([moreWays2],
      {
        x: FlxG.width * 2,
        speed: 0.4
      });

    var funnyScroll3:BGScrollingText = new BGScrollingText(0, orangeBackShit.y + 10, 'BOYFRIEND', FlxG.width / 2, 60);
    funnyScroll3.funnyColor = 0xFFFEA400;
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

    // TODO: Replace this.
    if (currentCharacter == 'pico') dj.visible = false;

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
        speed: 0.4,
        wait: 0
      });

    add(bgDad);
    FlxTween.tween(blackOverlayBullshitLOLXD, {x: pinkBack.width * 0.75}, 0.7, {ease: FlxEase.quintOut});

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

    albumRoll = new AlbumRoll();
    albumRoll.albumId = null;
    add(albumRoll);

    albumRoll.applyExitMovers(exitMovers);

    var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
    overhangStuff.y -= overhangStuff.height;
    add(overhangStuff);
    FlxTween.tween(overhangStuff, {y: 0}, 0.3, {ease: FlxEase.quartOut});

    var fnfFreeplay:FlxText = new FlxText(8, 8, 0, 'FREEPLAY', 48);
    fnfFreeplay.font = 'VCR OSD Mono';
    fnfFreeplay.visible = false;

    ostName = new FlxText(8, 8, FlxG.width - 8 - 8, 'OFFICIAL OST', 48);
    ostName.font = 'VCR OSD Mono';
    ostName.alignment = RIGHT;
    ostName.visible = false;

    exitMovers.set([overhangStuff, fnfFreeplay, ostName],
      {
        y: -overhangStuff.height,
        x: 0,
        speed: 0.2,
        wait: 0
      });

    var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
    fnfFreeplay.shader = sillyStroke;
    ostName.shader = sillyStroke;
    add(fnfFreeplay);
    add(ostName);

    var fnfHighscoreSpr:FlxSprite = new FlxSprite(860, 70);
    fnfHighscoreSpr.frames = Paths.getSparrowAtlas('freeplay/highscore');
    fnfHighscoreSpr.animation.addByPrefix('highscore', 'highscore small instance 1', 24, false);
    fnfHighscoreSpr.visible = false;
    fnfHighscoreSpr.setGraphicSize(0, Std.int(fnfHighscoreSpr.height * 1));
    fnfHighscoreSpr.updateHitbox();
    add(fnfHighscoreSpr);

    new FlxTimer().start(FlxG.random.float(12, 50), function(tmr) {
      fnfHighscoreSpr.animation.play('highscore');
      tmr.time = FlxG.random.float(20, 60);
    }, 0);

    fp = new FreeplayScore(460, 60, 7, 100);
    fp.visible = false;
    add(fp);

    var clearBoxSprite:FlxSprite = new FlxSprite(1165, 65).loadGraphic(Paths.image('freeplay/clearBox'));
    clearBoxSprite.visible = false;
    add(clearBoxSprite);

    txtCompletion = new AtlasText(1185, 87, '69', AtlasFont.FREEPLAY_CLEAR);
    txtCompletion.visible = false;
    add(txtCompletion);

    letterSort = new LetterSort(400, 75);
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
        case 'fav':
          generateSongList({filterType: FAVORITE}, true);
        case 'ALL':
          generateSongList(null, true);
        default:
          generateSongList({filterType: REGEXP, filterData: str}, true);
      }

      // We want to land on the first song of the group, rather than random song when changing letter sorts
      // that is, only if there's more than one song in the group!
      if (grpCapsules.members.length > 0)
      {
        curSelected = 1;
        changeSelection();
      }
    };

    exitMovers.set([fp, txtCompletion, fnfHighscoreSpr, txtCompletion, clearBoxSprite],
      {
        x: FlxG.width,
        speed: 0.3
      });

    var diffSelLeft:DifficultySelector = new DifficultySelector(20, grpDifficulties.y - 10, false, controls);
    var diffSelRight:DifficultySelector = new DifficultySelector(325, grpDifficulties.y - 10, true, controls);
    diffSelLeft.visible = false;
    diffSelRight.visible = false;
    add(diffSelLeft);
    add(diffSelRight);

    // be careful not to "add()" things in here unless it's to a group that's already added to the state
    // otherwise it won't be properly attatched to funnyCamera (relavent code should be at the bottom of create())
    dj.onIntroDone.add(function() {
      // when boyfriend hits dat shiii

      albumRoll.playIntro();

      new FlxTimer().start(0.75, function(_) {
        // albumRoll.showTitle();
      });

      FlxTween.tween(grpDifficulties, {x: 90}, 0.6, {ease: FlxEase.quartOut});

      diffSelLeft.visible = true;
      diffSelRight.visible = true;
      letterSort.visible = true;

      exitMovers.set([diffSelLeft, diffSelRight],
        {
          x: -diffSelLeft.width * 2,
          speed: 0.26
        });

      new FlxTimer().start(1 / 24, function(handShit) {
        fnfHighscoreSpr.visible = true;
        fnfFreeplay.visible = true;
        ostName.visible = true;
        fp.visible = true;
        fp.updateScore(0);

        clearBoxSprite.visible = true;
        txtCompletion.visible = true;
        intendedCompletion = 0;

        new FlxTimer().start(1.5 / 24, function(bold) {
          sillyStroke.width = 0;
          sillyStroke.height = 0;
          changeSelection();
        });
      });

      pinkBack.color = 0xFFFFD863;
      bgDad.visible = true;
      orangeBackShit.visible = true;
      alsoOrangeLOL.visible = true;
      grpTxtScrolls.visible = true;
    });

    generateSongList(null, false);

    // dedicated camera for the state so we don't need to fuk around with camera scrolls from the mainmenu / elsewhere
    var funnyCam:FunkinCamera = new FunkinCamera('freeplayFunny', 0, 0, FlxG.width, FlxG.height);
    funnyCam.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(funnyCam, false);

    forEach(function(bs) {
      bs.cameras = [funnyCam];
    });
  }

  var currentFilter:SongFilter = null;
  var currentFilteredSongs:Array<FreeplaySongData> = [];

  /**
   * Given the current filter, rebuild the current song list.
   *
   * @param filterStuff A filter to apply to the song list (regex, startswith, all, favorite)
   * @param force Whether the capsules should "jump" back in or not using their animation
   * @param onlyIfChanged Only apply the filter if the song list has changed
   */
  public function generateSongList(filterStuff:Null<SongFilter>, force:Bool = false, onlyIfChanged:Bool = true):Void
  {
    var tempSongs:Array<FreeplaySongData> = songs;

    // Remember just the difficulty because it's important for song sorting.
    if (rememberedDifficulty != null)
    {
      currentDifficulty = rememberedDifficulty;
    }

    if (filterStuff != null) tempSongs = sortSongs(tempSongs, filterStuff);

    // Filter further by current selected difficulty.
    if (currentDifficulty != null)
    {
      tempSongs = tempSongs.filter(song -> {
        if (song == null) return true; // Random
        return song.songDifficulties.contains(currentDifficulty);
      });
    }

    if (onlyIfChanged)
    {
      // == performs equality by reference
      if (tempSongs.isEqualUnordered(currentFilteredSongs)) return;
    }

    // Only now do we know that the filter is actually changing.

    // If curSelected is 0, the result will be null and fall back to the rememberedSongId.
    rememberedSongId = grpCapsules.members[curSelected]?.songData?.songId ?? rememberedSongId;

    for (cap in grpCapsules.members)
    {
      cap.kill();
    }

    currentFilter = filterStuff;

    currentFilteredSongs = tempSongs;
    curSelected = 0;

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

      funnyMenu.forcePosition();

      grpCapsules.add(funnyMenu);
    }

    FlxG.console.registerFunction('changeSelection', changeSelection);

    rememberSelection();

    changeSelection();
    changeDiff(0, true);
  }

  /**
   * Filters an array of songs based on a filter
   * @param songsToFilter What data to use when filtering
   * @param songFilter The filter to apply
   * @return Array<FreeplaySongData>
   */
  public function sortSongs(songsToFilter:Array<FreeplaySongData>, songFilter:SongFilter):Array<FreeplaySongData>
  {
    switch (songFilter.filterType)
    {
      case REGEXP:
        // filterStuff.filterData has a string with the first letter of the sorting range, and the second one
        // this creates a filter to return all the songs that start with a letter between those two

        // if filterData looks like "A-C", the regex should look something like this: ^[A-C].*
        // to get every song that starts between A and C
        var filterRegexp:EReg = new EReg('^[' + songFilter.filterData + '].*', 'i');
        songsToFilter = songsToFilter.filter(str -> {
          if (str == null) return true; // Random
          return filterRegexp.match(str.songName);
        });

      case STARTSWITH:
        // extra note: this is essentially a "search"

        songsToFilter = songsToFilter.filter(str -> {
          if (str == null) return true; // Random
          return str.songName.toLowerCase().startsWith(songFilter.filterData);
        });
      case ALL:
      // no filter!
      case FAVORITE:
        songsToFilter = songsToFilter.filter(str -> {
          if (str == null) return true; // Random
          return str.isFav;
        });
      default:
        // return all on default
    }
    return songsToFilter;
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

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.F)
    {
      var targetSong = grpCapsules.members[curSelected]?.songData;
      if (targetSong != null)
      {
        var realShit:Int = curSelected;
        targetSong.isFav = !targetSong.isFav;
        if (targetSong.isFav)
        {
          FlxTween.tween(grpCapsules.members[realShit], {angle: 360}, 0.4,
            {
              ease: FlxEase.elasticOut,
              onComplete: _ -> {
                grpCapsules.members[realShit].favIcon.visible = true;
                grpCapsules.members[realShit].favIcon.animation.play('fav');
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

    lerpScore = MathUtil.smoothLerp(lerpScore, intendedScore, elapsed, 0.5);
    lerpCompletion = MathUtil.smoothLerp(lerpCompletion, intendedCompletion, elapsed, 0.5);

    if (Math.isNaN(lerpScore))
    {
      lerpScore = intendedScore;
    }

    if (Math.isNaN(lerpCompletion))
    {
      lerpCompletion = intendedCompletion;
    }

    fp.updateScore(Std.int(lerpScore));

    txtCompletion.text = '${Math.floor(lerpCompletion * 100)}';

    // Right align the completion percentage
    switch (txtCompletion.text.length)
    {
      case 3:
        txtCompletion.offset.x = 10;
      case 2:
        txtCompletion.offset.x = 0;
      case 1:
        txtCompletion.offset.x = -24;
      default:
        txtCompletion.offset.x = 0;
    }

    handleInputs(elapsed);
  }

  function handleInputs(elapsed:Float):Void
  {
    if (busy) return;

    var upP:Bool = controls.UI_UP_P && !FlxG.keys.pressed.CONTROL;
    var downP:Bool = controls.UI_DOWN_P && !FlxG.keys.pressed.CONTROL;
    var accepted:Bool = controls.ACCEPT && !FlxG.keys.pressed.CONTROL;

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
          var dx:Float = initTouchPos.x - touch.screenX;
          var dy:Float = initTouchPos.y - touch.screenY;

          var angle:Float = Math.atan2(dy, dx);
          var length:Float = Math.sqrt(dx * dx + dy * dy);

          FlxG.watch.addQuick('LENGTH', length);
          FlxG.watch.addQuick('ANGLE', Math.round(FlxAngle.asDegrees(angle)));
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

    if (!FlxG.keys.pressed.CONTROL && (controls.UI_UP || controls.UI_DOWN))
    {
      if (spamming)
      {
        if (spamTimer >= 0.07)
        {
          spamTimer = 0;

          if (controls.UI_UP)
          {
            changeSelection(-1);
          }
          else
          {
            changeSelection(1);
          }
        }
      }
      else if (spamTimer >= 0.9)
      {
        spamming = true;
      }
      else if (spamTimer <= 0)
      {
        if (controls.UI_UP)
        {
          changeSelection(-1);
        }
        else
        {
          changeSelection(1);
        }
      }

      spamTimer += elapsed;
      dj.resetAFKTimer();
    }
    else
    {
      spamming = false;
      spamTimer = 0;
    }

    #if !html5
    if (FlxG.mouse.wheel != 0)
    {
      dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel));
    }
    #else
    if (FlxG.mouse.wheel < 0)
    {
      dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel / 8));
    }
    else if (FlxG.mouse.wheel > 0)
    {
      dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel / 8));
    }
    #end

    if (controls.UI_LEFT_P && !FlxG.keys.pressed.CONTROL)
    {
      dj.resetAFKTimer();
      changeDiff(-1);
      generateSongList(currentFilter, true);
    }
    if (controls.UI_RIGHT_P && !FlxG.keys.pressed.CONTROL)
    {
      dj.resetAFKTimer();
      changeDiff(1);
      generateSongList(currentFilter, true);
    }

    if (controls.BACK)
    {
      busy = true;
      FlxTween.globalManager.clear();
      FlxTimer.globalManager.clear();
      dj.onIntroDone.removeAll();

      FunkinSound.playOnce(Paths.sound('cancelMenu'));

      var longestTimer:Float = 0;

      for (grpSpr in exitMovers.keys())
      {
        var moveData:MoveData = exitMovers.get(grpSpr);

        for (spr in grpSpr)
        {
          if (spr == null) continue;

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

      if (Type.getClass(_parentState) == MainMenuState)
      {
        _parentState.persistentUpdate = false;
        _parentState.persistentDraw = true;
      }

      new FlxTimer().start(longestTimer, (_) -> {
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        if (Type.getClass(_parentState) == MainMenuState)
        {
          FunkinSound.playMusic('freakyMenu',
            {
              overrideExisting: true,
              restartTrack: false
            });
          close();
        }
        else
        {
          FlxG.switchState(() -> new MainMenuState());
        }
      });
    }

    if (accepted)
    {
      grpCapsules.members[curSelected].onConfirm();
    }
  }

  public override function destroy():Void
  {
    super.destroy();
    var daSong:Null<FreeplaySongData> = currentFilteredSongs[curSelected];
    if (daSong != null)
    {
      clearDaCache(daSong.songName);
    }
  }

  function changeDiff(change:Int = 0, force:Bool = false):Void
  {
    touchTimer = 0;

    var currentDifficultyIndex:Int = diffIdsCurrent.indexOf(currentDifficulty);

    if (currentDifficultyIndex == -1) currentDifficultyIndex = diffIdsCurrent.indexOf(Constants.DEFAULT_DIFFICULTY);

    currentDifficultyIndex += change;

    if (currentDifficultyIndex < 0) currentDifficultyIndex = diffIdsCurrent.length - 1;
    if (currentDifficultyIndex >= diffIdsCurrent.length) currentDifficultyIndex = 0;

    currentDifficulty = diffIdsCurrent[currentDifficultyIndex];

    var daSong:Null<FreeplaySongData> = grpCapsules.members[curSelected].songData;
    if (daSong != null)
    {
      var songScore:SaveScoreData = Save.instance.getSongScore(grpCapsules.members[curSelected].songData.songId, currentDifficulty);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore?.accuracy ?? 0.0;
      rememberedDifficulty = currentDifficulty;
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
    }

    if (intendedCompletion == Math.POSITIVE_INFINITY || intendedCompletion == Math.NEGATIVE_INFINITY || Math.isNaN(intendedCompletion))
    {
      intendedCompletion = 0;
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

    if (change != 0 || force)
    {
      // Update the song capsules to reflect the new difficulty info.
      for (songCapsule in grpCapsules.members)
      {
        if (songCapsule == null) continue;
        if (songCapsule.songData != null)
        {
          songCapsule.songData.currentDifficulty = currentDifficulty;
          songCapsule.init(null, null, songCapsule.songData);
        }
        else
        {
          songCapsule.init(null, null, null);
        }
      }
    }

    // Set the album graphic and play the animation if relevant.
    var newAlbumId:String = daSong?.albumId;
    if (albumRoll.albumId != newAlbumId)
    {
      albumRoll.albumId = newAlbumId;
      albumRoll.skipIntro();
    }
  }

  // Clears the cache of songs, frees up memory, they' ll have to be loaded in later tho function clearDaCache(actualSongTho:String)
  function clearDaCache(actualSongTho:String):Void
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
    trace('RANDOM SELECTED');

    busy = true;
    letterSort.inputEnabled = false;

    var availableSongCapsules:Array<SongMenuItem> = grpCapsules.members.filter(function(cap:SongMenuItem) {
      // Dead capsules are ones which were removed from the list when changing filters.
      return cap.alive && cap.songData != null;
    });

    trace('Available songs: ${availableSongCapsules.map(function(cap) {
      return cap.songData.songName;
    })}');

    if (availableSongCapsules.length == 0)
    {
      trace('No songs available!');
      busy = false;
      letterSort.inputEnabled = true;
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      return;
    }

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
    letterSort.inputEnabled = false;

    PlayStatePlaylist.isStoryMode = false;

    var targetSong:Song = SongRegistry.instance.fetchEntry(cap.songData.songId);
    if (targetSong == null)
    {
      FlxG.log.warn('WARN: could not find song with id (${cap.songData.songId})');
      return;
    }
    var targetDifficulty:String = currentDifficulty;
    var targetVariation:String = targetSong.getFirstValidVariation(targetDifficulty);

    PlayStatePlaylist.campaignId = cap.songData.levelId;

    // Visual and audio effects.
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    dj.confirm();

    new FlxTimer().start(1, function(tmr:FlxTimer) {
      Paths.setCurrentLevel(cap.songData.levelId);
      LoadingState.loadPlayState(
        {
          targetSong: targetSong,
          targetDifficulty: targetDifficulty,
          targetVariation: targetVariation,
          practiceMode: false,
          minimalMode: false,

          #if (debug || FORCE_DEBUG_VERSION)
          botPlayMode: FlxG.keys.pressed.SHIFT,
          #else
          botPlayMode: false,
          #end
          // TODO: Make these an option! It's currently only accessible via chart editor.
          // startTimestamp: 0.0,
          // playbackRate: 0.5,
          // botPlayMode: true,
        }, true);
    });
  }

  function rememberSelection():Void
  {
    if (rememberedSongId != null)
    {
      curSelected = currentFilteredSongs.findIndex(function(song) {
        if (song == null) return false;
        return song.songId == rememberedSongId;
      });

      if (curSelected == -1) curSelected = 0;
    }

    if (rememberedDifficulty != null)
    {
      currentDifficulty = rememberedDifficulty;
    }
  }

  function changeSelection(change:Int = 0):Void
  {
    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    var prevSelected:Int = curSelected;

    curSelected += change;

    if (curSelected < 0) curSelected = grpCapsules.countLiving() - 1;
    if (curSelected >= grpCapsules.countLiving()) curSelected = 0;

    var daSongCapsule:SongMenuItem = grpCapsules.members[curSelected];
    if (daSongCapsule.songData != null)
    {
      var songScore:SaveScoreData = Save.instance.getSongScore(daSongCapsule.songData.songId, currentDifficulty);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore?.accuracy ?? 0.0;
      diffIdsCurrent = daSongCapsule.songData.songDifficulties;
      rememberedSongId = daSongCapsule.songData.songId;
      changeDiff();
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      diffIdsCurrent = diffIdsTotal;
      rememberedSongId = null;
      rememberedDifficulty = null;
      albumRoll.albumId = null;
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
        FunkinSound.playMusic('freeplayRandom',
          {
            startingVolume: 0.0,
            overrideExisting: true,
            restartTrack: true
          });
        FlxG.sound.music.fadeIn(2, 0, 0.8);
      }
      else
      {
        // TODO: Stream the instrumental of the selected song?
        var didReplace:Bool = FunkinSound.playMusic('freakyMenu',
          {
            startingVolume: 0.0,
            overrideExisting: true,
            restartTrack: false
          });
        if (didReplace)
        {
          FunkinSound.playMusic('freakyMenu',
            {
              startingVolume: 0.0,
              overrideExisting: true,
              restartTrack: false
            });
          FlxG.sound.music.fadeIn(2, 0, 0.8);
        }
      }
      grpCapsules.members[curSelected].selected = true;
    }
  }

  /**
   * Build an instance of `FreeplayState` that is above the `MainMenuState`.
   * @return The MainMenuState with the FreeplayState as a substate.
   */
  public static function build(?params:FreeplayStateParams, ?stickers:StickerSubState):MusicBeatState
  {
    var result = new MainMenuState();

    result.openSubState(new FreeplayState(params, stickers));
    result.persistentUpdate = false;
    result.persistentDraw = true;
    return result;
  }
}

/**
 * The difficulty selector arrows to the left and right of the difficulty.
 */
class DifficultySelector extends FlxSprite
{
  var controls:Controls;
  var whiteShader:PureColor;

  public function new(x:Float, y:Float, flipped:Bool, controls:Controls)
  {
    super(x, y);

    this.controls = controls;

    frames = Paths.getSparrowAtlas('freeplay/freeplaySelector');
    animation.addByPrefix('shine', 'arrow pointer loop', 24);
    animation.play('shine');

    whiteShader = new PureColor(FlxColor.WHITE);

    shader = whiteShader;

    flipX = flipped;
  }

  override function update(elapsed:Float):Void
  {
    if (flipX && controls.UI_RIGHT_P && !FlxG.keys.pressed.CONTROL) moveShitDown();
    if (!flipX && controls.UI_LEFT_P && !FlxG.keys.pressed.CONTROL) moveShitDown();

    super.update(elapsed);
  }

  function moveShitDown():Void
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

/**
 * Structure for the current song filter.
 */
typedef SongFilter =
{
  var filterType:FilterType;
  var ?filterData:Dynamic;
}

/**
 * Possible types to use for the song filter.
 */
enum abstract FilterType(String)
{
  /**
   * Filter to songs which start with a string
   */
  public var STARTSWITH;

  /**
   * Filter to songs which match a regular expression
   */
  public var REGEXP;

  /**
   * Filter to songs which are favorited
   */
  public var FAVORITE;

  /**
   * Filter to all songs
   */
  public var ALL;
}

/**
 * Data about a specific song in the freeplay menu.
 */
class FreeplaySongData
{
  /**
   * Whether or not the song has been favorited.
   */
  public var isFav:Bool = false;

  var song:Song;

  public var levelId(default, null):String = '';
  public var songId(default, null):String = '';

  public var songDifficulties(default, null):Array<String> = [];

  public var songName(default, null):String = '';
  public var songCharacter(default, null):String = '';
  public var songRating(default, null):Int = 0;
  public var albumId(default, null):Null<String> = null;

  public var currentDifficulty(default, set):String = Constants.DEFAULT_DIFFICULTY;
  public var displayedVariations(default, null):Array<String> = [Constants.DEFAULT_VARIATION];

  function set_currentDifficulty(value:String):String
  {
    if (currentDifficulty == value) return value;

    currentDifficulty = value;
    updateValues(displayedVariations);
    return value;
  }

  public function new(levelId:String, songId:String, song:Song, ?displayedVariations:Array<String>)
  {
    this.levelId = levelId;
    this.songId = songId;
    this.song = song;
    if (displayedVariations != null) this.displayedVariations = displayedVariations;

    updateValues(displayedVariations);
  }

  function updateValues(variations:Array<String>):Void
  {
    this.songDifficulties = song.listDifficulties(variations, false, false);
    if (!this.songDifficulties.contains(currentDifficulty)) currentDifficulty = Constants.DEFAULT_DIFFICULTY;

    var songDifficulty:SongDifficulty = song.getDifficulty(currentDifficulty, variations);
    if (songDifficulty == null) return;
    this.songName = songDifficulty.songName;
    this.songCharacter = songDifficulty.characters.opponent;
    this.songRating = songDifficulty.difficultyRating;
    if (songDifficulty.album == null)
    {
      FlxG.log.warn('No album for: ${songDifficulty.songName}');
      this.albumId = Constants.DEFAULT_ALBUM_ID;
    }
    else
    {
      this.albumId = songDifficulty.album;
    }
  }
}

/**
 * The map storing information about the exit movers.
 */
typedef ExitMoverData = Map<Array<FlxSprite>, MoveData>;

/**
 * The data for an exit mover.
 */
typedef MoveData =
{
  var ?x:Float;
  var ?y:Float;
  var ?speed:Float;
  var ?wait:Float;
}

/**
 * The sprite for the difficulty
 */
class DifficultySprite extends FlxSprite
{
  /**
   * The difficulty id which this sprite represents.
   */
  public var difficultyId:String;

  public function new(diffId:String)
  {
    super();

    difficultyId = diffId;

    if (Assets.exists(Paths.file('images/freeplay/freeplay${diffId}.xml')))
    {
      this.frames = Paths.getSparrowAtlas('freeplay/freeplay${diffId}');
      this.animation.addByPrefix('idle', 'idle0', 24, true);
      if (Preferences.flashingLights) this.animation.play('idle');
    }
    else
    {
      this.loadGraphic(Paths.image('freeplay/freeplay' + diffId));
    }
  }
}
