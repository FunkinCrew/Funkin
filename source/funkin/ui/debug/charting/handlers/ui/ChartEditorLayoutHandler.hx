package funkin.ui.debug.charting.handlers.ui;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import funkin.assets.ValidatedPaths as Paths;
import funkin.data.character.CharacterRegistry;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.graphics.FunkinSprite;
import funkin.play.components.HealthIcon;
import funkin.play.components.Subtitles;
import funkin.ui.debug.charting.components.notes.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.grid.ChartEditorGridLines;
import funkin.ui.debug.charting.components.grid.ChartEditorMeasureTicks;
import funkin.ui.debug.charting.components.grid.ChartEditorDifficultyHeatmap;
import funkin.ui.debug.charting.components.playbar.ChartEditorNotePreview;
import funkin.ui.debug.charting.components.notes.ChartEditorNoteSprite;
import funkin.util.MathUtil;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen;
using Lambda;

@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorLayoutHandler
{
  public static function handleZoom(state:ChartEditorState, elapsed:Float):Void
  {
    var target:Float = ChartEditorState.ZOOM_LEVELS[state.zoomLevelIndex];
    if (state.zoomCurrent == target) return;

    // Eased in log space, so each zoom step feels the same size at both ends of the range.
    var logZoom:Float = MathUtil.smoothLerpPrecision(Math.log(state.zoomCurrent), Math.log(target), elapsed, ChartEditorState.ZOOM_EASE_DURATION, 1 / 1000);
    state.zoomCurrent = MathUtil.snap(Math.exp(logZoom), target, target / 1000);
    state.updateGridScale();
  }

  /**
   * Recalculate how the grid maps to the song.
   * @param rebuildScrollSpeeds Also rebuild the constant scroll speed map from the events.
   */
  public static function updateGridScale(state:ChartEditorState, rebuildScrollSpeeds:Bool = false):Void
  {
    var hasGrid:Bool = state.gridTiledSprite != null;
    var playheadSongMs:Float = hasGrid ? ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels + state.playheadPositionInPixels) : 0;
    var oldEase:Null<Float> = state.currentScrollEase;
    var easeSongMs:Null<Float> = (!hasGrid || oldEase == null) ? null : ChartEditorTimeScale.pixelsToMs(oldEase + state.playheadPositionInPixels);

    var oldStepHeight:Float = ChartEditorTimeScale.STEP_HEIGHT;
    var oldConstantScroll:Bool = ChartEditorTimeScale.CONSTANT_SCROLL;
    var oldPixelsPerMs:Float = ChartEditorTimeScale.PIXELS_PER_MS;
    ChartEditorTimeScale.STEP_HEIGHT = ChartEditorState.GRID_SIZE * state.zoomCurrent;
    ChartEditorTimeScale.CONSTANT_SCROLL = state.constantScrollEnabled;
    ChartEditorTimeScale.PIXELS_PER_MS = ChartEditorTimeScale.STEP_HEIGHT * state.constantScrollSpeed / ChartEditorTimeScale.CONSTANT_SCROLL_REFERENCE_STEP_MS;
    var speedsChanged:Bool = rebuildScrollSpeeds && ChartEditorTimeScale.buildScrollSpeedPoints(state.currentSongChartEventData, state.currentSongChartScrollSpeed);

    if (!hasGrid) return;
    var layoutChanged:Bool = speedsChanged && !ChartEditorTimeScale.CONSTANT_SCROLL;
    if (!layoutChanged && oldStepHeight == ChartEditorTimeScale.STEP_HEIGHT && oldConstantScroll == ChartEditorTimeScale.CONSTANT_SCROLL && oldPixelsPerMs == ChartEditorTimeScale.PIXELS_PER_MS) return;

    // Then back to pixels with the new scale.
    var playheadSongPixels:Float = ChartEditorTimeScale.msToPixels(playheadSongMs);
    var easeSongPixels:Null<Float> = (easeSongMs == null) ? null : ChartEditorTimeScale.msToPixels(easeSongMs);
    var newPlayhead:Float = state.playheadPositionInPixels;
    var newScroll:Float = playheadSongPixels - newPlayhead;
    if (newScroll < 0)
    {
      newScroll = 0;
      newPlayhead = playheadSongPixels;
    }

    // The old values are in the old scale's pixels, so write them directly before the setters clamp against them.
    @:bypassAccessor state.playheadPositionInPixels = newPlayhead;
    @:bypassAccessor state.scrollPositionInPixels = -1;
    state.scrollPositionInPixels = newScroll;
    state.playheadPositionInPixels = newPlayhead;

    state.currentScrollEase = (easeSongPixels == null) ? state.scrollPositionInPixels : Math.max(0, easeSongPixels - newPlayhead);

    if (state.gridTiledSprite != null) state.gridTiledSprite.height = state.songLengthInPixels;
    state.measureTicks?.setHeight(state.songLengthInPixels);

    state.noteDisplayDirty = true;
    state.commentDisplayDirty = true;
    state.gridLinesDirty = true;
    state.waveformsDirty = true;
  }

  /**
   * The note preview keeps the same gap to the grid that it has at 1280x720.
   */
  public static function notePreviewXPos():Float
  {
    return ChartEditorState.GRID_X_POS - (FlxG.initialWidth / 2 - ChartEditorState.GRID_SIZE * ChartEditorState.STRUMLINE_SIZE - ChartEditorState.NOTE_PREVIEW_X_POS);
  }

  /**
   * Keep toolboxes and dialogs at the same place relative to the screen when its size changes, and fully on it.
   */
  public static function relayoutDialogs(state:ChartEditorState):Void
  {
    var ratioX:Float = FlxG.width / state.dialogLayoutSize.x;
    var ratioY:Float = FlxG.height / state.dialogLayoutSize.y;
    state.dialogLayoutSize.set(FlxG.width, FlxG.height);
    if (ratioX == 1 && ratioY == 1) return;

    state.repositionNotifications();

    var dialogs:Array<Dialog> = [for (toolbox in state.activeToolboxes) toolbox];
    for (component in Screen.instance.rootComponents)
    {
      if (component is Dialog && !dialogs.contains(cast component)) dialogs.push(cast component);
    }

    for (dialog in dialogs)
    {
      // Scale the dialog's center, so it stays in the same part of the screen.
      var centerX:Float = (dialog.left + dialog.width / 2) * ratioX;
      var centerY:Float = (dialog.top + dialog.height / 2) * ratioY;
      var maxLeft:Float = Math.max(0, FlxG.width - dialog.width);
      var maxTop:Float = Math.max(ChartEditorState.MENU_BAR_HEIGHT, FlxG.height - dialog.height);
      dialog.left = FlxMath.bound(centerX - dialog.width / 2, 0, maxLeft);
      dialog.top = FlxMath.bound(centerY - dialog.height / 2, ChartEditorState.MENU_BAR_HEIGHT, maxTop);
    }
  }

  public static function buildBackground(state:ChartEditorState):Void
  {
    state.menuBG = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-desat').toFlxGraphicAsset());
    state.add(state.menuBG);

    state.menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
    state.menuBG.updateHitbox();
    state.menuBG.screenCenter();
    state.menuBG.scrollFactor.set(0, 0);
    state.menuBG.zIndex = -100;
  }

  /**
   * Builds and displays the chart editor grid, including the playhead and cursor.
   */
  public static function buildGrid(state:ChartEditorState):Void
  {
    if (state.gridBitmap == null) throw 'ERROR: Tried to build grid, but gridBitmap is null! Check ChartEditorThemeHandler.updateTheme().';

    state.gridTiledSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
    state.gridTiledSprite.width = ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT;
    state.gridTiledSprite.height = 1000;
    state.gridTiledSprite.visible = false;
    state.gridTiledSprite.x = ChartEditorState.GRID_X_POS; // Center the grid.
    state.gridTiledSprite.y = ChartEditorState.GRID_INITIAL_Y_POS; // Push down to account for the menu bar.
    state.add(state.gridTiledSprite);
    state.gridTiledSprite.zIndex = 10;

    state.gridLines = new ChartEditorGridLines(state);
    state.gridLines.backing.zIndex = 10;
    state.add(state.gridLines.backing);

    state.gridLines.lines.zIndex = 16;
    state.add(state.gridLines.lines);
    state.gridLines.dividers.zIndex = 16;
    state.add(state.gridLines.dividers);
    state.gridLines.subBeats.zIndex = 17;
    state.add(state.gridLines.subBeats);
    state.gridLines.markers.zIndex = 30;
    state.add(state.gridLines.markers);

    state.rangeSelectionSprite = new FlxSprite().makeGraphic(1, 1, ChartEditorState.RANGE_SELECTION_COLOR);
    state.rangeSelectionSprite.visible = false;
    state.rangeSelectionSprite.zIndex = 18;
    state.add(state.rangeSelectionSprite);

    state.gridCursorLine = new FunkinSprite().makeSolidColor(ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT, 2, ChartEditorState.CURSOR_LINE_COLOR);
    state.gridCursorLine.visible = false;
    state.gridCursorLine.zIndex = 17;

    var playerView:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0x3033C6FF);
    playerView.origin.set(0, 0);
    playerView.visible = false;
    playerView.zIndex = 17;
    state.add(playerView);
    state.gridPlayerView = playerView;
    var playerViewEdge:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xC033C6FF);
    playerViewEdge.origin.set(0, 0);
    playerViewEdge.visible = false;
    playerViewEdge.zIndex = 17;
    state.add(playerViewEdge);
    state.gridPlayerViewEdge = playerViewEdge;
    state.add(state.gridCursorLine);

    state.gridGhostNote = new ChartEditorNoteSprite(state, true);
    state.gridGhostNote.alpha = 0.6;
    state.gridGhostNote.noteData = new SongNoteData(0, 0, 0, '', []);
    state.gridGhostNote.visible = false;
    state.add(state.gridGhostNote);
    state.gridGhostNote.zIndex = 21;

    state.gridGhostHoldNote = new ChartEditorHoldNoteSprite(state);
    state.gridGhostHoldNote.alpha = 0.6;
    state.gridGhostHoldNote.noteData = null;
    state.gridGhostHoldNote.visible = false;
    state.add(state.gridGhostHoldNote);
    state.gridGhostHoldNote.zIndex = 21;

    state.gridGhostEvent = new ChartEditorEventSprite(state, true);
    state.gridGhostEvent.alpha = 0.6;
    state.gridGhostEvent.eventData = new SongEventData(-1, '', {
    });
    state.gridGhostEvent.visible = false;
    state.add(state.gridGhostEvent);
    state.gridGhostEvent.zIndex = 22;

    state.buildNoteGroup();

    state.add(state.renderedPins);
    state.renderedPins.zIndex = 50;

    // The playhead that show the current position in the song.
    state.add(state.gridPlayhead);
    state.gridPlayhead.zIndex = 30;

    var playheadWidth:Int = ChartEditorState.GRID_SIZE * (ChartEditorState.STRUMLINE_SIZE * 2 + 1) + ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH;
    var playheadBaseYPos:Float = ChartEditorState.GRID_INITIAL_Y_POS;
    state.gridPlayhead.setPosition(ChartEditorState.GRID_X_POS, playheadBaseYPos);
    var playheadSprite:FunkinSprite = new FunkinSprite().makeSolidColor(playheadWidth, ChartEditorState.PLAYHEAD_HEIGHT, ChartEditorState.PLAYHEAD_COLOR);
    playheadSprite.x = -ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadSprite.y = 0;
    state.gridPlayhead.add(playheadSprite);

    var playheadBlock:FlxSprite = ChartEditorThemeHandler.buildPlayheadBlock();
    playheadBlock.x = -ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadBlock.y = -ChartEditorState.PLAYHEAD_HEIGHT / 2;
    state.gridPlayhead.add(playheadBlock);

    state.add(state.gridGhostPlayhead);
    state.gridGhostPlayhead.zIndex = 29;
    state.gridGhostPlayhead.setPosition(ChartEditorState.GRID_X_POS, playheadBaseYPos);
    var ghostLine:FunkinSprite = new FunkinSprite().makeSolidColor(playheadWidth - ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH, ChartEditorState.PLAYHEAD_HEIGHT,
      ChartEditorState.PLAYHEAD_COLOR);
    ghostLine.alpha = 0.4;
    state.gridGhostPlayhead.add(ghostLine);
    var ghostText:flixel.text.FlxText = new flixel.text.FlxText(0, -18, 0, '', 12);
    ghostText.setBorderStyle(flixel.text.FlxText.FlxTextBorderStyle.OUTLINE, 0xFF000000, 1);
    ghostText.alpha = 0.8;
    state.gridGhostPlayhead.add(ghostText);
    state.gridGhostPlayheadText = ghostText;
    state.gridGhostPlayhead.visible = false;

    // Character icons.
    state.healthIconDad = new HealthIcon(state.currentSongMetadata.playData.characters.opponent);
    state.healthIconDad.autoUpdate = false;
    state.healthIconDad.size.set(0.5, 0.5);
    state.add(state.healthIconDad);
    state.healthIconDad.zIndex = 30;

    state.healthIconBF = new HealthIcon(state.currentSongMetadata.playData.characters.player);
    state.healthIconBF.autoUpdate = false;
    state.healthIconBF.size.set(0.5, 0.5);
    state.healthIconBF.flipX = true;
    state.add(state.healthIconBF);
    state.healthIconBF.zIndex = 30;

    // 15 is above the grid, but below most stuff that's on the grid.
    state.audioWaveforms.zIndex = 15;
    state.add(state.audioWaveforms);
  }

  public static function createSubtitles(state:ChartEditorState):Void
  {
    state.subtitles = new Subtitles(0, 78);
    state.subtitles.zIndex = 100;
    state.subtitles.cameras = [state.uiCamera];
    state.add(state.subtitles);
  }

  public static function buildMeasureTicks(state:ChartEditorState):Void
  {
    state.measureTicks = new ChartEditorMeasureTicks(state);
    var measureTicksWidth = ChartEditorState.GRID_SIZE;
    state.measureTicks.x = state.gridTiledSprite.x - measureTicksWidth;
    state.measureTicks.zIndex = 20;
    state.add(state.measureTicks);

    state.handleMeasureTickPosition();
  }

  public static function buildNotePreview(state:ChartEditorState):Void
  {
    var playbarHeightWithPad = ChartEditorState.PLAYBAR_HEIGHT + 10;
    var notePreviewHeight:Int = FlxG.height - ChartEditorState.NOTE_PREVIEW_Y_POS - playbarHeightWithPad;
    state.notePreview = new ChartEditorNotePreview(notePreviewHeight);
    state.notePreview.x = ChartEditorLayoutHandler.notePreviewXPos();
    state.notePreview.y = ChartEditorState.NOTE_PREVIEW_Y_POS;
    state.add(state.notePreview);

    state.difficultyHeatmap = new ChartEditorDifficultyHeatmap(state);
    state.difficultyHeatmap.zIndex = 19;
    state.difficultyHeatmap.visible = state.showDifficultyHeatmap;
    state.add(state.difficultyHeatmap);

    if (state.notePreviewViewport == null) throw 'ERROR: Tried to build note preview, but notePreviewViewport is null! Check ChartEditorThemeHandler.updateTheme().';

    state.notePreviewViewport.scrollFactor.set(0, 0);
    state.add(state.notePreviewViewport);
    state.notePreviewViewport.zIndex = 30;

    state.notePreviewPlayhead = new FlxSprite().makeGraphic(2, 2, 0xFFFF0000);
    state.notePreviewPlayhead.scrollFactor.set(0, 0);
    state.notePreviewPlayhead.scale.set(state.notePreview.width / 2, 0.5); // Setting width does nothing.
    state.notePreviewPlayhead.updateHitbox();
    state.notePreviewPlayhead.x = state.notePreview.x;
    state.notePreviewPlayhead.y = state.notePreview.y;
    state.add(state.notePreviewPlayhead);
    state.notePreviewPlayhead.zIndex = 31;

    state.setNotePreviewViewportBounds(state.calculateNotePreviewViewportBounds());
  }

  public static function setSelectionBoxBounds(state:ChartEditorState, ?bounds:FlxRect):Void
  {
    if (state.selectionBoxSprite == null) throw 'ERROR: Tried to set selection box bounds, but selectionBoxSprite is null! Check ChartEditorThemeHandler.updateTheme().';

    if (bounds == null)
    {
      state.selectionBoxSprite.visible = false;
      state.selectionBoxSprite.x = -9999;
      state.selectionBoxSprite.y = -9999;
    }
    else
    {
      state.selectionBoxSprite.visible = true;
      state.selectionBoxSprite.x = bounds.x;
      state.selectionBoxSprite.y = bounds.y;
      state.selectionBoxSprite.width = bounds.width;
      state.selectionBoxSprite.height = bounds.height;
    }
  }

  public static function calculateNotePreviewViewportBounds(state:ChartEditorState):FlxRect
  {
    var bounds:FlxRect = FlxRect.weak();

    // Return 0, 0, 0, 0 if the note preview doesn't exist for some reason.
    if (state.notePreview == null) return bounds;

    // Horizontal position and width are constant.
    bounds.x = state.notePreview.x;
    bounds.width = state.notePreview.width;

    var viewTopPixels:Float = state.scrollPositionInPixels - ChartEditorState.GRID_TOP_PAD;
    var viewHeightPixels:Float = FlxG.height - ChartEditorState.MENU_BAR_HEIGHT - ChartEditorState.PLAYBAR_HEIGHT;
    bounds.y = state.notePreview.y + (state.notePreview.height * (viewTopPixels / state.songLengthInPixels));
    bounds.height = state.notePreview.height * (viewHeightPixels / state.songLengthInPixels);

    var MIN_HEIGHT:Int = 8;
    if (bounds.height < MIN_HEIGHT)
    {
      bounds.y -= (MIN_HEIGHT - bounds.height) / 2;
      bounds.height = MIN_HEIGHT;
    }

    // Make sure the viewport doesn't go off the top or bottom of the note preview.
    if (bounds.y < state.notePreview.y)
    {
      bounds.height -= state.notePreview.y - bounds.y;
      bounds.y = state.notePreview.y;
    }
    if (bounds.y + bounds.height > state.notePreview.y + state.notePreview.height)
    {
      bounds.height -= (bounds.y + bounds.height) - (state.notePreview.y + state.notePreview.height);
    }
    if (bounds.height < 1) bounds.height = 1;

    // trace('Note preview viewport bounds: ' + bounds.toString());

    return bounds;
  }

  public static function setNotePreviewViewportBounds(state:ChartEditorState, ?bounds:FlxRect):Void
  {
    if (state.notePreviewViewport == null)
    {
      trace(' WARNING '.warning() + ' Tried to set note preview viewport bounds, but notePreviewViewport is null!');
      return;
    }

    if (bounds == null)
    {
      state.notePreviewViewport.visible = false;
      state.notePreviewViewport.x = -9999;
      state.notePreviewViewport.y = -9999;
    }
    else
    {
      state.notePreviewViewport.visible = true;
      state.notePreviewViewport.x = bounds.x;
      state.notePreviewViewport.y = bounds.y;
      state.notePreviewViewport.width = bounds.width;
      state.notePreviewViewport.height = bounds.height;
    }
  }

  public static function refreshNotePreviewPlayheadPosition(state:ChartEditorState):Void
  {
    if (state.notePreviewPlayhead == null) return;

    state.notePreviewPlayhead.y = state.notePreview.y + (state.notePreview.height * ((state.scrollPositionInPixels + state.playheadPositionInPixels) / state.songLengthInPixels));
  }

  public static function handleGridLines(state:ChartEditorState):Void
  {
    if (state.gridLines == null) return;
    state.gridLines.refresh(state.gridLinesDirty);
    state.gridLinesDirty = false;
  }

  public static function updateGridHeight(state:ChartEditorState):Void
  {
    // Make sure playhead doesn't go outside the song after we update the grid height.
    if (state.playheadPositionInMs > state.songLengthInMs) state.playheadPositionInMs = state.songLengthInMs;

    if (state.gridTiledSprite != null)
    {
      state.gridTiledSprite.height = state.songLengthInPixels;
      state.measureTicks.setHeight(state.gridTiledSprite.height);
    }
    state.gridLinesDirty = true;
    state.waveformsDirty = true;

    for (difficultyNotes in state.currentSongChartData.notes)
    {
      for (note in difficultyNotes)
      {
        note.getStepTime(true);
        note.getStepLength(true);
      }
    }
    for (event in state.currentSongChartData.events)
    {
      event.getStepTime(null, true);
    }

    if (state.audioInstTrack != null && state.currentSongChartData.notes.get(state.selectedDifficulty) != null)
    {
      // Remove any notes past the end of the song, if this difficulty exists.
      var songCutoffPointSteps:Float = state.gridLengthInSteps - 0.1;
      var songCutoffPointMs:Float = Conductor.instance.getStepTimeInMs(songCutoffPointSteps);
      state.currentSongChartNoteData = SongDataUtils.clampSongNoteData(state.currentSongChartNoteData, 0.0, songCutoffPointMs);
      state.currentSongChartEventData = SongDataUtils.clampSongEventData(state.currentSongChartEventData, 0.0, songCutoffPointMs);
    }
    else
    {
      // We end up here if we're midway through switching variation AND difficulty,
      // and we're on the new variation but the old difficulty, so the current difficulty doesn't exist.
      trace('Skipping difficulty that does not exist');
    }

    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.noteDisplayDirty = true;
    state.commentDisplayDirty = true;
    state.moveSongToScrollPosition();
  }

  /**
   * Handle positioning the measure ticks sprite.
   */
  public static function handleMeasureTickPosition(state:ChartEditorState):Void
  {
    // var currentMeasureTime = Conductor.instance.getMeasureTimeInMs(Math.floor(Conductor.instance.getTimeInMeasures(scrollPositionInMs)));
    // var currentMeasurePos = currentMeasureTime < 0 ? 0 : Conductor.instance.getTimeInSteps(currentMeasureTime) * GRID_SIZE;
    state.measureTicks.y = state.gridTiledSprite?.y;
  }

  public static function handleNotePreview(state:ChartEditorState):Void
  {
    if (state.notePreviewDirty && state.notePreview != null)
    {
      state.notePreviewDirty = false;
      state.difficultyHeatmapDirty = true;

      // TODO: Only update the notes that have changed.
      state.notePreview.erase();
      state.notePreview.addNotes(state.currentSongChartNoteData, state.songLengthInPixels);
      state.notePreview.addOverlappingNotes(state.currentOverlappingNotes, state.songLengthInPixels);
      state.notePreview.addSelectedNotes(state.currentNoteSelection, state.songLengthInPixels);
      state.notePreview.addEvents(state.currentSongChartEventData, state.songLengthInPixels);
    }

    if (state.difficultyHeatmap != null && state.difficultyHeatmap.visible && state.gridTiledSprite != null)
    {
      if (state.difficultyHeatmapDirty)
      {
        state.difficultyHeatmapDirty = false;
        state.difficultyHeatmap.setChart(state.currentSongChartNoteData, state.currentSongChartScrollSpeed);
      }
      state.difficultyHeatmap.refresh(state.gridTiledSprite.x, state.gridTiledSprite.y, ChartEditorState.MENU_BAR_HEIGHT, FlxG.height - ChartEditorState.PLAYBAR_HEIGHT);
    }

    if (state.notePreviewViewportBoundsDirty)
    {
      state.setNotePreviewViewportBounds(state.calculateNotePreviewViewportBounds());
      state.notePreviewViewportBoundsDirty = false;
    }
  }

  @:access(funkin.play.character.BaseCharacter)
  public static function handleHealthIcons(state:ChartEditorState):Void
  {
    if (state.healthIconsDirty)
    {
      state._charIconData = state.currentPlayerCharacterPlayer?.character?._data ?? CharacterRegistry.instance.fetchCharacterData(
        state.currentSongMetadata.playData.characters.player
      );

      if (state.healthIconBF != null)
      {
        state.healthIconBF.configure(state._charIconData?.healthIcon);
        state.healthIconBF.iconOffset.set();
        state.healthIconBF.size *= 0.5; // Make the icon smaller in Chart Editor.
        state.healthIconBF.flipX = !state.healthIconBF.flipX; // BF faces the other way.
      }

      if (state.buttonSelectPlayer != null)
      {
        state.buttonSelectPlayer.text = state._charIconData?.name ?? 'Player';
      }

      state._charIconData = state.currentOpponentCharacterPlayer?.character?._data ?? CharacterRegistry.instance.fetchCharacterData(
        state.currentSongMetadata.playData.characters.opponent
      );

      if (state.healthIconDad != null)
      {
        state.healthIconDad.configure(state._charIconData?.healthIcon);
        state.healthIconDad.iconOffset.set();
        state.healthIconDad.size *= 0.5; // Make the icon smaller in Chart Editor.
      }
      if (state.buttonSelectOpponent != null)
      {
        state.buttonSelectOpponent.text = state._charIconData?.name ?? 'Opponent';
      }
      state.waveformsDirty = true;
      state.healthIconsDirty = false;
      state._charIconData = null;
    }

    // Right align, and visibly center, the BF health icon.
    if (state.healthIconBF != null)
    {
      // Base X position to the right of the grid.
      state.healthIconBF.x = (state.gridTiledSprite == null) ? (0) : (state.gridTiledSprite.x + state.gridTiledSprite.width);
      var yOffset = 30 - (state.healthIconBF.height / 2);
      state.healthIconBF.y = (state.gridTiledSprite == null) ? (0) : (ChartEditorState.NOTE_SELECT_BUTTON_Y + 8) + yOffset;
    }

    // Visibly center the Dad health icon.
    if (state.healthIconDad != null)
    {
      state.healthIconDad.x = (state.gridTiledSprite == null) ? (0) : (state.measureTicks.x - state.healthIconDad.width);
      var yOffset = 30 - (state.healthIconDad.height / 2);
      state.healthIconDad.y = (state.gridTiledSprite == null) ? (0) : (ChartEditorState.NOTE_SELECT_BUTTON_Y + 8) + yOffset;
    }
  }
}
#end
