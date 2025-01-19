package funkin.mobile.ui;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.input.actions.FlxActionInput;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.FunkinSprite;
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinButton;
import funkin.play.notes.NoteDirection;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import openfl.Vector;
import flixel.math.FlxMath;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.animation.AnimationData;
import funkin.util.assets.FlxAnimationUtil;

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
   *
   * Available styles:
   * - `'invisible_till_press'`: The hint is invisible until pressed, then becomes visible.
   *   Alpha values: [0.3, 0.00001]
   * - `'visible_till_press'`: The hint is visible until pressed, and then becomes less visible.
   *   Alpha values: [0.3, 0.15]
   */
  @:noCompletion
  static final HINT_ALPHA_STYLE:Map<FunkinHintAlphaStyle, Array<Float>> = [INVISIBLE_TILL_PRESS => [0.3, 0.00001], VISIBLE_TILL_PRESS => [0.5, 0.35]];

  /**
   * The direction of the note associated with the button.
   */
  @:noCompletion
  var noteDirection:NoteDirection;

  /**
   * The label associated with the button, represented as a `FunkinSprite`.
   * It is displayed on top of the button.
   */
  @:noCompletion
  var label:Null<FunkinSprite>;

  /**
   * The HSV shader used to adjust the hue and saturation of the button.
   */
  @:noCompletion
  var hsvShader:HSVShader;

  /**
   * The tween used to animate the alpha changes of the button.
   */
  @:noCompletion
  var alphaTween:Null<FlxTween>;

  public var isPixel:Bool = false;

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

      final hintAlpha:Null<Array<Float>> = HINT_ALPHA_STYLE.get(INVISIBLE_TILL_PRESS);

      if (hintAlpha != null) this.label.alpha = hintAlpha[0];
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
   * Sets up handlers for `onDown`, `onUp`, and `onOut` events to modify the button's
   * `alpha` property using tweens. Cancels any existing tween when an event occurs
   * and creates a new tween to transition the `alpha` property accordingly:
   * - `onDown`: Transitions `alpha` to `HINT_ALPHA_DOWN`.
   * - `onUp` and `onOut`: Transitions `alpha` to `HINT_ALPHA_UP`.
   *
   * Uses `FlxEase.circInOut` easing for smooth transitions.
   */
  public function initTween(style:FunkinHintAlphaStyle):Void
  {
    final hintAlpha:Null<Array<Float>> = HINT_ALPHA_STYLE.get(style);

    if (hintAlpha == null) return;

    switch (style)
    {
      case INVISIBLE_TILL_PRESS:
        onDown.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[0]}, hintAlpha[1],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] - (hintAlpha[0] * twn.percent);
              }
            });
        });
        onUp.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[1]}, hintAlpha[0],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] * twn.percent;
              }
            });
        });
        onOut.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[1]}, hintAlpha[0],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] * twn.percent;
              }
            });
        });

        alpha = hintAlpha[1];
      case VISIBLE_TILL_PRESS:
        onDown.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[0]}, hintAlpha[1],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] - (hintAlpha[0] * twn.percent);
              }
            });
        });
        onUp.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[1]}, hintAlpha[0],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] * twn.percent;
              }
            });
        });
        onOut.add(function():Void {
          if (alphaTween != null) alphaTween.cancel();

          alphaTween = FlxTween.tween(this, {alpha: hintAlpha[1]}, hintAlpha[0],
            {
              ease: FlxEase.circInOut,
              onUpdate: function(twn:FlxTween):Void {
                if (label != null) label.alpha = hintAlpha[0] * twn.percent;
              }
            });
        });

        alpha = hintAlpha[1];
    }
  }

  var followTarget:Null<FunkinSprite>;
  var followTargetSize:Bool = false;

  public function follow(sprite:FunkinSprite, followTargetSize:Bool = true)
  {
    this.followTargetSize = followTargetSize;
    followTarget = sprite;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (followTarget != null)
    {
      var widthMultiplier:Float = isPixel ? 1.1 : 1.35;
      var heightMultiplier:Float = 4;
      var xOffset:Float = isPixel ? 43.265 : 0;
      var yOffset:Float = isPixel ? 57.65 : 0;

      // TODO: THIS feels off when playing on regular notes but it's fine for pixel notes? Hard to explain needs more testing
      if (followTargetSize)
      {
        var scaledWidth = followTarget.width * widthMultiplier + (isPixel ? 93.05 : 0);
        var scaledHeight = followTarget.height * heightMultiplier + (isPixel ? 118 : 0);
        setSize(scaledWidth, scaledHeight);
      }

      var newX = (followTarget.x - (followTarget.width * ((widthMultiplier - 1) / 2))) - xOffset;
      var newY = (followTarget.y - 80) - yOffset;

      setPosition(newX, newY);
    }
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
    if (label != null) label = FlxDestroyUtil.destroy(label);

    if (alphaTween != null) alphaTween = FlxDestroyUtil.destroy(alphaTween);

    super.destroy();
  }

  @:noCompletion
  override function set_x(Value:Float):Float
  {
    super.set_x(Value);

    if (label != null) label.x = x;

    return x;
  }

  @:noCompletion
  override function set_y(Value:Float):Float
  {
    super.set_y(Value);

    if (label != null) label.y = y;

    return y;
  }
}

enum abstract FunkinHitboxControlSchemes(String) from String to String
{
  final FourLanes = 'Four Lanes';
  final DoubleThumbTriangle = 'Double Thumb Triangle';
  final DoubleThumbSquare = 'Double Thumb Square';
  final DoubleThumbDPad = 'Double Thumb DPad';
  final Arrows = 'Arrows';
}

/**
 * The `FunkinHitbox` class represents a zone with four buttons, designed to be easily customizable in layout.
 * It extends `FlxTypedSpriteGroup` with `FunkinHint` as the type parameter.
 */
@:nullSafety
class FunkinHitbox extends FlxTypedSpriteGroup<FunkinHint>
{
  /**
   * A `FlxTypedSignal` that triggers every time a button is pressed.
   */
  public var onHintDown:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  /**
   * A `FlxTypedSignal` that triggers every time a button is released.
   */
  public var onHintUp:FlxTypedSignal<FunkinHint->Void> = new FlxTypedSignal<FunkinHint->Void>();

  public var isPixel(default, set):Bool = false;

  /**
   * The list of tracked inputs for the hitbox.
   */
  @:noCompletion
  var trackedInputs:Array<FlxActionInput> = [];

  /**
   * Creates a new `FunkinHitbox` object.
   */
  public function new(?schemeOverride:String = null, ?directionsOverride:Array<NoteDirection> = null, ?colorsOverride:Array<FlxColor> = null):Void
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
          add(createHintLane(i * hintWidth, 0, hintsNoteDirections[i % hintsNoteDirections.length], hintWidth, hintHeight,
            hintsColors[i % hintsColors.length]));
      case FunkinHitboxControlSchemes.DoubleThumbTriangle:
        final screenHalf:Int = Math.floor(FlxG.width / 2);

        for (i in 0...2)
        {
          final xOffset:Int = (i == 1) ? screenHalf : 0;

          add(createHintTriangle(xOffset, 0, hintsNoteDirections[0], Math.floor(FlxG.width / 4), FlxG.height, hintsColors[0]));
          add(createHintTriangle(xOffset, FlxG.height / 2, hintsNoteDirections[1], Math.floor(FlxG.width / 2), Math.floor(FlxG.height / 2), hintsColors[1]));
          add(createHintTriangle(xOffset, 0, hintsNoteDirections[2], Math.floor(FlxG.width / 2), Math.floor(FlxG.height / 2), hintsColors[2]));
          add(createHintTriangle(xOffset + Math.floor(FlxG.width / 4), 0, hintsNoteDirections[3], Math.floor(FlxG.width / 4), FlxG.height, hintsColors[3]));
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
            if (j == 1 || j == 2) add(createHintLane(xOffset + hintWidth, (j == 1) ? boxHeight : 0, hintsNoteDirections[j], boxWidth, boxHeight,
              hintsColors[j % hintsColors.length], false));
            else
              add(createHintLane(xOffset + (j == 0 ? 0 : hintWidth + boxWidth), 0, hintsNoteDirections[j], hintWidth, hintHeight,
                hintsColors[j % hintsColors.length], false));
          }
        }
      case FunkinHitboxControlSchemes.DoubleThumbDPad:
        final hintSize:Int = 80;
        final hintsAngles:Array<Float> = [Math.PI, Math.PI / 2, Math.PI * 1.5, 0];
        final hintsZoneRadius:Int = 115;

        for (i in 0...2)
        {
          for (j in 0...hintsAngles.length)
          {
            final x:Float = ((i == 1) ? FlxG.width - (hintSize * 4) : hintSize * 2) + Math.cos(hintsAngles[j]) * hintsZoneRadius;
            final y:Float = (FlxG.height - (hintSize * 3.75)) + Math.sin(hintsAngles[j]) * hintsZoneRadius;

            add(createHintCircle(x, y, hintsNoteDirections[j % hintsNoteDirections.length], hintSize, hintsColors[j % hintsColors.length]));
          }
        }
      case FunkinHitboxControlSchemes.Arrows:
        final hintWidth:Int = 146;
        final hintHeight:Int = 149;
        final noteSpacing:Int = 80;

        final xPos:Int = Math.floor((FlxG.width - (hintWidth + noteSpacing) * hintsNoteDirections.length) / 2);
        final yPos:Int = Math.floor(FlxG.height - hintHeight * 2 - 24);

        for (i in 0...hintsNoteDirections.length)
          add(createHintTransparentNote(xPos + i * hintWidth + noteSpacing * i, yPos, hintsNoteDirections[i % hintsNoteDirections.length], hintWidth,
            hintHeight));
    }
    #end

    scrollFactor.set();

    ControlsHandler.setupHitbox(PlayerSettings.player1.controls, this, trackedInputs);
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
  @:noCompletion
  function createHintLane(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int, color:FlxColor = 0xFFFFFFFF, label:Bool = true):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, label ? createHintLaneLabelGraphic(width, height, Math.floor(height * 0.035), color) : null);
    hint.loadGraphic(createHintLaneGraphic(width, height, color));
    hint.onDown.add(() -> onHintDown.dispatch(hint));
    hint.onUp.add(() -> onHintUp.dispatch(hint));
    hint.onOut.add(() -> onHintUp.dispatch(hint));
    hint.initTween(INVISIBLE_TILL_PRESS);
    return hint;
  }

  /**
   * Creates a new `FunkinHint`representing a transparent note corresponding to the note from the scene.
   * @param x The x position of the button.
   * @param y The y position of the button.
   * @param noteDirection The direction of the note the button represents (e.g. left, right).
   * @param width The width of the button.
   * @param height The height of the button.
   * @return A new `FunkinHint` object.
   */
  @:noCompletion
  function createHintTransparentNote(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.alpha = 0;
    hint.setSize(width, height);
    hint.onDown.add(() -> onHintDown.dispatch(hint));
    hint.onUp.add(() -> onHintUp.dispatch(hint));
    hint.onOut.add(() -> onHintUp.dispatch(hint));

    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchDefault();
    @:privateAccess
    @:nullSafety(Off)
    {
      hint.frames = Paths.getSparrowAtlas(noteStyle.getStrumlineAssetPath() ?? '', noteStyle.getStrumlineAssetLibrary());
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
  @:noCompletion
  function createHintTriangle(x:Float, y:Float, noteDirection:NoteDirection, width:Int, height:Int, color:FlxColor = 0xFFFFFFFF):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.polygon = getTriangleVertices(width, height, noteDirection);
    hint.loadGraphic(createHintTriangleGraphic(width, height, noteDirection, color));
    hint.onDown.add(() -> onHintDown.dispatch(hint));
    hint.onUp.add(() -> onHintUp.dispatch(hint));
    hint.onOut.add(() -> onHintUp.dispatch(hint));
    hint.initTween(INVISIBLE_TILL_PRESS);
    return hint;
  }

  /**
   * Creates a new `FunkinHint` circular button with specified properties.
   *
   * @param x The x position of the circular button.
   * @param y The y position of the circular button.
   * @param noteDirection The direction of the note the button represents (e.g., left, right).
   * @param radius The radius of the circular button.
   * @param color The color of the circular button (default is white).
   * @return A new `FunkinHint` circular object.
   */
  @:noCompletion
  function createHintCircle(x:Float, y:Float, noteDirection:NoteDirection, radius:Float, color:FlxColor = 0xFFFFFFFF):FunkinHint
  {
    final hint:FunkinHint = new FunkinHint(x, y, noteDirection, null);
    hint.loadGraphic(createHintCircleGraphic(radius, color));
    hint.limitToBounds = false;
    hint.isCircle = true;
    hint.radius = radius;
    hint.onDown.add(() -> onHintDown.dispatch(hint));
    hint.onUp.add(() -> onHintUp.dispatch(hint));
    hint.onOut.add(() -> onHintUp.dispatch(hint));
    hint.initTween(VISIBLE_TILL_PRESS);
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
  @:noCompletion
  function createHintLaneGraphic(width:Int, height:Int, baseColor:FlxColor = 0xFFFFFFFF, gradient:Bool = true):FlxGraphic
  {
    final shape:Shape = new Shape();

    if (gradient)
    {
      final matrix:Matrix = new Matrix();
      matrix.createGradientBox(width, height, 0, 0, 0);
      shape.graphics.beginGradientFill(RADIAL, [baseColor.to24Bit(), baseColor.to24Bit()], [0, 1], [60, 255], matrix, PAD, RGB, 0);
    }
    else
      shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);

    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    final graphicData:BitmapData = new BitmapData(width, height, true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  @:noCompletion
  function createHintLaneLabelGraphic(width:Int, height:Int, labelHeight:Int, baseColor:FlxColor = 0xFFFFFFFF):FlxGraphic
  {
    final shape:Shape = new Shape();

    shape.graphics.beginFill(0, 0);
    shape.graphics.drawRect(0, 0, width, height);
    shape.graphics.endFill();

    shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
    shape.graphics.drawRect(0, 0, width, labelHeight);
    shape.graphics.endFill();

    shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
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
  @:noCompletion
  function createHintTriangleGraphic(width:Int, height:Int, facing:NoteDirection, baseColor:FlxColor = 0xFFFFFFFF, gradient:Bool = true):FlxGraphic
  {
    final shape:Shape = new Shape();

    if (gradient)
    {
      final matrix:Matrix = new Matrix();
      matrix.createGradientBox(width, height, 0, 0, 0);
      shape.graphics.beginGradientFill(RADIAL, [baseColor.to24Bit(), baseColor.to24Bit()], [0, 1], [60, 255], matrix, PAD, RGB, 0);
    }
    else
      shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);

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
   * @return A `FlxGraphic` object representing the circular button graphic.
   */
  @:noCompletion
  function createHintCircleGraphic(radius:Float, baseColor:FlxColor = 0xFFFFFFFF):FlxGraphic
  {
    final shape:Shape = new Shape();
    shape.graphics.beginFill(baseColor.to24Bit(), baseColor.alphaFloat);
    shape.graphics.drawCircle(radius, radius, radius);
    shape.graphics.endFill();

    final graphicData:BitmapData = new BitmapData(Math.floor(radius * 2), Math.floor(radius * 2), true, 0);
    graphicData.draw(shape, true);
    return FlxGraphic.fromBitmapData(graphicData, false, null, false);
  }

  /**
   * Сalculates vertices in a given direction
   * @param width width of triangle
   * @param height height of triangle
   * @param facing The side the triangle faces
   * @return array of vertices
   */
  @:noCompletion
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
