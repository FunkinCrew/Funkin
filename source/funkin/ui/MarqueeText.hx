package funkin.ui;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Matrix;

class MarqueeFadeShader extends flixel.system.FlxAssets.FlxShader
{
  @:glFragmentSource('
		#pragma header

		uniform float uFadeLeft;
		uniform float uFadeRight;
		uniform float uGamma;

		void main()
		{
			vec4  col  = flixel_texture2D(bitmap, openfl_TextureCoordv);
			float x    = openfl_TextureCoordv.x;
			float aL   = uFadeLeft <= 0.0001 ? 1.0 : smoothstep(0.0, uFadeLeft, x);
			float aR   = uFadeRight <= 0.0001 ? 1.0 : 1.0 - smoothstep(1.0 - uFadeRight, 1.0, x);
			float mask = pow(aL * aR, uGamma);
			gl_FragColor = col * mask;
		}
	')
  public function new(fl:Float = 0.12, fr:Float = 0.12, gamma:Float = 0.65)
  {
    super();
    uFadeLeft.value = [fl];
    uFadeRight.value = [fr];
    uGamma.value = [gamma];
  }

  public inline function setFade(l:Float, r:Float):Void
  {
    setFadeLeft(l);
    setFadeRight(r);
  }

  public inline function setFadeLeft(value:Float):Void uFadeLeft.value = [value];

  public inline function setFadeRight(value:Float):Void uFadeRight.value = [value];

  public inline function setGamma(g:Float):Void
  {
    uGamma.value = [g];
  }
}

class MarqueeText extends FlxSprite
{
  public var speed:Float;
  public var direction(default, set):Int = 1;
  public var paused:Bool = false;
  public var currentSpeed(default, null):Float = 0;
  public var bounceMode:Bool = false;
  public var bounceOffset:Float = 0;
  public var bounceRange(default, null):Float = 0;
  public var fadeLeftAmount(default, null):Float = 0.12;
  public var fadeRightAmount(default, null):Float = 0.12;
  public var fadeGamma(default, null):Float = 0.65;
  public var fadeEnabled(default, null):Bool = true;
  public var useExternalShader:Bool = false;
  public var textField(get, never):FlxText;
  public var text(get, set):String;
  public var font(get, set):String;
  public var size(get, set):Int;
  public var bold(get, set):Bool;
  public var italic(get, set):Bool;
  public var textColor(get, set):FlxColor;
  public var borderStyle(get, set):FlxTextBorderStyle;
  public var borderColor(get, set):FlxColor;
  public var borderSize(get, set):Float;
  public var alignment(get, set):FlxTextAlign;
  public var textAntialiasing(get, set):Bool;

  var _src:FlxText;
  var _fadeShader:Null<MarqueeFadeShader>;
  var _scrollX:Float = 0;
  var _textW:Float = 0;
  var _textH:Float = 0;
  var _textOffY:Float = 0;
  var _gap:Float;
  var _easeTime:Float;
  var _numCopies:Int = 3;
  var _drawMatrix:Matrix;
  var _lastScrollX:Float = Math.NEGATIVE_INFINITY;
  var _lastBounceOff:Float = Math.NEGATIVE_INFINITY;
  var _drawDirty:Bool = true;

  public function new(x:Float,
    y:Float,
    panelWidth:Float,
    panelHeight:Float,
    text:String,
    fontSize:Int = 16,
    speed:Float = 90,
    gap:Float = 100,
    fadeLeft:Float = 0.12,
    fadeRight:Float = 0.12,
    gamma:Float = 0.65,
    bgColor:FlxColor = FlxColor.TRANSPARENT,
    textColor:FlxColor = FlxColor.WHITE,
    ?font:String,
    easeTime:Float = 0.35,
    useExternalShader:Bool = false)
  {
    super(x, y);

    this.speed = speed;
    _gap = gap;
    _easeTime = easeTime;
    this.useExternalShader = useExternalShader;

    makeGraphic(Std.int(panelWidth), Std.int(panelHeight), bgColor, true);

    _src = new FlxText(0, 0, 0, text, fontSize);
    _src.autoSize = true;
    _src.color = textColor;
    if (font != null) _src.font = font;
    _src.drawFrame(true);

    _rebuildLayout(panelHeight);

    _scrollX = panelWidth;
    _drawMatrix = new Matrix();

    _fadeShader = useExternalShader ? null : new MarqueeFadeShader(fadeLeft, fadeRight, gamma);
    fadeLeftAmount = fadeLeft;
    fadeRightAmount = fadeRight;
    fadeGamma = gamma;
    if (_fadeShader != null) shader = _fadeShader;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (!bounceMode)
    {
      _easeSpeed(elapsed);
      _advanceLoop(elapsed);
    }
  }

  inline function _easeSpeed(dt:Float):Void
  {
    var target = paused ? 0.0 : speed;
    if (_easeTime <= 0)
    {
      currentSpeed = target;
      return;
    }
    currentSpeed += (target - currentSpeed) * Math.min(1.0, dt / _easeTime * 5.0);
    if (Math.abs(currentSpeed) < 0.5) currentSpeed = 0;
  }

  inline function _advanceLoop(dt:Float):Void
  {
    if (currentSpeed == 0) return;

    var cycle = Math.max(1.0, _textW + _gap);
    _scrollX -= currentSpeed * direction * dt;

    if (direction >= 0)
    {
      while (_scrollX < -cycle)
        _scrollX += cycle;
    }
    else
    {
      while (_scrollX > 0)
        _scrollX -= cycle;
    }
  }

  override public function draw():Void
  {
    if (!visible || !exists || alpha <= 0)
    {
      super.draw();
      return;
    }

    var posChanged:Bool;
    if (bounceMode) posChanged = bounceOffset != _lastBounceOff;
    else
      posChanged = _scrollX != _lastScrollX;

    if (_drawDirty || posChanged)
    {
      if (!isOnScreen())
      {
        super.draw();
        return;
      }

      _drawDirty = false;
      _lastScrollX = _scrollX;
      _lastBounceOff = bounceOffset;

      pixels.fillRect(pixels.rect, 0x00000000);

      var srcPx = _src.framePixels;
      if (srcPx != null)
      {
        if (bounceMode) _drawBounce(srcPx);
        else
          _drawLoop(srcPx);
      }

      dirty = true;
    }

    super.draw();
  }

  inline function _drawSource(srcPx:openfl.display.BitmapData,
    x:Float,
    y:Float):Void
  {
    _drawMatrix.identity();
    _drawMatrix.tx = x;
    _drawMatrix.ty = y;
    pixels.draw(srcPx, _drawMatrix, null, null, null, true);
  }

  inline function _getStaticX():Float
  {
    if (_textW >= width) return 0;

    return switch (_src.alignment)
    {
      case CENTER:
        (width - _textW) * 0.5;
      case RIGHT:
        width - _textW;
      default:
        0;
    }
  }

  function _drawLoop(srcPx:openfl.display.BitmapData):Void
  {
    var pw = width;
    var tw = _textW;
    var srcH = _textH;
    var cycle = Math.max(1.0, _textW + _gap);
    var ty = _textOffY;

    if (tw <= 0 || srcH <= 0) return;

    for (i in 0..._numCopies)
    {
      var sx = _scrollX + cycle * i;
      if (sx + tw <= 0 || sx >= pw) continue;

      _drawSource(srcPx, sx, ty);
    }
  }

  function _drawBounce(srcPx:openfl.display.BitmapData):Void
  {
    var pw = width;
    var tw = _textW;
    var srcH = _textH;
    var ty = _textOffY;

    if (tw <= 0 || srcH <= 0) return;

    if (tw <= pw)
    {
      _drawSource(srcPx, _getStaticX(), ty);
      return;
    }

    _drawSource(srcPx, -bounceOffset, ty);
  }

  public function applyMarkup(input:String,
    rules:Array<FlxTextFormatMarkerPair>):MarqueeText
  {
    _src.applyMarkup(input, rules);
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return this;
  }

  public function addFormat(format:FlxTextFormat, start:Int = -1, end:Int = -1):MarqueeText
  {
    _src.addFormat(format, start, end);
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return this;
  }

  public function clearFormats():MarqueeText
  {
    _src.clearFormats();
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return this;
  }

  public inline function setText(value:String):Void text = value;

  public function refresh():Void
  {
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
  }

  public function setPanelSize(w:Float, h:Float):Void
  {
    final newWidth:Int = Std.int(w);
    final newHeight:Int = Std.int(h);
    if (pixels != null && pixels.width == newWidth && pixels.height == newHeight) return;

    makeGraphic(newWidth, newHeight, FlxColor.TRANSPARENT, true);
    _rebuildLayout(h);
    _scrollX = bounceMode ? 0 : w;
    bounceOffset = 0;
    _drawDirty = true;
  }

  public inline function setFade(left:Float, right:Float):Void
  {
    setFadeLeft(left);
    setFadeRight(right);
  }

  public inline function setFadeLeft(value:Float):Void
  {
    fadeLeftAmount = value;
    _fadeShader?.setFadeLeft(value);
  }

  public inline function setFadeRight(value:Float):Void
  {
    fadeRightAmount = value;
    _fadeShader?.setFadeRight(value);
  }

  public inline function setGamma(g:Float):Void
  {
    fadeGamma = g;
    _fadeShader?.setGamma(g);
  }

  public function setFadeEnabled(value:Bool):Void
  {
    fadeEnabled = value;
    if (!useExternalShader) shader = value ? _fadeShader : null;
  }

  public inline function stopInstant():Void
  {
    currentSpeed = 0;
    paused = true;
  }

  public inline function resetScroll(startAtRight:Bool = true):Void
  {
    if (bounceMode || !startAtRight) _scrollX = 0;
    else
      _scrollX = direction >= 0 ? width : -(_textW + _gap);
    bounceOffset = 0;
    _drawDirty = true;
  }

  function _rebuildLayout(panelH:Float):Void
  {
    _textW = _src.width;
    _textH = _src.height;
    _textOffY = Math.max(0, (panelH - _textH) * 0.5);
    bounceRange = Math.max(0, _textW - width);

    var cycle = Math.max(1.0, _textW + _gap);
    _numCopies = Std.int(Math.ceil(width / cycle)) + 2;
    if (_numCopies < 2) _numCopies = 2;
  }

  function set_direction(v:Int):Int
  {
    if (!bounceMode) _scrollX = v >= 0 ? width : -(_textW + _gap);
    return direction = v;
  }

  inline function get_textField():FlxText return _src;

  function get_text():String return _src.text;

  function set_text(v:String):String
  {
    _src.text = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_font():String return _src.font;

  function set_font(v:String):String
  {
    _src.font = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_size():Int return _src.size;

  function set_size(v:Int):Int
  {
    _src.size = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_bold():Bool return _src.bold;

  function set_bold(v:Bool):Bool
  {
    _src.bold = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_italic():Bool return _src.italic;

  function set_italic(v:Bool):Bool
  {
    _src.italic = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_textColor():FlxColor return _src.color;

  function set_textColor(v:FlxColor):FlxColor
  {
    _src.color = v;
    _src.drawFrame(true);
    _drawDirty = true;
    return v;
  }

  function get_borderStyle():FlxTextBorderStyle return _src.borderStyle;

  function set_borderStyle(v:FlxTextBorderStyle):FlxTextBorderStyle
  {
    _src.borderStyle = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_borderColor():FlxColor return _src.borderColor;

  function set_borderColor(v:FlxColor):FlxColor
  {
    _src.borderColor = v;
    _src.drawFrame(true);
    _drawDirty = true;
    return v;
  }

  function get_borderSize():Float return _src.borderSize;

  function set_borderSize(v:Float):Float
  {
    _src.borderSize = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_alignment():FlxTextAlign return _src.alignment;

  function set_alignment(v:FlxTextAlign):FlxTextAlign
  {
    _src.alignment = v;
    _src.drawFrame(true);
    _rebuildLayout(height);
    _drawDirty = true;
    return v;
  }

  function get_textAntialiasing():Bool return _src.antialiasing;

  function set_textAntialiasing(v:Bool):Bool
  {
    _src.antialiasing = v;
    _src.drawFrame(true);
    _drawDirty = true;
    return v;
  }

  override public function destroy():Void
  {
    _src = FlxDestroyUtil.destroy(_src);
    super.destroy();
  }
}
