package funkin.ui.options;

import funkin.util.InputUtil;
import flixel.FlxCamera;
import flixel.FlxObject;
import funkin.graphics.FunkinCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import funkin.graphics.FunkinSprite;
import funkin.input.Controls.Device;
import funkin.input.Controls.Control;
import funkin.ui.AtlasText;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.TextMenuList;
import funkin.ui.Page;
#if FEATURE_TOUCH_CONTROLS
import funkin.mobile.ui.FunkinBackButton;
#end

class ControlsMenu extends Page<OptionsState.OptionsMenuPageName>
{
  public static inline final COLUMNS = 2;
  static var controlList = Control.createAll();
  /*
   * Defines groups of controls that cannot share inputs, like left and right. Say, if ACCEPT is Z, Back is X,
   * if the player sets Back to Z it also set ACCEPT to X. This prevents the player from setting the controls in
   * a way the prevents them from changing more controls or exiting the menu.
   */
  static var controlGroups:Array<Array<Control>> = [
    [NOTE_UP, NOTE_DOWN, NOTE_LEFT, NOTE_RIGHT],
    [UI_UP, UI_DOWN, UI_LEFT, UI_RIGHT, ACCEPT, BACK],
    [CUTSCENE_ADVANCE],
    [FREEPLAY_FAVORITE, FREEPLAY_LEFT, FREEPLAY_RIGHT, FREEPLAY_CHAR_SELECT],
    [WINDOW_FULLSCREEN, #if FEATURE_SCREENSHOTS WINDOW_SCREENSHOT, #end],
    [VOLUME_UP, VOLUME_DOWN, VOLUME_MUTE],
    [
      #if FEATURE_DEBUG_MENU DEBUG_MENU, #end
      #if FEATURE_CHART_EDITOR DEBUG_CHART, #end
      #if FEATURE_STAGE_EDITOR DEBUG_STAGE, #end
    ]
  ];

  var itemGroups:Array<Array<InputItem>> = [for (i in 0...controlGroups.length) []];

  var controlGrid:MenuTypedList<InputItem>;
  var deviceList:TextMenuList;
  var menuCamera:FlxCamera;
  var prompt:Prompt;
  var popup:Prompt;
  var camFollow:FlxObject;
  var labels:FlxTypedGroup<AtlasText>;

  var currentDevice:Device = Keys;
  var deviceListSelected:Bool = false;

  var actionPrevented:Bool = false;

  static final CONTROL_BASE_X = 50;
  static final CONTROL_MARGIN_X = 700;
  static final CONTROL_SPACING_X = 300;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('controlsMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;
    camera = menuCamera;

    labels = new FlxTypedGroup<AtlasText>();
    var headers:FlxTypedGroup<AtlasText> = new FlxTypedGroup<AtlasText>();
    controlGrid = new MenuTypedList(Columns(COLUMNS), Vertical);

    add(labels);
    add(headers);
    add(controlGrid);

    if (FlxG.gamepads.numActiveGamepads > 0)
    {
      var devicesBg:FunkinSprite = new FunkinSprite();
      devicesBg.makeSolidColor(FlxG.width, 100, 0xFFFAFD6D);
      add(devicesBg);
      deviceList = new TextMenuList(Horizontal, None);
      add(deviceList);
      deviceListSelected = true;

      var item:TextMenuItem;

      item = deviceList.createItem('Keyboard', AtlasFont.BOLD, selectDevice.bind(Keys));
      item.x = FlxG.width / 2 - item.width - 30;
      item.y = (devicesBg.height - item.height) / 2;

      item = deviceList.createItem('Gamepad', AtlasFont.BOLD, selectDevice.bind(Gamepad(FlxG.gamepads.firstActive.id)));
      item.x = FlxG.width / 2 + 30;
      item.y = (devicesBg.height - item.height) / 2;
    }

    // FlxG.debugger.drawDebug = true;
    var y = deviceList == null ? 30 : 120;
    var spacer = 70;
    var currentHeader:String = null;
    // list order is determined by enum order
    for (i in 0...controlList.length)
    {
      var control = controlList[i];
      var name = control.getName();
      if (currentHeader != "UI_" && name.indexOf("UI_") == 0)
      {
        currentHeader = "UI_";
        headers.add(new AtlasText(0, y, "UI", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "NOTE_" && name.indexOf("NOTE_") == 0)
      {
        currentHeader = "NOTE_";
        headers.add(new AtlasText(0, y, "NOTES", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "CUTSCENE_" && name.indexOf("CUTSCENE_") == 0)
      {
        currentHeader = "CUTSCENE_";
        headers.add(new AtlasText(0, y, "CUTSCENE", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "FREEPLAY_" && name.indexOf("FREEPLAY_") == 0)
      {
        currentHeader = "FREEPLAY_";
        headers.add(new AtlasText(0, y, "FREEPLAY", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "WINDOW_" && name.indexOf("WINDOW_") == 0)
      {
        currentHeader = "WINDOW_";
        headers.add(new AtlasText(0, y, "WINDOW", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "VOLUME_" && name.indexOf("VOLUME_") == 0)
      {
        currentHeader = "VOLUME_";
        headers.add(new AtlasText(0, y, "VOLUME", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }
      else if (currentHeader != "DEBUG_" && name.indexOf("DEBUG_") == 0)
      {
        currentHeader = "DEBUG_";
        headers.add(new AtlasText(0, y, "DEBUG", AtlasFont.BOLD)).screenCenter(X);
        y += spacer;
      }

      if (currentHeader != null && name.indexOf(currentHeader) == 0) name = name.substr(currentHeader.length);

      var formatName = name.replace('_', ' ');
      var label = labels.add(new AtlasText(Math.max(FullScreenScaleMode.gameNotchSize.x, CONTROL_BASE_X), y, formatName, AtlasFont.BOLD));
      label.alpha = 0.6;
      for (i in 0...COLUMNS)
        createItem(label.x + CONTROL_MARGIN_X + i * CONTROL_SPACING_X, y, control, i);

      y += spacer;
    }

    camFollow = new FlxObject(FlxG.width / 2, 0, 70, 70);
    if (deviceList != null)
    {
      camFollow.y = deviceList.selectedItem.y;
      controlGrid.selectedItem.idle();
      controlGrid.enabled = false;
    }
    else
      camFollow.y = controlGrid.selectedItem.y;

    menuCamera.follow(camFollow, null, 0.06);
    var margin = 100;
    menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    menuCamera.minScrollY = 0;
    controlGrid.onChange.add(function(selected) {
      camFollow.y = selected.y;

      labels.forEach((label) -> label.alpha = 0.6);
      labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 1.0;
    });

    prompt = new Prompt("\nPress any key to rebind\n\n\nBackspace to unbind\n    Escape to cancel", None);
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFfafd6d);
    prompt.back.scrollFactor.set(0, 0);
    prompt.exists = false;
    add(prompt);

    popup = new Prompt("\nYou cannot unbind\nthat key!\n\n\nEscape to exit", None);
    popup.create();
    popup.createBgFromMargin(100, 0xFFfafd6d);
    popup.back.scrollFactor.set(0, 0);
    popup.exists = false;
    add(popup);

    #if FEATURE_TOUCH_CONTROLS
    var backButton:FunkinBackButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, function():Void {
      if (controlGrid.enabled && deviceList != null && deviceListSelected == false)
      {
        goToDeviceList();
      }
      else if (canExit)
      {
        exit();
      }
    }, 1.0);
    add(backButton);
    #end
  }

  function createItem(x = 0.0, y = 0.0, control:Control, index:Int)
  {
    var item = new InputItem(x, y, currentDevice, control, index, onSelect);
    for (i in 0...controlGroups.length)
    {
      if (controlGroups[i].contains(control)) itemGroups[i].push(item);
    }

    return controlGrid.addItem(item.name, item);
  }

  function onSelect():Void
  {
    switch (currentDevice)
    {
      case Keys:
        {
          keyUsedToEnterPrompt = FlxG.keys.firstJustPressed();
        }
      case Gamepad(id):
        {
          buttonUsedToEnterPrompt = FlxG.gamepads.getByID(id).firstJustPressedID();
        }
    }

    controlGrid.enabled = false;
    canExit = false;
    prompt.exists = true;
  }

  function createPopup():Void
  {
    canExit = false;
    popup.exists = true;
  }

  function goToDeviceList():Void
  {
    controlGrid.selectedItem.idle();
    labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 0.6;
    controlGrid.enabled = false;
    deviceList.enabled = true;
    canExit = true;
    camFollow.y = deviceList.selectedItem.y;
    deviceListSelected = true;
  }

  function selectDevice(device:Device):Void
  {
    currentDevice = device;

    for (item in controlGrid.members)
      item.updateDevice(currentDevice);

    var inputName = device == Keys ? "key" : "button";
    var cancel = device == Keys ? "Escape" : "Back";
    // todo: alignment
    if (device == Keys)
    {
      prompt.setText('\nPress any key to rebind\n\n\n\n    $cancel to cancel');
      popup.setText('\nYou cannot unbind\nthat key!\n\n\n$cancel to exit');
    }
    else
    {
      prompt.setText('\nPress any button\n   to rebind\n\n\n $cancel to cancel');
      popup.setText('\nYou cannot unbind\nthat button!\n\n\n$cancel to exit');
    }

    controlGrid.selectedItem.select();
    labels.members[Std.int(controlGrid.selectedIndex / COLUMNS)].alpha = 1.0;
    controlGrid.enabled = true;
    deviceList.enabled = false;
    deviceListSelected = false;
    canExit = false;
  }

  var keyUsedToEnterPrompt:Null<Int> = null;
  var buttonUsedToEnterPrompt:Null<Int> = null;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    var controls = PlayerSettings.player1.controls;
    if (controlGrid.enabled && deviceList != null && deviceListSelected == false && controls.BACK) goToDeviceList();

    if (prompt.exists)
    {
      switch (currentDevice)
      {
        case Keys:
          {
            // Um?
            // Checking pressed causes problems when you change the BACK key,
            // but checking released causes problems when the prompt is instant.

            // keyUsedToEnterPrompt is my weird workaround.

            var key = FlxG.keys.firstJustReleased();
            if (key != NONE && key != keyUsedToEnterPrompt)
            {
              if (key == ESCAPE)
              {
                closePrompt();
              }
              else if (key == BACKSPACE)
              {
                onInputSelect(NONE);
                closePrompt();
              }
              else
              {
                onInputSelect(key);
                closePrompt();
              }
            }
          }
        case Gamepad(id):
          {
            var button = FlxG.gamepads.getByID(id).firstJustReleasedID();
            if (button != NONE && button != buttonUsedToEnterPrompt)
            {
              if (button != BACK) onInputSelect(button);
              closePrompt();
            }

            var key = FlxG.keys.firstJustReleased();
            if (key != NONE && key != keyUsedToEnterPrompt)
            {
              if (key == ESCAPE)
              {
                closePrompt();
              }
              else if (key == BACKSPACE)
              {
                onInputSelect(NONE);
                closePrompt();
              }
            }
          }
      }
    }

    if (actionPrevented && !popup.exists) createPopup();

    if (popup.exists)
    {
      switch (currentDevice)
      {
        case Keys:
          {
            var key = FlxG.keys.firstJustReleased();
            if (key == ESCAPE) closePopup();
          }
        case Gamepad(id):
          {
            var button = FlxG.gamepads.getByID(id).firstJustReleasedID();
            if (button == BACK) closePopup();

            var key = FlxG.keys.firstJustReleased();
            if (key == ESCAPE) closePopup();
          }
      }
    }

    switch (currentDevice)
    {
      case Keys:
        {
          var keyJustReleased:Int = FlxG.keys.firstJustReleased();
          if (keyJustReleased != NONE && keyJustReleased == keyUsedToEnterPrompt)
          {
            keyUsedToEnterPrompt = null;
          }
          buttonUsedToEnterPrompt = null;
        }
      case Gamepad(id):
        {
          var buttonJustReleased:Int = FlxG.gamepads.getByID(id).firstJustReleasedID();
          if (buttonJustReleased != NONE && buttonJustReleased == buttonUsedToEnterPrompt)
          {
            buttonUsedToEnterPrompt = null;
          }
          keyUsedToEnterPrompt = null;
        }
    }
  }

  function onInputSelect(input:Int):Void
  {
    var item = controlGrid.selectedItem;
    var leftItem = controlGrid.members[controlGrid.selectedIndex - 1];
    var rightItem = controlGrid.members[controlGrid.selectedIndex + 1];

    // check if all keybinds are being removed and this is a UI control, prevent removing last keybind for this
    if (input == FlxKey.NONE && controlGrid.selectedIndex != 1 && rightItem.input == FlxKey.NONE)
    {
      for (group in itemGroups)
      {
        if (group.toString() == itemGroups[1].toString() && group.contains(item)) actionPrevented = true;
      }
    }

    if (actionPrevented) return;

    // check if that key is already set for this
    if (input != FlxKey.NONE)
    {
      var column0 = Math.floor(controlGrid.selectedIndex / 2) * 2;
      for (i in 0...COLUMNS)
      {
        if (controlGrid.members[column0 + i].input == input) return;
      }
    }

    // Check if items in the same group already have the new input
    for (group in itemGroups)
    {
      if (input != FlxKey.NONE && group.contains(item))
      {
        for (otherItem in group)
        {
          if (otherItem != item && otherItem.input == input)
          {
            // replace that input with this items old input.
            PlayerSettings.player1.controls.replaceBinding(otherItem.control, currentDevice, item.input, otherItem.input);
            // Don't use resetItem() since items share names/labels
            otherItem.input = item.input;
            otherItem.label.text = item.label.text;
          }
        }
      }
    }

    PlayerSettings.player1.controls.replaceBinding(item.control, currentDevice, input, item.input);

    // Don't use resetItem() since items share names/labels
    item.input = input;
    item.label.text = item.getLabel(input);

    // Shift left on the grid if the item on the right is bound and the item on the left is unbound.
    if (controlGrid.selectedIndex % 2 == 1)
    {
      trace('Modified item on right side of grid');
      if (leftItem != null && input != FlxKey.NONE && leftItem.input == FlxKey.NONE)
      {
        trace('Left item is unbound and right item is not!');
        // Swap them.
        var temp = leftItem.input;
        leftItem.input = item.input;
        item.input = temp;

        leftItem.label.text = leftItem.getLabel(leftItem.input);
        item.label.text = item.getLabel(item.input);
      }
    }
    else
    {
      trace('Modified item on left side of grid');
      if (rightItem != null && input == FlxKey.NONE && rightItem.input != FlxKey.NONE)
      {
        trace('Left item is unbound and right item is not!');
        // Swap them.
        var temp = item.input;
        item.input = rightItem.input;
        rightItem.input = temp;

        item.label.text = item.getLabel(item.input);
        rightItem.label.text = rightItem.getLabel(rightItem.input);
      }
    }

    PlayerSettings.player1.saveControls();
  }

  function closePrompt()
  {
    prompt.exists = false;
    controlGrid.enabled = true;
    if (deviceList == null) canExit = true;
  }

  function closePopup()
  {
    popup.exists = false;
    actionPrevented = false;
    if (deviceList == null) canExit = true;
  }

  override function destroy()
  {
    super.destroy();

    itemGroups = null;

    if (FlxG.cameras.list.contains(menuCamera)) FlxG.cameras.remove(menuCamera);
  }

  override function set_enabled(value:Bool)
  {
    if (value == false)
    {
      controlGrid.enabled = false;
      if (deviceList != null) deviceList.enabled = false;
    }
    else
    {
      controlGrid.enabled = !deviceListSelected;
      if (deviceList != null) deviceList.enabled = deviceListSelected;
    }
    return super.set_enabled(value);
  }
}

class InputItem extends TextMenuItem
{
  public var device(default, null):Device = Keys;
  public var control:Control;
  public var input:Int = -1;
  public var index:Int = -1;

  public function new(x = 0.0, y = 0.0, device, control, index, ?callback)
  {
    this.device = device;
    this.control = control;
    this.index = index;
    this.input = getInput();

    super(x, y, getLabel(input), DEFAULT, callback);

    this.fireInstantly = true;
  }

  public function updateDevice(device:Device)
  {
    if (this.device != device)
    {
      this.device = device;
      input = getInput();
      label.text = getLabel(input);
    }
  }

  function getInput()
  {
    var list = PlayerSettings.player1.controls.getInputsFor(control, device);
    list = list.distinct();
    if (list.length > index)
    {
      if (list[index] != FlxKey.ESCAPE || list[index] != FlxGamepadInputID.BACK) return list[index];

      if (list.length > ControlsMenu.COLUMNS) // Escape isn't mappable, show a third option, instead.
        return list[ControlsMenu.COLUMNS];
    }

    return -1;
  }

  public function getLabel(input:Int)
  {
    return input == FlxKey.NONE ? "---" : InputUtil.format(input, device);
  }
}
