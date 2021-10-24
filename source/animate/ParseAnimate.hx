package animate;

import haxe.format.JsonParser;
import openfl.Assets;
import openfl.geom.Matrix3D;
import openfl.geom.Matrix;
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

	private var _atlas:Map<String, Sprite>;
	private var _symbolData:Map<String, Symbol>;
	private var _defaultSymbolName:String;

	public function new(data:AnimJson, atlas:Spritemap)
	{
		// bitmap data could prob be instead
		// this code is mostly nabbed from https://github.com/miltoncandelero/OpenFLAnimateAtlas/blob/master/Source/animateatlas/displayobject/SpriteAnimationLibrary.hx
		parseAnimationData(data);
		parseAtlasData(atlas);
	}

	private function parseAnimationData(data:AnimJson):Void
	{
		_symbolData = new Map();

		var symbols = data.SD.S;
		for (symbol in symbols)
			_symbolData[symbol.SN] = preprocessSymbolData(symbol);

		var defaultSymbol:Symbol = preprocessSymbolData(data.AN);
		_defaultSymbolName = defaultSymbol.SN;
		_symbolData.set(_defaultSymbolName, defaultSymbol);
	}

	// at little redundant, does exactly the same thing as genSpritemap()
	private function parseAtlasData(atlas:Spritemap):Void
	{
		_atlas = new Map<String, Sprite>();
		if (atlas.ATLAS != null && atlas.ATLAS.SPRITES != null)
		{
			for (s in atlas.ATLAS.SPRITES)
				_atlas.set(s.SPRITE.name, s.SPRITE);
		}
	}

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

	// should change dis to all private?
	public static function generateSymbolmap(symbols:Array<Symbol>)
	{
		for (symbol in symbols)
		{
			// trace(symbol.SN + "has: " + symbol.TL.L.length + " LAYERS");

			symbolMap.set(symbol.SN, symbol);
			// parseTimeline(symbol.TL);
		}
	}

	public static function preprocessSymbolData(anim:Symbol):Symbol
	{
		var timelineData:Timeline = anim.TL;
		var layerData:Array<Layer> = timelineData.L;

		if (!timelineData.sortedForRender)
		{
			timelineData.sortedForRender = true;
			layerData.reverse();
		}

		for (layerStuff in layerData)
		{
			var frames:Array<Frame> = layerStuff.FR;

			for (frame in frames)
			{
				var elements:Array<Element> = frame.E;
				for (e in 0...elements.length)
				{
					var element:Element = elements[e];
					if (element.ASI != null)
					{
						element = elements[e] = {
							SI: {
								SN: "ATLAS_SYMBOL_SPRITE",
								LP: "LP",
								TRP: {x: 0, y: 0},
								M3D: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
								FF: 0,
								ST: "G",
								ASI: element.ASI
							}
						}
					}
				}
			}
		}

		return anim;
	}

	public static var curLoopType:String;

	/**
	 * Stuff for debug parsing
	 */
	public static var depthTypeBeat:String = "";

	/**
	 * Array of bullshit that will eventually be RENDERED by whoever wanna use it!
	 */
	public static var frameList:Array<Array<VALIDFRAME>> = [];

	// for loop stuf

	/**
	 * Similar to frameList, keeps track of shit according to framess?
	 * That amount of arrays within arrays is fuckin dumb
	 * but innermost array is basically just x and y value, cuz im dum
	 */
	public static var matrixHelp:Array<Array<Array<Float>>> = [];

	public static var trpHelpIDK:Array<Array<Array<Float>>> = [];

	public static var loopedFrameShit:Int = 0;

	public static var funnyMatrix:Matrix = new Matrix();
	public static var matrixFlipper:Array<Matrix> = [];

	// clean up all the crazy ass arrays

	public static function resetFrameList()
	{
		// funnyMatrix.identity();

		frameList = [];
		frameList.push([]);
		matrixHelp = [];
		matrixHelp.push([]);

		trpHelpIDK = [];
		trpHelpIDK.push([]);
	}

	public static var isFlipped:Bool = false;

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
				// single frame stuff isn't fully implemented
			}
			else
				frameInput = frameArray[frameInput];

			// trace(frameMap.get(frameInput));

			var frame:Frame = frameMap.get(frameInput);

			// get somethin sorted per element list, which would essentially be per symbol things properly sorted
			// seperate data types if symbol or atlassymbolinstance? would probably be maybe slightly less memory intensive? i dunno

			// goes thru each layer, and then each element
			// after it gets thru each element it adds to the layer frame stuff.
			// make somethin that works recursively, maybe thats the symbol dictionary type shit?

			for (element in frame.E)
			{
				if (Reflect.hasField(element, "ASI"))
				{
					matrixHelp[matrixHelp.length - 1].push(element.ASI.M3D);

					var m3D = element.ASI.M3D;
					var lilMatrix:Matrix = new Matrix(m3D[0], m3D[1], m3D[4], m3D[5], m3D[12], m3D[13]);
					matrixFlipper.push(lilMatrix);

					// matrixFlipper.reverse();

					// funnyMatrix.identity();

					// for (m in matrixFlipper)
					// funnyMatrix.concat(m);

					if (isFlipped)
					{
						trace("MORE FLIPPED SHIT");
						trace("MORE FLIPPED SHIT");
						trace("MORE FLIPPED SHIT");
						trace(funnyMatrix);
						trace(matrixFlipper);
					}

					// trace(funnyMatrix);

					funnyMatrix.concat(lilMatrix);
					// trace(funnyMatrix);

					frameList[frameList.length - 1].push({
						frameName: element.ASI.N,
						depthString: depthTypeBeat,
						matrixArray: matrixHelp[matrixHelp.length - 1],
						trpArray: trpHelpIDK[trpHelpIDK.length - 1],
						fullMatrix: funnyMatrix.clone()
					});

					// flips the matrix once?? I cant remember exactly why it needs to be flipped
					// matrixHelp[matrixHelp.length - 1].reverse();

					// trpHelpIDK = [];

					// push the matrix array after each symbol?

					funnyMatrix.identity();
					matrixFlipper = [];

					depthTypeBeat = "";
					curLoopType = "";
					loopedFrameShit = 0;

					isFlipped = false;
				}
				else
				{
					var m3D = element.SI.M3D;
					var lilMatrix:Matrix = new Matrix(m3D[0], m3D[1], m3D[4], m3D[5], m3D[12], m3D[13]);

					if (lilMatrix.a == -1)
					{
						isFlipped = true;

						trace('IS THE NEGATIVE ONE');
					}

					if (isFlipped)
						trace(lilMatrix);

					funnyMatrix.concat(lilMatrix);
					matrixFlipper.push(lilMatrix);
					// trace(funnyMatrix);

					matrixHelp[matrixHelp.length - 1].push(element.SI.M3D);
					trpHelpIDK[trpHelpIDK.length - 1].push([element.SI.TRP.x, element.SI.TRP.y]); // trpHelpIDK.push();
					depthTypeBeat += "->" + element.SI.SN;
					curLoopType = element.SI.LP;

					var inputFrame:Int = element.SI.FF;

					// JANKY FIX, MAY NOT ACCOUNT FOR ALL SCENARIOS OF SINGLE FRAME ANIMATIONS!!
					if (curLoopType == "SF")
					{
						// trace("LOOP SHIT: " + inputFrame);
						loopedFrameShit = inputFrame;
					}

					// condense the animation code, so it automatically already fills up animation shit per symbol

					parseTimeline(symbolMap.get(element.SI.SN).TL, tabbed + 1, inputFrame);
				}

				// idk if this should go per layer or per element / object?

				matrixHelp.push([]);
				trpHelpIDK.push([]);
			}

			if (tabbed == 0)
			{
				frameList[frameList.length - 1].reverse();
				frameList.push([]); // new layer essentially
			}
		}

		frameList.reverse();
	}
}

typedef VALIDFRAME =
{
	frameName:String,
	depthString:String,
	matrixArray:Array<Array<Float>>,
	trpArray:Array<Array<Float>>,
	fullMatrix:Matrix
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
	?sortedForRender:Bool,
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
	// maybe need to implement names if it has frame labels?
}

typedef Element =
{
	SI:SymbolInstance,
	?ASI:AlsoSymbolInstance
	// lmfao idk what ASI stands for lmfaoo, i dont think its "also"
}

typedef SymbolInstance =
{
	SN:String,
	ASI:AlsoSymbolInstance,

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
