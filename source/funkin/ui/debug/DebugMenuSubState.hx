package funkin.ui.debug;

import flixel.FlxObject;
import flixel.FlxSprite;
import funkin.MusicBeatSubstate;
import funkin.ui.TextMenuList;
import funkin.ui.debug.charting.ChartEditorState;

class DebugMenuSubState extends MusicBeatSubstate
{
  var items:TextMenuList;

  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;

  override function create()
  {
    super.create();

    // Create an object for the camera to track.
    camFocusPoint = new FlxObject(0, 0);
    add(camFocusPoint);

    // Follow the camera focus as we scroll.
    FlxG.camera.follow(camFocusPoint, null, 0.06);

    // Create the green background.
    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    menuBG.color = 0xFF4CAF50;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    // Create the list for menu items.
    items = new TextMenuList();
    // Move the camera when the menu is scrolled.
    items.onChange.add(onMenuChange);
    add(items);

    // Create each menu item.
    // Call onMenuChange when the first item is created to move the camera .
    onMenuChange(createItem("CHART EDITOR", openChartEditor));
    createItem("ANIMATION EDITOR", openAnimationEditor);
    createItem("STAGE EDITOR", openStageEditor);
  }

  function onMenuChange(selected:TextMenuItem)
  {
    camFocusPoint.setPosition(selected.x + selected.width / 2, selected.y + selected.height / 2);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      exitDebugMenu();
    }
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  function openChartEditor()
  {
    FlxG.switchState(new ChartEditorState());
  }

  function openAnimationEditor()
  {
    FlxG.switchState(new funkin.ui.animDebugShit.DebugBoundingState());
    trace('Animation Editor');
  }

  function openStageEditor()
  {
    trace('Stage Editor');
  }

  function exitDebugMenu()
  {
    // TODO: Add a transition?
    this.close();
  }
}
