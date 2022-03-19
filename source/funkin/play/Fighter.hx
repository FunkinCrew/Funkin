package funkin.play;

import flixel.FlxSprite;

class Fighter extends Character
{
	public function new(?x:Float = 0, ?y:Float = 0, ?char:String = "pico-fighter")
	{
		super(x, y, char);

		animation.finishCallback = function(anim:String)
		{
			switch anim
			{
				case "punch low" | "punch high" | "block" | 'dodge':
					dance();
			}
		};
	}

	public var actions:Array<ACTIONS> = [PUNCH, BLOCK, DODGE];

	public function doSomething(?forceAction:ACTIONS)
	{
		var daAction:ACTIONS = FlxG.random.getObject(actions);

		if (forceAction != null)
			daAction = forceAction;

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
		playAnim('dodge');
		curAction = DODGE;
	}

	public function block()
	{
		playAnim('block');
		curAction = BLOCK;
	}

	public function punch()
	{
		curAction = PUNCH;
		playAnim('punch ' + (FlxG.random.bool() ? "low" : "high"));
	}
}

enum ACTIONS
{
	DODGE;
	BLOCK;
	PUNCH;
}
