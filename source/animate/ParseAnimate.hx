package animate;

import haxe.format.JsonParser;
import openfl.Assets;
import sys.io.File;

/**
 * Generally designed / written in a way that can be easily taken out of FNF and used elsewhere
 * I don't think it even has ties to OpenFL? Could probably just use it for ANY haxe
 * project if needed, DOES NEED A LOT OF CLEANUP THOUGH!
 */
class ParseAnimate
{
	// make list of frames needed to render (with ASI)
	// make GIANT list of all the frames ever and have them in order?
	public static var symbolMap:Map<String, Symbol> = new Map();
	public static var actualSprites:Map<String, Sprite> = new Map();

	/**
	 * Not used, was used for testing stuff though!	
	 */
	public static function init()
	{
		// Main.gids
		var folder:String = 'tightestBars';

		// var spritemap:Spritemap =
		// var spritemap:Spritemap = genSpritemap('test/$folder/spritemap1.json');

		actualSprites = genSpritemap('test/$folder/spritemap1.json');

		var animation:AnimJson = cast CoolUtil.coolJSON(Assets.getText('src/$folder/Animation.json'));

		generateSymbolmap(animation.SD.S);

		trace("\n\nANIMATION SHIT\n");

		var timelineLength:Int = 0;
		for (lyr in animation.AN.TL.L)
			timelineLength = Std.int(Math.max(lyr.FR.length, timelineLength));

		var content:String = animation.AN.TL.L[0].LN;
		content += "TOTAL FRAMES NEEDED: " + timelineLength + "\n";

		for (frm in 0...timelineLength)
		{
			trace('FRAME NUMBER ' + frm);
			try
			{
				parseTimeline(animation.AN.TL, 1, frm);
				content += 'Good write on frame: ' + frm + "\n";
			}
			catch (e)
			{
				content += "BAD WRITE : " + frm + "\n";
				content += "\t" + e + "\n";
				trace(e);
			}

			// File.saveContent("output.txt", content);
		}

		parseTimeline(animation.AN.TL, 1, 0);
		trace(actualSprites);
	}

	/**
	 * a MAP of SPRITES, not to be confused with Spritemap... lol
	 */
	public static function genSpritemap(json:String):Map<String, Sprite>
	{
		var sprShitty:Spritemap = cast CoolUtil.coolJSON(json);
		var sprMap:Map<String, Sprite> = new Map();

		for (spr in sprShitty.ATLAS.SPRITES)
			sprMap.set(spr.SPRITE.name, spr.SPRITE);
		return sprMap;
	}

	public static function generateSymbolmap(symbols:Array<Symbol>)
	{
		for (symbol in symbols)
		{
			// trace(symbol.SN + "has: " + symbol.TL.L.length + " LAYERS");

			symbolMap.set(symbol.SN, symbol);
			// parseTimeline(symbol.TL);
		}
	}

	public static var curLoopType:String;

	/**
	 * Stuff for debug parsing
	 */
	public static var depthTypeBeat:String = "";

	public static var frameList:Array<Array<VALIDFRAME>> = [];
	public static var matrixMap:Map<String, Array<Array<Float>>> = new Map();
	public static var trpMap:Map<String, Array<Array<Float>>> = new Map();
	public static var theRoots:Map<String, String> = new Map();

	// for loop stuf

	/**
	 * Similar to frameList, keeps track of shit according to framess?
	 * That amount of arrays within arrays is fuckin dumb
	 * but innermost array is basically just x and y value, cuz im dum
	 */
	public static var matrixHelp:Array<Array<Array<Float>>> = [];

	public static var trpHelpIDK:Array<Array<Float>> = [];

	public static var loopedFrameShit:Int = 0;

	public static function resetFrameList()
	{
		frameList = [];
		frameList.push([]);
		matrixHelp = [];
		matrixHelp.push([]);
		matrixMap.clear();
		theRoots.clear();
		trpMap.clear();
	}

	public static function parseTimeline(TL:Timeline, tabbed:Int = 0, ?frameInput:Int)
	{
		var strTab:String = "";
		for (i in 0...tabbed)
			strTab += '\t';

		for (layer in TL.L)
		{
			var frameArray:Array<Int> = [];
			var frameMap:Map<Int, Frame> = new Map();

			for (frms in layer.FR)
			{
				for (i in 0...frms.DU)
					frameArray.push(frms.I);

				frameMap.set(frms.I, frms);
			}

			if (frameInput == null)
				frameInput = 0;

			var oldFrm:Int = frameInput;
			/* 
				if (curLoopType == "SF")
				{
					trace(layer.LN);

					trace(frameArray);
					trace(frameInput);
					trace(curLoopType);
			}*/

			if (curLoopType == "LP")
				frameInput = frameArray[frameInput % frameArray.length];
			else if (curLoopType == "SF")
			{
				frameInput = frameArray[loopedFrameShit];

				// see what happens when something has more than 2 layer?
			}
			else
				frameInput = frameArray[frameInput];

			// trace(frameMap.get(frameInput));

			var frame:Frame = frameMap.get(frameInput);

			for (element in frame.E)
			{
				if (Reflect.hasField(element, "ASI"))
				{
					matrixHelp[matrixHelp.length - 1].push(element.ASI.M3D);
					// matrixMap.set(element.ASI.N, matrixHelp);

					frameList[frameList.length - 1].push({
						frameName: element.ASI.N,
						M3D: element.ASI.M3D,
						depthString: depthTypeBeat,
						matrixArray: matrixHelp[matrixHelp.length - 1]
					});

					trpMap.set(element.ASI.N, trpHelpIDK);

					// flips the matrix once?? I cant remember exactly why it needs to be flipped
					// matrixMap[matrixHelp.length - 1].reverse();
					// matrixHelp[matrixHelp.length - 1].reverse();

					trpHelpIDK = [];

					theRoots.set(element.ASI.N, depthTypeBeat);

					depthTypeBeat = "";
					curLoopType = "";
					loopedFrameShit = 0;
				}
				else
				{
					matrixHelp[matrixHelp.length - 1].push(element.SI.M3D);
					trpHelpIDK.push([element.SI.TRP.x, element.SI.TRP.y]);
					depthTypeBeat += "->" + element.SI.SN;
					curLoopType = element.SI.LP;

					var inputFrame:Int = element.SI.FF;

					// JANKY FIX, MAY NOT ACCOUNT FOR ALL SCENARIOS!
					if (curLoopType == "SF")
					{
						// trace("LOOP SHIT: " + inputFrame);
						loopedFrameShit = inputFrame;
					}

					parseTimeline(symbolMap.get(element.SI.SN).TL, tabbed + 1, inputFrame);
				}
			}

			frameList.push([]);
			matrixHelp.push([]);
		}

		frameList.reverse();
	}
}

typedef VALIDFRAME =
{
	frameName:String,
	M3D:Array<Float>,
	depthString:String,
	matrixArray:Array<Array<Float>>
}

typedef AnimJson =
{
	AN:Animation,
	SD:SymbolDictionary,
	MD:MetaData
}

typedef Animation =
{
	N:String,
	SN:String,
	TL:Timeline
}

typedef SymbolDictionary =
{
	S:Array<Symbol>
}

typedef Symbol =
{
	/**Symbol name*/
	SN:String,

	TL:Timeline
}

typedef Timeline =
{
	L:Array<Layer>
}

typedef Layer =
{
	LN:String,
	FR:Array<Frame>
}

typedef Frame =
{
	E:Array<Element>,
	I:Int,
	DU:Int
}

typedef Element =
{
	SI:SymbolInstance,
	ASI:AlsoSymbolInstance
	// lmfao idk what ASI stands for lmfaoo, i dont think its "also"
}

typedef SymbolInstance =
{
	SN:String,

	/**Symbol type, prob either G (graphic), or movie clip?*/ ST:String,

	/**First frame*/ FF:Int,

	/**Loop type, loop ping pong, etc.*/ LP:String,

	/**3D matrix*/ M3D:Array<Float>,

	TRP:
	{
		x:Float, y:Float
	}
}

typedef AlsoSymbolInstance =
{
	N:String,
	M3D:Array<Float>
}

typedef MetaData =
{
	/**
	 * Framerate
	 */
	FRT:Int
}

// SPRITEMAP BULLSHIT
typedef Spritemap =
{
	ATLAS:
	{
		SPRITES:Array<SpriteBullshit>
	},
	meta:Meta
}

typedef SpriteBullshit =
{
	SPRITE:Sprite
}

typedef Sprite =
{
	name:String,
	x:Int,
	y:Int,
	w:Int,
	h:Int,
	rotated:Bool
}

typedef Meta =
{
	app:String,
	verstion:String,
	image:String,
	format:String,
	size:
	{
		w:Int, h:Float
	},
	resolution:Float
}
