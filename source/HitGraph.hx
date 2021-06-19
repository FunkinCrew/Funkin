import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFieldAutoSize;
import flixel.system.FlxAssets;
import openfl.text.TextFormat;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormatAlign;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * stolen from https://github.com/HaxeFlixel/flixel/blob/master/flixel/system/debug/stats/StatsGraph.hx
 */
class HitGraph extends Sprite
{
	static inline var AXIS_COLOR:FlxColor = 0xffffff;
	static inline var AXIS_ALPHA:Float = 0.5;
	inline static var HISTORY_MAX:Int = 30;

	public var minLabel:TextField;
	public var curLabel:TextField;
	public var maxLabel:TextField;
	public var avgLabel:TextField;

	public var minValue:Float = -(Math.floor((PlayState.rep.replay.sf / 60) * 1000) + 95);
	public var maxValue:Float = Math.floor((PlayState.rep.replay.sf / 60) * 1000) + 95;

	public var graphColor:FlxColor;

	public var history:Array<Dynamic> = [];

	public var bitmap:Bitmap;

	var _axis:Shape;
	var _width:Int;
	var _height:Int;
	var _unit:String;
	var _labelWidth:Int;
	var _label:String;

	public function new(X:Int, Y:Int, Width:Int, Height:Int)
	{
		super();
		x = X;
		y = Y;
		_width = Width;
		_height = Height;

		var bm = new BitmapData(Width,Height);
		bm.draw(this);
		bitmap = new Bitmap(bm);

		_axis = new Shape();
		_axis.x = _labelWidth + 10;

		var ts = Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166;

		var early = createTextField(10,10,FlxColor.WHITE,12);
		var late = createTextField(10,_height - 20,FlxColor.WHITE,12);

		early.text = "Early (" + -166 * ts + "ms)";
		late.text = "Late (" + 166 * ts + "ms)";

		addChild(early);
		addChild(late);

		addChild(_axis);

		drawAxes();
	}

	/**
	 * Redraws the axes of the graph.
	 */
	function drawAxes():Void
	{
		var gfx = _axis.graphics;
		gfx.clear();
		gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

		// y-Axis
		gfx.moveTo(0, 0);
		gfx.lineTo(0, _height);

		// x-Axis
		gfx.moveTo(0, _height);
		gfx.lineTo(_width, _height);

		gfx.moveTo(0, _height / 2);
		gfx.lineTo(_width, _height / 2);
		
	}

	public static function createTextField(X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):TextField
	{
		return initTextField(new TextField(), X, Y, Color, Size);
	}

	public static function initTextField<T:TextField>(tf:T, X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):T
	{
		tf.x = X;
		tf.y = Y;
		tf.multiline = false;
		tf.wordWrap = false;
		tf.embedFonts = true;
		tf.selectable = false;
		#if flash
		tf.antiAliasType = AntiAliasType.NORMAL;
		tf.gridFitType = GridFitType.PIXEL;
		#end
		tf.defaultTextFormat = new TextFormat("assets/fonts/vcr.ttf", Size, Color.to24Bit());
		tf.alpha = Color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	function drawJudgementLine(ms:Float):Void
	{

		var gfx:Graphics = graphics;

		gfx.lineStyle(1, graphColor, 0.3);

		var ts = Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166;
		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);

		var value = ((ms * ts) - minValue) / range;

		var pointY = _axis.y + ((-value * _height - 1) + _height);

		var graphX = _axis.x + 1;

		if (ms == 45)
			gfx.moveTo(graphX, _axis.y + pointY);

		var graphX = _axis.x + 1;

		gfx.drawRect(graphX,pointY, _width,1);

		gfx.lineStyle(1, graphColor, 1);
	}

	/**
	 * Redraws the graph based on the values stored in the history.
	 */
	function drawGraph():Void
	{
		var gfx:Graphics = graphics;
		gfx.clear();
		gfx.lineStyle(1, graphColor, 1);

		gfx.beginFill(0x00FF00);
		drawJudgementLine(45);
		gfx.endFill();

		gfx.beginFill(0xFF0000);
		drawJudgementLine(90);
		gfx.endFill();

		gfx.beginFill(0x8b0000);
		drawJudgementLine(135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(166);
		gfx.endFill();

		gfx.beginFill(0x00FF00);
		drawJudgementLine(-45);
		gfx.endFill();

		gfx.beginFill(0xFF0000);
		drawJudgementLine(-90);
		gfx.endFill();

		gfx.beginFill(0x8b0000);
		drawJudgementLine(-135);
		gfx.endFill();

		gfx.beginFill(0x580000);
		drawJudgementLine(-166);
		gfx.endFill();


		var inc:Float = _width / (PlayState.rep.replay.songNotes.length);
		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
		var graphX = _axis.x + 1;

		for (i in 0...history.length)
		{
			
			var value = (history[i][0] - minValue) / range;
			var judge = history[i][1];

			switch(judge)
			{
				case "sick":
					gfx.beginFill(0x00FFFF);
				case "good":
					gfx.beginFill(0x00FF00);
				case "bad":
					gfx.beginFill(0xFF0000);
				case "shit":
					gfx.beginFill(0x8b0000);
				case "miss":
					gfx.beginFill(0x580000);
				default:
					gfx.beginFill(0xFFFFFF);
			}
			var pointY = (-value * _height - 1) + _height;
			/*if (i == 0)
				gfx.moveTo(graphX, _axis.y + pointY);*/
			gfx.drawRect(graphX + (i * inc), pointY,4,4);

			gfx.endFill();
		}

		var bm = new BitmapData(_width,_height);
		bm.draw(this);
		bitmap = new Bitmap(bm);
	}

	public function addToHistory(diff:Float, judge:String)
	{
		history.push([diff,judge]);
	}

	public function update():Void
	{
		drawGraph();
	}

	public function average():Float
	{
		var sum:Float = 0;
		for (value in history)
			sum += value;
		return sum / history.length;
	}

	public function destroy():Void
	{
		_axis = FlxDestroyUtil.removeChild(this, _axis);
		history = null;
	}
}