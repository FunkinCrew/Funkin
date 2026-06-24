package funkin.ui.modmenu;

import haxe.io.Path;
import polymod.PolymodConfig;
import funkin.input.Cursor;
import funkin.util.FileUtil;
import funkin.ui.mainmenu.MainMenuState;
import funkin.InitState;
import funkin.ui.title.TitleState;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
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
import flixel.addons.transition.FlxTransitionableState;
import funkin.ui.modmenu.ModMenuButton;
import funkin.util.PropertyAnimator;
import funkin.util.WindowUtil;
import flixel.tweens.FlxTween;
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
  var buttonBackToMenu:ModMenuButton = new ModMenuButton();
  var buttonOpenFolder:ModMenuButton = new ModMenuButton();
  var buttonDone:ModMenuButton = new ModMenuButton();

  /**
   * This flag is enabled when returning to the main menu.
   * This should disable other interaction.
   */
  var exitingMenu:Bool = false;

  var disabledModItems:ModMenuItemList = new ModMenuItemList();
  var enabledModItems:ModMenuItemList = new ModMenuItemList();
  var selection:ModMenuSelection = DisabledModList;
  var transitionLayer:FunkinSpriteGroup;

  /**
   * Items that are currently flying between the two lists.
   * Each one owns the tween that carries it, plus the list/index it should land in.
   */
  var pendingTransitions:Array<TransitionRecord> = [];

  var bgWires:FunkinSprite;
  var darkness:FunkinSprite;
  var fileDrop:FunkinSprite;
  var openFolderAnimator:PropertyAnimator;
  var doneButtonAnimator:PropertyAnimator;
  var lastSelectDir:Int = 0;

  public function new()
  {
    super();
  }

  override public function create():Void
  {
    super.create();

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

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

    var dragText:FlxText = new FlxText(98, 95, FlxG.width, 'Drag packs onto this window to add new stuff');
    dragText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 32, false);
    dragText.scale.set(1, 0.8);
    dragText.letterSpacing = 5;
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

    refreshModList();

    add(enabledModItems);
    add(disabledModItems);
    add(enabledModItems.titleText);
    add(disabledModItems.titleText);

    add(enabledModItems.scrollbarTrack);
    add(enabledModItems.scrollbarThumb);

    add(disabledModItems.scrollbarTrack);
    add(disabledModItems.scrollbarThumb);

    transitionLayer = new FunkinSpriteGroup();
    add(transitionLayer);

    enabledModItems.titleText.x = rightRectangle.x + (rightRectangle.width / 2) - (enabledModItems.titleText.width / 2);
    enabledModItems.titleText.y = rightRectangle.y + 14;
    disabledModItems.titleText.x = leftRectangle.x + (leftRectangle.width / 2) - (disabledModItems.titleText.width / 2);
    disabledModItems.titleText.y = leftRectangle.y + 14;

    enabledModItems.clipRect = FlxRect.get(rightRectangle.x, rightRectangle.y + 60, rightRectangle.width, rightRectangle.height - 75);
    disabledModItems.clipRect = FlxRect.get(leftRectangle.x, leftRectangle.y + 60, leftRectangle.width, leftRectangle.height - 75);

    buttonBackToMenu.x = 8;
    buttonBackToMenu.y = 32;
    buttonBackToMenu.loadTexture('ui/mods/mod-menu-back');
    // add(buttonBackToMenu);

    add(bfAndGF);

    buttonDone.x = 865;
    buttonDone.y = 642;
    buttonDone.scale.set(0.65, 0.65);
    buttonDone.loadTexture('ui/mods/mod-menu-done');
    buttonDone.updateHitbox();
    add(buttonDone);

    buttonOpenFolder.x = 240;
    buttonOpenFolder.y = 640;
    buttonOpenFolder.scale.set(0.65, 0.65);
    buttonOpenFolder.loadTexture('ui/mods/mod-menu-open-folder');
    buttonOpenFolder.updateHitbox();
    add(buttonOpenFolder);

    buttonDone.graphicName = 'mod-menu-done';
    buttonOpenFolder.graphicName = 'mod-menu-open-folder';

    openFolderAnimator = new PropertyAnimator(buttonOpenFolder);
    doneButtonAnimator = new PropertyAnimator(buttonDone);

    openFolderAnimator.addAnimationByName('select', 24);

    openFolderAnimator.addProperty('select', 'scale.x', [0.72]);
    openFolderAnimator.addProperty('select', 'scale.y', [0.72]);
    openFolderAnimator.addProperty('select', 'selected', [true]);
    openFolderAnimator.addProperty('select', 'invert', [false]);

    openFolderAnimator.addAnimationByName('deselect', 24);
    openFolderAnimator.addProperty('deselect', 'scale.x', [0.65]);
    openFolderAnimator.addProperty('deselect', 'scale.y', [0.65]);
    openFolderAnimator.addProperty('deselect', 'selected', [false]);
    openFolderAnimator.addProperty('deselect', 'invert', [false]);

    openFolderAnimator.addAnimationByName('accept', 24);
    openFolderAnimator.addProperty('accept', 'scale.x', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    openFolderAnimator.addProperty('accept', 'scale.y', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    openFolderAnimator.addProperty('accept', 'invert', [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ]);
    openFolderAnimator.addProperty('accept', 'selected', [
      false,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    ]);

    doneButtonAnimator.addAnimationByName('select', 24);
    doneButtonAnimator.addProperty('select', 'scale.x', [0.72]);
    doneButtonAnimator.addProperty('select', 'scale.y', [0.72]);
    doneButtonAnimator.addProperty('select', 'selected', [true]);
    doneButtonAnimator.addProperty('select', 'invert', [false]);

    doneButtonAnimator.addAnimationByName('deselect', 24);
    doneButtonAnimator.addProperty('deselect', 'scale.x', [0.65]);
    doneButtonAnimator.addProperty('deselect', 'scale.y', [0.65]);
    doneButtonAnimator.addProperty('deselect', 'selected', [false]);
    doneButtonAnimator.addProperty('deselect', 'invert', [false]);

    doneButtonAnimator.addAnimationByName('accept', 24);
    doneButtonAnimator.addProperty('accept', 'scale.x', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    doneButtonAnimator.addProperty('accept', 'scale.y', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    doneButtonAnimator.addProperty('accept', 'invert', [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ]);
    doneButtonAnimator.addProperty('accept', 'selected', [
      false,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    ]);

    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    add(darkness);

    fileDrop = FunkinSprite.create(0, 0, 'ui/mods/mod-menu-drop-hover');
    fileDrop.setGraphicSize(FlxG.width * 0.95, FlxG.height * 0.9);
    fileDrop.scrollFactor.set(0, 0);
    fileDrop.updateHitbox();
    fileDrop.x = FlxG.width / 2 - (fileDrop.width / 2);
    fileDrop.y = FlxG.height / 2 - (fileDrop.height / 2);
    fileDrop.visible = false;
    add(fileDrop);

    enabledModItems.repositionItems();
    disabledModItems.repositionItems();

    if (disabledModItems.modItems.length > 0)
    {
      disabledModItems.selectFirstItem();
      selection = DisabledModList;
      enabledModItems.deselectAll();
    }
    else
    {
      enabledModItems.selectFirstItem();
      selection = EnabledModList;
      disabledModItems.deselectAll();
    }

    FlxG.stage.window.onDropFile.add(onDropFile);
    FlxG.stage.window.onDropBegin.add(startFileDropHover);
    FlxG.stage.window.onDropComplete.add(hideFileDropHover);

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

  // TRANSITION CODE //

  /**
   * Moves an item into the unclipped transition layer at the given world coordinates, so it can be tweened independently of the lists.
   * @param item
   * @param worldX
   * @param worldY
   */
  function putItemInTransitionLayer(item:ModMenuItem, worldX:Float, worldY:Float):Void
  {
    if (item == null || transitionLayer == null) return;

    enabledModItems.remove(item);
    disabledModItems.remove(item);
    if (transitionLayer.children.contains(item)) transitionLayer.remove(item);

    item.clipRect = null;
    transitionLayer.add(item);
    item.localX = worldX - transitionLayer.x;
    item.localY = worldY - transitionLayer.y;
  }

  /**
   * Immediately finishes placing an item into its destination list, bypassing any in-flight tween.
   * @param item
   * @param destinationList
   * @param index
   */
  function finishItemTransitionToList(item:ModMenuItem,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null || destinationList == null || transitionLayer == null) return;

    transitionLayer.remove(item);

    var clamped:Int = index;
    if (clamped > destinationList.modItems.length) clamped = destinationList.modItems.length;
    if (clamped < 0) clamped = 0;
    destinationList.addModRawWithoutLayout(item, clamped);

    item.localX = ModMenuItemList.ITEM_X_OFFSET;

    if (incomingCount(destinationList) == 0) destinationList.repositionItems();
    else
      destinationList.updateScrollbar();
  }

  /**
   * Tween an item from the transition layer into its destination list, tracking it
   * so it can be force-settled later if another swap interrupts it.
   */
  function startItemTransition(item:ModMenuItem,
    targetX:Float,
    targetY:Float,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null) return;

    var record:TransitionRecord = {
      item: item,
      dest: destinationList,
      index: index,
      tween: null
    };
    pendingTransitions.push(record);

    record.tween = FlxTween.tween(item, {
      localX: targetX,
      localY: targetY
    }, 0.2, {
      ease: FlxEase.quadOut,
      onComplete: _ -> completeTransition(record)
    });
  }

  /**
   * Land a single in-flight item in its destination list. Safe to call more than
   * once for the same record (subsequent calls are no-ops).
   */
  function completeTransition(record:TransitionRecord):Void
  {
    if (record == null) return;
    if (!pendingTransitions.contains(record)) return;
    pendingTransitions.remove(record);

    if (record.tween != null)
    {
      record.tween.cancel();
      record.tween = null;
    }

    finishItemTransitionToList(record.item, record.dest, record.index);
  }

  /**
   * Immediately settle every in-flight item into its destination list.
   */
  function completeAllTransitions():Void
  {
    if (pendingTransitions.length == 0) return;
    for (record in pendingTransitions.copy())
    {
      completeTransition(record);
    }
  }

  /**
   * How many items are currently flying into `dest` (pending transitions whose destination
   * is that list).
   */
  function incomingCount(dest:ModMenuItemList):Int
  {
    var count:Int = 0;
    for (record in pendingTransitions)
    {
      if (record.dest == dest) count++;
    }
    return count;
  }

  // OVERRIDES //

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
      var destPath = PolymodHandler.MOD_FOLDER + '/' + fileName + '.zip';

      try
      {
        FileUtil.moveFile(path, destPath);
      }
      catch (e:Dynamic)
      {
        trace('Failed to move file: ' + e);
        WindowUtil.showError('Failed to move file (PLACEHOLDER)', 'Could not move zip file to mods folder. Check logs for details.');
        return;
      }

      var newItems = refreshModList();
      for (item in newItems)
      {
        if (item.mod != null)
        {
          item.flashBackground();
          break;
        }
      }

      handleSelection();
    }
    else if (Path.isAbsolute(path) && FileUtil.directoryExists(path))
    {
      if (!FileUtil.pathExists(Path.join([path, PolymodConfig.modMetadataFile])))
      {
        WindowUtil.showError('Failed to move folder (PLACEHOLDER)', 'Could not find polymod metadata inside the folder, are you sure this is a mod pack?');
        return;
      }

      try
      {
        FileUtil.copyDirectory(path, Path.join([PolymodHandler.MOD_FOLDER, Path.withoutDirectory(path)]));
      }
      catch (e:Dynamic)
      {
        trace('Failed to move folder: ' + e);
        WindowUtil.showError('Failed to move folder (PLACEHOLDER)', 'Could not move folder to mods folder. Check logs for details.');
        return;
      }

      var newItems = refreshModList();
      for (item in newItems)
      {
        if (item.mod != null)
        {
          item.flashBackground();
          break;
        }
      }

      handleSelection();
    }
    else
      WindowUtil.showWarning('Invalid file type (PLACEHOLDER)', 'Only .zip files are supported for mod installation.');
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
      darkness.alpha = FlxMath.lerp(0, 0.72, FlxEase.backOut(adjustT));
    }

    handleKeyboard();
  }

  function hasTransitions():Bool
  {
    return pendingTransitions.length > 0;
  }


  // INPUT //

  function handleMouse():Void
  {
    if (hasTransitions()) return;

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
      }
      else if (buttonDone.overlapsPoint(target))
      {
        applyModlist();
      }
    }
  }

  var holdDirection:Int = 0; // -1 for up, 1 for down, -2 for left, 2 for right
  var holdTimer:Float = 0;
  var doHoldAction:Bool = false;
  var delay:Float = 0;
  var acceptDelay:Float = 0;
  var oldSelection:ModMenuSelection;
  var lastInput:String = '';

  function handleKeyboard():Void
  {
    if (hasTransitions()) return;

    var pressingCtrl:Bool = FlxG.keys.pressed.CONTROL;
    if (controls.BACK_P)
    {
      backToMainMenu();
    }

    oldSelection = selection;

    if (controls.UI_UP || controls.UI_DOWN || controls.UI_LEFT || controls.UI_RIGHT)
    {
      if (holdDirection == 0)
      {
        holdDirection = controls.UI_UP ? -1 : controls.UI_DOWN ? 1 : controls.UI_LEFT ? -2 : 2;
        holdTimer = 0.5; // initial delay before starting to scroll
      }
      else if
        ((controls.UI_UP && holdDirection == -1)
          || (controls.UI_DOWN && holdDirection == 1)
          || (controls.UI_LEFT && holdDirection == -2)
          || (controls.UI_RIGHT && holdDirection == 2)
        )
      {
        holdTimer -= FlxG.elapsed;
        if (holdTimer <= 0)
        {
          doHoldAction = true;
        }
      }
    }
    else
    {
      holdDirection = 0;
      doHoldAction = false;
    }

    if (doHoldAction && delay <= 0)
    {
      delay = 0.1;
      switch (selection)
      {
        case DisabledModList:
          switch (holdDirection)
          {
            case -1:
              disabledModItems.moveUp();
            case 1:
              disabledModItems.moveDown();
            case -2:
              selection = Done;
              lastSelectDir = -2;
            case 2:
              selection = EnabledModList;
              lastSelectDir = 2;
          }
        case EnabledModList:
          switch (holdDirection)
          {
            case -1:
              enabledModItems.moveUp();
            case 1:
              enabledModItems.moveDown();
            case -2:
              if (disabledModItems.modItems.length > 0) selection = DisabledModList;
              else
                selection = Done;
              lastSelectDir = -2;
            case 2:
              selection = OpenModsFolder;
              lastSelectDir = 2;
          }
        case OpenModsFolder:
          switch (holdDirection)
          {
            case -1:
              selection = DisabledModList;
              lastSelectDir = -1;
            case 1:
              selection = DisabledModList;
              lastSelectDir = 1;
            case -2:
              selection = EnabledModList;
              lastSelectDir = -2;
            case 2:
              selection = Done;
              lastSelectDir = 2;
          }
        case Done:
          switch (holdDirection)
          {
            case -1:
              selection = EnabledModList;
              lastSelectDir = -1;
            case 1:
              selection = EnabledModList;
              lastSelectDir = 1;
            case -2:
              selection = OpenModsFolder;
              lastSelectDir = -2;
            case 2:
              selection = DisabledModList;
              lastSelectDir = 2;
          }
        case BackToMenu:
          // Do nothing
      }
    }
    if (delay > 0) delay -= FlxG.elapsed;

    if (controls.UI_LEFT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          selection = Done;
          lastSelectDir = -2;
        case EnabledModList:
          if (disabledModItems.modItems.length > 0)
          {
            selection = DisabledModList;
            lastSelectDir = -2;
          }
          else selection = OpenModsFolder;
        case OpenModsFolder:
          selection = EnabledModList;
          lastSelectDir = -2;
        case Done:
          selection = OpenModsFolder;
          lastSelectDir = -2;
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.UI_RIGHT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          if (enabledModItems.modItems.length > 0)
          {
            selection = EnabledModList;
            lastSelectDir = 2;
          }
        case EnabledModList:
          selection = OpenModsFolder;
          lastSelectDir = 2;
        case OpenModsFolder:
          selection = Done;
          lastSelectDir = 2;
        case Done:
          selection = DisabledModList;
          lastSelectDir = 2;
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.UI_UP_P)
    {
      lastInput = 'up';
      switch (selection)
      {
        case DisabledModList:
          if (!disabledModItems.moveUp(false))
          {
            selection = OpenModsFolder;
            lastSelectDir = -1;
          }
        case EnabledModList:
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, true);
          else
          {
            if (!enabledModItems.moveUp(false))
            {
              selection = Done;
              lastSelectDir = -1;
            }
          }
        case OpenModsFolder:
          selection = DisabledModList;
          lastSelectDir = -1;
        case Done:
          selection = EnabledModList;
          lastSelectDir = -1;
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.UI_DOWN_P)
    {
      lastInput = 'down';
      switch (selection)
      {
        case DisabledModList:
          if (!disabledModItems.moveDown(false))
          {
            selection = OpenModsFolder;
            lastSelectDir = 1;
          }
        case EnabledModList:
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, false);
          else
          {
            if (!enabledModItems.moveDown(false))
            {
              selection = Done;
              lastSelectDir = 1;
            }
          }
        case OpenModsFolder:
          selection = DisabledModList;
          lastSelectDir = 1;
        case Done:
          selection = EnabledModList;
          lastSelectDir = 1;
        case BackToMenu:
          // Do nothing
      }
    }

    if (controls.ACCEPT_P && !hasTransitions() && acceptDelay <= 0)
    {
      enabledModItems.repositionItems();
      disabledModItems.repositionItems();

      switch (selection)
      {
        case DisabledModList:
          enableMod(disabledModItems.selectedModItem);
        case EnabledModList:
          disableMod(enabledModItems.selectedModItem);
        case BackToMenu:
          backToMainMenu();
        case OpenModsFolder:
          openFolderAnimator.playAnimation('accept');
          openFolderAnimator.onFinish = openModsFolder;
        case Done:
          doneButtonAnimator.playAnimation('accept');
          doneButtonAnimator.onFinish = applyModlist;
      }

      oldSelection = selection;

      // Mashing causes a weird bug where the item gets set to the top left of the disabled list.
      // Most defn a bug with local coordinates vs world coordinates in FunkinGroup, couldn't figure out how to fix it though!
      acceptDelay = 0.08;
    }

    if (acceptDelay > 0) acceptDelay -= FlxG.elapsed;

    if (oldSelection != selection) handleSelection();
  }

  function handleSelection():Void
  {
    disabledModItems.deselect();
    enabledModItems.deselect();

    if (openFolderAnimator.curAnim == 'select' && selection != OpenModsFolder) openFolderAnimator.playAnimation('deselect');
    if (doneButtonAnimator.curAnim == 'select' && selection != Done) doneButtonAnimator.playAnimation('deselect');

    if (disabledModItems.modItems.length == 0 && selection == DisabledModList) selection = EnabledModList;

    switch (selection)
    {
      case DisabledModList:
        if (oldSelection == OpenModsFolder && lastInput == 'up') disabledModItems.selectLastItem(lastSelectDir);
        else
          disabledModItems.selectFirstItem(lastSelectDir);
      case EnabledModList:
        if (oldSelection == OpenModsFolder && lastInput == 'up') enabledModItems.selectLastItem(lastSelectDir);
        else
          enabledModItems.selectFirstItem(lastSelectDir);
      case OpenModsFolder:
        openFolderAnimator.playAnimation('select');
      case Done:
        doneButtonAnimator.playAnimation('select');
      case BackToMenu:
        // Do nothing
    }

    lastInput = '';
    lastSelectDir = 0;
  }

  // MOD LIST BUILDING //

  var tempDisabledMods:Array<ModMetadata> = [];
  var tempEnabledMods:Array<ModMetadata> = [];

  function refreshModList():Array<ModMenuItem>
  {
    PolymodHandler.getAllMods(true);

    tempDisabledMods = disabledModItems.modItems.map((item) -> item.mod);
    tempEnabledMods = enabledModItems.modItems.map((item) -> item.mod).filter((m) -> m != null && m.id != BASE_GAME_MOD_ID);

    var oldSelectedId:Null<String> = null;
    if (selection == DisabledModList && disabledModItems.selectedModItem != null) oldSelectedId = disabledModItems.selectedModItem.getModId();
    else if (selection == EnabledModList && enabledModItems.selectedModItem != null) oldSelectedId = enabledModItems.selectedModItem.getModId();

    var newItems = buildDisabledModList();
    buildEnabledModList();

    tempDisabledMods = [];
    tempEnabledMods = [];

    // reselect items if possible, otherwise select first item in the list

    if (oldSelectedId != null)
    {
      if (selection == DisabledModList)
      {
        var itemToSelect = disabledModItems.modItems.find((item) -> item.getModId() == oldSelectedId);
        if (itemToSelect != null) disabledModItems.selectModItem(itemToSelect);
        else
          disabledModItems.selectFirstItem();
      }
      else if (selection == EnabledModList)
      {
        var itemToSelect = enabledModItems.modItems.find((item) -> item.getModId() == oldSelectedId);
        if (itemToSelect != null) enabledModItems.selectModItem(itemToSelect);
        else
          enabledModItems.selectFirstItem();
      }
    }
    else
    {
      if (selection == DisabledModList) disabledModItems.selectFirstItem();
      else if (selection == EnabledModList) enabledModItems.selectFirstItem();
    }

    disabledModItems.repositionItems();
    enabledModItems.repositionItems();

    return newItems;
  }

  function buildDisabledModList():Array<ModMenuItem>
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledMods();
    var newModId:Array<String> = [];

    if (tempDisabledMods.length > 0 || tempEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = tempDisabledMods.concat(tempEnabledMods).map((m) -> m.id);
      var reconciled:Array<ModMetadata> = tempDisabledMods.copy();

      for (mod in disabledMods)
      {
        if (!allKnownIds.contains(mod.id))
        {
          reconciled.push(mod);
          newModId.push(mod.id);
        }
      }

      for (mod in PolymodHandler.getEnabledMods())
      {
        if (mod.id == BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id))
        {
          reconciled.push(mod);
          newModId.push(mod.id);
        }
      }

      disabledMods = reconciled;
    }

    disabledModItems.removeAll();
    disabledModItems.title = 'DISABLED';
    disabledModItems.x = leftRectangle.x;
    disabledModItems.y = leftRectangle.y;

    for (mod in disabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      disabledModItems.addMod(mod);
    }

    var newItems:Array<ModMenuItem> = [];
    for (modId in newModId)
    {
      var item = disabledModItems.modItems.find((it) -> it.getModId() == modId);
      if (item != null) newItems.push(item);
    }
    return newItems;
  }

  function buildEnabledModList():Void
  {
    var enabledMods:Array<ModMetadata> = PolymodHandler.getEnabledMods();

    if (tempDisabledMods.length > 0 || tempEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = tempDisabledMods.concat(tempEnabledMods).map((m) -> m.id);

      var reconciled:Array<ModMetadata> = tempEnabledMods.copy();

      for (mod in enabledMods)
      {
        if (mod.id == BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id)) reconciled.push(mod);
      }

      enabledMods = reconciled;
    }

    enabledModItems.removeAll();
    enabledModItems.title = 'ENABLED';
    enabledModItems.x = rightRectangle.x;
    enabledModItems.y = rightRectangle.y;

    for (mod in enabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      enabledModItems.addMod(mod);
    }

    if (enabledModItems.modItems.exists((item) -> item.getModId() == BASE_GAME_MOD_ID))
    {
      // make sure its not selected (weird ass bug)
      var baseGameItem = enabledModItems.modItems.find((item) -> item.getModId() == BASE_GAME_MOD_ID);
      if (baseGameItem != null) baseGameItem.selected = false;
      return;
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

    transitionOut(() ->
    {
      var blackScreen = new FunkinSprite();
      blackScreen.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
      blackScreen.scrollFactor.set(0, 0);
      blackScreen.alpha = 1;
      add(blackScreen);

      PolymodHandler.forceReloadAssets();
      if (InitState.customTitleState == null) FlxG.switchState(() -> new TitleState());
      else
      {
        FlxG.switchState(() -> InitState.customTitleState);
      }
    });
  }

  function enableMod(item:Null<ModMenuItem>, ?forcedInsertIndex:Int = -1, ?batchFutureCount:Int = -1):Void
  {
    if (item == null) return;
    if (!disabledModItems.modItems.contains(item)) return;
    if (item.getModId() == BASE_GAME_MOD_ID) return;

    item.selected = false;

    var dependenciesToEnable:Array<String> = checkDependencies(item.mod);
    trace('Dependencies to enable for ${item.getModTitle()}: ${dependenciesToEnable}');

    // Top-level call locks the denominator for the whole batch (this mod + all the
    // deps that fly with it), so every flying item animates to the SAME final layout.
    if (batchFutureCount == -1)
    {
      batchFutureCount = enabledModItems.modItems.length + countEnableBatch(item, []);
    }

    var originalInsertIndex:Int = forcedInsertIndex;

    if (originalInsertIndex == -1)
    {
      originalInsertIndex = enabledModItems.modItems.length;
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
              originalInsertIndex = enabledModItems.modItems.indexOf(enabledMod);
              b = true;
              break;
            }
          }
          if (b) break;
        }
      }
    }

    var nextInsertIndex = originalInsertIndex;
    for (dependencyId in dependenciesToEnable)
    {
      var dependencyItem = disabledModItems.modItems.find((it) -> it.getModId() == dependencyId);
      if (dependencyItem != null)
      {
        enableMod(dependencyItem, nextInsertIndex, batchFutureCount); // share denominator
        nextInsertIndex++;
      }
      else
      {
        trace('Error: Dependency ${dependencyId} for mod ${item.getModTitle()} not found!');
        return;
      }
    }

    var oldIndex:Int = disabledModItems.modItems.indexOf(item);
    var srcLocalX:Float = ModMenuItemList.ITEM_X_OFFSET;
    var srcLocalY:Float = disabledModItems.getModItemYPos(oldIndex) + disabledModItems.scrollOffset;
    var worldX:Float = disabledModItems.x + srcLocalX;
    var worldY:Float = disabledModItems.y + srcLocalY;
    disabledModItems.removeModWithoutLayout(item);

    var insertIndex:Int = originalInsertIndex;

    putItemInTransitionLayer(item, worldX, worldY);

    var finalIndex:Int = insertIndex;
    for (record in pendingTransitions)
    {
      if (record.dest == enabledModItems && record.index <= finalIndex) finalIndex++;
    }

    var inFlight:Int = incomingCount(enabledModItems);

    enabledModItems.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = enabledModItems.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = enabledModItems.y + enabledModItems.getModItemYPosForCount(finalIndex, batchFutureCount) + enabledModItems.scrollOffset;

    enabledModItems.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, 0.28, FlxEase.quartOut);
    disabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
    startItemTransition(item, targetX, targetY, enabledModItems, finalIndex);

    enabledModItems.selectModItem(item, false);

    if (disabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, disabledModItems.modItems.length - 1));
      disabledModItems.selectModItem(disabledModItems.modItems[newIndex], false);
      selection = DisabledModList;
    }
    else
    {
      selection = EnabledModList;
    }
  }

  function disableMod(item:Null<ModMenuItem>, ?batchFutureCount:Int = -1):Void
  {
    if (item == null) return;

    if (!enabledModItems.modItems.contains(item)) return;
    if (enabledModItems.isPinnedItem(item) || item.locked) return;

    item.selected = false;

    if (batchFutureCount == -1)
    {
      batchFutureCount = disabledModItems.modItems.length + countDisableBatch(item, []);
    }

    // Disable any mods that depend on this mod as well.
    var brokenDependencies = validateDependencies(item.mod);
    trace('Broken dependencies for ${item.getModTitle()}: ${brokenDependencies}');
    for (dependencyTitle in brokenDependencies)
    {
      var dependencyItem = enabledModItems.modItems.find((it) -> it.getModTitle() == dependencyTitle);
      if (dependencyItem != null)
      {
        trace('Disabling ${dependencyItem.getModTitle()} since it depends on ${item.getModTitle()}');
        disableMod(dependencyItem, batchFutureCount); // share denominator
      }
    }

    var oldIndex:Int = enabledModItems.modItems.indexOf(item);
    var srcLocalX:Float = ModMenuItemList.ITEM_X_OFFSET;
    var srcLocalY:Float = enabledModItems.getModItemYPos(oldIndex) + enabledModItems.scrollOffset;
    var worldX:Float = enabledModItems.x + srcLocalX;
    var worldY:Float = enabledModItems.y + srcLocalY;
    enabledModItems.removeModWithoutLayout(item);

    putItemInTransitionLayer(item, worldX, worldY);

    // Always insert at the top of the disabled list; order there doesn't matter.
    var destIndex:Int = disabledModItems.modItems.length;

    var finalIndex:Int = destIndex;
    for (record in pendingTransitions)
    {
      if (record.dest == disabledModItems && record.index <= finalIndex) finalIndex++;
    }

    var inFlight:Int = incomingCount(disabledModItems);

    disabledModItems.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = disabledModItems.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = disabledModItems.y + disabledModItems.getModItemYPosForCount(finalIndex, batchFutureCount) + disabledModItems.scrollOffset;

    disabledModItems.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, 0.28, FlxEase.quartOut);
    enabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
    startItemTransition(item, targetX, targetY, disabledModItems, finalIndex);

    disabledModItems.selectModItem(item, false);

    if (enabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, enabledModItems.modItems.length - 1));
      enabledModItems.selectModItem(enabledModItems.modItems[newIndex], false);
      selection = EnabledModList;
    }
    else
    {
      selection = DisabledModList;
    }
  }

  function nudgeBlocked(item:ModMenuItem, moveUp:Bool):Void
  {
    var index:Int = enabledModItems.modItems.indexOf(item);
    if (index < 0) return;

    var restY:Float = enabledModItems.getModItemYPos(index) + enabledModItems.scrollOffset;

    FlxTween.cancelTweensOf(item);
    item.localX = ModMenuItemList.ITEM_X_OFFSET;
    item.localY = restY;

    var dir:Float = moveUp ? -1 : 1;
    FlxTween.tween(item, {
      localY: restY + dir * 14
    }, 0.07, {
      ease: FlxEase.quadOut,
      onComplete: _ -> FlxTween.tween(item, {
        localY: restY
      }, 0.12, {
        ease: FlxEase.quadOut
      })
    });
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

    if (index < minMovableIndex) return;
    if (minMovableIndex >= modList.length) return;

    var newIndex = moveUp ? index + 1 : index - 1;

    if (newIndex < minMovableIndex || newIndex >= modList.length)
    {
      nudgeBlocked(modItem, moveUp);
      return;
    }

    var otherModItem = modList[newIndex];

    var blocked:Bool = false;

    if (moveUp)
    {
      for (depId => version in modItem.getDependencies()) if (otherModItem.getModId() == depId)
      {
        blocked = true;
        break;
      }

      if (!blocked)
      {
        var otherOpt = otherModItem.getOptionalDependencies();
        if (otherOpt != null) for (depId => version in otherOpt) if (modItem.getModId() == depId && version.isSatisfiedBy(modItem.getModVersion()))
        {
          blocked = true;
          break;
        }
      }
    }
    else
    {
      for (depId => version in otherModItem.getDependencies()) if (modItem.getModId() == depId)
      {
        blocked = true;
        break;
      }

      if (!blocked)
      {
        var myOpt = modItem.getOptionalDependencies();
        if (myOpt != null) for (depId => version in myOpt) if (otherModItem.getModId() == depId && version.isSatisfiedBy(otherModItem.getModVersion()))
        {
          blocked = true;
          break;
        }
      }
    }

    if (blocked)
    {
      trace('Blocked reorder of ${modItem.getModTitle()} (dependency ordering)');
      nudgeBlocked(modItem, moveUp);
      return;
    }

    trace('Moving mod ${modItem.getModTitle()} from index $index to $newIndex');

    modList.splice(index, 1);
    modList.insert(newIndex, modItem);

    enabledModItems.deselectAll();
    enabledModItems.selectModItem(modItem);
    enabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
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
      if (
        !toEnable.contains(dependencyId)
        && !enabledModItems.modItems.exists((item) -> item.getModId() == dependencyId && version.isSatisfiedBy(item.getModVersion()))
      )
      {
        toEnable.push(dependencyId);
      }
    }

    return toEnable;
  }

  // HELPERS //

  /**
   * Recursively counts how many mods would be enabled if we enable this mod, including itself and all dependencies.
   * @param item
   * @param seen
   * @return Int
   */
  function countEnableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1;
    for (depId in checkDependencies(item.mod))
    {
      var depItem = disabledModItems.modItems.find((it) -> it.getModId() == depId);
      if (depItem != null) total += countEnableBatch(depItem, seen);
    }
    return total;
  }

  /**
   * Recursively counts how many mods would be disabled if we disable this mod, including itself and all dependents.
   * @param item
   * @param seen
   * @return Int
   */
  function countDisableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null || item.mod == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1; // this item
    for (depTitle in validateDependencies(item.mod))
    {
      var depItem = enabledModItems.modItems.find((it) -> it.getModTitle() == depTitle);
      if (depItem != null) total += countDisableBatch(depItem, seen);
    }
    return total;
  }

  function distanceToPoint(point1:FlxPoint, point2:FlxPoint):Float
  {
    var dx = point1.x - point2.x;
    var dy = point1.y - point2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Open the folder where the user's mods are stored.
   */
  function openModsFolder():Void
  {
    FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
    openFolderAnimator.playAnimation('select');
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

/**
 * Typedef for tracking an item that's currently in-flight in the transition layer.
 */
typedef TransitionRecord =
{
  var item:ModMenuItem;
  var dest:ModMenuItemList;
  var index:Int;
  var tween:Null<flixel.tweens.FlxTween>;
}
