package funkin;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.debug.log.LogStyle;
import flixel.util.FlxColor;
import funkin.modding.module.ModuleHandler;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.cutscene.dialogue.ConversationDataParser;
import funkin.play.cutscene.dialogue.DialogueBoxDataParser;
import funkin.play.cutscene.dialogue.SpeakerDataParser;
import funkin.play.event.SongEventData.SongEventParser;
import funkin.play.PlayState;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.stage.StageData.StageDataParser;
import funkin.ui.PreferencesMenu;
import funkin.util.macro.MacroUtil;
import funkin.util.WindowUtil;
import openfl.display.BitmapData;
#if discord_rpc
import Discord.DiscordClient;
#end

/**
 * Initializes the game state using custom defines.
 * Only used in Debug builds.
 */
class InitState extends FlxTransitionableState
{
  override public function create():Void
  {
    trace('This is a debug build, loading InitState...');
    #if android
    FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
    #end
    #if newgrounds
    NGio.init();
    #end
    #if discord_rpc
    DiscordClient.initialize();

    Application.current.onExit.add(function(exitCode) {
      DiscordClient.shutdown();
    });
    #end

    // ==== flixel shit ==== //

    // This big obnoxious white button is for MOBILE, so that you can press it
    // easily with your finger when debug bullshit pops up during testing lol!
    FlxG.debugger.addButton(LEFT, new BitmapData(200, 200), function() {
      FlxG.debugger.visible = false;
    });

    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFFCC2233), function() {
      if (FlxG.vcr.paused)
      {
        FlxG.vcr.resume();

        for (snd in FlxG.sound.list)
        {
          snd.resume();
        }

        FlxG.sound.music.resume();
      }
      else
      {
        FlxG.vcr.pause();

        for (snd in FlxG.sound.list)
        {
          snd.pause();
        }

        FlxG.sound.music.pause();
      }
    });

    #if FLX_DEBUG
    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFF2222CC), function() {
      FlxG.game.debugger.vcr.onStep();

      for (snd in FlxG.sound.list)
      {
        snd.pause();
        snd.time += FlxG.elapsed * 1000;
      }

      FlxG.sound.music.pause();
      FlxG.sound.music.time += FlxG.elapsed * 1000;
    });
    #end

    FlxG.sound.muteKeys = [ZERO];
    FlxG.game.focusLostFramerate = 60;

    // FlxG.stage.window.borderless = true;
    // FlxG.stage.window.mouseLock = true;

    var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
    diamond.persist = true;
    diamond.destroyOnNoUse = false;

    FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
      new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
    FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
      new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

    // ===== save shit ===== //

    FlxG.save.bind('funkin', 'ninjamuffin99');

    // https://github.com/HaxeFlixel/flixel/pull/2396
    // IF/WHEN MY PR GOES THRU AND IT GETS INTO MAIN FLIXEL, DELETE THIS CHUNKOF CODE, AND THEN UNCOMMENT THE LINE BELOW
    // FlxG.sound.loadSavedPrefs();

    if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
    if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

    // Make errors and warnings less annoying.
    LogStyle.ERROR.openConsole = false;
    LogStyle.ERROR.errorSound = null;
    LogStyle.WARNING.openConsole = false;
    LogStyle.WARNING.errorSound = null;

    // FlxG.save.close();
    // FlxG.sound.loadSavedPrefs();
    WindowUtil.initWindowEvents();
    WindowUtil.disableCrashHandler();

    PreferencesMenu.initPrefs();
    PlayerSettings.init();
    Highscore.load();

    if (FlxG.save.data.weekUnlocked != null)
    {
      // FIX LATER!!!
      // WEEK UNLOCK PROGRESSION!!
      // StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;

      // if (StoryMenuState.weekUnlocked.length < 4) StoryMenuState.weekUnlocked.insert(0, true);

      // QUICK PATCH OOPS!
      // if (!StoryMenuState.weekUnlocked[0]) StoryMenuState.weekUnlocked[0] = true;
    }

    if (FlxG.save.data.seenVideo != null) VideoState.seenVideo = FlxG.save.data.seenVideo;

    // ===== fuck outta here ===== //

    // FlxTransitionableState.skipNextTransOut = true;
    FlxTransitionableState.skipNextTransIn = true;

    // TODO: Register custom event callbacks here

    funkin.data.level.LevelRegistry.instance.loadEntries();
    SongEventParser.loadEventCache();
    ConversationDataParser.loadConversationCache();
    DialogueBoxDataParser.loadDialogueBoxCache();
    SpeakerDataParser.loadSpeakerCache();
    SongDataParser.loadSongCache();
    StageDataParser.loadStageCache();
    CharacterDataParser.loadCharacterCache();
    ModuleHandler.buildModuleCallbacks();
    ModuleHandler.loadModuleCache();

    FlxG.debugger.toggleKeys = [F2];

    ModuleHandler.callOnCreate();

    #if song
    var song:String = getSong();

    var weeks:Array<Array<String>> = [
      ['bopeebo', 'fresh', 'dadbattle'],
      ['spookeez', 'south', 'monster'],
      ['spooky', 'spooky', 'monster'],
      ['pico', 'philly', 'blammed'],
      ['satin-panties', 'high', 'milf'],
      ['cocoa', 'eggnog', 'winter-horrorland'],
      ['senpai', 'roses', 'thorns'],
      ['ugh', 'guns', 'stress']
    ];

    var week:Int = 0;
    for (i in 0...weeks.length)
    {
      if (weeks[i].contains(song))
      {
        week = i + 1;
        break;
      }
    }

    if (week == 0) throw 'Invalid -D song=$song';

    startSong(week, song, false);
    #elseif week
    var week:Int = getWeek();

    var songs:Array<String> = [
      'bopeebo',
      'spookeez',
      'spooky',
      'pico',
      'satin-panties',
      'cocoa',
      'senpai',
      'ugh'
    ];

    if (week <= 0 || week >= songs.length) throw 'invalid -D week=' + week;

    startSong(week, songs[week - 1], true);
    #elseif FREEPLAY
    FlxG.switchState(new FreeplayState());
    #elseif ANIMATE
    FlxG.switchState(new funkin.ui.animDebugShit.FlxAnimateTest());
    #elseif CHARTING
    FlxG.switchState(new funkin.ui.debug.charting.ChartEditorState());
    #elseif STAGEBUILD
    FlxG.switchState(new StageBuilderState());
    #elseif FIGHT
    FlxG.switchState(new PicoFight());
    #elseif ANIMDEBUG
    FlxG.switchState(new funkin.ui.animDebugShit.DebugBoundingState());
    #elseif LATENCY
    FlxG.switchState(new LatencyState());
    #elseif NETTEST
    FlxG.switchState(new netTest.NetTest());
    #else
    FlxG.sound.cache(Paths.music('freakyMenu'));
    FlxG.switchState(new TitleState());
    #end
  }

  function startSong(week, song, isStoryMode):Void
  {
    var dif:Int = getDif();

    var targetDifficulty = switch (dif)
    {
      case 0: 'easy';
      case 1: 'normal';
      case 2: 'hard';
      default: 'normal';
    };
    LoadingState.loadAndSwitchState(new PlayState(
      {
        targetSong: SongDataParser.fetchSong(song),
        targetDifficulty: targetDifficulty,
      }));
  }
}

function getWeek():Int
  return Std.parseInt(MacroUtil.getDefine('week'));

function getSong():String
  return MacroUtil.getDefine('song');

function getDif():Int
  return Std.parseInt(MacroUtil.getDefine('dif', '1'));
