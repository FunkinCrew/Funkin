package funkin.ui.freeplay;

import funkin.ui.freeplay.backcards.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ShakeTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.effects.IntervalShake;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.AngleMask;
import funkin.graphics.shaders.GaussianBlurShader;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.shaders.PureColor;
import funkin.graphics.shaders.BlueFade;
import funkin.graphics.shaders.StrokeShader;
import openfl.filters.ShaderFilter;
import funkin.input.Controls;
import funkin.play.PlayStatePlaylist;
import funkin.play.scoring.Scoring;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.play.song.Song;
import funkin.save.Save;
import funkin.save.Save.SaveScoreData;
import funkin.ui.AtlasText;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.freeplay.SongMenuItem.FreeplayRank;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.story.Level;
import funkin.ui.transition.LoadingState;
import funkin.ui.transition.StickerSubState;
import funkin.util.MathUtil;
import funkin.util.SortUtil;
import openfl.display.BlendMode;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.song.SongData.SongMusicData;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end

/**
 * The state for the freeplay menu, allowing the player to select any song to play.
 */
@:nullSafety
class FreeplayState extends MusicBeatSubState
{
  //
  // Params
  //

  /**
   * The current character for this FreeplayState.
   * You can't change this without transitioning to a new FreeplayState.
   */
  final currentCharacterId:String;

  final currentCharacter:PlayableCharacter;

  /**
   * For the audio preview, the duration of the fade-in effect.
   */
  public static final FADE_IN_DURATION:Float = 0.5;

  /**
   * For the audio preview, the duration of the fade-out effect.
   *
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

  var curSelected:Int = 0;

  /**
   * Currently selected difficulty, in string form.
   */
  var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   *  Current variation: default, erect, pico, bf, etc.
   */
  var currentVariation:String = Constants.DEFAULT_VARIATION;

  public var fp:FreeplayScore;

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
  var curPlaying:Bool = false;

  var dj:Null<FreeplayDJ> = null;

  var ostName:FlxText;
  var albumRoll:AlbumRoll;

  var charSelectHint:FlxText;

  var letterSort:LetterSort;
  var exitMovers:ExitMoverData = new Map();

  var exitMoversCharSel:ExitMoverData = new Map();

  var stickerSubState:Null<StickerSubState> = null;

  /**
   * The difficulty we were on when this menu was last accessed.
   */
  public static var rememberedDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   * The song we were on when this menu was last accessed.
   * NOTE: `null` if the last song was `Random`.
   */
  public static var rememberedSongId:Null<String> = 'tutorial';

  /**
   * The character we were on when this menu was last accessed.
   */
  public static var rememberedCharacterId:String = Constants.DEFAULT_CHARACTER;

  /**
   * The remembered variation we were on when this menu was last accessed.
   */
  public static var rememberedVariation:String = Constants.DEFAULT_VARIATION;

  var funnyCam:FunkinCamera;
  var rankCamera:FunkinCamera;
  var rankBg:FunkinSprite;
  var rankVignette:FlxSprite;

  var backingCard:Null<BackingCard> = null;

  /**
   * The backing card that has the toned dots, right now we just use that one dad graphic dave cooked up
   */
  public var bgDad:FlxSprite;

  public var angleMaskShader:AngleMask = new AngleMask();

  var fadeShader:BlueFade = new BlueFade();

  var fromResultsParams:Null<FromResultsParams> = null;
  var prepForNewRank:Bool = false;
  var styleData:Null<FreeplayStyle> = null;
  var fromCharSelect:Bool = false;

  public function new(?params:FreeplayStateParams, ?stickers:StickerSubState)
  {
    currentCharacterId = params?.character ?? rememberedCharacterId;
    styleData = FreeplayStyleRegistry.instance.fetchEntry(currentCharacterId);

    var fetchPlayableCharacter = function():PlayableCharacter {
      var targetCharId = params?.character ?? rememberedCharacterId;
      var result = PlayerRegistry.instance.fetchEntry(targetCharId);
      if (result == null) throw 'No valid playable character with id ${targetCharId}';
      return result;
    };

    currentCharacter = fetchPlayableCharacter();
    currentVariation = rememberedVariation;
    styleData = FreeplayStyleRegistry.instance.fetchEntry(currentCharacter.getFreeplayStyleID());
    rememberedCharacterId = currentCharacter?.id ?? Constants.DEFAULT_CHARACTER;
    fromCharSelect = params?.fromCharSelect ?? false;
    fromResultsParams = params?.fromResults;
    prepForNewRank = fromResultsParams?.playRankAnim ?? false;

    super(FlxColor.TRANSPARENT);

    if (stickers?.members != null) stickerSubState = stickers;

    switch (currentCharacterId)
    {
      case(PlayerRegistry.instance.hasNewCharacter()) => true:
        backingCard = new NewCharacterCard(currentCharacter);
      case 'bf':
        backingCard = new BoyfriendCard(currentCharacter);
      case 'pico':
        backingCard = new PicoCard(currentCharacter);
      default:
        backingCard = new BackingCard(currentCharacter);
    }

    // We build a bunch of sprites BEFORE create() so we can guarantee they aren't null later on.
    albumRoll = new AlbumRoll();
    fp = new FreeplayScore(460, 60, 7, 100, styleData);
    rankCamera = new FunkinCamera('rankCamera', 0, 0, FlxG.width, FlxG.height);
    funnyCam = new FunkinCamera('freeplayFunny', 0, 0, FlxG.width, FlxG.height);
    grpCapsules = new FlxTypedGroup<SongMenuItem>();
    grpDifficulties = new FlxTypedSpriteGroup<DifficultySprite>(-300, 80);
    letterSort = new LetterSort(400, 75);
    grpSongs = new FlxTypedGroup<Alphabet>();
    rankBg = new FunkinSprite(0, 0);
    rankVignette = new FlxSprite(0, 0).loadGraphic(Paths.image('freeplay/rankVignette'));
    sparks = new FlxSprite(0, 0);
    sparksADD = new FlxSprite(0, 0);
    txtCompletion = new AtlasText(1185, 87, '69', AtlasFont.FREEPLAY_CLEAR);

    ostName = new FlxText(8, 8, FlxG.width - 8 - 8, 'OFFICIAL OST', 48);
    charSelectHint = new FlxText(-40, 18, FlxG.width - 8 - 8, 'Press [ LOL ] to change characters', 32);

    bgDad = new FlxSprite(backingCard.pinkBack.width * 0.74, 0).loadGraphic(styleData == null ? 'freeplay/freeplayBGdad' : styleData.getBgAssetGraphic());
  }

  override function create():Void
  {
    super.create();

    FlxG.state.persistentUpdate = false;
    FlxTransitionableState.skipNextTransIn = true;

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    funnyCam.filters = [fadeShaderFilter];

    if (stickerSubState != null)
    {
      this.persistentUpdate = true;
      this.persistentDraw = true;

      openSubState(stickerSubState);
      stickerSubState.degenStickers();
    }

    #if FEATURE_DISCORD_RPC
    // Updating Discord Rich Presence
    DiscordClient.instance.setPresence({state: 'In the Menus', details: null});
    #end

    var isDebug:Bool = false;

    #if FEATURE_DEBUG_FUNCTIONS
    isDebug = true;
    #end

    // Block input until the intro finishes.
    busy = true;

    // Add a null entry that represents the RANDOM option
    songs.push(null);

    // programmatically adds the songs via LevelRegistry and SongRegistry
    for (levelId in LevelRegistry.instance.listSortedLevelIds())
    {
      var level:Null<Level> = LevelRegistry.instance.fetchEntry(levelId);

      if (level == null)
      {
        trace('[WARN] Could not find level with id (${levelId})');
        continue;
      }

      for (songId in level.getSongs())
      {
        var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);

        if (song == null)
        {
          trace('[WARN] Could not find song with id (${songId})');
          continue;
        }

        songs.push(new FreeplaySongData(song, level));
      }
    }

    // LOAD MUSIC

    // LOAD CHARACTERS

    trace(FlxG.width);
    trace(FlxG.camera.zoom);
    trace(FlxG.camera.initialZoom);
    trace(FlxCamera.defaultZoom);

    if (backingCard != null)
    {
      add(backingCard);
      backingCard.init();
      backingCard.applyExitMovers(exitMovers, exitMoversCharSel);
      backingCard.instance = this;
    }

    if (currentCharacter?.getFreeplayDJData() != null)
    {
      dj = new FreeplayDJ(640, 366, currentCharacterId);
      exitMovers.set([dj],
        {
          x: -dj.width * 1.6,
          speed: 0.5
        });
      add(dj);
      exitMoversCharSel.set([dj],
        {
          y: -175,
          speed: 0.8,
          wait: 0.1
        });
    }

    bgDad.shader = angleMaskShader;
    bgDad.visible = false;

    var blackOverlayBullshitLOLXD:FlxSprite = new FlxSprite(FlxG.width).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
    add(blackOverlayBullshitLOLXD); // used to mask the text lol!

    // this makes the texture sizes consistent, for the angle shader
    bgDad.setGraphicSize(0, FlxG.height);
    blackOverlayBullshitLOLXD.setGraphicSize(0, FlxG.height);

    bgDad.updateHitbox();
    blackOverlayBullshitLOLXD.updateHitbox();

    exitMovers.set([blackOverlayBullshitLOLXD, bgDad],
      {
        x: FlxG.width * 1.5,
        speed: 0.4,
        wait: 0
      });

    exitMoversCharSel.set([blackOverlayBullshitLOLXD, bgDad],
      {
        y: -100,
        speed: 0.8,
        wait: 0.1
      });

    add(bgDad);
    // backingCard.pinkBack.width * 0.74

    blackOverlayBullshitLOLXD.shader = bgDad.shader;

    rankBg.makeSolidColor(FlxG.width, FlxG.height, 0xD3000000);
    add(rankBg);

    add(grpSongs);

    add(grpCapsules);

    add(grpDifficulties);

    exitMovers.set([grpDifficulties],
      {
        x: -300,
        speed: 0.25,
        wait: 0
      });

    exitMoversCharSel.set([grpDifficulties],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    for (diffId in Constants.DEFAULT_DIFFICULTY_LIST_FULL)
    {
      var diffSprite:DifficultySprite = new DifficultySprite(diffId);
      diffSprite.difficultyId = diffId;
      diffSprite.visible = diffId == Constants.DEFAULT_DIFFICULTY;
      grpDifficulties.add(diffSprite);
    }

    albumRoll.albumId = null;
    add(albumRoll);

    var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 164, FlxColor.BLACK);
    overhangStuff.y -= overhangStuff.height;

    if (fromCharSelect)
    {
      blackOverlayBullshitLOLXD.x = 387.76;
      overhangStuff.y = -100;
      backingCard?.skipIntroTween();
    }
    else
    {
      albumRoll.applyExitMovers(exitMovers, exitMoversCharSel);
      FlxTween.tween(overhangStuff, {y: -100}, 0.3, {ease: FlxEase.quartOut});
      FlxTween.tween(blackOverlayBullshitLOLXD, {x: 387.76}, 0.7, {ease: FlxEase.quintOut});
    }

    var fnfFreeplay:FlxText = new FlxText(8, 8, 0, 'FREEPLAY', 48);
    fnfFreeplay.font = 'VCR OSD Mono';
    fnfFreeplay.visible = false;

    ostName.font = 'VCR OSD Mono';
    ostName.alignment = RIGHT;
    ostName.visible = false;

    charSelectHint.alignment = CENTER;
    charSelectHint.font = "5by7";
    charSelectHint.color = 0xFF5F5F5F;
    charSelectHint.text = 'Press [ ${controls.getDialogueNameFromControl(FREEPLAY_CHAR_SELECT, true)} ] to change characters';
    charSelectHint.y -= 100;
    FlxTween.tween(charSelectHint, {y: charSelectHint.y + 100}, 0.8, {ease: FlxEase.quartOut});

    exitMovers.set([overhangStuff, fnfFreeplay, ostName, charSelectHint],
      {
        y: -overhangStuff.height,
        x: 0,
        speed: 0.2,
        wait: 0
      });

    exitMoversCharSel.set([overhangStuff, fnfFreeplay, ostName, charSelectHint],
      {
        y: -300,
        speed: 0.8,
        wait: 0.1
      });

    var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
    fnfFreeplay.shader = sillyStroke;
    ostName.shader = sillyStroke;

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

    fp.visible = false;
    add(fp);

    var clearBoxSprite:FlxSprite = new FlxSprite(1165, 65).loadGraphic(Paths.image('freeplay/clearBox'));
    clearBoxSprite.visible = false;
    add(clearBoxSprite);

    txtCompletion.visible = false;
    add(txtCompletion);

    add(letterSort);
    letterSort.visible = false;

    exitMovers.set([letterSort],
      {
        y: -100,
        speed: 0.3
      });

    exitMoversCharSel.set([letterSort],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    // Reminder, this is a callback function being set, rather than these being called here in create()
    letterSort.changeSelectionCallback = (str) -> {
      switch (str)
      {
        case 'fav':
          generateSongList({filterType: FAVORITE}, true);
        case 'ALL':
          generateSongList(null, true);
        case '#':
          generateSongList({filterType: REGEXP, filterData: '0-9'}, true);
        default:
          generateSongList({filterType: REGEXP, filterData: str}, true);
      }

      // We want to land on the first song of the group, rather than random song when changing letter sorts
      // that is, only if there's more than one song in the group!
      if (grpCapsules.members.length > 0)
      {
        FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
        curSelected = 1;
        changeSelection();
      }
    };

    exitMovers.set([fp, txtCompletion, fnfHighscoreSpr, clearBoxSprite],
      {
        x: FlxG.width,
        speed: 0.3
      });

    exitMoversCharSel.set([fp, txtCompletion, fnfHighscoreSpr, clearBoxSprite],
      {
        y: -270,
        speed: 0.8,
        wait: 0.1
      });

    var diffSelLeft:DifficultySelector = new DifficultySelector(this, 20, grpDifficulties.y - 10, false, controls, styleData);
    var diffSelRight:DifficultySelector = new DifficultySelector(this, 325, grpDifficulties.y - 10, true, controls, styleData);
    diffSelLeft.visible = false;
    diffSelRight.visible = false;
    add(diffSelLeft);
    add(diffSelRight);

    // putting these here to fix the layering
    add(overhangStuff);
    add(fnfFreeplay);
    add(ostName);

    if (PlayerRegistry.instance.hasNewCharacter())
    {
      add(charSelectHint);
    }

    // be careful not to "add()" things in here unless it's to a group that's already added to the state
    // otherwise it won't be properly attatched to funnyCamera (relavent code should be at the bottom of create())
    var onDJIntroDone = function() {
      busy = false;

      // when boyfriend hits dat shiii

      albumRoll.playIntro();
      var daSong = grpCapsules.members[curSelected].freeplayData;
      albumRoll.albumId = daSong?.data.getAlbumId(currentDifficulty, currentVariation);

      if (!fromCharSelect)
      {
        // render optimisation
        if (_parentState != null) _parentState.persistentDraw = false;

        FlxTween.color(bgDad, 0.6, 0xFF000000, 0xFFFFFFFF,
          {
            ease: FlxEase.expoOut,
            onUpdate: function(_) {
              angleMaskShader.extraColor = bgDad.color;
            }
          });
      }

      FlxTween.tween(grpDifficulties, {x: 90}, 0.6, {ease: FlxEase.quartOut});

      diffSelLeft.visible = true;
      diffSelRight.visible = true;
      letterSort.visible = true;

      exitMovers.set([diffSelLeft, diffSelRight],
        {
          x: -diffSelLeft.width * 2,
          speed: 0.26
        });

      exitMoversCharSel.set([diffSelLeft, diffSelRight],
        {
          y: -270,
          speed: 0.8,
          wait: 0.1
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

      bgDad.visible = true;
      backingCard?.introDone();

      if (prepForNewRank && fromResultsParams != null)
      {
        rankAnimStart(fromResultsParams);
      }
    };

    if (dj != null)
    {
      dj.onIntroDone.add(onDJIntroDone);
    }
    else
    {
      onDJIntroDone();
    }

    // Generates song list with the starter params (who our current character is, last remembered difficulty, etc.)
    generateSongList(null, false);

    // dedicated camera for the state so we don't need to fuk around with camera scrolls from the mainmenu / elsewhere
    funnyCam.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(funnyCam, false);

    rankVignette.scale.set(2, 2);
    rankVignette.updateHitbox();
    rankVignette.blend = BlendMode.ADD;
    // rankVignette.cameras = [rankCamera];
    add(rankVignette);
    rankVignette.alpha = 0;

    forEach(function(bs) {
      bs.cameras = [funnyCam];
    });

    rankCamera.bgColor = FlxColor.TRANSPARENT;
    FlxG.cameras.add(rankCamera, false);
    rankBg.cameras = [rankCamera];
    rankBg.alpha = 0;

    if (prepForNewRank)
    {
      rankCamera.fade(0xFF000000, 0, false, null, true);
    }

    if (fromCharSelect)
    {
      enterFromCharSel();
      onDJIntroDone();
    }
  }

  var currentFilter:Null<SongFilter> = null;
  var currentFilteredSongs:Array<Null<FreeplaySongData>> = [];

  /**
   * Given the current filter, rebuild the current song list and display it.
   * Automatically takes into account currentDifficulty, character, and variation
   *
   * @param filterStuff A filter to apply to the song list (regex, startswith, all, favorite)
   * @param force Whether the capsules should "jump" back in or not using their animation
   * @param onlyIfChanged Only apply the filter if the song list has changed
   */
  public function generateSongList(filterStuff:Null<SongFilter>, force:Bool = false, onlyIfChanged:Bool = true):Void
  {
    var tempSongs:Array<Null<FreeplaySongData>> = songs;

    if (filterStuff != null) tempSongs = sortSongs(tempSongs, filterStuff);

    tempSongs = tempSongs.filter(song -> {
      if (song == null) return true; // Random

      // Available variations for current character. We get this since bf is usually `default` variation, and `pico` is `pico`
      // but sometimes pico can be the default variation (weekend 1 songs), and bf can be `bf` variation (darnell)
      var characterVariations:Array<String> = song.data.getVariationsByCharacter(currentCharacter);

      // Gets all available difficulties for our character, via our available variations
      var difficultiesAvailable:Array<String> = song.data.listDifficulties(null, characterVariations);

      return difficultiesAvailable.contains(currentDifficulty);
    });

    if (onlyIfChanged)
    {
      // == performs equality by reference
      if (tempSongs.isEqualUnordered(currentFilteredSongs)) return;
    }

    // Only now do we know that the filter is actually changing.
    currentFilter = filterStuff;

    currentFilteredSongs = tempSongs;
    curSelected = 0;

    // If curSelected is 0, the result will be null and fall back to the rememberedSongId.
    // We set this so if we change the filter, we'd remain on the same song if it's still in the list.
    rememberedSongId = grpCapsules.members[curSelected]?.freeplayData?.data.id ?? rememberedSongId;

    grpCapsules.killMembers();

    // Initialize the random capsule, with empty/blank info (which we display once bf/pico does his hand)
    var randomCapsule:SongMenuItem = grpCapsules.recycle(SongMenuItem);
    randomCapsule.init(FlxG.width, 0, null, styleData);
    randomCapsule.y = randomCapsule.intendedY(0) + 10;
    randomCapsule.targetPos.x = randomCapsule.x;
    randomCapsule.alpha = 0;
    randomCapsule.songText.visible = false;
    randomCapsule.favIcon.visible = false;
    randomCapsule.favIconBlurred.visible = false;
    randomCapsule.ranking.visible = false;
    randomCapsule.blurredRanking.visible = false;
    randomCapsule.onConfirm = function() {
      capsuleOnConfirmRandom(randomCapsule);
    };

    if (fromCharSelect) randomCapsule.forcePosition();
    else
      randomCapsule.initJumpIn(0, force);

    var hsvShader:HSVShader = new HSVShader();
    randomCapsule.hsvShader = hsvShader;
    grpCapsules.add(randomCapsule);

    for (i in 0...tempSongs.length)
    {
      var tempSong = tempSongs[i];
      if (tempSong == null) continue;

      var funnyMenu:SongMenuItem = grpCapsules.recycle(SongMenuItem);

      funnyMenu.init(FlxG.width, 0, tempSong, styleData);
      funnyMenu.onConfirm = function() {
        capsuleOnOpenDefault(funnyMenu);
      };
      funnyMenu.y = funnyMenu.intendedY(i + 1) + 10;
      funnyMenu.targetPos.x = funnyMenu.x;
      funnyMenu.ID = i;
      funnyMenu.capsule.alpha = 0.5;
      funnyMenu.hsvShader = hsvShader;
      funnyMenu.newText.animation.curAnim.curFrame = 45 - ((i * 4) % 45);
      funnyMenu.forcePosition();

      grpCapsules.add(funnyMenu);
    }

    FlxG.console.registerFunction('changeSelection', changeSelection);

    rememberSelection();
    changeSelection();
    refreshCapsuleDisplays();
  }

  /**
   * Filters an array of songs based on a filter
   * @param songsToFilter What data to use when filtering
   * @param songFilter The filter to apply
   * @return Array<FreeplaySongData>
   */
  public function sortSongs(songsToFilter:Array<Null<FreeplaySongData>>, songFilter:SongFilter):Array<Null<FreeplaySongData>>
  {
    var filterAlphabetically = function(a:Null<FreeplaySongData>, b:Null<FreeplaySongData>):Int {
      return SortUtil.alphabetically(a?.data.songName ?? '', b?.data.songName ?? '');
    };

    switch (songFilter.filterType)
    {
      case REGEXP:
        // filterStuff.filterData has a string with the first letter of the sorting range, and the second one
        // this creates a filter to return all the songs that start with a letter between those two

        // if filterData looks like "A-C", the regex should look something like this: ^[A-C].*
        // to get every song that starts between A and C
        var filterRegexp:EReg = new EReg('^[' + songFilter.filterData + '].*', 'i');
        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filterRegexp.match(filteredSong.data.songName);
        });

        songsToFilter.sort(filterAlphabetically);

      case STARTSWITH:
        // extra note: this is essentially a "search"

        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filteredSong.data.songName.toLowerCase().startsWith(songFilter.filterData ?? '');
        });
      case ALL:
        // no filter!
      case FAVORITE:
        songsToFilter = songsToFilter.filter(filteredSong -> {
          if (filteredSong == null) return true; // Random
          return filteredSong.isFav;
        });

        songsToFilter.sort(filterAlphabetically);

      default:
        // return all on default
    }

    return songsToFilter;
  }

  var sparks:FlxSprite;
  var sparksADD:FlxSprite;

  function rankAnimStart(fromResults:FromResultsParams):Void
  {
    busy = true;
    grpCapsules.members[curSelected].sparkle.alpha = 0;
    // grpCapsules.members[curSelected].forcePosition();

    rememberedSongId = fromResults.songId;
    rememberedDifficulty = fromResults.difficultyId;
    changeSelection();
    changeDiff();

    if (fromResultsParams?.newRank == SHIT)
    {
      if (dj != null) dj.fistPumpLossIntro();
    }
    else
    {
      if (dj != null) dj.fistPumpIntro();
    }

    // rankCamera.fade(FlxColor.BLACK, 0.5, true);
    rankCamera.fade(0xFF000000, 0.5, true, null, true);
    if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
    rankBg.alpha = 1;

    if (fromResults.oldRank != null)
    {
      grpCapsules.members[curSelected].fakeRanking.rank = fromResults.oldRank;
      grpCapsules.members[curSelected].fakeBlurredRanking.rank = fromResults.oldRank;

      sparks.frames = Paths.getSparrowAtlas('freeplay/sparks');
      sparks.animation.addByPrefix('sparks', 'sparks', 24, false);
      sparks.visible = false;
      sparks.blend = BlendMode.ADD;
      sparks.setPosition(517, 134);
      sparks.scale.set(0.5, 0.5);
      add(sparks);
      sparks.cameras = [rankCamera];

      sparksADD.visible = false;
      sparksADD.frames = Paths.getSparrowAtlas('freeplay/sparksadd');
      sparksADD.animation.addByPrefix('sparks add', 'sparks add', 24, false);
      sparksADD.setPosition(498, 116);
      sparksADD.blend = BlendMode.ADD;
      sparksADD.scale.set(0.5, 0.5);
      add(sparksADD);
      sparksADD.cameras = [rankCamera];

      switch (fromResults.oldRank)
      {
        case SHIT:
          sparksADD.color = 0xFF6044FF;
        case GOOD:
          sparksADD.color = 0xFFEF8764;
        case GREAT:
          sparksADD.color = 0xFFEAF6FF;
        case EXCELLENT:
          sparksADD.color = 0xFFFDCB42;
        case PERFECT:
          sparksADD.color = 0xFFFF58B4;
        case PERFECT_GOLD:
          sparksADD.color = 0xFFFFB619;
      }
      // sparksADD.color = sparks.color;
    }

    grpCapsules.members[curSelected].doLerp = false;

    // originalPos.x = grpCapsules.members[curSelected].x;
    // originalPos.y = grpCapsules.members[curSelected].y;

    originalPos.x = 320.488;
    originalPos.y = 235.6;
    trace(originalPos);

    grpCapsules.members[curSelected].ranking.visible = false;
    grpCapsules.members[curSelected].blurredRanking.visible = false;

    rankCamera.zoom = 1.85;
    FlxTween.tween(rankCamera, {"zoom": 1.8}, 0.6, {ease: FlxEase.sineIn});

    funnyCam.zoom = 1.15;
    FlxTween.tween(funnyCam, {"zoom": 1.1}, 0.6, {ease: FlxEase.sineIn});

    grpCapsules.members[curSelected].cameras = [rankCamera];
    // grpCapsules.members[curSelected].targetPos.set((FlxG.width / 2) - (grpCapsules.members[curSelected].width / 2),
    //  (FlxG.height / 2) - (grpCapsules.members[curSelected].height / 2));

    grpCapsules.members[curSelected].setPosition((FlxG.width / 2) - (grpCapsules.members[curSelected].width / 2),
      (FlxG.height / 2) - (grpCapsules.members[curSelected].height / 2));

    new FlxTimer().start(0.5, _ -> {
      rankDisplayNew(fromResults);
    });
  }

  function rankDisplayNew(fromResults:Null<FromResultsParams>):Void
  {
    grpCapsules.members[curSelected].ranking.visible = true;
    grpCapsules.members[curSelected].blurredRanking.visible = true;
    grpCapsules.members[curSelected].ranking.scale.set(20, 20);
    grpCapsules.members[curSelected].blurredRanking.scale.set(20, 20);

    if (fromResults != null && fromResults.newRank != null)
    {
      grpCapsules.members[curSelected].ranking.animation.play(fromResults.newRank.getFreeplayRankIconAsset(), true);
    }

    FlxTween.tween(grpCapsules.members[curSelected].ranking, {"scale.x": 1, "scale.y": 1}, 0.1);

    if (fromResults != null && fromResults.newRank != null)
    {
      grpCapsules.members[curSelected].blurredRanking.animation.play(fromResults.newRank.getFreeplayRankIconAsset(), true);
    }
    FlxTween.tween(grpCapsules.members[curSelected].blurredRanking, {"scale.x": 1, "scale.y": 1}, 0.1);

    new FlxTimer().start(0.1, _ -> {
      if (fromResults?.oldRank != null)
      {
        grpCapsules.members[curSelected].fakeRanking.visible = false;
        grpCapsules.members[curSelected].fakeBlurredRanking.visible = false;

        sparks.visible = true;
        sparksADD.visible = true;
        sparks.animation.play('sparks', true);
        sparksADD.animation.play('sparks add', true);

        sparks.animation.finishCallback = anim -> {
          sparks.visible = false;
          sparksADD.visible = false;
        };
      }

      switch (fromResultsParams?.newRank)
      {
        case SHIT:
          FunkinSound.playOnce(Paths.sound('ranks/rankinbad'));
        case PERFECT:
          FunkinSound.playOnce(Paths.sound('ranks/rankinperfect'));
        case PERFECT_GOLD:
          FunkinSound.playOnce(Paths.sound('ranks/rankinperfect'));
        default:
          FunkinSound.playOnce(Paths.sound('ranks/rankinnormal'));
      }
      rankCamera.zoom = 1.3;

      FlxTween.tween(rankCamera, {"zoom": 1.5}, 0.3, {ease: FlxEase.backInOut});

      grpCapsules.members[curSelected].x -= 10;
      grpCapsules.members[curSelected].y -= 20;

      FlxTween.tween(funnyCam, {"zoom": 1.05}, 0.3, {ease: FlxEase.elasticOut});

      grpCapsules.members[curSelected].capsule.angle = -3;
      FlxTween.tween(grpCapsules.members[curSelected].capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

      IntervalShake.shake(grpCapsules.members[curSelected].capsule, 0.3, 1 / 30, 0.1, 0, FlxEase.quadOut);
    });

    new FlxTimer().start(0.4, _ -> {
      FlxTween.tween(funnyCam, {"zoom": 1}, 0.8, {ease: FlxEase.sineIn});
      FlxTween.tween(rankCamera, {"zoom": 1.2}, 0.8, {ease: FlxEase.backIn});
      FlxTween.tween(grpCapsules.members[curSelected], {x: originalPos.x - 7, y: originalPos.y - 80}, 0.8 + 0.5, {ease: FlxEase.quartIn});
    });

    new FlxTimer().start(0.6, _ -> {
      rankAnimSlam(fromResults);
    });
  }

  function rankAnimSlam(fromResultsParams:Null<FromResultsParams>):Void
  {
    // FlxTween.tween(rankCamera, {"zoom": 1.9}, 0.5, {ease: FlxEase.backOut});
    FlxTween.tween(rankBg, {alpha: 0}, 0.5, {ease: FlxEase.expoIn});

    // FlxTween.tween(grpCapsules.members[curSelected], {angle: 5}, 0.5, {ease: FlxEase.backIn});

    switch (fromResultsParams?.newRank)
    {
      case SHIT:
        FunkinSound.playOnce(Paths.sound('ranks/loss'));
      case GOOD:
        FunkinSound.playOnce(Paths.sound('ranks/good'));
      case GREAT:
        FunkinSound.playOnce(Paths.sound('ranks/great'));
      case EXCELLENT:
        FunkinSound.playOnce(Paths.sound('ranks/excellent'));
      case PERFECT:
        FunkinSound.playOnce(Paths.sound('ranks/perfect'));
      case PERFECT_GOLD:
        FunkinSound.playOnce(Paths.sound('ranks/perfect'));
      default:
        FunkinSound.playOnce(Paths.sound('ranks/loss'));
    }

    FlxTween.tween(grpCapsules.members[curSelected], {"targetPos.x": originalPos.x, "targetPos.y": originalPos.y}, 0.5, {ease: FlxEase.expoOut});
    new FlxTimer().start(0.5, _ -> {
      funnyCam.shake(0.0045, 0.35);

      if (fromResultsParams?.newRank == SHIT)
      {
        if (dj != null) dj.fistPumpLoss();
      }
      else
      {
        if (dj != null) dj.fistPump();
      }

      rankCamera.zoom = 0.8;
      funnyCam.zoom = 0.8;
      FlxTween.tween(rankCamera, {"zoom": 1}, 1, {ease: FlxEase.elasticOut});
      FlxTween.tween(funnyCam, {"zoom": 1}, 0.8, {ease: FlxEase.elasticOut});

      for (index => capsule in grpCapsules.members)
      {
        var distFromSelected:Float = Math.abs(index - curSelected) - 1;

        if (distFromSelected < 5)
        {
          if (index == curSelected)
          {
            FlxTween.cancelTweensOf(capsule);
            // capsule.targetPos.x += 50;
            capsule.fadeAnim();

            rankVignette.color = capsule.getTrailColor();
            rankVignette.alpha = 1;
            FlxTween.tween(rankVignette, {alpha: 0}, 0.6, {ease: FlxEase.expoOut});

            capsule.doLerp = false;
            capsule.setPosition(originalPos.x, originalPos.y);
            IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12, 0, FlxEase.quadOut, function(_) {
              capsule.doLerp = true;
              capsule.cameras = [funnyCam];

              // NOW we can interact with the menu
              busy = false;
              capsule.sparkle.alpha = 0.7;
              playCurSongPreview(capsule);
            }, null);

            // FlxTween.tween(capsule, {"targetPos.x": capsule.targetPos.x - 50}, 0.6,
            //   {
            //     ease: FlxEase.backInOut,
            //     onComplete: function(_) {
            //       capsule.cameras = [funnyCam];
            //     }
            //   });
            FlxTween.tween(capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});
          }
          if (index > curSelected)
          {
            // capsule.color = FlxColor.RED;
            new FlxTimer().start(distFromSelected / 20, _ -> {
              capsule.doLerp = false;

              capsule.capsule.angle = FlxG.random.float(-10 + (distFromSelected * 2), 10 - (distFromSelected * 2));
              FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

              IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12 / (distFromSelected + 1), 0, FlxEase.quadOut, function(_) {
                capsule.doLerp = true;
              });
            });
          }

          if (index < curSelected)
          {
            // capsule.color = FlxColor.BLUE;
            new FlxTimer().start(distFromSelected / 20, _ -> {
              capsule.doLerp = false;

              capsule.capsule.angle = FlxG.random.float(-10 + (distFromSelected * 2), 10 - (distFromSelected * 2));
              FlxTween.tween(capsule.capsule, {angle: 0}, 0.5, {ease: FlxEase.backOut});

              IntervalShake.shake(capsule, 0.6, 1 / 24, 0.12 / (distFromSelected + 1), 0, FlxEase.quadOut, function(_) {
                capsule.doLerp = true;
              });
            });
          }
        }

        index += 1;
      }
    });

    new FlxTimer().start(2, _ -> {
      // dj.fistPump();
      prepForNewRank = false;
    });
  }

  function tryOpenCharSelect():Void
  {
    // Check if we have ACCESS to character select!
    trace('Is Pico unlocked? ${PlayerRegistry.instance.fetchEntry('pico')?.isUnlocked()}');
    trace('Number of characters: ${PlayerRegistry.instance.countUnlockedCharacters()}');

    if (PlayerRegistry.instance.countUnlockedCharacters() > 1)
    {
      trace('Opening character select!');
    }
    else
    {
      trace('Not enough characters unlocked to open character select!');
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      return;
    }

    busy = true;

    FunkinSound.playOnce(Paths.sound('confirmMenu'));

    if (dj != null)
    {
      dj.toCharSelect();
    }

    // Get this character's transition delay, with a reasonable default.
    var transitionDelay:Float = currentCharacter.getFreeplayDJData()?.getCharSelectTransitionDelay() ?? 0.25;

    new FlxTimer().start(transitionDelay, _ -> {
      transitionToCharSelect();
    });
  }

  function transitionToCharSelect():Void
  {
    var transitionGradient = new FlxSprite(0, 720).loadGraphic(Paths.image('freeplay/transitionGradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.updateHitbox();
    transitionGradient.cameras = [rankCamera];
    exitMoversCharSel.set([transitionGradient],
      {
        y: -720,
        speed: 0.8,
        wait: 0.1
      });
    add(transitionGradient);
    for (index => capsule in grpCapsules.members)
    {
      var distFromSelected:Float = Math.abs(index - curSelected) - 1;
      if (distFromSelected < 5)
      {
        capsule.doLerp = false;
        exitMoversCharSel.set([capsule],
          {
            y: -250,
            speed: 0.8,
            wait: 0.1
          });
      }
    }
    fadeShader.fade(1.0, 0.0, 0.8, {ease: FlxEase.quadIn});
    FlxG.sound.music?.fadeOut(0.9, 0);
    new FlxTimer().start(0.9, _ -> {
      FlxG.switchState(new funkin.ui.charSelect.CharSelectSubState());
    });
    for (grpSpr in exitMoversCharSel.keys())
    {
      var moveData:Null<MoveData> = exitMoversCharSel.get(grpSpr);
      if (moveData == null) continue;

      for (spr in grpSpr)
      {
        if (spr == null) continue;

        var funnyMoveShit:MoveData = moveData;

        var moveDataY = funnyMoveShit.y ?? spr.y;
        var moveDataSpeed = funnyMoveShit.speed ?? 0.2;
        var moveDataWait = funnyMoveShit.wait ?? 0.0;

        FlxTween.tween(spr, {y: moveDataY + spr.y}, moveDataSpeed, {ease: FlxEase.backIn});
      }
    }
    backingCard?.enterCharSel();
  }

  function enterFromCharSel():Void
  {
    busy = true;
    if (_parentState != null) _parentState.persistentDraw = false;

    var transitionGradient = new FlxSprite(0, 720).loadGraphic(Paths.image('freeplay/transitionGradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.updateHitbox();
    transitionGradient.cameras = [rankCamera];
    exitMoversCharSel.set([transitionGradient],
      {
        y: -720,
        speed: 1.5,
        wait: 0.1
      });
    add(transitionGradient);
    // FlxTween.tween(transitionGradient, {alpha: 0}, 1, {ease: FlxEase.circIn});
    // for (index => capsule in grpCapsules.members)
    // {
    //   var distFromSelected:Float = Math.abs(index - curSelected) - 1;
    //   if (distFromSelected < 5)
    //   {
    //     capsule.doLerp = false;
    //     exitMoversCharSel.set([capsule],
    //       {
    //         y: -250,
    //         speed: 0.8,
    //         wait: 0.1
    //       });
    //   }
    // }
    fadeShader.fade(0.0, 1.0, 0.8, {ease: FlxEase.quadIn});
    for (grpSpr in exitMoversCharSel.keys())
    {
      var moveData:Null<MoveData> = exitMoversCharSel.get(grpSpr);
      if (moveData == null) continue;

      for (spr in grpSpr)
      {
        if (spr == null) continue;

        var funnyMoveShit:MoveData = moveData;

        var moveDataY = funnyMoveShit.y ?? spr.y;
        var moveDataSpeed = funnyMoveShit.speed ?? 0.2;
        var moveDataWait = funnyMoveShit.wait ?? 0.0;

        spr.y += moveDataY;
        FlxTween.tween(spr, {y: spr.y - moveDataY}, moveDataSpeed * 1.2,
          {
            ease: FlxEase.expoOut,
            onComplete: function(_) {
              for (index => capsule in grpCapsules.members)
              {
                capsule.doLerp = true;
                fromCharSelect = false;
                busy = false;
                albumRoll.applyExitMovers(exitMovers, exitMoversCharSel);
              }
            }
          });
      }
    }
  }

  var touchY:Float = 0;
  var touchX:Float = 0;
  var dxTouch:Float = 0;
  var dyTouch:Float = 0;
  var velTouch:Float = 0;

  var touchTimer:Float = 0;

  var initTouchPos:FlxPoint = new FlxPoint();

  var spamTimer:Float = 0;
  var spamming:Bool = false;

  /**
   * If true, disable interaction with the interface.
   */
  public var busy:Bool = false;

  var originalPos:FlxPoint = new FlxPoint();

  var hintTimer:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (charSelectHint != null)
    {
      hintTimer += elapsed * 2;
      var targetAmt:Float = (Math.sin(hintTimer) + 1) / 2;
      charSelectHint.alpha = FlxMath.lerp(0.3, 0.9, targetAmt);
    }

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.justPressed.P)
    {
      FlxG.switchState(() -> FreeplayState.build(
        {
          {
            character: currentCharacterId == "pico" ? Constants.DEFAULT_CHARACTER : "pico",
          }
        }));
    }

    if (FlxG.keys.justPressed.T)
    {
      rankAnimStart(fromResultsParams ??
        {
          playRankAnim: true,
          newRank: PERFECT_GOLD,
          songId: "tutorial",
          difficultyId: "hard"
        });
    }

    // if (FlxG.keys.justPressed.H)
    // {
    //   rankDisplayNew(fromResultsParams);
    // }

    // if (FlxG.keys.justPressed.G)
    // {
    //   rankAnimSlam(fromResultsParams);
    // }
    #end // ^<-- FEATURE_DEBUG_FUNCTIONS

    if (controls.FREEPLAY_CHAR_SELECT && !busy)
    {
      tryOpenCharSelect();
    }

    if (controls.FREEPLAY_FAVORITE && !busy)
    {
      var targetSong = grpCapsules.members[curSelected]?.freeplayData;
      if (targetSong != null)
      {
        var realShit:Int = curSelected;
        var isFav = targetSong.toggleFavorite();
        if (isFav)
        {
          grpCapsules.members[realShit].favIcon.visible = true;
          grpCapsules.members[realShit].favIconBlurred.visible = true;
          grpCapsules.members[realShit].favIcon.animation.play('fav');
          grpCapsules.members[realShit].favIconBlurred.animation.play('fav');
          FunkinSound.playOnce(Paths.sound('fav'), 1);
          grpCapsules.members[realShit].checkClip();
          grpCapsules.members[realShit].selected = grpCapsules.members[realShit].selected; // set selected again, so it can run it's getter function to initialize movement
          busy = true;

          grpCapsules.members[realShit].doLerp = false;
          FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y - 5}, 0.1, {ease: FlxEase.expoOut});

          FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y + 5}, 0.1,
            {
              ease: FlxEase.expoIn,
              startDelay: 0.1,
              onComplete: function(_) {
                grpCapsules.members[realShit].doLerp = true;
                busy = false;
              }
            });
        }
        else
        {
          grpCapsules.members[realShit].favIcon.animation.play('fav', true, true, 9);
          grpCapsules.members[realShit].favIconBlurred.animation.play('fav', true, true, 9);
          FunkinSound.playOnce(Paths.sound('unfav'), 1);
          new FlxTimer().start(0.2, _ -> {
            grpCapsules.members[realShit].favIcon.visible = false;
            grpCapsules.members[realShit].favIconBlurred.visible = false;
            grpCapsules.members[realShit].checkClip();
          });

          busy = true;
          grpCapsules.members[realShit].doLerp = false;
          FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y + 5}, 0.1, {ease: FlxEase.expoOut});
          FlxTween.tween(grpCapsules.members[realShit], {y: grpCapsules.members[realShit].y - 5}, 0.1,
            {
              ease: FlxEase.expoIn,
              startDelay: 0.1,
              onComplete: function(_) {
                grpCapsules.members[realShit].doLerp = true;
                busy = false;
              }
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

    if (dj != null) FlxG.watch.addQuick('dj-anim', dj.getCurrentAnimation());
  }

  function handleInputs(elapsed:Float):Void
  {
    if (busy) return;

    var upP:Bool = controls.UI_UP_P;
    var downP:Bool = controls.UI_DOWN_P;
    var accepted:Bool = controls.ACCEPT;

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

    if ((controls.UI_UP || controls.UI_DOWN))
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
      if (dj != null) dj.resetAFKTimer();
    }
    else
    {
      spamming = false;
      spamTimer = 0;
    }

    #if !html5
    if (FlxG.mouse.wheel != 0)
    {
      if (dj != null) dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel));
    }
    #else
    if (FlxG.mouse.wheel < 0)
    {
      if (dj != null) dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel / 8));
    }
    else if (FlxG.mouse.wheel > 0)
    {
      if (dj != null) dj.resetAFKTimer();
      changeSelection(-Math.round(FlxG.mouse.wheel / 8));
    }
    #end

    if (controls.UI_LEFT_P)
    {
      if (dj != null) dj.resetAFKTimer();
      changeDiff(-1);
      generateSongList(currentFilter, true);
    }
    if (controls.UI_RIGHT_P)
    {
      if (dj != null) dj.resetAFKTimer();
      changeDiff(1);
      generateSongList(currentFilter, true);
    }

    if (controls.BACK && !busy)
    {
      busy = true;
      FlxTween.globalManager.clear();
      FlxTimer.globalManager.clear();
      if (dj != null) dj.onIntroDone.removeAll();

      FunkinSound.playOnce(Paths.sound('cancelMenu'));

      var longestTimer:Float = 0;

      backingCard?.disappear();

      for (grpSpr in exitMovers.keys())
      {
        var moveData:Null<MoveData> = exitMovers.get(grpSpr);
        if (moveData == null) continue;

        for (spr in grpSpr)
        {
          if (spr == null) continue;

          var funnyMoveShit:MoveData = moveData;

          var moveDataX = funnyMoveShit.x ?? spr.x;
          var moveDataY = funnyMoveShit.y ?? spr.y;
          var moveDataSpeed = funnyMoveShit.speed ?? 0.2;
          var moveDataWait = funnyMoveShit.wait ?? 0.0;

          FlxTween.tween(spr, {x: moveDataX, y: moveDataY}, moveDataSpeed, {ease: FlxEase.expoIn});

          longestTimer = Math.max(longestTimer, moveDataSpeed + moveDataWait);
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
              restartTrack: false,
              // Continue playing this music between states, until a different music track gets played.
              persist: true
            });
          FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
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

  override function beatHit():Bool
  {
    backingCard?.beatHit();

    return super.beatHit();
  }

  public override function destroy():Void
  {
    super.destroy();
    FlxG.cameras.remove(funnyCam);
  }

  /**
   * changeDiff is the root of both difficulty and variation changes/management.
   * It will check the difficulty of the current variation, all available variations, and all available difficulties per variation.
   * It's generally recommended that after calling this you re-sort the song list, however usually it's already on the way to being sorted.
   * @param change
   * @param force
   */
  function changeDiff(change:Int = 0, force:Bool = false):Void
  {
    touchTimer = 0;
    var previousVariation:String = currentVariation;

    // Available variations for current character. We get this since bf is usually `default` variation, and `pico` is `pico`
    // but sometimes pico can be the default variation (weekend 1 songs), and bf can be `bf` variation (darnell)
    var characterVariations:Array<String> = grpCapsules.members[curSelected].freeplayData?.data.getVariationsByCharacter(currentCharacter) ?? Constants.DEFAULT_VARIATION_LIST;

    // Gets all available difficulties for our character, via our available variations
    var difficultiesAvailable:Array<String> = grpCapsules.members[curSelected].freeplayData?.data.listDifficulties(null,
      characterVariations) ?? Constants.DEFAULT_DIFFICULTY_LIST;

    var currentDifficultyIndex:Int = difficultiesAvailable.indexOf(currentDifficulty);

    if (currentDifficultyIndex == -1) currentDifficultyIndex = difficultiesAvailable.indexOf(Constants.DEFAULT_DIFFICULTY);

    currentDifficultyIndex += change;

    if (currentDifficultyIndex < 0) currentDifficultyIndex = Std.int(difficultiesAvailable.length - 1);
    if (currentDifficultyIndex >= difficultiesAvailable.length) currentDifficultyIndex = 0;

    // Update the current difficulty
    currentDifficulty = difficultiesAvailable[currentDifficultyIndex];
    for (variation in characterVariations)
    {
      if (grpCapsules.members[curSelected].freeplayData?.data.hasDifficulty(currentDifficulty, variation) ?? false)
      {
        currentVariation = variation;
        rememberedVariation = variation;
        break;
      }
    }

    var daSong:Null<FreeplaySongData> = grpCapsules.members[curSelected].freeplayData;
    if (daSong != null)
    {
      var targetSong:Null<Song> = SongRegistry.instance.fetchEntry(daSong.data.id);
      if (targetSong == null)
      {
        FlxG.log.warn('WARN: could not find song with id (${daSong.data.id})');
        return;
      }

      var songScore:Null<SaveScoreData> = Save.instance.getSongScore(daSong.data.id, currentDifficulty, currentVariation);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore == null ? 0.0 : ((songScore.tallies.sick + songScore.tallies.good) / songScore.tallies.totalNotes);
      rememberedDifficulty = currentDifficulty;
      grpCapsules.members[curSelected].refreshDisplay();
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      rememberedDifficulty = currentDifficulty;
    }

    if (intendedCompletion == Math.POSITIVE_INFINITY || intendedCompletion == Math.NEGATIVE_INFINITY || Math.isNaN(intendedCompletion))
    {
      intendedCompletion = 0;
    }

    for (diffSprite in grpDifficulties.group.members)
    {
      if (diffSprite == null) continue;
      diffSprite.visible = false;

      if (diffSprite.difficultyId == currentDifficulty)
      {
        diffSprite.visible = true;

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
      }
    }

    if (change != 0 || force)
    {
      // Update the song capsules to reflect the new difficulty info.
      for (songCapsule in grpCapsules.members)
      {
        if (songCapsule == null) continue;

        if (songCapsule.freeplayData != null)
        {
          songCapsule.init(null, null, songCapsule.freeplayData);
          songCapsule.checkClip();
        }
      }

      // Reset the song preview in case we changed variations (normal->erect etc)
      if (currentVariation != previousVariation) playCurSongPreview();
    }

    // Set the album graphic and play the animation if relevant.
    var newAlbumId:Null<String> = daSong?.data.getAlbumId(currentDifficulty, currentVariation);
    if (albumRoll.albumId != newAlbumId)
    {
      albumRoll.albumId = newAlbumId;
      albumRoll.skipIntro();
    }

    // Set difficulty star count.
    albumRoll.setDifficultyStars(daSong?.data.getDifficulty(currentDifficulty, currentVariation)?.difficultyRating ?? 0);
  }

  function capsuleOnConfirmRandom(randomCapsule:SongMenuItem):Void
  {
    trace('RANDOM SELECTED');

    busy = true;
    letterSort.inputEnabled = false;

    var availableSongCapsules:Array<SongMenuItem> = grpCapsules.members.filter(function(cap:SongMenuItem) {
      // Dead capsules are ones which were removed from the list when changing filters.
      return cap.alive && cap.freeplayData != null;
    });

    trace('Available songs: ${availableSongCapsules.map(function(cap) {
      return cap?.freeplayData?.data.songName;
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

  /**
   * Called when hitting ENTER to open the instrumental list.
   */
  function capsuleOnOpenDefault(cap:SongMenuItem):Void
  {
    var targetSongId:String = cap?.freeplayData?.data.id ?? 'unknown';
    var targetSongNullable:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
    if (targetSongNullable == null)
    {
      FlxG.log.warn('WARN: could not find song with id (${targetSongId})');
      return;
    }
    var targetSong:Song = targetSongNullable;
    var targetDifficultyId:String = currentDifficulty;
    var targetVariation:Null<String> = currentVariation;
    trace('target song: ${targetSongId} (${targetVariation})');
    var targetLevelId:Null<String> = cap?.freeplayData?.levelId;
    PlayStatePlaylist.campaignId = targetLevelId ?? null;

    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(targetDifficultyId, targetVariation);
    if (targetDifficulty == null)
    {
      FlxG.log.warn('WARN: could not find difficulty with id (${targetDifficultyId})');
      return;
    }

    trace('target difficulty: ${targetDifficultyId}');
    trace('target variation: ${targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION}');

    var baseInstrumentalId:String = targetSong.getBaseInstrumentalId(targetDifficultyId, targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
    var altInstrumentalIds:Array<String> = targetSong.listAltInstrumentalIds(targetDifficultyId,
      targetDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];

    if (altInstrumentalIds.length > 0)
    {
      var instrumentalIds = [baseInstrumentalId].concat(altInstrumentalIds);
      openInstrumentalList(cap, instrumentalIds);
    }
    else
    {
      trace('NO ALTS');
      capsuleOnConfirmDefault(cap);
    }
  }

  public function getControls():Controls
  {
    return controls;
  }

  function openInstrumentalList(cap:SongMenuItem, instrumentalIds:Array<String>):Void
  {
    busy = true;

    capsuleOptionsMenu = new CapsuleOptionsMenu(this, cap.x + 175, cap.y + 115, instrumentalIds);
    capsuleOptionsMenu.cameras = [funnyCam];
    capsuleOptionsMenu.zIndex = 10000;
    add(capsuleOptionsMenu);

    capsuleOptionsMenu.onConfirm = function(targetInstId:String) {
      capsuleOnConfirmDefault(cap, targetInstId);
    };
  }

  var capsuleOptionsMenu:Null<CapsuleOptionsMenu> = null;

  public function cleanupCapsuleOptionsMenu():Void
  {
    this.busy = false;

    if (capsuleOptionsMenu != null)
    {
      remove(capsuleOptionsMenu);
      capsuleOptionsMenu = null;
    }
  }

  /**
   * Called when hitting ENTER to play the song.
   */
  function capsuleOnConfirmDefault(cap:SongMenuItem, ?targetInstId:String):Void
  {
    busy = true;
    letterSort.inputEnabled = false;

    PlayStatePlaylist.isStoryMode = false;

    var targetSongId:String = cap?.freeplayData?.data.id ?? 'unknown';
    var targetSongNullable:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
    if (targetSongNullable == null)
    {
      FlxG.log.warn('WARN: could not find song with id (${targetSongId})');
      return;
    }
    var targetSong:Song = targetSongNullable;
    var targetVariation:Null<String> = currentVariation;
    var targetLevelId:Null<String> = cap?.freeplayData?.levelId;
    PlayStatePlaylist.campaignId = targetLevelId ?? null;

    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(currentDifficulty, currentVariation);
    if (targetDifficulty == null)
    {
      FlxG.log.warn('WARN: could not find difficulty with id (${currentDifficulty})');
      return;
    }

    if (targetInstId == null)
    {
      var baseInstrumentalId:String = targetSong?.getBaseInstrumentalId(currentDifficulty, targetDifficulty.variation ?? Constants.DEFAULT_VARIATION) ?? '';
      targetInstId = baseInstrumentalId;
    }

    // Visual and audio effects.
    FunkinSound.playOnce(Paths.sound('confirmMenu'));
    if (dj != null) dj.confirm();

    grpCapsules.members[curSelected].forcePosition();
    grpCapsules.members[curSelected].confirm();

    backingCard?.confirm();

    new FlxTimer().start(styleData?.getStartDelay(), function(tmr:FlxTimer) {
      FunkinSound.emptyPartialQueue();

      Paths.setCurrentLevel(cap?.freeplayData?.levelId);
      LoadingState.loadPlayState(
        {
          targetSong: targetSong,
          targetDifficulty: currentDifficulty,
          targetVariation: currentVariation,
          targetInstrumental: targetInstId,
          practiceMode: false,
          minimalMode: false,

          #if FEATURE_DEBUG_FUNCTIONS
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

  function refreshCapsuleDisplays():Void
  {
    grpCapsules.forEachAlive((cap:SongMenuItem) -> {
      cap.refreshDisplay();
    });
  }

  function rememberSelection():Void
  {
    if (rememberedSongId != null)
    {
      curSelected = currentFilteredSongs.findIndex(function(song) {
        if (song == null) return false;
        return song.data.id == rememberedSongId;
      });

      if (curSelected == -1) curSelected = 0;
    }

    if (rememberedDifficulty != null)
    {
      currentDifficulty = rememberedDifficulty;
    }

    if (rememberedVariation != null)
    {
      currentVariation = rememberedVariation;
    }
  }

  function changeSelection(change:Int = 0):Void
  {
    var prevSelected:Int = curSelected;

    curSelected += change;

    if (!prepForNewRank && curSelected != prevSelected) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    if (curSelected < 0) curSelected = grpCapsules.countLiving() - 1;
    if (curSelected >= grpCapsules.countLiving()) curSelected = 0;

    var daSongCapsule:SongMenuItem = grpCapsules.members[curSelected];
    if (daSongCapsule.freeplayData != null)
    {
      var songScore:Null<SaveScoreData> = Save.instance.getSongScore(daSongCapsule.freeplayData.data.id, currentDifficulty, currentVariation);
      intendedScore = songScore?.score ?? 0;
      intendedCompletion = songScore == null ? 0.0 : ((songScore.tallies.sick + songScore.tallies.good) / songScore.tallies.totalNotes);
      rememberedSongId = daSongCapsule.freeplayData.data.id;
      changeDiff();
      daSongCapsule.refreshDisplay();
    }
    else
    {
      intendedScore = 0;
      intendedCompletion = 0.0;
      rememberedSongId = null;
      rememberedDifficulty = Constants.DEFAULT_DIFFICULTY;
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

    if (grpCapsules.countLiving() > 0 && !prepForNewRank)
    {
      playCurSongPreview(daSongCapsule);
      grpCapsules.members[curSelected].selected = true;
    }
  }

  public function playCurSongPreview(?daSongCapsule:SongMenuItem):Void
  {
    if (daSongCapsule == null) daSongCapsule = grpCapsules.members[curSelected];
    if (curSelected == 0)
    {
      FunkinSound.playMusic('freeplayRandom',
        {
          startingVolume: 0.0,
          overrideExisting: true,
          restartTrack: false
        });
      FlxG.sound.music.fadeIn(2, 0, 0.8);
    }
    else
    {
      var previewSong:Null<Song> = daSongCapsule?.freeplayData?.data;
      if (previewSong == null) return;

      // Check if character-specific difficulty exists
      var songDifficulty:Null<SongDifficulty> = previewSong.getDifficulty(currentDifficulty, currentVariation);

      var baseInstrumentalId:String = previewSong.getBaseInstrumentalId(currentDifficulty, songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
      var altInstrumentalIds:Array<String> = previewSong.listAltInstrumentalIds(currentDifficulty,
        songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];
      var instSuffix:String = baseInstrumentalId;
      #if FEATURE_DEBUG_FUNCTIONS
      if (altInstrumentalIds.length > 0 && FlxG.keys.pressed.CONTROL)
      {
        instSuffix = altInstrumentalIds[0];
      }
      #end
      instSuffix = (instSuffix != '') ? '-$instSuffix' : '';
      trace('Attempting to play partial preview: ${previewSong.id}:${instSuffix}');
      FunkinSound.playMusic(previewSong.id,
        {
          startingVolume: 0.0,
          overrideExisting: true,
          restartTrack: false,
          mapTimeChanges: false, // The music metadata is not alongside the audio file so this won't work.
          pathsFunction: INST,
          suffix: instSuffix,
          partialParams:
            {
              loadPartial: true,
              start: 0,
              end: 0.2
            },
          onLoad: function() {
            FlxG.sound.music.fadeIn(2, 0, 0.4);
          }
        });
      if (songDifficulty != null)
      {
        Conductor.instance.mapTimeChanges(songDifficulty.timeChanges);
        Conductor.instance.update(FlxG.sound?.music?.time ?? 0.0);
      }
    }
  }

  /**
   * Build an instance of `FreeplayState` that is above the `MainMenuState`.
   * @return The MainMenuState with the FreeplayState as a substate.
   */
  public static function build(?params:FreeplayStateParams, ?stickers:StickerSubState):MusicBeatState
  {
    var result:MainMenuState;
    result = new MainMenuState(true);
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

  var parent:FreeplayState;

  public function new(parent:FreeplayState, x:Float, y:Float, flipped:Bool, controls:Controls, ?styleData:FreeplayStyle = null)
  {
    super(x, y);

    this.parent = parent;
    this.controls = controls;

    frames = Paths.getSparrowAtlas(styleData == null ? 'freeplay/freeplaySelector' : styleData.getSelectorAssetKey());
    animation.addByPrefix('shine', 'arrow pointer loop', 24);
    animation.play('shine');

    whiteShader = new PureColor(FlxColor.WHITE);

    shader = whiteShader;

    flipX = flipped;
  }

  override function update(elapsed:Float):Void
  {
    if (flipX && controls.UI_RIGHT_P && !parent.busy) moveShitDown();
    if (!flipX && controls.UI_LEFT_P && !parent.busy) moveShitDown();

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
   * We used to have a billion fields, but this SongMetadata variable should be all we need
   * to be able to get most information about an available song.
   * For example, you can get the artist via `data.songArtist`
   *
   * You can usually get various other particulars of a specific difficulty/variation by
   * using data.getDifficulty(), and inputting specifics on your difficulty, variations, etc.
   * See the getters here for songCharacter, fullSongName, and songStartingBpm for examples.
   *
   * @see Song
   */
  public var data:Song;

  /**
   * The level id of the song, useful for sorting from week1 -> week 7 + weekend1
   * and for properly loading PlayStatePlaylist for preloading on web
   */
  public var levelId(get, never):Null<String>;

  function get_levelId():Null<String>
  {
    return _levelId;
  }

  var _levelId:String;

  /**
   * Whether or not the song has been favorited.
   */
  public var isFav:Bool = false;

  /**
   * Whether the player has seen/played this song before within freeplay
   */
  public var isNew(get, never):Bool;

  /**
   * The default opponent for the song.
   * Does the getter stuff for you depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var songCharacter(get, never):String;

  /**
   * The full song name, dynamically generated depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var fullSongName(get, never):String;

  /**
   * The starting BPM of the song, dynamically generated depending on your current (or rather, rememberd) variation and difficulty.
   */
  public var songStartingBpm(get, never):Float;

  public var difficultyRating(get, never):Int;

  public var scoringRank(get, never):Null<ScoringRank>;

  public function new(data:Song, levelData:Level)
  {
    this.data = data;
    _levelId = levelData.id;
    this.isFav = Save.instance.isSongFavorited(data.songName);
  }

  /**
   * Toggle whether or not the song is favorited, then flush to save data.
   * @return Whether or not the song is now favorited.
   */
  public function toggleFavorite():Bool
  {
    isFav = !isFav;
    if (isFav)
    {
      Save.instance.favoriteSong(data.songName);
    }
    else
    {
      Save.instance.unfavoriteSong(data.songName);
    }
    return isFav;
  }

  function updateValues(variations:Array<String>):Void
  {
    // this.isNew = song.isSongNew(suffixedDifficulty);
  }

  function get_isNew():Bool
  {
    // We use a slightly different manner to get the new status of a song than the other getters here
    // `isSongNew()` only takes a single variation, and it's data that isn't accessible via the Song data/metadata
    // it's stored in the song .hxc script in a function that overrides `isSongNew()`
    // and is only accessible with the correct valid variation inputs

    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    var variation:String = data.getFirstValidVariation(FreeplayState.rememberedDifficulty, null, variations);
    return data.isSongNew(FreeplayState.rememberedDifficulty, variation);
  }

  function get_songCharacter():String
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.characters.opponent ?? '';
  }

  function get_fullSongName():String
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);

    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.songName ?? data.songName;
  }

  function get_songStartingBpm():Float
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);

    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.getStartingBPM() ?? 0;
  }

  function get_difficultyRating():Int
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.difficultyRating ?? 0;
  }

  function get_scoringRank():Null<ScoringRank>
  {
    var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacterId);
    var variation:String = data.getFirstValidVariation(FreeplayState.rememberedDifficulty, null, variations);

    return Save.instance.getSongRank(data.id, FreeplayState.rememberedDifficulty, variation);
  }
}

/**
 * Parameters used to initialize the FreeplayState.
 */
typedef FreeplayStateParams =
{
  ?character:String,

  ?fromCharSelect:Bool,

  ?fromResults:FromResultsParams,
};

/**
 * A set of parameters for transitioning to the FreeplayState from the ResultsState.
 */
typedef FromResultsParams =
{
  /**
   * The previous rank the song hand, if any. Null if it had no score before.
   */
  var ?oldRank:ScoringRank;

  /**
   * Whether or not to play the rank animation on returning to freeplay.
   */
  var playRankAnim:Bool;

  /**
   * The new rank the song has.
   */
  var newRank:ScoringRank;

  /**
   * The song ID to play the animation on.
   */
  var songId:String;

  /**
   * The difficulty ID to play the animation on.
   */
  var difficultyId:String;
};

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

    var assetDiffId:String = diffId;
    while (!Assets.exists(Paths.image('freeplay/freeplay${assetDiffId}')))
    {
      // Remove the last suffix of the difficulty id until we find an asset or there are no more suffixes.
      var assetDiffIdParts:Array<String> = assetDiffId.split('-');
      assetDiffIdParts.pop();
      if (assetDiffIdParts.length == 0)
      {
        trace('Could not find difficulty asset: freeplay/freeplay${diffId} (from ${diffId})');
        return;
      };
      assetDiffId = assetDiffIdParts.join('-');
    }

    // Check for an XML to use an animation instead of an image.
    if (Assets.exists(Paths.file('images/freeplay/freeplay${assetDiffId}.xml')))
    {
      this.frames = Paths.getSparrowAtlas('freeplay/freeplay${assetDiffId}');
      this.animation.addByPrefix('idle', 'idle0', 24, true);
      if (Preferences.flashingLights) this.animation.play('idle');
    }
    else
    {
      this.loadGraphic(Paths.image('freeplay/freeplay' + assetDiffId));
      trace('Loaded difficulty asset: freeplay/freeplay${assetDiffId} (from ${diffId})');
    }
  }
}
