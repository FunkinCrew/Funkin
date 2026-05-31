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

import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

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

  var bgWires:FunkinSprite;

  var darkness:FunkinSprite;
  var fileDrop:FunkinSprite;

  public function new()
  {
    super();
  }

  override public function create():Void
  {
    super.create();

    funkin.util.plugins.SidePanelPlugin.showGrabber = false;

    enabledModItems.pinnedTopModId = BASE_GAME_MOD_ID;

    var menuBG = FunkinSprite.create('ui/mods/mod-menu-bg');
    menuBG.scale.set(0.66, 0.67);
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -1000;
    add(menuBG);

    var topText:FunkinSprite = FunkinSprite.create('ui/mods/mod-menu-top-text');
    topText.scale.set(0.66, 0.67);
    add(topText);
    topText.updateHitbox();

    topText.x = FlxG.width / 2 - (topText.width / 2);
    topText.y = 25;

    var dragText:FlxText = new FlxText(112, 95, FlxG.width, 'Drag packs onto this window to add new stuff');
    dragText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 32, FlxColor.WHITE);
    add(dragText);

    leftRectangle.x = 60;
    leftRectangle.y = 138;
    leftRectangle.scale.set(0.64, 0.67);
    leftRectangle.loadTexture('ui/mods/mod-menu-box');
    add(leftRectangle);
    leftRectangle.updateHitbox();

    rightRectangle.x = leftRectangle.x + leftRectangle.width + 35;
    rightRectangle.y = leftRectangle.y;
    rightRectangle.scale.set(0.64, 0.67);
    rightRectangle.loadTexture('ui/mods/mod-menu-box');
    add(rightRectangle);
    rightRectangle.updateHitbox();

    bgWires = new FunkinSprite();
    bgWires.x = 1040;
    bgWires.y = 240;
    bgWires.scale.set(0.7, 0.7);
    bgWires.loadTexture('ui/mods/mod-menu-bgwires');
    add(bgWires);
    bgWires.updateHitbox();

    var bfAndGF:FunkinSprite = new FunkinSprite();
    bfAndGF.x = 705;
    bfAndGF.y = 40;
    bfAndGF.scale.set(0.7, 0.7);
    bfAndGF.loadTexture('ui/mods/mod-menu-bfgf');
    bfAndGF.updateHitbox();

    buildDisabledModList();
    buildEnabledModList();

    add(enabledModItems);
    add(disabledModItems);
    add(enabledModItems.titleText);
    add(disabledModItems.titleText);

    add(enabledModItems.scrollbarTrack);
    add(enabledModItems.scrollbarThumb);

    add(disabledModItems.scrollbarTrack);
    add(disabledModItems.scrollbarThumb);

    enabledModItems.titleText.x = rightRectangle.x + (rightRectangle.width / 2) - (enabledModItems.titleText.width / 2);
    enabledModItems.titleText.y = rightRectangle.y + 14;
    disabledModItems.titleText.x = leftRectangle.x + (leftRectangle.width / 2) - (disabledModItems.titleText.width / 2);
    disabledModItems.titleText.y = leftRectangle.y + 14;

    enabledModItems.clipRect = FlxRect.get(rightRectangle.x, rightRectangle.y + 60, rightRectangle.width, rightRectangle.height - 60);
    disabledModItems.clipRect = FlxRect.get(leftRectangle.x, leftRectangle.y + 60, leftRectangle.width, leftRectangle.height - 60);

    buttonBackToMenu.x = 8;
    buttonBackToMenu.y = 32;
    buttonBackToMenu.loadTexture('ui/mods/mod-menu-back');
    //add(buttonBackToMenu);

    add(bfAndGF);

    buttonDone.x = 865;
    buttonDone.y = 642;
    buttonDone.scale.set(0.65, 0.65);
    buttonDone.loadTexture('ui/mods/mod-menu-done');
    buttonDone.updateHitbox();
    add(buttonDone);

    buttonOpenFolder.x = 240;
    buttonOpenFolder.y = 640;
    buttonOpenFolder.scale.set(0.66, 0.67);
    buttonOpenFolder.loadTexture('ui/mods/mod-menu-open-folder');
    buttonOpenFolder.updateHitbox();
    add(buttonOpenFolder);

    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    add(darkness);

    fileDrop = FunkinSprite.create(0,0,'ui/mods/mod-menu-drop-hover');
    fileDrop.setGraphicSize(FlxG.width, FlxG.height);
    fileDrop.scrollFactor.set(0, 0);
    fileDrop.updateHitbox();
    fileDrop.visible = false;
    add(fileDrop);

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
    FlxG.stage.window.onDropBegin.add(startFileDropHover);
    FlxG.stage.window.onDropComplete.add(hideFileDropHover);

    applyInitialSelection();

    buttonOpenFolder.alpha = 0.5;
    buttonDone.alpha = 0.5;

    FlxG.autoPause = false;
  }

  var fileDropTimer:Float = 0;
  var fileElapsed:Float = 0;
  var isHoveringFile:Bool = false;
  var animDone:Bool = false;

  function startFileDropHover():Void
  {
    isHoveringFile = true;
    trace('File drop hover start');
    fileDropTimer = 0.5;
    fileElapsed = 0;
    fileDrop.visible = true;
    darkness.visible = true;
    animDone = false;
    darkness.alpha = 0;
    fileDrop.alpha = 0;
  }

  function hideFileDropHover(x:Float, y:Float):Void
  {
    fileElapsed = 0;
    isHoveringFile = false;
    animDone = false;
    trace('File drop hover end');
    fileDropTimer = -0.08;
  }

  public override function destroy():Void
  {
    super.destroy();
    FlxG.autoPause = true;
    FlxG.stage.window.onDropFile.remove(onDropFile);
    FlxG.stage.window.onDropBegin.remove(startFileDropHover);
    FlxG.stage.window.onDropComplete.remove(hideFileDropHover);
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

  function distanceToPoint(point1:FlxPoint, point2:FlxPoint):Float
  {
    var dx = point1.x - point2.x;
    var dy = point1.y - point2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!animDone)
    {
      fileElapsed += elapsed;
      var t = fileElapsed / fileDropTimer;

      var adjustT = t;
      if (adjustT < 0) adjustT += 1;

      if (t > 1)
      {
        t = 1;
        animDone = true;
      }
      else if (t < -1)
      {
        t = -1;
        animDone = true;
      }
      fileDrop.alpha = FlxMath.lerp(0, 1, FlxEase.backOut(adjustT));
      darkness.alpha = FlxMath.lerp(0, 0.5, FlxEase.backOut(adjustT));
    }

    // handleMouse();
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
    if (controls.BACK_P)
    {
      backToMainMenu();
    }

    var oldSelection = selection;

    if (controls.UI_UP_P)
    {
      switch (selection)
      {
        case DisabledModList:
          disabledModItems.moveUp();
        case EnabledModList:
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, true);
          else enabledModItems.moveUp();
        case OpenModsFolder:
          // Do nothing
        case Done:
          // Do nothing
        case BackToMenu:
          // Do nothing
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
        case OpenModsFolder:
          // Do nothing
        case Done:
          // Do nothing
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.UI_LEFT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          selection = Done;
        case EnabledModList:
          if (disabledModItems.modItems.length > 0) selection = DisabledModList;
        case OpenModsFolder:
          selection = EnabledModList;
        case Done:
          selection = OpenModsFolder;
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.UI_RIGHT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          if (enabledModItems.modItems.length > 0) selection = EnabledModList;
        case EnabledModList:
          selection = OpenModsFolder;
        case OpenModsFolder:
          selection = Done;
        case Done:
          selection = DisabledModList;
        case BackToMenu:
          // Do nothing
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

    if (oldSelection != selection) handleSelection();
  }

  function handleSelection():Void
  {
    disabledModItems.deselect();
    enabledModItems.deselect();
    buttonOpenFolder.alpha = 0.5;
    buttonDone.alpha = 0.5;

    switch (selection)
    {
      case DisabledModList:
        disabledModItems.selectFirstItem();
      case EnabledModList:
        enabledModItems.selectFirstItem();
      case OpenModsFolder:
        buttonOpenFolder.alpha = 1;
      case Done:
        buttonDone.alpha = 1;
      case BackToMenu:
        // Do nothing
    }
  }

  function buildDisabledModList():Void
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledMods();

    disabledModItems.removeAll();
    disabledModItems.title = 'DISABLED';
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
    enabledModItems.title = 'ENABLED';
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
