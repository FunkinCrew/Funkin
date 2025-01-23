package funkin.ui.charSelect;

import openfl.display.BitmapData;
import openfl.filters.DropShadowFilter;
import openfl.filters.ConvolutionFilter;
import funkin.graphics.shaders.StrokeShader;

class CharIconCharacter extends CharIcon
{
  public var dropShadowFilter:DropShadowFilter;

  var matrixFilter:Array<Float> = [
    1, 1, 1,
    1, 1, 1,
    1, 1, 1
  ];

  var divisor:Int = 1;
  var bias:Int = 0;
  var convolutionFilter:ConvolutionFilter;

  public var noDropShadow:BitmapData;
  public var withDropShadow:BitmapData;

  var strokeShader:StrokeShader;

  public function new(path:String)
  {
    super(0, 0, false);

    loadGraphic(Paths.image('freeplay/icons/' + path + 'pixel'));
    setGraphicSize(128, 128);
    updateHitbox();
    antialiasing = false;

    strokeShader = new StrokeShader();
    // shader = strokeShader;

    // noDropShadow = pixels.clone();

    // dropShadowFilter = new DropShadowFilter(5, 45, 0, 1, 0, 0);
    // convolutionFilter = new ConvolutionFilter(3, 3, matrixFilter, divisor, bias);
    // pixels.applyFilter(pixels, pixels.rect, new openfl.geom.Point(0, 0), dropShadowFilter);
    // pixels.applyFilter(pixels, pixels.rect, new openfl.geom.Point(0, 0), convolutionFilter);
    // withDropShadow = pixels.clone();

    // pixels = noDropShadow.clone();
  }
}
