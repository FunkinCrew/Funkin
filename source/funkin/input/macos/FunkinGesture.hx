package funkin.input.macos;

#if macos
import lime.ui.Gesture;
import lime.ui.Gesture.GestureType;
#end

typedef FunkinGestureParams =
{
  var ?preGestureStart:Gesture->Bool;
  var ?onGestureStart:Gesture->Void;
  var ?onGestureEnd:Gesture->Void;
  var ?onMagnificationGesture:Float->Void;
  var ?onPanGesture:Array<Float>->Void;
  var ?onScrollGesture:Array<Float>->Void;
  var ?onMomentumScrollGesture:Array<Float>->Void;
}

class FunkinGesture
{
  // Callbacks.
  public var preGestureStart:Gesture->Bool;
  public var onGestureStart:Gesture->Void;
  public var onGestureEnd:Gesture->Void;
  public var onMagnificationGesture:Float->Void;
  public var onPanGesture:Array<Float>->Void;
  public var onScrollGesture:Array<Float>->Void;
  public var onMomentumScrollGesture:Array<Float>->Void;

  // Gesture values.
  var _lastMagnification:Float = 0;
  var _lastPanTranslationX:Float = 0;
  var _lastPanTranslationY:Float = 0;

  public var gestureActive:Bool = false;
  public var gesturePanning:Bool = false;

  public function new(?params:FunkinGestureParams)
  {
    #if FEATURE_MACOS_GESTURES
    if (params != null)
    {
      this.preGestureStart = params.preGestureStart;
      this.onGestureStart = params.onGestureStart;
      this.onGestureEnd = params.onGestureEnd;
      this.onMagnificationGesture = params.onMagnificationGesture;
      this.onPanGesture = params.onPanGesture;
      this.onScrollGesture = params.onScrollGesture;
      this.onMomentumScrollGesture = params.onMomentumScrollGesture;
    }

    Gesture.onStart.add(_onGestureStart);
    Gesture.onMove.add(_onGestureMove);
    Gesture.onEnd.add(_onGestureEnd);
    Gesture.onCancel.add(_onGestureCancel);
    #end
  }

  public function destroy()
  {
    #if FEATURE_MACOS_GESTURES
    Gesture.onStart.remove(_onGestureStart);
    Gesture.onMove.remove(_onGestureMove);
    Gesture.onEnd.remove(_onGestureEnd);
    Gesture.onCancel.remove(_onGestureCancel);
    #end
  }

  function _onGestureStart(g:Gesture):Void
  {
    #if FEATURE_MACOS_GESTURES
    var cancel:Bool = false;

    if (preGestureStart != null)
    {
      cancel = !preGestureStart(g);
    }

    if (cancel) return;

    gestureActive = true;
    _lastMagnification = g.magnification;
    _lastPanTranslationX = g.panTranslationX;
    _lastPanTranslationY = g.panTranslationY;

    if (g.type == PAN)
    {
      gesturePanning = true;
    }

    if (onGestureStart != null)
    {
      onGestureStart(g);
    }
    #end
  }

  function _onGestureMove(g:Gesture):Void
  {
    #if FEATURE_MACOS_GESTURES
    if (!gestureActive) return;

    switch (g.type)
    {
      case MAGNIFICATION:
        var delta = g.magnification - _lastMagnification;
        _lastMagnification = g.magnification;

        if (onMagnificationGesture != null)
        {
          onMagnificationGesture(delta);
        }

      case PAN:
        var dx = g.panTranslationX - _lastPanTranslationX;
        var dy = g.panTranslationY - _lastPanTranslationY;
        _lastPanTranslationX = g.panTranslationX;
        _lastPanTranslationY = g.panTranslationY;

        if (onPanGesture != null)
        {
          final delta:Array<Float> = [dx, dy];

          onPanGesture(delta);
        }

      case SCROLL:
        final delta:Array<Float> = [g.scrollX, g.scrollY];

        if (onScrollGesture != null)
        {
          onScrollGesture(delta);
        }

      case MOMENTUMSCROLL:
        final delta:Array<Float> = [g.momentumScrollX, g.momentumScrollY];

        if (onMomentumScrollGesture != null)
        {
          onMomentumScrollGesture(delta);
        }

      case ROTATION | UNSPECIFIED:
        // ignored
    }
    #end
  }

  function _onGestureEnd(g:Gesture):Void
  {
    #if FEATURE_MACOS_GESTURES
    if (onGestureEnd != null)
    {
      onGestureEnd(g);
    }

    gestureActive = false;
    gesturePanning = false;
    _lastMagnification = 0;
    _lastPanTranslationX = 0;
    _lastPanTranslationY = 0;
    #end
  }

  function _onGestureCancel(g:Gesture):Void
  {
    _onGestureEnd(g);
  }
}
