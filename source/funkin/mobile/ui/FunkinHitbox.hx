package funkin.mobile.ui;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.input.actions.FlxActionInput;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.FunkinSprite;
import funkin.mobile.input.ControlsHandler;
import funkin.play.notes.NoteDirection;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import openfl.Vector;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.animation.AnimationData;
import funkin.util.assets.FlxAnimationUtil;
import funkin.ui.FullScreenScaleMode;

enum FunkinHintAlphaStyle
{
  INVISIBLE_TILL_PRESS;
  VISIBLE_TILL_PRESS;
}

/**
 * The `FunkinHint` class represents a button with HSV color properties, allowing hue and saturation adjustments.
 */
@:nullSafety
class FunkinHint extends FunkinButton
{
  /**
   * A map defining different alpha styles for hint visibility during press and release states.
   *
   * Each style is represented as a key with an associated array of two alpha values:
   * - The first value corresponds to the alpha when the hint is pressed.
   * - The second value corresponds to the alpha when the hint is not pressed.
   * - The third value corresponds to the duratuon it'll take to tween between the two values.
   */
  static final HINT_ALPHA_STYLE:Map<FunkinHintAlphaStyle, Array<Float>> = [
    INVISIBLE_TILL_PRESS => [0.3, 0.00001, 0.01],
    VISIBLE_TILL_PRESS => [0.4, 0.2, 0.08]
  ];

  /**
   * Indicates whether the hint is pixel.
   */
  public var isPixel:Bool = false;

  /**
   * The direction of the note associated with the button.
   */
  var noteDirection:NoteDirection;

  /**
   * The label associated with the button.
   */
  var label:Null<FunkinSprite>;

  /**
   * The tween used to animate the alpha changes of the button.
   */
  var labelAlphaTween:Null<FlxTween>;

  /**
   * The HSV shader used to adjust the hue and saturation of the button.
   */
  var hsvShader:HSVShader;

  /**
   * The tween used to animate the alpha changes of the button.
   */
  var alphaTween:Null<FlxTween>;

  var followTarget:Null<FunkinSprite>;

  var followTargetSize:Bool = false;

  /**
   * Creates a new `FunkinHint` object.
   *
   * @param x The x position of the button.
   * @param y The y position of the button.
   * @param noteDirection The direction of the note the button represents (e.g. left, right).
   * @param label An graphic to display as the label on the button.
   */
  public function new(x:Float, y:Float, noteDirection:NoteDirection, label:Null<FlxGraphic>):Void
  {
    super(x, y);

    this.noteDirection = noteDirection;

    if (label != null)
    {
      this.label = new FunkinSprite(x, y);
      this.label.loadGraphic(label);
    }

    hsvShader = new HSVShader();
    hsvShader.hue = 1.0;
    hsvShader.saturation = 1.0;
    hsvShader.value = 1.0;
    shader = hsvShader;
  }

  /**
   * Initializes alpha tween animations for the button.
   *
   * @param style The alpha style to use.
   */
  public function initTween(style:FunkinHintAlphaStyle):Void
  {
    final hintAlpha:Null<Array<Float>> = HINT_ALPHA_STYLE.get(style);
    final swapValues:Bool = style == VISIBLE_TILL_PRESS;

    if (hintAlpha == null || hintAlpha.length < 2) return;

    function createTween(targetAlpha:Float, transitionTime:Float, isPressed:Bool):Void
    {
      alphaTween?.cancel();
      alphaTween = FlxTween.tween(this, {alpha: targetAlpha}, transitionTime, {ease: FlxEase.circInOut});

      if (label != null)
      {
        labelAlphaTween?.cancel();
        labelAlphaTween = FlxTween.tween(label, {alpha: (hintAlpha[0] + hintAlpha[1]) - targetAlpha}, transitionTime, {ease: FlxEase.circInOut});
      }
    }

    onDown.add(createTween.bind(hintAlpha[swapValues ? 1 : 0], hintAlpha[2], true));
    onUp.add(createTween.bind(hintAlpha[swapValues ? 0 : 1], hintAlpha[2], false));
    onOut.add(createTween.bind(hintAlpha[swapValues ? 0 : 1], hintAlpha[2], false));

    alpha = hintAlpha[swapValues ? 0 : 1];

    if (label != null && hintAlpha != null) label.alpha = hintAlpha[0];
  }

  /**
   * Makes the hitbox follow the specified sprite.
   *
   * @param sprite The FunkinSprite instance that the hitbox should follow.
   * @param followTargetSize A boolean indicating whether the hitbox should adjust to the target's size. Default is true.
   */
  public function follow(sprite:FunkinSprite, followTargetSize:Bool = true):Void
  {
    this.followTargetSize = followTargetSize;
    followTarget = sprite;
  }

  /**
   * Desaturates the button, setting its saturation to 0.2.
   */
  public function desaturate():Void
  {
    hsvShader.saturation = 0.2;
  }

  /**
   * Sets the hue of the button.
   *
   * @param hue The new hue value.
   */
  public function setHue(hue:Float):Void
  {
    hsvShader.hue = hue;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (followTarget != null)
    {
      final widthMultiplier:Float = isPixel ? 1.35 : 1.35;
      final heightMultiplier:Float = 8;

      final xOffset:Float = isPixel ? 43.265 : 0;
      final yOffset:Float = isPixel ? 57.65 : 0;

      // TODO: THIS feels off when playing on regular notes but it's fine for pixel notes? Hard to explain needs more testing
      if (followTargetSize)
      {
        setSize(followTarget.width * widthMultiplier + (isPixel ? 93.05 : 0), followTarget.height * heightMultiplier + (isPixel ? 118 : 0));
      }

      setPosition((followTarget.x - (followTarget.width * ((widthMultiplier - 1) / 2))) - xOffset, (followTarget.y - 220) - yOffset);
    }
  }

  public override function draw():Void
  {
    super.draw();

    if (label != null && label.visible)
    {
      label.cameras = _cameras;
      label.draw();
    }
  }

  #if FLX_DEBUG
  public override function drawDebug():Void
  {
    super.drawDebug();

    if (label != null) label.drawDebug();
  }
  #end

  /**
   * Cleans up memory used by the `FunkinHint`.
   */
  public override function destroy():Void
  {
    if (alphaTween != null) alphaTween = FlxDestroyUtil.destroy(alphaTween);

    if (labelAlphaTween != null) labelAlphaTween = FlxDestroyUtil.destroy(labelAlphaTween);

    if (label != null) label = FlxDestroyUtil.destroy(label);

    super.destroy();
  }

  override function set_x(v:Float):Float
  {
    super.set_x(v);

    if (label != null) label.x = x;

    return x;
  }

  override function set_y(v:Float):Float
  {
    super.set_y(v);

    if (label != null) label.y = y;

    return y;
  }
}

enum abstract FunkinHitboxControlSchemes(String) from String to String
{
  var FourLanes = 'Four Lanes';
  var DoubleThumbTriangle = 'Double Thumb Triangle';
  var DoubleThumbSquare = 'Double Thumb Square';
  var DoubleThumbDPad = 'Double Thumb DPad';
  var Arrows = 'Arrows';
}

/**
 * This class represents a zone with four buttons, designed to be easily customizable in layout.
 */
@:nullSafety
class FunkinHitbox extends FlxTypedSpriteGroup<FunkinHint>
{
  /**
   * Indicates whether the hitbox is pixel.
   */
  public var isPixel(default, set):Bool = false;

  /**
   * A `FlxTypedSignal` that triggers every time a button is pressed.
   */
  public var onHintDown:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * A `FlxTypedSignal` that triggers every time a button is released.
   */
  public var onHintUp:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * The list of tracked inputs for the hitbox.
   */
  var trackedInputs:Array<FlxActionInput> = [];

  /**
   * Creates a new `FunkinHitbox` object.
   */
  public function new(?schemeOverride:String, ?showGradint:Bool = true, ?directionsOverride:Array<NoteDirection>, ?colorsOverride:Array<FlxColor>):Void
  {
    super();

    final hintsColors:Array<FlxColor> = (colorsOverride == null || colorsOverride.length == 0) ? [0xFFC34B9A, 0xFF00FFFF, 0xFF12FB06, 0xFFF9393F] : colorsOverride;
    final hintsNoteDirections:Array<NoteDirection> = (directionsOverride == null || directionsOverride.length == 0) ? [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT] : directionsOverride;

    #if mobile
    final controlsScheme:String = (schemeOverride == null || schemeOverride.length == 0) ? Preferences.controlsScheme : schemeOverride;

    switch (controlsScheme)
    {
      case FunkinHitboxControlSchemes.FourLanes:
        final hintWidth:Int = Math.floor(FlxG.width / hintsNoteDirections.length);
        final hintHeight:Int = FlxG.height;

        for (i in 0...hintsNoteDirections.length)
        {
          add(createHintLane(i * hintWidth, 0, hintsNoteDirections[i % hintsNoteDirections.length], hintWidth, hintHeight,
            hintsColors[i % hintsColors.length], true, showGradint));
        }
      case FunkinHitboxControlSchemes.DoubleThumbTriangle:
        final screenHalf:Int = Math.floor(FlxG.width / 2);

        for (i in 0...2)
        {
          final xOffset:Int = (i == 1) ? screenHalf : 0;

          add(createHintTriangle(xOffset, 0, hintsNoteDirections[0], Math.floor(FlxG.width / 4), FlxG.height, hintsColors[0], showGradint));
          add(createHintTriangle(xOffset, FlxG.height / 2, hintsNoteDirections[1], Math.floor(FlxG.width / 2), Math.floor(FlxG.height / 2), hintsColors[1],
            showGradint));
          add(createHintTriangle(xOffset, 0, hintsNoteDirections[2], Math.floor(FlxG.width / 2), Math.floor(FlxG.height / 2), hintsColors[2], showGradint));
          add(createHintTriangle(xOffset + Math.floor(FlxG.width / 4), 0, hintsNoteDirections[3], Math.floor(FlxG.width / 4), FlxG.height, hintsColors[3],
            showGradint));
        }
      case FunkinHitboxControlSchemes.DoubleThumbSquare:
        final screenHalf:Int = Math.floor(FlxG.width / 2);

        final hintWidth:Int = Math.floor((FlxG.width / hintsNoteDirections.length) / 2);
        final hintHeight:Int = FlxG.height;

        final boxWidth:Int = Math.floor(hintWidth * 2);
        final boxHeight:Int = Math.floor(hintHeight / 2);

        for (i in 0...2)
        {
          final xOffset:Int = (i == 1) ? screenHalf : 0;

          for (j in 0...hintsNoteDirections.length)
          {
            if (j == 1 || j == 2)
            {
              add(createHintLane(xOffset + hintWidth, (j == 1) ? boxHeight : 0, hintsNoteDirections[j], boxWidth, boxHeight,
                hintsColors[j % hintsColors.length], false, showGradint));
            }
            else
            {
              add(createHintLane(xOffset + (j == 0 ? 0 : hintWidth + boxWidth), 0, hintsNoteDirections[j], hintWidth, hintHeight,
                hintsColors[j % hintsColors.length], false, showGradint));
            }
          }
        }
      case FunkinHitboxControlSchemes.DoubleThumbDPad:
        final hintSize:Int = 75;
        final outlineThickness:Int = 5;
        final hintsAngles:Array<Float> = [Math.PI, Math.PI / 2, Math.PI * 1.5, 0];
        final hintsZoneRadius:Int = 115;

        for (i in 0...2)
        {
          for (j in 0...hintsAngles.length)
          {
            final x:Float = ((i == 1) ? FlxG.width - (hintSize * 4) : hintSize * 2) + Math.cos(hintsAngles[j]) * hintsZoneRadius;
            final y:Float = (FlxG.height - (hintSize * 3.75)) + Math.sin(hintsAngles[j]) * hintsZoneRadius;

            add(createHintCircle(i == 0 ? x + FullScreenScaleMode.gameNotchSize.x : x - FullScreenScaleMode.gameNotchSize.x, y,
              hintsNoteDirections[j % hintsNoteDirections.length], hintSize, outlineThickness, hintsColors[j % hintsColors.length]));
          }
        }
      case FunkinHitboxControlSchemes.Arrows:
        final hintWidth:Int = 146;
        final hintHeight:Int = 149;
        final noteSpacing:Int = 80;

        final xPos:Int = Math.floor((FlxG.width - (hintWidth + noteSpacing) * hintsNoteDirections.length) / 2);
        final yPos:Int = Math.floor(FlxG.height - hintHeight * 2 - 24);

        for (i in 0...hintsNoteDirections.length)
        {
          add(createHintTransparentNote(xPos + i * hintWidth + noteSpacing * i, yPos, hintsNoteDirections[i % hintsNoteDirections.length], hintWidth,
            hintHeight));
        }
    }
    #end

    scrollFactor.set();

    ControlsHandler.setupHitbox(PlayerSettings.player1.controls, this, trackedInputs);
  }

  public function getFirstHintByDirection(direction:NoteDirection):Null<FunkinHint>
  {
    var result:Null<FunkinHint> = null;
    forEachOfType(FunkinHint, function(hint:FunkinHint):Void {
      @:privateAccess
      if (hint.noteDirection == direction) result = hint;
    });

    return result;
  }

  /**
   * Creates a new `FunkinHint` lane button along side a graphic label with specified properties.
   *
   * @param x The x position of the button.
   * @param y The y position of the button.
   * @param noteDirection The direction of the note the button represents (e.g. left, right).
   * @param width The width of the button.
   * @param height The height of the button.
   * @param id The ID of the button.
   * @param color The color of the button.
   * @return A new `FunkinHint` object.
   */
  function createHintLane(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int, color:FlxColor = 0xFFFFFFFF, label:Bool = true,
      gradient:Bool = true):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, label ? createHintLaneLabelGraphic(width, height, Math.floor(height * 0.035), color) : null);
    hint.loadGraphic(createHintLaneGraphic(width, height, color, gradient));
    hint.onDown.add(onHintDown.dispatch.bind(hint));
    hint.onUp.add(onHintUp.dispatch.bind(hint));
    hint.onOut.add(onHintUp.dispatch.bind(hint));
    hint.initTween(INVISIBLE_TILL_PRESS);
    return hint;
  }

  /**
   * Creates a new `FunkinHint` triangle button with specified properties.
   *
   * @param x The x position of the triangle button.
   * @param y The y position of the triangle button.
   * @param noteDirection The direction of the note the button represents (e.g. left, right).
   * @param size The size of the triangle (base length).
   * @param upright A boolean indicating if the triangle is upright (true) or inverted (false).
   * @param id The unique ID of the triangle button.
   * @param color The color of the triangle button (default is white).
   * @return A new `FunkinHint` triangle object.
   */
  function createHintTriangle(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int, color:FlxColor = 0xFFFFFFFF,
      gradient:Bool = true):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.loadGraphic(createHintTriangleGraphic(width, height, noteDirection, color, gradient));
    hint.onDown.add(onHintDown.dispatch.bind(hint));
    hint.onUp.add(onHintUp.dispatch.bind(hint));
    hint.onOut.add(onHintUp.dispatch.bind(hint));
    hint.initTween(INVISIBLE_TILL_PRESS);
    hint.polygon = getTriangleVertices(width, height, noteDirection);
    return hint;
  }

  /**
   * Creates a new `FunkinHint` circular button with specified properties.
   *
   * @param x The x position of the circular button.
   * @param y The y position of the circular button.
   * @param noteDirection The direction of the note the button represents (e.g., left, right).
   * @param radius The radius of the circular button.
   * @param outlineThickness The thickness of the outline for the circle.
   * @param color The color of the circular button (default is white).
   * @return A new `FunkinHint` circular object.
   */
  function createHintCircle(x:Float, y:Float, noteDirection:NoteDirection, radius:Float, outlineThickness:Int, color:FlxColor = 0xFFFFFFFF):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.loadGraphic(createHintCircleGraphic(radius, outlineThickness, color));
    hint.limitToBounds = false;
    hint.radius = radius;
    hint.onDown.add(onHintDown.dispatch.bind(hint));
    hint.onUp.add(onHintUp.dispatch.bind(hint));
    hint.onOut.add(onHintUp.dispatch.bind(hint));
    hint.initTween(VISIBLE_TILL_PRESS);
    return hint;
  }

  /**
   * Creates a new `FunkinHint` representing a transparent note corresponding to the note from the scene.
   * @param x The x position of the button.
   * @param y The y position of the button.
   * @param noteDirection The direction of the note the button represents (e.g. left, right).
   * @param width The width of the button.
   * @param height The height of the button.
   * @return A new `FunkinHint` object.
   */
  function createHintTransparentNote(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.alpha = 0;
    hint.setSize(width, height);
    hint.onDown.add(onHintDown.dispatch.bind(hint));
    hint.onUp.add(onHintUp.dispatch.bind(hint));
    hint.onOut.add(onHintUp.dispatch.bind(hint));

    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchDefault();
    @:privateAccess
    @:nullSafety(Off)
    {
      hint.frames = Paths.getSparrowAtlas(noteStyle.getStrumlineAssetPath() ?? '', noteStyle.getAssetLibrary(noteStyle.getStrumlineAssetPath(true)));
      FlxAnimationUtil.addAtlasAnimations(hint, noteStyle.getStrumlineAnimationData(noteDirection));
    }

    hint.animation.play('static', true);

    hint.onDown.add(() -> {
      hint.animation.play('press', true);
      hint.centerOrigin();
      hint.centerOffsets();
    });

    hint.onUp.add(() -> {
      hint.animation.play('static', true);
      hint.centerOrigin();
      hint.centerOffsets();
    });

    hint.onOut.add(() -> {
      hint.animation.play('static', true);
      hint.centerOrigin();
      hint.centerOffsets();
    });

    hint.centerOffsets();
    hint.centerOrigin();

    return hint;
  }

  /**
   * Creates a lane graphic for a hint button.
   *
   * @param width The width of the graphic.
   * @param height The height of the graphic.
   * @param baseColor The base color of the graphic.
   * @return A `FlxGraphic` object representing the button graphic.
   */
  function createHintLaneGraphic(width:Int, height:Int, baseColor:FlxColor = 0xFFFFFFFF, gradient:Bool = true):FlxGraphic
  {
    final shape:Shape = new Shape();

    if (gradient)
    {
      final matrix:Matrix = new Matrix();
      matrix.createGradientBox(width, height, 0, 0, 0);
      shape.graphics.beginGradientFill(RADIAL, [baseColor.to24Bit(), baseColor.to24Bit()], [0, baseColor.alphaFloat], [60, 255], matrix, PAD, RGB, 0);
    }
    else
    {
      shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
    }

    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    final graphicData:BitmapData = new BitmapData(width, height, true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  function createHintLaneLabelGraphic(width:Int, height:Int, labelHeight:Int, baseColor:FlxColor = 0xFFFFFFFF):FlxGraphic
  {
    final shape:Shape = new Shape();
    shape.graphics.beginFill(0, 0);
    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    final matrix:Matrix = new Matrix();
    matrix.createGradientBox(width, labelHeight, Math.PI / 2, 0, 0);
    shape.graphics.beginGradientFill(LINEAR, [baseColor.to24Bit(), baseColor.to24Bit()], [baseColor.alphaFloat, 0], [0, 255], matrix);
    shape.graphics.drawRect(0, 0, width, labelHeight);
    shape.graphics.endFill();

    final matrix:Matrix = new Matrix();
    matrix.createGradientBox(width, labelHeight, Math.PI / 2, 0, height - labelHeight);
    shape.graphics.beginGradientFill(LINEAR, [baseColor.to24Bit(), baseColor.to24Bit()], [0, baseColor.alphaFloat], [0, 255], matrix);
    shape.graphics.drawRect(0, height - labelHeight, width, labelHeight);
    shape.graphics.endFill();

    final graphicData:BitmapData = new BitmapData(width, height, true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  /**
   * Creates a triangle graphic for a hint button.
   *
   * @param size The base length of the triangle.
   * @param upright A boolean indicating if the triangle is upright (true) or inverted (false).
   * @param baseColor The base color of the triangle graphic (default is white).
   * @return A `FlxGraphic` object representing the triangle button graphic.
   */
  function createHintTriangleGraphic(width:Int, height:Int, facing:NoteDirection, baseColor:FlxColor = 0xFFFFFFFF, gradient:Bool = true):FlxGraphic
  {
    final shape:Shape = new Shape();

    if (gradient)
    {
      final matrix:Matrix = new Matrix();
      matrix.createGradientBox(width, height, 0, 0, 0);
      shape.graphics.beginGradientFill(RADIAL, [baseColor.to24Bit(), baseColor.to24Bit()], [0, baseColor.alphaFloat], [60, 255], matrix, PAD, RGB, 0);
    }
    else
    {
      shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
    }

    shape.graphics.drawRect(width / 2, height / 2, width / 2, height / 2);
    shape.graphics.drawTriangles(Vector.ofArray(getTriangleVertices(width, height, facing)), Vector.ofArray([0, 1, 2]));
    shape.graphics.endFill();

    final graphicData:BitmapData = new BitmapData(width, height, true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  /**
   * Creates a circular graphic for a hint button.
   *
   * @param radius The radius of the circle.
   * @param baseColor The base color of the circle graphic (default is white).
   * @param outlineThickness The thickness of the outline for the circle.
   * @return A `FlxGraphic` object representing the circular button graphic.
   */
  function createHintCircleGraphic(radius:Float, outlineThickness:Int, baseColor:FlxColor = 0xFFFFFFFF):FlxGraphic
  {
    var brightColor:FlxColor = baseColor;
    brightColor.brightness += 0.6;

    if (baseColor.brightness >= 0.75) baseColor.alphaFloat -= baseColor.brightness * 0.35;

    final shape:Shape = new Shape();
    shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
    shape.graphics.lineStyle(outlineThickness, brightColor.to24Bit(), brightColor.alpha);
    shape.graphics.drawCircle(radius, radius, radius);
    shape.graphics.endFill();

    final matrix:Matrix = new Matrix();
    matrix.translate(outlineThickness, outlineThickness);

    final graphicData:BitmapData = new BitmapData(Math.floor((radius + outlineThickness) * 2), Math.floor((radius + outlineThickness) * 2), true, 0);
    graphicData.draw(shape, matrix, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  /**
   * Сalculates vertices in a given direction
   * @param width width of triangle
   * @param height height of triangle
   * @param facing The side the triangle faces
   * @return array of vertices
   */
  function getTriangleVertices(width:Int, height:Int, facing:NoteDirection):Array<Float>
  {
    if (facing == UP) facing = DOWN;
    else if (facing == DOWN) facing = UP;

    return switch (facing)
    {
      case UP: [width / 2, 0, 0, height, width, height];
      case DOWN: [0, 0, width, 0, width / 2, height];
      case LEFT: [0, 0, width, height / 2, 0, height];
      case RIGHT: [width, 0, 0, height / 2, width, height];
    }
  }

  /**
   * Cleans up memory used by the `FunkinHitbox`.
   */
  public override function destroy():Void
  {
    if (trackedInputs != null && trackedInputs.length > 0) ControlsHandler.removeCachedInput(PlayerSettings.player1.controls, trackedInputs);

    FlxDestroyUtil.destroy(onHintDown);
    FlxDestroyUtil.destroy(onHintUp);

    super.destroy();
  }

  @:noCompletion
  function set_isPixel(value:Bool):Bool
  {
    isPixel = value;
    forEachOfType(FunkinHint, function(hint:FunkinHint):Void {
      hint.isPixel = value;
    });
    return value;
  }
}
