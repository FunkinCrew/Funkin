package funkin.ui.quickpanel;

import flixel.FlxG;
import funkin.ui.options.OptionsState;
import funkin.ui.transition.Transition;

class PanelActions
{
  static final actions:Map<String, Void->Void> = [
    'none' => () -> {
    },
    'exitToTitle' => exitToTitle,
    'mods' => openMods,
    'freeplay' => openFreeplay,
    'options' => openOptions
  ];

  public static function register(id:String, action:Void->Void):Void
  {
    actions.set(id, action);
  }

  public static function unregister(id:String):Void
  {
    actions.remove(id);
  }

  public static function exists(id:String):Bool
  {
    return actions.exists(id);
  }

  public static function run(id:String):Void
  {
    var action:Null<Void->Void> = actions.get(id);
    if (action == null)
    {
      trace('[QUICKPANEL] Unknown action: $id');
      return;
    }
    action();
  }

  static function exitToTitle():Void
  {
    QuickPanelState.stopMusic();
    Transition.switchState(() -> new funkin.ui.title.TitleState(), {
      assetQuery: funkin.ui.title.TitleState.queryAssets,
      transition: BlackScreen(Fade(North), Fade(South))
    });
  }

  static function openMods():Void
  {
    QuickPanelState.stopMusic();
    Transition.switchState(() -> new funkin.ui.modmenu.ModMenuState(), {
      assetQuery: funkin.ui.modmenu.ModMenuState.queryAssets,
      transition: BlackScreen(Fade(North), Fade(South))
    });
  }

  static function openFreeplay():Void
  {
    var freeplayParams = {
      fromCharSelect: true
    };
    Transition.switchState(() -> funkin.ui.freeplay.FreeplayState.build(freeplayParams), {
      assetQuery: funkin.ui.freeplay.FreeplayState.queryAssets.bind(_, freeplayParams),
      transition: BlackScreen(None, Fade(South))
    });
  }

  static function openOptions():Void
  {
    QuickPanelState.stopMusic();
    Transition.switchState(() -> new OptionsState(), {
      assetQuery: OptionsState.queryAssets,
      transition: None,
      shouldPurgeCache: false
    });
  }
}
