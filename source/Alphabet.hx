package;

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
	var isStepped:Bool = true;
	var groupX:Float = 90;
	var groupY:Float = 0.48;
	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;
	var lastWasEscape:Bool = false;
	var drawHypens:Bool = false;
	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, stepped:Bool = true, alignX:Float = 90, alignY:Float = 0.48, ?drawHypens:Bool = false)
	{
		super(x, y);

		_finalText = text;
		this.text = text;
		isBold = bold;
		isStepped = stepped;
		groupX = alignX;
		groupY = alignY;
		this.drawHypens = drawHypens;
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
	public function clearText() {
		var kidsToMurder:Array<FlxSprite> = [];
		forEach(function (sprite:FlxSprite) {
			kidsToMurder.push(sprite);
		});
		clear();
		for( kid in kidsToMurder ) {
			kid.destroy();
		}

	}
	public function addText()
	{
		_finalText = text;
		clearText();
		lastSprite = null;
		lastWasSpace = false;
		doSplitWords();
		var xPos:Float = 0;
		for (character in splitWords)
		{
			// if (character.fastCodeAt() == " ")
			// {
			// }
			// doing dummy character bs because idk how for loops in haxe work
			var dummyCharacter = character;
			if (dummyCharacter == " " || (dummyCharacter == "-" && !drawHypens))
			{
				lastWasSpace = true;
			}
			if (dummyCharacter == "\\" && !lastWasEscape) {
				lastWasEscape = true;
				continue;
			}
			if (lastWasEscape) {
				switch (dummyCharacter) {
					case "\\":
						// do nothing
					case "v":
						dummyCharacter = "da";
					case ">":
						dummyCharacter = "ra";
					case "<":
						dummyCharacter = "la";
					case "^":
						dummyCharacter = "ua";
					case "h":
						dummyCharacter = "heart";
				}
				lastWasEscape = false;
			}
			if ((AlphaCharacter.alphabet.indexOf(dummyCharacter.toLowerCase()) != -1 || AlphaCharacter.numbers.indexOf(dummyCharacter) != -1 || StringTools.contains(AlphaCharacter.symbols,dummyCharacter)) && (dummyCharacter != "-" || drawHypens))
				// if (AlphaCharacter.alphabet.contains(character.toLowerCase()))
			{
				if (lastSprite != null)
				{
					xPos = lastSprite.x + lastSprite.width;
				}

				if (lastWasSpace)
				{
					xPos += 40;
					lastWasSpace = false;
				}

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);

				if (isBold)
					letter.createBold(dummyCharacter);
				else
				{
					letter.createLetter(dummyCharacter);
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

		// trace(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			if (splitWords[loopNum] == " ")
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

			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol)
				// if (AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase()) || isNumber || isSymbol)

			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
					// if (isBold)
					// xPos -= 80;
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
				// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
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

				if (FlxG.random.bool(40))
				{
					var daSound:String = "GF_";
					FlxG.sound.play('assets/sounds/' + daSound + FlxG.random.int(1, 4) + TitleState.soundExt, 0.4);
				}

				add(letter);

				lastSprite = letter;
			}

			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * groupY), 0.16);
			if (isStepped) {
				x = FlxMath.lerp(x, (targetY * 20) + groupX, 0.16);
			} else {
				// bad no
				//	x = FlxMath.lerp(x, groupX, 0.16);
			}

		}

		super.update(elapsed);
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = ".,'!/?\\-+_#$%&()*:;<=>@[]^|~\"daralauaheart";

	public var row:Int = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		var tex = FlxAtlasFrames.fromSparrow('assets/images/alphabet.png', 'assets/images/alphabet.xml');
		frames = tex;

		antialiasing = true;
	}

	public function createBold(letter:String)
	{
		if (StringTools.contains(alphabet, letter) || StringTools.contains(numbers, letter)) {
			animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
			animation.play(letter);
			updateHitbox();
		} else {
			var animName = "";
			switch (letter)
			{
				case '.':
					animName = "period bold";
					y += 50;
				case "'":
					animName = "apostraphie bold";
					y -= 0;
				case "?":
					animName = "question mark bold";
				case "!":
					animName = "exclamation point bold";
				case ",":
					animName = "comma bold";
				case "\\":
					animName = "bs bold";
				case "/":
					animName = "fs bold";
				case "da":
					animName = "down arrow bold";
				case "ua":
					animName = "up arrow bold";
				case "la":
					animName = "left arrow bold";
				case "heart":
					animName = "heart bold";
				case "ra":
					animName = "right arrow bold";
				case "\"":
					animName = "quote";
				default:
					animName = letter + " bold";
					switch (letter) {
						case "-" | "~" | "+":
							y += 25;
						case "_":
							y += 50;
					}

			}
			animation.addByPrefix(letter, animName, 24);
			animation.play(letter);
			updateHitbox();
		}

	}

	public function createLetter(letter:String):Void
	{
		if (StringTools.contains(alphabet, letter)) {
			var letterCase:String = "lowercase";
			if (letter.toLowerCase() != letter)
			{
				letterCase = 'capital';
			}

			animation.addByPrefix(letter, letter + " " + letterCase, 24);
			animation.play(letter);
			updateHitbox();

			FlxG.log.add('the row' + row);

			y = (110 - height);
			y += row * 60;
	  } else if (StringTools.contains(numbers,letter)) {
			createNumber(letter);
		} else if (StringTools.contains(symbols,letter)) {
			createSymbol(letter);
		}
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);

		updateHitbox();
	}

	public function createSymbol(letter:String)
	{
		switch (letter)
		{
			case '.':
				animation.addByPrefix(letter, 'period', 24);
				animation.play(letter);
				y += 50;
			case "'":
				animation.addByPrefix(letter, 'apostraphie', 24);
				animation.play(letter);
				y -= 0;
			case "?":
				animation.addByPrefix(letter, 'question mark', 24);
				animation.play(letter);
			case "!":
				animation.addByPrefix(letter, 'exclamation point', 24);
				animation.play(letter);
			case ",":
				animation.addByPrefix(letter, 'comma', 24);
				animation.play(letter);
			case "\\":
				animation.addByPrefix(letter, 'bs', 24);
				animation.play(letter);
			case "/":
				animation.addByPrefix(letter, 'fs', 24);
				animation.play(letter);
			case "da":
				animation.addByPrefix(letter, 'down arrow', 24);
				animation.play(letter);
			case "ua":
				animation.addByPrefix(letter, 'up arrow', 24);
				animation.play(letter);
			case "la":
				animation.addByPrefix(letter, 'left arrow', 24);
				animation.play(letter);
			case "heart":
				animation.addByPrefix(letter, 'heart', 24);
				animation.play(letter);
			case "ra":
				animation.addByPrefix(letter, 'right arrow', 24);
				animation.play(letter);
			default:
				animation.addByPrefix(letter, letter.toLowerCase(), 24);
				animation.play(letter);
				switch (letter) {
					case "-":
						y += 25;
					case "_":
						y += 50;
					case "~":
						y += 25;
					case "+":
						y += 25;
				}
		}

		updateHitbox();
	}
}
