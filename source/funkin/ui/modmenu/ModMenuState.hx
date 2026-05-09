package funkin.ui.modmenu;

import funkin.input.Cursor;
import funkin.util.FileUtil;
import funkin.ui.mainmenu.MainMenuState;
import funkin.InitState;
import funkin.ui.title.TitleState;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.modding.PolymodHandler;
import polymod.Polymod;
import polymod.Polymod.ModMetadata;
import polymod.Polymod.ModDependencies;
import funkin.save.Save;
import funkin.ui.MusicBeatState;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import funkin.util.plugins.SidePanelPlugin;

/**
 * The user interface for the mod menu.
 */
class ModMenuState extends MusicBeatState
{
  static inline final BASE_GAME_MOD_ID:String = '__base_game__';
  static inline final BASE_GAME_MOD_ICON_PATH:String = 'ui/mods/mod-menu-base-icon';

  var leftRectangle:FunkinSprite = new FunkinSprite();
  var rightRectangle:FunkinSprite = new FunkinSprite();
  var buttonBackToMenu:FunkinSprite = new FunkinSprite();
  var buttonOpenFolder:FunkinSprite = new FunkinSprite();
  var buttonDone:FunkinSprite = new FunkinSprite();

  /**
   * This flag is enabled when returning to the main menu.
   * This should disable other interaction.
   */
  var exitingMenu:Bool = false;

  var disabledModItems:ModMenuItemList = new ModMenuItemList();
  var enabledModItems:ModMenuItemList = new ModMenuItemList();
  var selection:ModMenuSelection = DisabledModList;

  public function new()
  {
    super();
  }

  override public function create():Void
  {
    super.create();

    funkin.util.plugins.SidePanelPlugin.showGrabber = false;

    enabledModItems.pinnedTopModId = BASE_GAME_MOD_ID;

    // Show a simple background.
    var menuBG = FunkinSprite.create('ui/main-menu/menu-desat');
    menuBG.color = 0xFF999999;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -1000;
    add(menuBG);

    var background:FunkinSprite = new FunkinSprite(24, 24);
    background.makeSolidColor(FlxG.width - 48, FlxG.height - 48, FlxColor.BLACK);
    background.alpha = 0.7;
    add(background);

    var topText:FlxText = new FlxText(112, 48, FlxG.width, 'FUCKING COOL ASS MOD MENU');
    topText.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 24, FlxColor.WHITE);
    add(topText);

    leftRectangle.x = 52;
    leftRectangle.y = 112;
    var width:Float = (background.width - 12) / 3.0;
    leftRectangle.makeSolidColor(cast width, cast(background.height - 132, Int), FlxColor.BLACK);
    leftRectangle.alpha = 0.5;
    add(leftRectangle);

    rightRectangle.x = leftRectangle.x + leftRectangle.width + 48;
    rightRectangle.y = 112;
    rightRectangle.makeSolidColor(cast width, cast(background.height - 132, Int), FlxColor.BLACK);
    rightRectangle.alpha = 0.5;
    add(rightRectangle);

    var bfAndGF:FunkinSprite = new FunkinSprite();
    bfAndGF.x = 960;
    bfAndGF.y = 256;
    bfAndGF.loadTexture('ui/mods/one-million-followers-on-tiktok-or-gf-fucking-dies');
    add(bfAndGF);

    buildDisabledModList();
    buildEnabledModList();

    add(enabledModItems);
    add(disabledModItems);

    enabledModItems.clipRect = new FlxRect(0, 0, rightRectangle.width, rightRectangle.height);
    disabledModItems.clipRect = new FlxRect(0, 0, leftRectangle.width, leftRectangle.height);

    buttonBackToMenu.x = 8;
    buttonBackToMenu.y = 32;
    buttonBackToMenu.loadTexture('ui/mods/mod-menu-back');
    add(buttonBackToMenu);

    buttonDone.x = 960;
    buttonDone.y = 640;
    buttonDone.loadTexture('ui/mods/mod-menu-done');
    add(buttonDone);

    buttonOpenFolder.x = 16;
    buttonOpenFolder.y = 640;
    buttonOpenFolder.loadTexture('ui/mods/mod-menu-open-folder');
    add(buttonOpenFolder);

    enabledModItems.repositionItems();
    disabledModItems.repositionItems();

    if (disabledModItems.modItems.length > 0)
    {
      disabledModItems.selectFirstItem();
      selection = DisabledModList;
    }
    else
    {
      enabledModItems.selectFirstItem();
      selection = EnabledModList;
    }

    FlxG.stage.window.onDropFile.add(onDropFile);

    applyInitialSelection();

    Cursor.show();
  }

  public override function destroy():Void
  {
    super.destroy();

    FlxG.stage.window.onDropFile.remove(onDropFile);
  }

  public function onDropFile(path:String, state:String, x:Float, y:Float):Void
  {
    // If zip file, move to mods folder.
    if (StringTools.endsWith(path, '.zip'))
    {
      var fileClean = StringTools.replace(path, '\\', '/');
      var fileName = StringTools.replace(path.substring(fileClean.lastIndexOf('/') + 1), ".zip", "");
      var destPath = PolymodHandler.MOD_FOLDER + '/' + fileName;

      trace('Unzipping mod from $path to $destPath');
      FileUtil.unzipToFolder(FileUtil.readBytesFromPath(path), destPath);

      buildDisabledModList();
      disabledModItems.repositionItems();
    }
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleMouse();
    handleKeyboard();
  }

  function applyInitialSelection():Void
  {
    disabledModItems.selectFirstItem();
  }

  function handleMouse():Void
  {
    if (FlxG.mouse.justPressed)
    {
      // TODO: Make this less bad

      var target = FlxG.mouse.getWorldPosition();

      if (buttonBackToMenu.overlapsPoint(target))
      {
        backToMainMenu();
      }
      else if (buttonOpenFolder.overlapsPoint(target))
      {
        openModsFolder();
      } else if (buttonDone.overlapsPoint(target))
      {
        applyModlist();
      }
    }
  }

  function handleKeyboard():Void
  {
    var pressingCtrl:Bool = FlxG.keys.pressed.CONTROL;
    if (controls.UI_UP_P)
    {
      switch (selection)
      {
        case DisabledModList:
          disabledModItems.moveUp();
        case EnabledModList:
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, true);
          else enabledModItems.moveUp();
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          selection = DisabledModList;
        case Done:
          selection = DisabledModList;
      }
    }

    if (controls.UI_DOWN_P)
    {
      switch (selection)
      {
        case DisabledModList:
          disabledModItems.moveDown();
        case EnabledModList:
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, false);
          else enabledModItems.moveDown();
        case BackToMenu:
          selection = DisabledModList;
        case OpenModsFolder:
          // Don't do anything
        case Done:
          // Don't do anything
      }
    }

    if (controls.UI_LEFT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          // Don't do anything
        case EnabledModList:
          if (disabledModItems.modItems.length > 0)
          {
            enabledModItems.deselect();
            disabledModItems.selectFirstItem();
            selection = DisabledModList;
          }
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          // Don't do anything
        case Done:
          selection = OpenModsFolder;
      }
    }

    if (controls.UI_RIGHT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          if (enabledModItems.modItems.length > 0)
          {
            disabledModItems.deselect();
            enabledModItems.selectFirstItem();
            selection = EnabledModList;
          }
        case EnabledModList:
          // Don't do anything
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          selection = Done;
        case Done:
          // Don't do anything
      }
    }

    if (controls.ACCEPT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          enableMod(disabledModItems.selectedModItem);
          if (disabledModItems.modItems.length == 0)
          {
            enabledModItems.selectFirstItem();
            selection = EnabledModList;
          }
          else disabledModItems.selectFirstItem();
        case EnabledModList:
          disableMod(enabledModItems.selectedModItem);
        case BackToMenu:
          backToMainMenu();
        case OpenModsFolder:
          openModsFolder();
        case Done:
          applyModlist();
      }
    }
  }

  function buildDisabledModList():Void
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledMods();

    disabledModItems.removeAll();

    disabledModItems.x = leftRectangle.x;
    disabledModItems.y = leftRectangle.y;

    for (mod in disabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      disabledModItems.addMod(mod);
    }
  }

  function buildEnabledModList():Void
  {
    var enabledMods:Array<ModMetadata> = PolymodHandler.getEnabledMods();

    enabledModItems.removeAll();

    enabledModItems.x = rightRectangle.x;
    enabledModItems.y = rightRectangle.y;

    for (mod in enabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      enabledModItems.addMod(mod);
    }

    var baseGameItem = new ModMenuItem(null, BASE_GAME_MOD_ICON_PATH, BASE_GAME_MOD_ID, 'Base Game', 'Default game content');
    baseGameItem.locked = true;
    enabledModItems.addModRaw(baseGameItem);

    enabledModItems.modItems.remove(baseGameItem);
    enabledModItems.modItems.insert(0, baseGameItem);
    enabledModItems.remove(baseGameItem);
    enabledModItems.insert(baseGameItem, 0);
  }

  function applyModlist():Void
  {
    // Backup the user's save data before switching mods.
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
    trace('[SAVE] Backed up current save data in case of emergency to $backupSlot!');

    // set enabled mods
    var enabledModIds:Array<String> = [];
    for (modItem in enabledModItems.modItems)
    {
      var modId = modItem.getModId();
      if (modId == BASE_GAME_MOD_ID) continue;
      enabledModIds.push(modId);
    }

    PolymodHandler.disableAllMods();
    for (modId in enabledModIds)
    {
      PolymodHandler.enableMod(modId);
    }

    InitState.resetTitleState();

    PolymodHandler.forceReloadAssets();
    if (InitState.customTitleState == null) FlxG.switchState(() -> new TitleState());
    else {
      SidePanelPlugin.showGrabber = true;
      FlxG.switchState(() -> InitState.customTitleState);
    }
  }

  function enableMod(item:Null<ModMenuItem>):Void
  {
    if (item == null) return;

    if (!disabledModItems.modItems.contains(item)) return;

    if (item.getModId() == BASE_GAME_MOD_ID) return;

    item.selected = false;

    var dependenciesToEnable:Array<String> = checkDependencies(item.mod);
    trace('Dependencies to enable for ${item.getModTitle()}: ${dependenciesToEnable}');

    for (dependencyId in dependenciesToEnable)
    {
      var dependencyItem = disabledModItems.modItems.find((item) -> item.getModId() == dependencyId);
      if (dependencyItem != null)
      {
        enableMod(dependencyItem);
      }
      else
      {
        trace('Error: Dependency ${dependencyId} for mod ${item.getModTitle()} not found!');
        return;
      }
    }

    var oldIndex:Int = disabledModItems.modItems.indexOf(item);
    disabledModItems.removeMod(item);

    // check for optional dependencies that depend on this mod, if they exist then add this mod *before* them.
    var insertedAtPosition = false;
    for (enabledMod in enabledModItems.modItems)
    {
      if (enabledMod.mod == null) continue;

      var optionalDependencies:ModDependencies = enabledMod.getOptionalDependencies();
      if (optionalDependencies != null)
      {
        var b:Bool = false;
        for (optionalDependencyId => version in optionalDependencies)
        {
          if (optionalDependencyId == item.getModId() && version.isSatisfiedBy(item.getModVersion()))
          {
            trace('Mod ${enabledMod.getModTitle()} has an optional dependency on ${item.getModTitle()}, so enabling ${item.getModTitle()} before ${enabledMod.getModTitle()}');
            // Insert the mod before the mod with the optional dependency, so that the optional dependency is still satisfied.
            var modList:Array<ModMenuItem> = enabledModItems.modItems;
            var index = modList.indexOf(enabledMod);
            modList.insert(index, item);
            enabledModItems.insert(item, index);
            insertedAtPosition = true;
            b = true;
            break;
          }
        }

        if (b) break;
      }
    }

    if (!insertedAtPosition)
    {
      enabledModItems.addModRaw(item);
    }
    else
    {
      var index = enabledModItems.modItems.indexOf(item);
      item.localX = 0;
      item.localY = enabledModItems.getModItemYPos(index) + enabledModItems.scrollOffset;
    }

    // Update selections: try to keep selection on the source list at the next logical item.
    if (disabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, disabledModItems.modItems.length - 1));
      disabledModItems.selectModItem(disabledModItems.modItems[newIndex]);
      selection = DisabledModList;
    }
    else
    {
      enabledModItems.selectModItem(item);
      selection = EnabledModList;
    }

    disabledModItems.repositionItems();
    enabledModItems.repositionItems();
  }

  function disableMod(item:Null<ModMenuItem>):Void
  {
    if (item == null) return;

    if (!enabledModItems.modItems.contains(item)) return;
    if (enabledModItems.isPinnedItem(item) || item.locked) return;

    item.selected = false;

    // Disable any mods that depend on this mod as well.
    var brokenDependencies = validateDependencies(item.mod);
    trace('Broken dependencies for ${item.getModTitle()}: ${brokenDependencies}');
    for (dependencyTitle in brokenDependencies)
    {
      var dependencyItem = enabledModItems.modItems.find((item) -> item.getModTitle() == dependencyTitle);
      if (dependencyItem != null)
      {
        trace('Disabling ${dependencyItem.getModTitle()} since it depends on ${item.getModTitle()}');
        disableMod(dependencyItem);
      }
    }

    var oldIndex:Int = enabledModItems.modItems.indexOf(item);
    enabledModItems.removeMod(item);
    disabledModItems.addModRaw(item);

    if (enabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, enabledModItems.modItems.length - 1));
      enabledModItems.selectModItem(enabledModItems.modItems[newIndex]);
      selection = EnabledModList;
    }
    else
    {
      disabledModItems.selectModItem(item);
      selection = DisabledModList;
    }

    enabledModItems.repositionItems();
    disabledModItems.repositionItems();
  }

  function orderMod(modItem:Null<ModMenuItem>, moveUp:Bool):Void
  {
    if (modItem == null) return;

    if (enabledModItems.isPinnedItem(modItem)) return;

    var modList:Array<ModMenuItem> = enabledModItems.modItems;
    var index = modList.indexOf(modItem);
    if (index == -1) return;

    var pinnedItem = enabledModItems.getPinnedTopItem();
    var pinnedIndex = pinnedItem != null ? modList.indexOf(pinnedItem) : -1;
    var minMovableIndex = pinnedIndex != -1 ? pinnedIndex + 1 : 0;

    // Can't move items if they're somehow before the pinned item or there's no space to move
    if (index < minMovableIndex) return;
    if (minMovableIndex >= modList.length) return;

    var newIndex = moveUp ? index + 1 : index - 1;

    // Prevent wrapping across pinned item boundary; just clamp or return
    if (newIndex < minMovableIndex || newIndex >= modList.length)
    {
      return; // Don't allow moves that would wrap around or go out of bounds
    }

    trace('Moving mod ${modItem.getModTitle()} from index $index to $newIndex');

    var otherModItem = modList[newIndex];

    var shouldRebuildDepends:Bool = false;

    for (mod => version in modItem.getDependencies())
    {
      if (otherModItem.getModId() == mod)
      {
        shouldRebuildDepends = true;
        break;
      }
    }

    for (mod => version in otherModItem.getDependencies())
    {
      if (modItem.getModId() == mod)
      {
        shouldRebuildDepends = true;
        break;
      }
    }

    // Optional dependency check: if the other mod is an optional dependency (of our mod), if so then rebuild.
    if (!moveUp)
    {
      var optionalDependencies:ModDependencies = modItem.getOptionalDependencies();
      for (mod => version in optionalDependencies)
      {
        if (otherModItem.getModId() == mod)
        {
          shouldRebuildDepends = true;
          break;
        }
      }
    }

    modList.splice(index, 1);
    modList.insert(newIndex, modItem);

    if (shouldRebuildDepends)
    {
      trace('Mod ${modItem.getModTitle()} depends on ${otherModItem.getModTitle()}, so rebuilding enabled mod list to update dependencies');

      var modMetadataList:Array<ModMetadata> = [];
      for (modItem in modList)
      {
        if (enabledModItems.isPinnedItem(modItem)) continue;
        modMetadataList.push(modItem.mod);
      }
      var selectedId:Null<String> = null;
      if (enabledModItems.selectedModItem != null) selectedId = enabledModItems.selectedModItem.getModId();
      modMetadataList = Polymod.sortModsByDependencies(modMetadataList);
      enabledModItems.removeAll();
      var i = 0;
      for (modMetadata in modMetadataList)
      {
        enabledModItems.addMod(modMetadata);
        if (modMetadata.id == selectedId) modItem = enabledModItems.modItems[i];
        i++;
      }
    }

    enabledModItems.deselectAll();
    enabledModItems.selectModItem(modItem);
    enabledModItems.repositionItems();
  }

  // return an array of mod IDs that depend on the given mod that are currently enabled, which would be broken by disabling this mod
  function validateDependencies(mod:ModMetadata):Array<String>
  {
    var brokenDependencies:Array<String> = [];

    for (enabledModItem in enabledModItems.modItems)
    {
      var enabledMod = enabledModItem.mod;
      if (enabledMod == null) continue;

      var dependencies:ModDependencies = enabledMod.dependencies;
      for (dependencyId => version in dependencies)
      {
        if (dependencyId == mod.id) brokenDependencies.push(enabledMod.title);
      }
    }

    return brokenDependencies;
  }

  // return an array of mod IDs that the given mod depends on that are currently disabled.
  function checkDependencies(mod:ModMetadata):Array<String>
  {
    var toEnable:Array<String> = [];

    var dependencies:ModDependencies = mod.dependencies;
    for (dependencyId => version in dependencies)
    {
      if (!toEnable.contains(dependencyId) &&
        !enabledModItems.modItems.exists((item) -> item.getModId() == dependencyId && version.isSatisfiedBy(item.getModVersion())))
      {
        toEnable.push(dependencyId);
      }
    }

    return toEnable;
  }


  /**
   * Open the folder where the user's mods are stored.
   */
  function openModsFolder():Void
  {
    FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
  }

  /**
   * Return to the main menu.
   */
  function backToMainMenu():Void
  {
    exitingMenu = true;
    FlxG.keys.enabled = false;
    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'));
  }
}

enum ModMenuSelection
{
  DisabledModList;
  EnabledModList;
  BackToMenu;
  OpenModsFolder;
  Done;
}
