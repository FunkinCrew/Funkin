package funkin.ui.debug.replay;

import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.ListView;
import haxe.ui.data.ArrayDataSource;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.LoadingState;
import funkin.input.Cursor;
import funkin.util.FileUtil;
import funkin.play.ReplaySystem;
import funkin.data.song.SongRegistry;
import flixel.FlxSprite;

using StringTools;

/**
 * Temporary state for viewing replays
 * In the future this would probably be using actual art
 * However, currently it will only use simple ui
 */
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/replay-state/main-view.xml'))
class ReplayState extends UIState
{
  var menuBG:FlxSprite;

  var replayList:ListView;

  var isExiting:Bool = false;

  public override function create():Void
  {
    super.create();

    Cursor.show();

    this.root.zIndex = 100;

    menubarItemReload.onClick = (_) -> {
      reload();
    };

    menubarItemExit.onClick = (_) -> {
      exit();
    };

    replayList.onChange = (_) -> {
      play();
    };

    buildBackground();

    reload();

    refresh();
  }

  public override function update(elapsed:Float):Void
  {
    if (isExiting)
    {
      return;
    }

    super.update(elapsed);

    handleKeybinds();
  }

  function handleKeybinds():Void
  {
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.R)
    {
      reload();
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      exit();
    }
  }

  function buildBackground():Void
  {
    menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    add(menuBG);

    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -100;
  }

  function reload():Void
  {
    replayList.dataSource = new ArrayDataSource<String>();
    for (file in FileUtil.listFiles('replays', '.fnfr'))
    {
      replayList.dataSource.add(file.replace('.fnfr', ''));
    }
  }

  function exit():Void
  {
    isExiting = true;
    FlxG.switchState(() -> new MainMenuState());
    Cursor.hide();
  }

  function play():Void
  {
    var replayFile:String = replayList.dataSource.get(replayList.selectedIndex);
    var replay:ReplayData = ReplayData.fromBytes(FileUtil.readBytesFromPath('replays/${replayFile}.fnfr'));

    LoadingState.loadPlayState(
      {
        targetSong: SongRegistry.instance.fetchEntry(replay.id),
        targetDifficulty: replay.difficulty,
        targetVariation: replay.variation,
        targetInstrumental: null,
        practiceMode: false,
        minimalMode: false,
        botPlayMode: false,
        replayData: replay,
      }, true);
  }
}
