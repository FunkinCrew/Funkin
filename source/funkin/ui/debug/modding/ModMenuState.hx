package funkin.ui.debug.modding;

import funkin.ui.debug.modding.components.ModBox;
import funkin.ui.mainmenu.MainMenuState;
import funkin.graphics.FunkinCamera;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import haxe.ui.backend.flixel.UIState;
import polymod.Polymod;
import flixel.FlxG;

/**
 * A state for enabling and reordering mods.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/main-view.xml"))
class ModMenuState extends UIState // UIState derives from MusicBeatState
{
  var uiCamera:FunkinCamera;
  var mods:Array<ModBox>;

  public function new()
  {
    super();

    menubarItemReloadMods.onClick = _ -> {
      saveMods();
      reloadMods();
    };

    menubarItemQuit.onClick = _ -> quitModState();
  }

  override function create():Void
  {
    super.create();

    mods = [];

    reloadMods();

    Cursor.show();

    uiCamera = new FunkinCamera('modStateUI');
    FlxG.cameras.reset(uiCamera);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleCursor();

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.R)
    {
      saveMods();
      reloadMods();
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      quitModState();
    }
  }

  override function destroy():Void
  {
    super.destroy();

    Cursor.hide();
  }

  function addMod(id:String, name:String, description:String, enabled:Bool):Void
  {
    var mod:ModBox = new ModBox(id, name, description);

    mod.onClick = function(_) {
      if (mod.parentComponent == disabledModsBox)
      {
        disabledModsBox.removeComponent(mod, false);
        enabledModsBox.addComponentAt(mod, 0);
      }
      else
      {
        enabledModsBox.removeComponent(mod, false);
        disabledModsBox.addComponentAt(mod, 0);
      }
    }

    mods.push(mod);

    if (enabled)
    {
      enabledModsBox.addComponent(mod);
    }
    else
    {
      disabledModsBox.addComponent(mod);
    }
  }

  function handleCursor():Void
  {
    if (FlxG.mouse.justPressed)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    }

    if (FlxG.mouse.justReleased)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));
    }
  }

  function reloadMods():Void
  {
    while (mods.length > 0)
    {
      mods[0].parentComponent.removeComponent(mods[0]);
      mods.shift();
    }

    #if desktop
    var detectedMods:Array<ModMetadata> = PolymodHandler.getAllMods();
    var enabledModIds:Array<String> = Save.instance.enabledModIds;
    enabledModIds.reverse();

    // Sort detectedMods based on the order of enabledModIds
    detectedMods.sort((a, b) -> {
      var indexA = enabledModIds.indexOf(a.id);
      var indexB = enabledModIds.indexOf(b.id);

      if (indexA == -1 && indexB == -1) return 0;
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;

      return indexA - indexB;
    });

    trace('ModState: Detected ${detectedMods.length} mods');

    for (mod in detectedMods)
    {
      addMod(mod.id, mod.title, mod.description, enabledModIds.contains(mod.id));
    }
    #end
  }

  function saveMods():Void
  {
    var enabledModIds:Array<String> = [];

    for (enabledMod in enabledModsBox.childComponents)
    {
      if (Std.isOfType(enabledMod, ModBox))
      {
        var modBox:ModBox = cast(enabledMod, ModBox);
        enabledModIds.push(modBox.modId);
      }
    }

    enabledModIds.reverse();

    Save.instance.enabledModIds = enabledModIds;
  }

  function quitModState():Void
  {
    saveMods();

    // stopping the music so that reloading the assets
    // will use the overwritten music
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.stop();
    }

    PolymodHandler.forceReloadAssets();

    FlxG.switchState(() -> new MainMenuState());
  }
}
