package;

import flixel.animation.FlxAnimation;
import haxe.ds.Vector;
import flxanimate.FlxAnimate;

using StringTools;

@:access(FlxAnimate)
class AtlasCharacter extends FlxAnimate 
{
    public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

    var flipXY:Map<String, Vector<Bool>>;

    public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false) {
        var path = switch (character){
            case "bf":
                // "assets/images/picohd";
                "assets/images/BOYFRIEND";

            default:
                "assets/images/BOYFRIEND";
        }
        
        super(x, y, path);

        // animation.add("anim", [0], 0, true);
        // animation.play("anim", true);

        flipXY = new Map();
        animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

        antialiasing = true;

        switch (curCharacter)
		{
			case 'bf':
                // anim.addBySymbol("up", "BF NOTE UP", 24, true);

                addByPrefix('idle', 'BF idle dance', 24, false);
				addByPrefix('singUP', 'BF NOTE UP', 24, false);
				addByPrefix('singLEFT', 'BF NOTE LEFT', 24, false);
				addByPrefix('singRIGHT', 'BF NOTE RIGHT', 24, false);
				addByPrefix('singDOWN', 'BF NOTE DOWN', 24, false);
				addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				addByPrefix('hey', 'BF HEY', 24, false);

				addByPrefix('firstDeath', "BF dies", 24, false);
				addByPrefix('deathLoop', "BF Dead Loop", 24, true);
				addByPrefix('deathConfirm', "BF Dead confirm", 24, false);

				addByPrefix('scared', 'BF idle shaking', 24);

				addOffset('idle', -5);
				addOffset("singUP", -29, 27);
				addOffset("singRIGHT", -38, -7);
				addOffset("singLEFT", 12, -6);
				addOffset("singDOWN", -10, -50);
				addOffset("singUPmiss", -29, 27);
				addOffset("singRIGHTmiss", -30, 21);
				addOffset("singLEFTmiss", 12, 24);
				addOffset("singDOWNmiss", -11, -19);
				addOffset("hey", 7, 4);
				addOffset('firstDeath', 37, 11);
				addOffset('deathLoop', 37, 5);
				addOffset('deathConfirm', 37, 69);
				addOffset('scared', -4);


				// addByPrefix('idle', "Pico Idle Dance", 24);
				// addByPrefix('singUP', 'pico Up note0', 24, false);
				// addByPrefix('singDOWN', 'Pico Down Note0', 24, false);
				// if (isPlayer)
				// {
				// 	addByPrefix('singLEFT', 'Pico NOTE LEFT0', 24, false);
				// 	addByPrefix('singRIGHT', 'Pico Note Right0', 24, false);
				// 	addByPrefix('singRIGHTmiss', 'Pico Note Right Miss', 24, false);
				// 	addByPrefix('singLEFTmiss', 'Pico NOTE LEFT miss', 24, false);
				// }
				// else
				// {
				// 	// Need to be flipped! REDO THIS LATER!
				// 	addByPrefix('singLEFT', 'Pico Note Right0', 24, false);
				// 	addByPrefix('singRIGHT', 'Pico NOTE LEFT0', 24, false);
				// 	addByPrefix('singRIGHTmiss', 'Pico NOTE LEFT miss', 24, false);
				// 	addByPrefix('singLEFTmiss', 'Pico Note Right Miss', 24, false);
				// }

				// addByPrefix('singUPmiss', 'pico Up note miss', 24);
				// addByPrefix('singDOWNmiss', 'Pico Down Note MISS', 24);


				playAnim('idle');

				flipX = true;

                // BF NOTE UP
        }

        dance();

        @:privateAccess
        if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
                var oldRight = anim.animsMap['singRIGHT'];
                anim.animsMap.set('singRIGHT', anim.animsMap['singLEFT']);
                anim.animsMap.set('singLEFT', oldRight);

				// IF THEY HAVE MISS ANIMATIONS??
				if (anim.animsMap.get('singRIGHTmiss') != null)
				{
                    var oldMiss = anim.animsMap['singRIGHTmiss'];
                    anim.animsMap.set('singRIGHTmiss', anim.animsMap['singLEFTmiss']);
                    anim.animsMap.set('singLEFTmiss', oldRight);
				}
			}
		}
    }

    public var curAnimName:String = "";

    override function update(elapsed:Float)
	{
        @:privateAccess
        curAnimName = anim.animationName;
		// trace(curAnimName);

		if (!curCharacter.startsWith('bf'))
		{
            @:privateAccess
			if (anim.animationName.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'dad')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				dance();
				holdTimer = 0;
			}
		}

		switch (curCharacter)
		{
			case 'gf':
                @:privateAccess
				if (anim.animationName == 'hairFall' && anim.finished)
					playAnim('danceRight');
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

    public function dance()
    {
        if (!debugMode)
		{
            @:privateAccess
			switch (curCharacter)
			{
				case 'gf':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-christmas':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'picoSpeaker':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('idle');
						else
							playAnim('idle');
					}

				case 'gf-tankman':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}
				case 'gf-car':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}
				case 'gf-pixel':
					if (!anim.animationName.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'spooky':
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');
				default:
					playAnim('idle');
			}
		}
    }

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
    {
		
        var flipArr = flipXY[AnimName];
        if (flipArr != null)
        {
            flipX = flipArr[0];
            flipY = flipArr[1];
        }
        else
        {
            flipX = false;
            flipY = false;
        }

        anim.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
    }

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

    function addByPrefix(Name:String, Prefix:String, FrameRate:Int = 30, Looped:Bool = true, FlipX:Bool = false, FlipY:Bool = false) {
        anim.addBySymbol(Name, Prefix, FrameRate, Looped, 0, 0);

        if (FlipX != false || FlipY != false)
        {
            var arr = new Vector(2);
            arr[0] = FlipX;
            arr[1] = FlipY;
            flipXY.set(Name, arr);
        }
    }
}

class AtlasBoyfriend extends AtlasCharacter
{
	public var stunned:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
        @:privateAccess
		if (!debugMode)
		{
			if (anim.animationName.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;

			if (anim.animationName.endsWith('miss') && anim.finished && !debugMode)
			{
				playAnim('idle', true, false, 10);
			}

			if (anim.animationName == 'firstDeath' && anim.finished)
			{
				playAnim('deathLoop');
			}
		}

		super.update(elapsed);
	}
}