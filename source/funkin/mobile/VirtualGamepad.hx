package funkin.mobile;

import funkin.input.Controls;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.actions.FlxAction.FlxActionDigital;
import flixel.input.actions.FlxActionInputDigital.FlxActionInputDigitalIFlxInput;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.typeLimit.OneOfTwo;
// import funkin.input.Controls.Control;
import openfl.Assets;
import openfl.display.Sprite;

@:access(Controls)
class VirtualGamepad extends FlxSpriteGroup
{
  var dPad:FlxTypedSpriteGroup<FlxButton>;
  var actions:FlxTypedSpriteGroup<FlxButton>;

  inline static var BUTTON_WIDTH:Int = 132;
  inline static var BUTTON_HEIGHT:Int = 135;

  var isBinded:Bool = false;

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

    var cam = new flixel.FlxCamera();
    FlxG.cameras.add(cam, false);
    cam.bgColor.alpha = 0;
    cameras = [cam];
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }

	public function switchMode(dPadMode:DPadMode = NONE, actionMode:ActionMode = NONE, bindButtons:Bool = false)
  {
    var screenWidth = referenceScreenSize.width;
    var screenHeight = referenceScreenSize.height;

		unbind();

    dPad.forEach((button) -> {
      removeButton(button);
    });

    actions.forEach((button) -> {
      removeButton(button);
    });

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

    if (bindButtons)
      bind();
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
		if (controls == null)
			return;

    if (isBinded)
      return;

		for (key => value in bindingMap)
		{
			for (action in value)
			{
				controls.bindInput(action, key);
			}
		}

    isBinded = true;
	}

	public function unbind()
	{
		if (controls == null)
			return;

    if (!isBinded)
      return;

		for (key => value in bindingMap)
		{
			for (action in value)
			{
				controls.unbindInput(action, key);
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

// mode for navigation buttons
enum DPadMode
{
	NONE;
	UP_DOWN;
	LEFT_RIGHT;
	UP_LEFT_RIGHT;
	RIGHT_FULL;
	FULL;
}

// mode for acton buttons. for example: accept (a), back (b)...
enum ActionMode
{
	NONE;
	A;
	A_B;
	A_B_C;
	A_B_X_Y;
}
