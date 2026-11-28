package funkin.modding.compat;

import flixel.util.typeLimit.NextState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.transition.Transition;
import funkin.ui.transition.stickers.StickerSprite;
import funkin.util.Constants;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.transition.loading.StickerLoadingState;
import flixel.FlxState;
import openfl.display.Sprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef StickerSubStateParams =
{
  ?targetState:StickerSubState->FlxState,
  ?stickerPack:String,
  ?oldStickers:Array<StickerSprite>
}

class StickerSubState extends MusicBeatSubState
{
  public static var transitionSprite:Null<StickerTransitionSprite> = null;

  public function new(params:StickerSubStateParams)
  {
    super();

    var targetState = params?.targetState ?? (sticker) -> FreeplayState.build(null);

    var nextState:NextState = () -> targetState(this);
    var stickId = params?.stickerPack ?? Constants.DEFAULT_STICKER_PACK;
    Transition.switchState(nextState, {
      transition: Sticker(stickId)
    });
  }
}

class StickerTransitionSprite extends Sprite
{
  public var stickersCamera:FlxCamera = null;
  public var grpStickers:FlxTypedGroup<StickerSprite> = null;

  public function new()
  {
    super();
  }

  public function update(elapsed:Float)
  {
  }

  public function insert()
  {
  }

  public function clear()
  {
  }

  public function onResize()
  {
  }

  public function setupStickers(group:FlxTypedGroup<StickerSprite>)
  {
  }
}
