package funkin.play;

import funkin.play.character.BaseCharacter;
import flixel.FlxSprite;

class Fighter extends BaseCharacter
{
  public function new(?x:Float = 0, ?y:Float = 0, ?char:String = "pico-fighter")
  {
    super(char, Custom);
    this.x = x;
    this.y = y;

    animation.finishCallback = function(anim:String) {
      switch anim
      {
        case "punch low" | "punch high" | "block" | 'dodge':
          dance(true);
      }
    };
  }

  public var actions:Array<ACTIONS> = [PUNCH, BLOCK, DODGE];

  public function doSomething(?forceAction:ACTIONS)
  {
    var daAction:ACTIONS = FlxG.random.getObject(actions);

    if (forceAction != null) daAction = forceAction;

    switch (daAction)
    {
      case PUNCH:
        punch();
      case BLOCK:
        block();
      case DODGE:
        dodge();
    }
  }

  public var curAction:ACTIONS = DODGE;

  function dodge()
  {
    playAnimation('dodge');
    curAction = DODGE;
  }

  public function block()
  {
    playAnimation('block');
    curAction = BLOCK;
  }

  public function punch()
  {
    curAction = PUNCH;
    playAnimation('punch ' + (FlxG.random.bool() ? "low" : "high"));
  }
}

enum ACTIONS
{
  DODGE;
  BLOCK;
  PUNCH;
}
