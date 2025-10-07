package funkin.ui.debug.stageeditor.handlers;

import flixel.addons.display.FlxGridOverlay;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorTheme;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorThemeHandler
{
  // ================================
  // Color 1 of the grid pattern. Alternates with Color 2.
  static final GRID_COLOR_1_LIGHT:FlxColor = 0xFFE7E6E6;
  static final GRID_COLOR_1_DARK:FlxColor = 0xFF181919;

  // Color 2 of the grid pattern. Alternates with Color 1.
  static final GRID_COLOR_2_LIGHT:FlxColor = 0xFFF8F8F8;
  static final GRID_COLOR_2_DARK:FlxColor = 0xFF202020;

  public static function updateTheme(state:StageEditorState):Void
  {
    updateGridBitmap(state);
    // updateGridBitmapSize(state);
  }

  public static function updateGridBitmap(state:StageEditorState):Void
  {
    var gridColor1:FlxColor = switch (state.currentTheme)
    {
      case Light: GRID_COLOR_1_LIGHT;
      case Dark: GRID_COLOR_1_DARK;
      default: GRID_COLOR_1_LIGHT;
    };

    var gridColor2:FlxColor = switch (state.currentTheme)
    {
      case Light: GRID_COLOR_2_LIGHT;
      case Dark: GRID_COLOR_2_DARK;
      default: GRID_COLOR_2_LIGHT;
    };

    state.gridBitmap = FlxGridOverlay.createGrid(StageEditorState.GRID_SIZE, StageEditorState.GRID_SIZE, FlxG.width, FlxG.height, true, gridColor1, gridColor2);

    if (state.gridTiledSprite != null) state.gridTiledSprite.loadGraphic(state.gridBitmap);
  }

  public static function updateGridBitmapSize(state:StageEditorState):Void
  {
    if (state.gridTiledSprite != null)
    {
      state.gridTiledSprite.scale.set(1 / FlxG.camera.zoom, 1 / FlxG.camera.zoom);
      state.gridTiledSprite.scrollFactor.set();
      state.gridTiledSprite.screenCenter();
    }
  }
}
