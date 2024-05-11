package funkin.util.plugins;

import funkin.input.Controls;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalIFlxInput;
import funkin.input.Controls.Control;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.Assets;
import openfl.display.Sprite;
import flixel.FlxState;
import flixel.util.typeLimit.OneOfTwo;

/**
 * A plugin which adds on-screen buttons for mobile targets
 */
class VirtualGamepadPlugin extends FlxBasic // maybe OnSceenControlPlugin??
{
  var gamepad:VirtualGamepad;

  public var ignoreList:Array<Class<OneOfTwo<FlxState, FlxSubState>>> = [funkin.InitState, funkin.ui.title.TitleState]; // funkin.play.PlayState

  public function new()
  {
    super();
    FlxG.state.forEachOfType(VirtualGamepad, gamepad -> FlxG.state.remove(gamepad).destroy());
    if (!ignoreList.contains(Type.getClass(FlxG.state))) FlxG.state.add(gamepad = new VirtualGamepad());
    FlxG.signals.preStateSwitch.add(onPreStateSwitch);
    FlxG.signals.postStateSwitch.add(onPostStateSwitch);
  }

  function onPostStateSwitch()
  {
    if (!ignoreList.contains(Type.getClass(FlxG.state))) FlxG.state.add(gamepad = new VirtualGamepad());

    FlxG.state.subStateOpened.add(onSubStateOpened);
    FlxG.state.subStateClosed.add(onSubStateClosed);
  }

  function onPreStateSwitch()
  {
    FlxG.state.subStateOpened.remove(onSubStateOpened);
    FlxG.state.subStateClosed.remove(onSubStateClosed);
    // FlxTween.color(gamepad, 0.3, gamepad.color, FlxColor.TRANSPARENT);
  }

  function onSubStateClosed(subState:FlxSubState)
  {
    subState.remove(gamepad);
    if (!ignoreList.contains(Type.getClass(FlxG.state))) FlxG.state.add(gamepad);
  }

  function onSubStateOpened(subState:FlxSubState)
  {
    FlxG.state.remove(gamepad);
    if (!ignoreList.contains(Type.getClass(subState))) subState.add(gamepad);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new VirtualGamepadPlugin());
  }
}

@:access(funkin.input.Controls)
class VirtualGamepad extends FlxSpriteGroup
{
  var dPad:FlxTypedSpriteGroup<FlxButton>;
  var actions:FlxTypedSpriteGroup<FlxButton>;

  inline static var BUTTON_WIDTH:Int = 132;
  inline static var BUTTON_HEIGHT:Int = 135;

  static var referenceScreenSize = {width: 1280, height: 720};

  private var controls(get, never):Controls;

  inline function get_controls():Controls
    return PlayerSettings.player1?.controls;

  /**
   * A map containing which button means which key(s) are currently binded
   */
  public var bindingMap(default, null):Map<FlxButton, Array<Control>>;

  public static var defaultMapping:Map<ButtonType, Array<Control>> = [
    ButtonType.A => [Control.ACCEPT],
    ButtonType.B => [Control.BACK],
    ButtonType.C => [],
    ButtonType.DOWN => [Control.NOTE_DOWN, Control.UI_DOWN],
    ButtonType.LEFT => [Control.NOTE_LEFT, Control.UI_LEFT],
    ButtonType.RIGHT => [Control.NOTE_RIGHT, Control.UI_RIGHT],
    ButtonType.UP => [Control.NOTE_UP, Control.UI_UP],
    ButtonType.X => [],
    ButtonType.Y => []
  ];

  public override function new()
  {
    super();

    scrollFactor.set(0, 0);
    zIndex = 100000;

    add(dPad = new FlxTypedSpriteGroup<FlxButton>());
    add(actions = new FlxTypedSpriteGroup<FlxButton>());

    bindingMap = new Map();

    switchMode();
  }

  override function update(elapsed:Float)
  {
    // timed
    // setPosition(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
    super.update(elapsed);
  }

  public function switchMode(dPadMode:DPadMode = FULL, actionMode:ActionMode = A_B)
  {
    var screenWidth = referenceScreenSize.width;
    var screenHeight = referenceScreenSize.height;

    dPad.forEach((button) -> {
      removeButton(button);
    });

    actions.forEach((button) -> {
      removeButton(button);
    });

    unbind();

    switch (dPadMode)
    {
      case UP_DOWN:
        dPad.add(createButton(0, FlxG.height - 255, "up"));
        dPad.add(createButton(0, FlxG.height - 135, "down"));
      case LEFT_RIGHT:
        dPad.add(createButton(0, FlxG.height - 135, "left"));
        dPad.add(createButton(126, FlxG.height - 135, "right"));
      case UP_LEFT_RIGHT:
        dPad.add(createButton(105, FlxG.height - 243, "up"));
        dPad.add(createButton(0, FlxG.height - 135, "left"));
        dPad.add(createButton(207, FlxG.height - 135, "right"));
      case FULL:
        dPad.add(createButton(105, FlxG.height - 348, "up"));
        dPad.add(createButton(0, FlxG.height - 243, "left"));
        dPad.add(createButton(207, FlxG.height - 243, "right"));
        dPad.add(createButton(105, FlxG.height - 135, "down"));
      case RIGHT_FULL:
        dPad.add(createButton(FlxG.width - 258, FlxG.height - 66 - 348, "up"));
        dPad.add(createButton(FlxG.width - 390, FlxG.height - 66 - 243, "left"));
        dPad.add(createButton(FlxG.width - 132, FlxG.height - 66 - 243, "right"));
        dPad.add(createButton(FlxG.width - 258, FlxG.height - 66 - 135, "down"));
      case NONE: // do nothing
    }

    switch (actionMode)
    {
      case A:
        actions.add(createButton(screenWidth - 132, screenHeight - 135, ButtonType.A));
      case A_B:
        actions.add(createButton(screenWidth - 132, screenHeight - 135, ButtonType.A));
        actions.add(createButton(screenWidth - 258, screenHeight - 135, ButtonType.B));
      case A_B_C:
        actions.add(createButton(screenWidth - 384, screenHeight - 135, ButtonType.A));
        actions.add(createButton(screenWidth - 258, screenHeight - 135, ButtonType.B));
        actions.add(createButton(screenWidth - 132, screenHeight - 135, ButtonType.C));
      case A_B_X_Y:
        actions.add(createButton(screenWidth - 258, screenHeight - 255, ButtonType.Y));
        actions.add(createButton(screenWidth - 132, screenHeight - 255, ButtonType.X));
        actions.add(createButton(screenWidth - 258, screenHeight - 135, ButtonType.B));
        actions.add(createButton(screenWidth - 132, screenHeight - 135, ButtonType.A));
      case NONE: // do nothing
    }

    bind();

    // switch (actionMode)
    // {
    //   case "NONE":
    //     actions.add(createButton(10, 10, ButtonType.A));
    // }
  }

  public function removeButton(button:FlxButton)
  {
    var findAndRemove = (group:FlxTypedSpriteGroup<FlxButton>, member:FlxButton) -> {
      if (button == member)
      {
        group.remove(member);
        bindingMap.remove(member);
      }
    }

    dPad.forEach(findAndRemove.bind(dPad));
    actions.forEach(findAndRemove.bind(actions));
  }

  public function bind()
  {
    if (controls == null) return;

    for (key => value in bindingMap)
    {
      for (action in value)
      {
        controls.forEachBound(action, (digital, state) -> {
          digital.addInput(key, state);
        });
      }
    }
  }

  public function unbind()
  {
    if (controls == null) return;

    for (key => value in bindingMap)
    {
      for (action in value)
      {
        controls.forEachBound(action, (digital, state) -> {
          for (i in 0...digital.inputs.length)
          {
            if (digital.inputs[i] is FlxActionInputDigitalIFlxInput)
            {
              var digitalAction:FlxActionInputDigitalIFlxInput = cast digital.inputs[i];
              @:privateAccess
              if (digitalAction.input == key)
              {
                digital.remove(digitalAction);
              }
            }
          }
        });
      }
    }
  }

  function createButton(x:Float, y:Float, type:ButtonType)
  {
    var button = new FlxButton(x, y);
    button.solid = false;
    button.immovable = true;

    bindingMap.set(button, defaultMapping.get(type));

    var frames = Paths.getSparrowAtlas('virtual-input');
    button.frames = FlxTileFrames.fromFrame(frames.getByName(type), FlxPoint.get(BUTTON_WIDTH, BUTTON_HEIGHT));
    button.resetSizeFromFrame();

    var widthScale = FlxG.width / referenceScreenSize.width;
    var heightScale = FlxG.height / referenceScreenSize.height;

    button.setPosition(x * widthScale, y * heightScale);

    button.setGraphicSize(button.frameWidth * widthScale, button.frameHeight * heightScale);
    button.updateHitbox();

    #if FLX_DEBUG
    button.ignoreDrawDebug = true;
    #end

    return button;
  }

  public override function destroy()
  {
    unbind();

    super.destroy();

    dPad = FlxDestroyUtil.destroy(dPad);
    actions = FlxDestroyUtil.destroy(dPad);
  }
}

enum abstract ButtonType(String) to String from String
{
  var A = "a";
  var B = "b";
  var C = "c";
  var DOWN = "down";
  var LEFT = "left";
  var RIGHT = "right";
  var UP = "up";
  var X = "x";
  var Y = "y";
}

enum DPadMode
{
  NONE;
  UP_DOWN;
  LEFT_RIGHT;
  UP_LEFT_RIGHT;
  RIGHT_FULL;
  FULL;
}

enum ActionMode
{
  NONE;
  A;
  A_B;
  A_B_C;
  A_B_X_Y;
}

// enum Anchor {
//   LEFT_BOTTOM;
//   RIGHT_BOTTOM;
// }
// enum Mode{
// }
