package ui;

import utilities.CoolUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

using StringTools;

/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;

	public var text:String = "";

	var _finalText:String = "";
	var _curText:String = "";

	public var widthOfWords:Float = FlxG.width;

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false)
	{
		super(x, y);

		forceX = Math.NEGATIVE_INFINITY;

		_finalText = text;
		this.text = text;
		isBold = bold;

		if (text != "")
		{
			if (typed)
			{
				startTypedText();
			}
			else
			{
				addText();
			}
		}
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			// if (character.fastCodeAt() == " ")
			// {
			// }

			if (character == " ")
				lastWasSpace = true;

			#if (haxe >= "4.0.0")
			var canDoThingyLol:Bool = (!isBold && AlphaCharacter.alphabet.contains(character.toLowerCase()) || isBold && AlphaCharacter.boldalphabet.contains(character.toLowerCase()));
			#else
			var canDoThingyLol:Bool = (!isBold && AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1 || isBold && AlphaCharacter.boldalphabet.indexOf(character.toLowerCase()) != -1);
			#end

			if (canDoThingyLol)
			{
				if (lastSprite != null)
				{
					xPos += lastSprite.width;
				}

				if (lastWasSpace)
				{
					xPos += 40;
					lastWasSpace = false;
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);

				if (isBold)
					letter.createBold(character);
				else
				{
					letter.createLetter(character);
				}

				add(letter);

				lastSprite = letter;
			}

			// loopNum += 1;
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';

	public function startTypedText():Void
	{
		_finalText = text;
		doSplitWords();

		var xPos:Float = 0;
		var curRow:Int = 0;

		for(loopNum in 0..._finalText.length)
		{
			new FlxTimer().start(0.05 + (0.05 * loopNum), function(tmr:FlxTimer)
			{
				if(this != null && this.active && this.visible && this.alpha != 0)
				{
					if (_finalText.charCodeAt(loopNum) == "\n".code)
					{
						yMulti += 1;
						xPosResetted = true;
						xPos = 0;
						curRow += 1;
					}
	
					if (splitWords[loopNum - 1] == " ")
					{
						lastWasSpace = true;
					}
	
					#if (haxe >= "4.0.0")
					var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
					var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);
					#else
					var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
					var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
					#end
	
					#if (haxe >= "4.0.0")
					var canDoThingyLol:Bool = (!isBold && AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase()) || isBold && AlphaCharacter.boldalphabet.contains(splitWords[loopNum].toLowerCase()) || isNumber || isSymbol);
					#else
					var canDoThingyLol:Bool = (!isBold && AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isBold && AlphaCharacter.boldalphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol);
					#end
	
					if (canDoThingyLol)
					{
						if (lastSprite != null && !xPosResetted)
						{
							lastSprite.updateHitbox();
							xPos += lastSprite.width + 3;
						}
						else
						{
							xPosResetted = false;
						}
	
						if (lastWasSpace)
						{
							xPos += 20;
							lastWasSpace = false;
						}
	
						var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti);
						letter.row = curRow;
	
						if (isBold)
						{
							letter.createBold(splitWords[loopNum]);
						}
						else
						{
							if (isNumber)
							{
								letter.createNumber(splitWords[loopNum]);
							}
							else if (isSymbol)
							{
								letter.createSymbol(splitWords[loopNum]);
							}
							else
							{
								letter.createLetter(splitWords[loopNum]);
							}
	
							letter.x += 90;
						}
	
						add(letter);
	
						lastSprite = letter;
					}
				}
			});
		}
	}

	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
			
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);

			if(forceX != Math.NEGATIVE_INFINITY) {
				x = forceX;
			} else {
				x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
			}
		}

		super.update(elapsed);
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var boldalphabet:String = "abcdefghijklmnopqrstuvwxyz1234567890|~#$%()*+-:;<=>@[]^.,'!?";
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
	public static var bottomShit:String = ".,_";

	public var row:Int = 0;

	public static var textTexture:FlxAtlasFrames;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		
		if(textTexture == null)
			textTexture = Paths.getSparrowAtlas('alphabet');

		frames = textTexture;

		antialiasing = true;
	}

	public function createBold(letter:String)
	{
		letter.replace("<", "less than").replace("&", "and");

		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();

		if(letter == "-")
			y += height;
		else if(bottomShit.contains(letter))
			y += height * 2;
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = "lowercase";

		if (letter.toLowerCase() != letter)
			letterCase = 'capital';

		animation.addByPrefix(letter, letter + " " + letterCase + '0', 24);
		animation.play(letter);
		updateHitbox();

		y -= height;
		y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter + "0", 24);
		animation.play(letter);
		updateHitbox();

		y -= height;
		y += row * 60;
	}

	public function createSymbol(letter:String)
	{
		switch (letter)
		{
			case '.':
				animation.addByPrefix(letter, '.0', 24);
				animation.play(letter);
			case "'":
				animation.addByPrefix(letter, 'apostraphie0', 24);
				animation.play(letter);
				y -= height;
			case "?":
				animation.addByPrefix(letter, 'question mark0', 24);
				animation.play(letter);
				y -= height;
			case "!":
				animation.addByPrefix(letter, 'exclamation point0', 24);
				animation.play(letter);
				y -= height;
			case ',':
				animation.addByPrefix(letter, 'comma0', 24);
				animation.play(letter);
			case '<':
				animation.addByPrefix(letter, 'less_than0', 24);
				animation.play(letter);
				y -= height;
			default:
				animation.addByPrefix(letter, letter + '0', 24);
				animation.play(letter);
				y -= height;
		}

		y += row * 60;

		updateHitbox();
	}
}
