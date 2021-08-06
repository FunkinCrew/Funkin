package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
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

	var listOAlphabets:List<AlphaCharacter> = new List<AlphaCharacter>();

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	var pastX:Float = 0;
	var pastY:Float  = 0;

	// ThatGuy: Variables here to be used later
	var xScale:Float;
	var yScale:Float;

	// ThatGuy: Added 2 more variables, xScale and yScale for resizing text
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, shouldMove:Bool = false, xScale:Float = 1, yScale:Float = 1)
	{
		pastX = x;
		pastY = y;

		// ThatGuy: Have to assign these variables
		this.xScale = xScale;
		this.yScale = yScale;

		super(x, y);

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

	public function reType(text, xScale:Float = 1, yScale:Float = 1)
	{
		for (i in listOAlphabets)
			remove(i);
		_finalText = text;
		this.text = text;

		lastSprite = null;

		updateHitbox();

		listOAlphabets.clear();
		x = pastX;
		y = pastY;

		this.xScale = xScale;
		this.yScale = yScale;
		
		addText();
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

			if (character == " " || character == "-")
			{
				lastWasSpace = true;
			}

			if (AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1)
				// if (AlphaCharacter.alphabet.contains(character.toLowerCase()))
			{
				if (lastSprite != null)
				{
					// ThatGuy: This is the line that fixes the spacing error when the x position of this class's objects was anything other than 0
					xPos = lastSprite.x - pastX + lastSprite.width;
				}

				if (lastWasSpace)
				{
					// ThatGuy: Also this line
					xPos += 40 * xScale;
					lastWasSpace = false;
				}

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);
				
				// ThatGuy: These are the lines that change the individual scaling of each character
				letter.scale.set(xScale, yScale);
				letter.updateHitbox();

				listOAlphabets.add(letter);

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

	// ThatGuy: THIS FUNCTION ISNT CHANGED! Because i dont use it lol
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
				listOAlphabets.add(letter);
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
					FlxG.sound.play(Paths.soundRandom(daSound, 1, 4));
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

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.30);
			x = FlxMath.lerp(x, (targetY * 20) + 90, 0.30);
		}

		super.update(elapsed);
	}

	// ThatGuy: Ooga booga function for resizing text, with the option of wanting it to have the same midPoint
		// Side note: Do not, EVER, do updateHitbox() unless you are retyping the whole thing. Don't know why, but the position gets retarded if you do that
	public function resizeText(xScale:Float, yScale:Float, xStaysCentered:Bool = true, yStaysCentered:Bool = false):Void {
		var oldWidth:Float = this.width;
		var oldHeight:Float = this.height;
		//trace('old x before scaling: ' + this.x);
		//trace('old midpoint before scaling: ' + this.getMidpoint().x);
		reType(text, xScale, yScale);
		//trace('old x after scaling: ' + this.x);
		//trace('old midpoint after scaling: ' + this.getMidpoint().x);
		//This works, commenting out all the tracing
		if(xStaysCentered) {
			/* 
			If oldX is the old position, that is the same for both sizes of text, e.g. oldX = 50
			And oldWidth is the old width of the text, e.g. oldWidth = 100
			And newWidth is the current width of the text, e.g. newWidth= 150
			And the midpoint, is always the same, e.g. midpoint = oldX + oldWidth/2 = 50 + 100/2 = 100
			and the newMidpoint, which is equal to midpoint, is newX + newWidth/2, then
			newX = midpoint - newWidth/2 <=> newX = oldX + oldWidth/2 - newWidth/2, e.g., <=> newX = 50 + 100/2 - 150/2 <=> newX = 25
			*/
			//Since this.x doesnt change with text scaling, in this equation, this.x can be used as both the old and the new x
			this.x = this.x + oldWidth/2 - this.width/2;
			//trace('new x after scaling: ' + this.x);
			//trace('new midpoint after scaling: ' + this.getMidpoint().x);
		}
		if(yStaysCentered) {
			// Same logic applies here
			this.y = this.y + oldHeight/2 - this.height/2;
		}
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!? ";

	public var row:Int = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		var tex = Paths.getSparrowAtlas('alphabet');
		frames = tex;
		if(FlxG.save.data.antialiasing)
			{
				antialiasing = true;
			}
	}

	public function createBold(letter:String)
	{
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createLetter(letter:String):Void
	{
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
			case '_':
				animation.addByPrefix(letter, '_', 24);
				animation.play(letter);
				y += 50;
			case "#":
				animation.addByPrefix(letter, '#', 24);
				animation.play(letter);
			case "$":
				animation.addByPrefix(letter, '$', 24);
				animation.play(letter);
			case "%":
				animation.addByPrefix(letter, '%', 24);
				animation.play(letter);
			case "&":
				animation.addByPrefix(letter, '&', 24);
				animation.play(letter);
			case "(":
				animation.addByPrefix(letter, '(', 24);
				animation.play(letter);
			case ")":
				animation.addByPrefix(letter, ')', 24);
				animation.play(letter);
			case "+":
				animation.addByPrefix(letter, '+', 24);
				animation.play(letter);
			case "-":
				animation.addByPrefix(letter, '-', 24);
				animation.play(letter);
			case '"':
				animation.addByPrefix(letter, '"', 24);
				animation.play(letter);
				y -= 0;
			case '@':
				animation.addByPrefix(letter, '@', 24);
				animation.play(letter);
			case "^":
				animation.addByPrefix(letter, '^', 24);
				animation.play(letter);
				y -= 0;
			case ' ':
				animation.addByPrefix(letter, 'space', 24);
				animation.play(letter);
		}

		updateHitbox();
	}
}
