package funkin.util.plugins;

import funkin.mobile.VirtualGamepad;
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

/**
 * A plugin which adds on-screen buttons for mobile targets
 */
class VirtualGamepadPlugin extends FlxBasic // maybe OnSceenControlPlugin??
{
  var gamepad:VirtualGamepad;

  public var ruleList:Array<StateConfig> = [
    {
      state: funkin.InitState,
      dPadMode: NONE,
      actionMode: NONE
    },
    {
      state: funkin.ui.title.TitleState,
      dPadMode: NONE,
      actionMode: NONE
    }
  ]; // funkin.play.PlayState

  public function new()
  {
    super();
    FlxG.state.forEachOfType(VirtualGamepad, gamepad -> FlxG.state.remove(gamepad).destroy());

    onPostStateSwitch();

    FlxG.signals.postStateSwitch.add(onPostStateSwitch);
  }

  function getRule(state:OneOfTwo<FlxState, FlxSubState>)
  {
    var currentRule:StateConfig = null;
    for (rule in ruleList)
    {
      if (cast Type.getClass(state) == rule.state)
      {
        currentRule = rule;
        break;
      }
    }
    if (currentRule == null)
    {
      currentRule =
        {
          state: Type.getClass(state),
          dPadMode: FULL,
          actionMode: A_B
        }
    }

    if (currentRule.sharedRule == null) currentRule.sharedRule = false;

    return currentRule;
  }

  function onPostStateSwitch()
  {
    var rule = getRule(FlxG.state);

    FlxG.state.add(gamepad = new VirtualGamepad());
    gamepad.switchMode(rule.dPadMode, rule.actionMode, true);

    FlxG.state.subStateOpened.add((state) -> onSubStateOpened(FlxG.state, rule, state));
    FlxG.state.subStateClosed.add((state) -> onSubStateClosed(FlxG.state, rule, state));
  }

  function onSubStateOpened(prevState:OneOfTwo<FlxState, FlxSubState>, prevRule:StateConfig, subState:FlxSubState)
  {
    var rule:StateConfig = null;
    var isInherited = false;

    if (prevRule.sharedRule == true)
    {
      rule = prevRule;
      isInherited = true;
    }
    else
    {
      rule = getRule(subState);
    }

    if (Std.downcast(prevState, FlxState) != null)
    {
      cast(prevState, FlxState).remove(gamepad).destroy();
    }

    subState.add(gamepad = new VirtualGamepad());

    if (!isInherited) gamepad.switchMode(rule.dPadMode, rule.actionMode, true);
    else
      gamepad.switchMode(prevRule.dPadMode, prevRule.actionMode, true);

    subState.subStateOpened.add(onSubStateOpened.bind(subState, rule));
    subState.subStateClosed.add(onSubStateClosed.bind(subState, rule));
  }

  function onSubStateClosed(prevState:OneOfTwo<FlxState, FlxSubState>, prevRule:StateConfig, subState:FlxSubState)
  {
    subState.remove(gamepad).destroy();

    if (Std.downcast(prevState, FlxState) != null)
    {
      cast(prevState, FlxState).add(gamepad = new VirtualGamepad());
      gamepad.switchMode(prevRule.dPadMode, prevRule.actionMode, true);
    }
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }

  public static function initialize():Void
  {
    if (true) // FlxG.onMobile
      FlxG.plugins.addPlugin(new VirtualGamepadPlugin());
  }
}

typedef StateConfig =
{
  /**
   * The class of state or substate to which this rule will apply
   */
  var state:Class<OneOfTwo<FlxState, FlxSubState>>;

  // Instance of class
  // var ?instanceOfState:OneOfTwo<FlxState, FlxSubState>;
  // mode of the left side of gamepad (for example left, right, up, down)
  var dPadMode:DPadMode;
  // mode of the right side of gamepad (for example a, b, c, x, y)
  var actionMode:ActionMode;
  // tells whether this rule is inherited by the substate
  var ?sharedRule:Bool;
}
