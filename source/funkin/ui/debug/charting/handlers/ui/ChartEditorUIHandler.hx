package funkin.ui.debug.charting.handlers.ui;

#if FEATURE_CHART_EDITOR
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxStringUtil;
import funkin.assets.ValidatedPaths as Paths;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.ui.debug.charting.commands.items.CutItemsCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.notes.FlipNotesCommand;
import funkin.ui.debug.charting.commands.selection.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.notes.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.items.PasteItemsCommand;
import funkin.ui.debug.charting.selection.ChartEditorSelectableItems;
import funkin.ui.debug.charting.commands.events.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.items.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.notes.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.notes.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.selection.SelectItemsCommand;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.components.palette.ChartEditorCommandPalette;
import funkin.ui.debug.charting.components.playbar.ChartEditorPlaybarHead;
import funkin.ui.debug.charting.toolboxes.ChartEditorDifficultyToolbox;
import funkin.ui.haxeui.components.CharacterPlayer;
import funkin.util.Constants;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.ui.components.Button;
import haxe.ui.components.Range;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.events.DragEvent;
import haxe.ui.events.UIEvent;
using Lambda;

@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorUIHandler
{
  public static function populateOpenRecentMenu(state:ChartEditorState):Void
  {
    if (state.menubarOpenRecent == null) return;

    #if sys
    state.menubarOpenRecent.removeAllComponents();

    for (chartPath in state.previousWorkingFilePaths)
    {
      if (chartPath == null) continue;

      var menuItemRecentChart:MenuItem = new MenuItem();
      menuItemRecentChart.text = chartPath;
      menuItemRecentChart.onClick = function(_event)
      {
        try
        {
          state.loadSongFromFNFCPath(chartPath);
        }
        catch (e)
        {
          state.error('Failure', 'Failed to load chart (${chartPath.toString()}): $e');
        }
      };

      if (!FileUtil.fileExists(chartPath))
      {
        trace('Previously loaded chart file (${chartPath.toString()}) does not exist, disabling link...');
        menuItemRecentChart.disabled = true;
      }
      else
      {
        menuItemRecentChart.disabled = false;
      }

      state.menubarOpenRecent.addComponent(menuItemRecentChart);
    }
    #else
    state.menubarOpenRecent.hide();
    #end
  }

  public static function buildAdditionalUI(state:ChartEditorState):Void
  {
    state.playbarHeadLayout = new ChartEditorPlaybarHead();

    state.playbarHeadLayout.zIndex = 110;
    state.playbarHeadLayout.width = FlxG.width;
    state.playbarHeadLayout.height = 10;
    state.playbarHeadLayout.x = 0;
    state.playbarHeadLayout.y = FlxG.height - 48 - 8;

    state.playbarHeadLayout.playbarHead.allowFocus = false;
    state.playbarHeadLayout.playbarHead.width = FlxG.width;
    state.playbarHeadLayout.playbarHead.height = 10;
    state.playbarHeadLayout.playbarHead.styleString = 'padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;';
    state.playbarHeadLayout.playbarHead.findComponent('range').styleString = 'padding-left: 4px; padding-right: 0px;';
    state.playbarHeadLayout.playbarHead.min = 0;

    state.playbarHeadLayout.playbarHead.onDragStart = function(_:DragEvent)
    {
      state.playbarHeadDragging = true;

      if ((state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing)
      {
        state.playbarHeadDraggingWasPlaying = true;
        state.stopAudioPlayback();
      }
      else
      {
        state.playbarHeadDraggingWasPlaying = false;
      }
    }

    state.playbarHeadLayout.playbarHead.onDrag = function(d:DragEvent)
    {
      if (state.playbarHeadDragging)
      {
        // Update the conductor and audio tracks to match.
        state.currentScrollEase = d.value;
        state.easeSongToScrollPosition(state.currentScrollEase);
      }
    }

    state.playbarHeadLayout.playbarHead.onDragEnd = function(_:DragEvent)
    {
      state.playbarHeadDragging = false;

      // If we were dragging the playhead while the song was playing, resume playing.
      if (state.playbarHeadDraggingWasPlaying)
      {
        state.playbarHeadDraggingWasPlaying = false;

        // Disabled code to resume song playback on drag.
        state.startAudioPlayback();
      }
    }

    state.add(state.playbarHeadLayout);

    state.buildCommentPanel();

    // Little text that shows up when you copy something.
    state.txtCopyNotif = new haxe.ui.backend.flixel.HiResFlxText(0, 0, 0, '', 24);
    state.txtCopyNotif.setBorderStyle(OUTLINE, 0xFF074809, 1);
    state.txtCopyNotif.color = 0xFF52FF77;
    state.txtCopyNotif.zIndex = 120;
    state.add(state.txtCopyNotif);

    state.setupNotifications();

    // Setup character dropdowns.
    FlxMouseEvent.add(state.healthIconDad, function(_)
    {
      if (!state.isCursorOverHaxeUI && !state.isPlaytesting)
      {
        if (FlxG.keys.pressed.SHIFT) return;
        if (state.pressingControl())
        {
          state.setToolboxState(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, true);
        }
        else
        {
          state.openCharacterDropdown(CharacterType.DAD, true);
        }
      }
    }, false, true, false);

    FlxMouseEvent.add(state.healthIconBF, function(_)
    {
      if (!state.isCursorOverHaxeUI && !state.isPlaytesting)
      {
        if (FlxG.keys.pressed.SHIFT) return;
        if (state.pressingControl())
        {
          state.setToolboxState(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, true);
        }
        else
        {
          state.openCharacterDropdown(CharacterType.BF, true);
        }
      }
    }, false, true, false);

    state.buttonSelectOpponent = new Button();
    state.buttonSelectOpponent.allowFocus = false;
    state.buttonSelectOpponent.text = 'Opponent'; // Default text.
    state.buttonSelectOpponent.x = ChartEditorState.GRID_X_POS;
    state.buttonSelectOpponent.y = ChartEditorState.NOTE_SELECT_BUTTON_Y;
    state.buttonSelectOpponent.width = ChartEditorState.GRID_SIZE * 4;
    state.buttonSelectOpponent.height = ChartEditorState.NOTE_SELECT_BUTTON_HEIGHT;
    state.buttonSelectOpponent.tooltip = 'Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.';
    state.buttonSelectOpponent.zIndex = 110;
    state.add(state.buttonSelectOpponent);

    state.buttonSelectOpponent.onClick = (_) ->
    {
      var notesToSelect:Array<SongNoteData> = state.currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, ChartEditorState.STRUMLINE_SIZE, ChartEditorState.STRUMLINE_SIZE * 2 - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        state.performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        state.performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    state.buttonSelectPlayer = new Button();
    state.buttonSelectPlayer.allowFocus = false;
    state.buttonSelectPlayer.text = 'Player'; // Default text.
    state.buttonSelectPlayer.x = state.buttonSelectOpponent.x + state.buttonSelectOpponent.width;
    state.buttonSelectPlayer.y = state.buttonSelectOpponent.y;
    state.buttonSelectPlayer.width = ChartEditorState.GRID_SIZE * 4;
    state.buttonSelectPlayer.height = ChartEditorState.NOTE_SELECT_BUTTON_HEIGHT;
    state.buttonSelectPlayer.tooltip = 'Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.';
    state.buttonSelectPlayer.zIndex = 110;
    state.add(state.buttonSelectPlayer);

    state.buttonSelectPlayer.onClick = (_) ->
    {
      var notesToSelect:Array<SongNoteData> = state.currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, 0, ChartEditorState.STRUMLINE_SIZE - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        state.performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        state.performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    state.buttonSelectEvent = new Button();
    state.buttonSelectEvent.allowFocus = false;
    state.buttonSelectEvent.icon = Paths.image('ui/editors/chart-editor/events/Default').toFlxGraphicAsset();
    state.buttonSelectEvent.iconPosition = 'top';
    state.buttonSelectEvent.x = state.buttonSelectPlayer.x + state.buttonSelectPlayer.width;
    state.buttonSelectEvent.y = state.buttonSelectPlayer.y;
    state.buttonSelectEvent.width = ChartEditorState.GRID_SIZE;
    state.buttonSelectEvent.height = ChartEditorState.NOTE_SELECT_BUTTON_HEIGHT;
    state.buttonSelectEvent.tooltip = 'Click to set selection to all events.\nShift-click to add all events to selection.';
    state.buttonSelectEvent.zIndex = 110;
    state.add(state.buttonSelectEvent);

    state.buttonSelectEvent.onClick = (_) ->
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        state.performCommand(new SelectItemsCommand([], state.currentSongChartEventData));
      }
      else
      {
        state.performCommand(new SetItemSelectionCommand([], state.currentSongChartEventData));
      }
    }

    state.buttonSelectDummy = new Button();
    state.buttonSelectDummy.allowFocus = false;
    state.buttonSelectDummy.x = state.buttonSelectOpponent.x - ChartEditorState.GRID_SIZE;
    state.buttonSelectDummy.y = state.buttonSelectEvent.y;
    state.buttonSelectDummy.width = ChartEditorState.GRID_SIZE;
    state.buttonSelectDummy.height = ChartEditorState.NOTE_SELECT_BUTTON_HEIGHT;
    state.buttonSelectDummy.zIndex = 110;
    state.add(state.buttonSelectDummy);
  }

  /**
   * Sets up the onClick listeners for the UI.
   */
  public static function setupUIListeners(state:ChartEditorState):Void
  {
    // Holding Ctrl while clicking a menu item keeps the menu open.
    for (menu in state.menubar.findComponents(null, Menu, 3))
    {
      menu.registerEvent(UIEvent.BEFORE_CLOSE, (event:UIEvent) ->
      {
        if (state.pressingControl()) event.cancel();
      });
    }

    // Add functionality to the playbar.

    state.playbarStart.onClick = _ -> state.playbarButtonPressed = 'playbarStart';
    state.playbarBack.onClick = _ -> state.playbarButtonPressed = 'playbarBack';
    state.playbarPlay.onClick = _ -> state.toggleAudioPlayback();
    state.playbarForward.onClick = _ -> state.playbarButtonPressed = 'playbarForward';
    state.playbarEnd.onClick = _ -> state.playbarButtonPressed = 'playbarEnd';

    // Cycle note snap quant.
    state.playbarNoteSnap.onRightClick = _ ->
    {
      state.noteSnapQuantIndex--;
      if (state.noteSnapQuantIndex < 0) state.noteSnapQuantIndex = ChartEditorState.SNAP_QUANTS.length - 1;
    };
    state.playbarNoteSnap.onClick = _ ->
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        state.noteSnapQuantIndex = ChartEditorState.BASE_QUANT_INDEX;
      }
      else
      {
        state.noteSnapQuantIndex++;
        if (state.noteSnapQuantIndex >= ChartEditorState.SNAP_QUANTS.length) state.noteSnapQuantIndex = 0;
      }
    };

    state.playbarZoom.onClick = _ ->
    {
      if (FlxG.keys.pressed.SHIFT) state.zoomLevelIndex = ChartEditorState.BASE_ZOOM_INDEX;
      else
        state.zoomLevelIndex++;
    };
    state.playbarZoom.onRightClick = _ -> state.zoomLevelIndex--;

    state.playbarBPM.onClick = _ ->
    {
      if (state.pressingControl())
      {
        state.setToolboxState(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, true);
      }
      else
      {
        Conductor.instance.currentTimeChange.bpm += 1;
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    state.playbarBPM.onRightClick = _ ->
    {
      Conductor.instance.currentTimeChange.bpm -= 1;
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    }

    state.playbarDifficulty.onClick = _ ->
    {
      if (state.pressingControl())
      {
        state.setToolboxState(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, true);
      }
      else
      {
        state.incrementDifficulty(-1);
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
    }

    state.playbarDifficulty.onRightClick = _ ->
    {
      state.incrementDifficulty(1);
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
    }

    // Add functionality to the menu items.

    // File
    state.menubarItemNewChart.onClick = _ -> state.openWelcomeDialog(true);
    state.menubarItemOpenChart.onClick = _ -> state.openBrowseFNFC(true);
    state.menubarItemSaveChart.onClick = _ ->
    {
      if (state.currentWorkingFilePath != null)
      {
        state.exportCurrentChartToFNFC(true, state.currentWorkingFilePath);
        state.success('Saved Chart', 'Chart saved successfully to ${state.currentWorkingFilePath}.');
      }
      else
      {
        state.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          state.success('Saved Chart', 'Chart saved successfully to ${path}.');
        }, function()
        {
          // CTRL + SHIFT + S Cancelled
        });
      }
    };
    state.menubarItemSaveChartAs.onClick = _ -> state.exportCurrentChartToFNFC(false, null, (path:String) ->
    {
      // CTRL + SHIFT + S Successful
      state.success('Saved Chart', 'Chart saved successfully to ${path}.');
    }, () -> {
        // CTRL + SHIFT + S Cancelled
    });
    state.menubarItemExportChartAsFolder.onClick = _ -> state.exportCurrentChartToFolder(null, (path:String) ->
    {
      state.success('Exported Chart', 'Chart exported successfully to ${path}.');
    }, () -> {
        // Cancelled
    });
    state.menubarItemExit.onClick = _ -> state.quitChartEditor(true);

    // Edit
    state.menubarItemUndo.onClick = _ -> state.undoLastCommand();
    state.menubarItemRedo.onClick = _ -> state.redoLastCommand();
    state.menubarItemCopy.onClick = function(_)
    {
      state.copySelection();
    };
    state.menubarItemCut.onClick = _ -> state.performCommand(new CutItemsCommand(state.currentNoteSelection, state.currentEventSelection));

    state.menubarItemPaste.onClick = _ ->
    {
      if (ChartEditorSelectableItems.pasteLastCopied()) return;
      var targetMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
      var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
      var targetSnappedStep:Float = Math.floor(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
      state.performCommand(new PasteItemsCommand(targetSnappedMs));
    };

    state.menubarItemPasteUnsnapped.onClick = _ ->
    {
      var targetMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
      state.performCommand(new PasteItemsCommand(targetMs));
    };

    state.menubarItemDelete.onClick = _ ->
    {
      if (state.currentNoteSelection.length > 0 && state.currentEventSelection.length > 0)
      {
        state.performCommand(new RemoveItemsCommand(state.currentNoteSelection, state.currentEventSelection));
      }
      else if (state.currentNoteSelection.length > 0)
      {
        state.performCommand(new RemoveNotesCommand(state.currentNoteSelection));
      }
      else if (state.currentEventSelection.length > 0)
      {
        state.performCommand(new RemoveEventsCommand(state.currentEventSelection));
      }
      else
      {
        // Do nothing???
      }
    };

    state.menubarItemDeleteStacked.onClick = _ ->
    {
      if (state.currentEventSelection.length > 0 && state.currentNoteSelection.length == 0)
      {
        state.performCommand(new RemoveEventsCommand(state.currentEventSelection));
      }
      else
      {
        state.performCommand(new RemoveStackedNotesCommand(state.currentNoteSelection.length > 0 ? state.currentNoteSelection : null));
      }
    };

    state.menubarItemFlipNotes.onClick = _ -> state.performCommand(new FlipNotesCommand(state.currentNoteSelection));

    state.menubarItemMirrorX.onClick = _ -> state.performCommand(
      new MirrorNotesCommand(state.currentNoteSelection, state.menubarItemMirrorFlipWithinStrumline.selected, !state.menubarItemMirrorFlipWithinStrumline.selected, true, false)
    );

    state.menubarItemMirrorY.onClick = _ -> state.performCommand(
      new MirrorNotesCommand(state.currentNoteSelection, state.menubarItemMirrorFlipWithinStrumline.selected, !state.menubarItemMirrorFlipWithinStrumline.selected, false, true)
    );

    state.menubarItemMirrorXY.onClick = _ -> state.performCommand(
      new MirrorNotesCommand(state.currentNoteSelection, state.menubarItemMirrorFlipWithinStrumline.selected, !state.menubarItemMirrorFlipWithinStrumline.selected, true, true)
    );

    state.menubarItemSelectAllNotes.onClick = _ -> state.performCommand(new SelectAllItemsCommand(true, false));

    state.menubarItemSelectAllEvents.onClick = _ -> state.performCommand(new SelectAllItemsCommand(false, true));

    state.menubarItemSelectInverse.onClick = _ -> state.performCommand(new InvertSelectedItemsCommand());

    state.menubarItemSelectNone.onClick = _ -> state.performCommand(new DeselectAllItemsCommand());

    state.menubarItemSelectBeforePlayhead.onClick = _ -> state.performCommand(
      new SelectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, true, true, true)
    );

    state.menubarItemSelectAfterPlayhead.onClick = _ -> state.performCommand(
      new SelectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, false, true, true)
    );

    state.menubarItemPlaytestFull.onClick = _ -> state.testSongInPlayState(false);
    state.menubarItemPlaytestMinimal.onClick = _ -> state.testSongInPlayState(true);

    state.menuBarItemNoteSnapDecrease.onClick = _ ->
    {
      state.noteSnapQuantIndex--;
      if (state.noteSnapQuantIndex < 0) state.noteSnapQuantIndex = ChartEditorState.SNAP_QUANTS.length - 1;
    };
    state.menuBarItemNoteSnapIncrease.onClick = _ ->
    {
      state.noteSnapQuantIndex++;
      if (state.noteSnapQuantIndex >= ChartEditorState.SNAP_QUANTS.length) state.noteSnapQuantIndex = 0;
    };

    state.menubarItemPreferences.onClick = _ -> state.setToolboxState(ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT, true);

    state.menubarItemAbout.onClick = _ -> state.openAboutDialog();
    state.menubarItemWelcomeDialog.onClick = _ -> state.openWelcomeDialog(true);

    #if sys
    state.menubarItemGoToBackupsFolder.onClick = _ -> state.openBackupsFolder();
    #else
    // Disable the menu item if we're not on a native platform.
    state.menubarItemGoToBackupsFolder.disabled = true;
    #end

    state.menubarItemUserGuide.onClick = _ -> state.openUserGuideDialog();

    state.menubarItemDownscroll.onClick = event -> state.isViewDownscroll = event.value;
    state.menubarItemDownscroll.selected = state.isViewDownscroll;

    state.menubarItemZoomIn.onClick = _ -> state.zoomLevelIndex++;
    state.menubarItemZoomOut.onClick = _ -> state.zoomLevelIndex--;
    state.menubarItemZoomReset.onClick = _ -> state.zoomLevelIndex = ChartEditorState.BASE_ZOOM_INDEX;

    state.menubarItemViewWaveforms.onClick = event -> state.audioWaveforms.visible = state.menubarItemViewWaveforms.selected;
    state.menubarItemViewDifficultyHeatmap.onClick = event -> state.showDifficultyHeatmap = state.menubarItemViewDifficultyHeatmap.selected;
    state.menubarItemViewDifficultyHeatmap.selected = state.showDifficultyHeatmap;
    state.menubarItemViewPlayerView.onClick = event -> state.showPlayerView = state.menubarItemViewPlayerView.selected;
    state.menubarItemViewPlayerView.selected = state.showPlayerView;
    state.menubarItemViewWaveforms.selected = state.audioWaveforms.visible;

    state.menubarItemCommandPalette.onClick = _ -> ChartEditorCommandPalette.openPalette(state, '?');
    state.menubarItemDifficultyUp.onClick = _ -> state.incrementDifficulty(1);
    state.menubarItemDifficultyDown.onClick = _ -> state.incrementDifficulty(-1);

    state.menubarItemPlayPause.onClick = _ -> state.toggleAudioPlayback();

    state.menubarItemMutePlayerVocals.onChange = _ -> state.playerVocalsMuted = state.menubarItemMutePlayerVocals.selected;
    state.menubarItemMutePlayerVocals.selected = state.playerVocalsMuted;

    state.menubarItemMuteOpponentVocals.onChange = _ -> state.opponentVocalsMuted = state.menubarItemMuteOpponentVocals.selected;
    state.menubarItemMuteOpponentVocals.selected = state.opponentVocalsMuted;

    state.menubarItemMuteInstrumental.onChange = _ -> state.instrumentalMuted = state.menubarItemMuteInstrumental.selected;
    state.menubarItemMuteInstrumental.selected = state.instrumentalMuted;

    state.menubarItemMuteMetronome.onChange = _ -> state.metronomeMuted = state.menubarItemMuteMetronome.selected;
    state.menubarItemMuteMetronome.selected = state.metronomeMuted;

    state.menubarItemMuteHitsounds.onChange = _ -> state.hitsoundsMuted = state.menubarItemMuteHitsounds.selected;
    state.menubarItemMuteHitsounds.selected = state.hitsoundsMuted;

    state.menubarItemLoadInstrumental.onClick = _ ->
    {
      var dialog = state.openUploadInstDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_)
      {
        state.isHaxeUIDialogOpen = false;
        state.switchToCurrentInstrumental();
        state.postLoadInstrumental();
      }
    };

    state.menubarItemLoadVocals.onClick = _ ->
    {
      var dialog = state.openUploadVocalsDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_)
      {
        state.isHaxeUIDialogOpen = false;
        state.switchToCurrentInstrumental();
        state.postLoadInstrumental();
      }
    };

    state.preferencesVolumeMetronome.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      state.metronomeVolume = volume;
      state.preferencesLabelVolumeMetronome.text = 'Metronome - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeMetronome.onRightClick = _ ->
    {
      if (state.metronomeVolume <= 0.0)
      {
        state.metronomeVolume = 1.0;
        state.preferencesVolumeMetronome.value = 100.0;
        state.preferencesLabelVolumeMetronome.text = 'Metronome - 100%';
      }
      else
      {
        state.metronomeVolume = 0.0;
        state.preferencesVolumeMetronome.value = 0.0;
        state.preferencesLabelVolumeMetronome.text = 'Metronome - 0%';
      }
    }
    state.preferencesVolumeMetronome.value = Std.int(state.metronomeVolume * 100);
    state.previousAudioVolumes[0] = Std.int(state.metronomeVolume * 100);

    state.preferencesVolumeHitsoundPlayer.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      state.hitsoundVolumePlayer = volume;
      state.preferencesLabelVolumeHitsoundPlayer.text = 'Player - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeHitsoundPlayer.onRightClick = _ ->
    {
      if (state.hitsoundVolumePlayer <= 0.0)
      {
        state.hitsoundVolumePlayer = 1.0;
        state.preferencesVolumeHitsoundPlayer.value = 100.0;
        state.preferencesLabelVolumeHitsoundPlayer.text = 'Player - 100%';
      }
      else
      {
        state.hitsoundVolumePlayer = 0.0;
        state.preferencesVolumeHitsoundPlayer.value = 0.0;
        state.preferencesLabelVolumeHitsoundPlayer.text = 'Player - 0%';
      }
    }
    state.preferencesVolumeHitsoundPlayer.value = Std.int(state.hitsoundVolumePlayer * 100);
    state.previousAudioVolumes[1] = Std.int(state.hitsoundVolumePlayer * 100);

    state.preferencesVolumeHitsoundOpponent.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      state.hitsoundVolumeOpponent = volume;
      state.preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeHitsoundOpponent.onRightClick = _ ->
    {
      if (state.hitsoundVolumeOpponent <= 0.0)
      {
        state.hitsoundVolumeOpponent = 1.0;
        state.preferencesVolumeHitsoundOpponent.value = 100.0;
        state.preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - 100%';
      }
      else
      {
        state.hitsoundVolumeOpponent = 0.0;
        state.preferencesVolumeHitsoundOpponent.value = 0.0;
        state.preferencesLabelVolumeHitsoundOpponent.text = 'Opponent - 0%';
      }
    }
    state.preferencesVolumeHitsoundOpponent.value = Std.int(state.hitsoundVolumeOpponent * 100);
    state.previousAudioVolumes[2] = Std.int(state.hitsoundVolumeOpponent * 100);

    state.preferencesVolumeInstrumental.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      if (state.audioInstTrack != null) state.audioInstTrack.volume = volume;
      state.preferencesLabelVolumeInstrumental.text = 'Instrumental - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeInstrumental.onRightClick = _ ->
    {
      if (state.preferencesVolumeInstrumental.value <= 0.0)
      {
        if (state.audioInstTrack != null) state.audioInstTrack.volume = 1.0;
        state.preferencesVolumeInstrumental.value = 100.0;
        state.preferencesLabelVolumeInstrumental.text = 'Instrumental - 100%';
      }
      else
      {
        if (state.audioInstTrack != null) state.audioInstTrack.volume = 0.0;
        state.preferencesVolumeInstrumental.value = 0.0;
        state.preferencesLabelVolumeInstrumental.text = 'Instrumental - 0%';
      }
    }
    state.previousAudioVolumes[3] = state.preferencesVolumeInstrumental.value;

    state.preferencesVolumeVocalsPlayer.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      state.audioVocalTrackGroup.playerVolume = volume;
      state.preferencesLabelVolumeVocalsPlayer.text = 'Player - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeVocalsPlayer.onRightClick = _ ->
    {
      if (state.audioVocalTrackGroup.playerVolume <= 0.0)
      {
        state.audioVocalTrackGroup.playerVolume = 1.0;
        state.preferencesVolumeVocalsPlayer.value = 100.0;
        state.preferencesLabelVolumeVocalsPlayer.text = 'Player - 100%';
      }
      else
      {
        state.audioVocalTrackGroup.playerVolume = 0.0;
        state.preferencesVolumeVocalsPlayer.value = 0.0;
        state.preferencesLabelVolumeVocalsPlayer.text = 'Player - 0%';
      }
    }
    state.previousAudioVolumes[4] = state.preferencesVolumeVocalsPlayer.value;

    state.preferencesVolumeVocalsOpponent.onChange = event ->
    {
      var volume:Float = event.value.toFloat() / 100.0;
      state.audioVocalTrackGroup.opponentVolume = volume;
      state.preferencesLabelVolumeVocalsOpponent.text = 'Opponent - ${Math.round(event.value)}%';
    };
    state.preferencesVolumeVocalsOpponent.onRightClick = _ ->
    {
      if (state.audioVocalTrackGroup.opponentVolume <= 0.0)
      {
        state.audioVocalTrackGroup.opponentVolume = 1.0;
        state.preferencesVolumeVocalsOpponent.value = 100.0;
        state.preferencesLabelVolumeVocalsOpponent.text = 'Opponent - 100%';
      }
      else
      {
        state.audioVocalTrackGroup.opponentVolume = 0.0;
        state.preferencesVolumeVocalsOpponent.value = 0.0;
        state.preferencesLabelVolumeVocalsOpponent.text = 'Opponent - 0%';
      }
    }
    state.previousAudioVolumes[5] = state.preferencesVolumeVocalsOpponent.value;

    state.menubarItemPlaybackSpeed.onChange = _ -> state.applyPlaybackSpeed(state.menubarItemPlaybackSpeed.pos / 50.0);
    state.menubarItemPlaybackSpeed.onRightClick = _ -> state.setPlaybackSpeed(1.0);

    state.menubarItemToggleToolboxDifficulty.onChange = event -> state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, state.menubarItemToggleToolboxDifficulty, event.value);
    state.menubarItemToggleToolboxMetadata.onChange = event -> state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, state.menubarItemToggleToolboxMetadata, event.value);
    state.menubarItemToggleToolboxTiming.onChange = event -> state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT, state.menubarItemToggleToolboxTiming, event.value);
    state.menubarItemToggleToolboxNoteData.onChange = event -> state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT, state.menubarItemToggleToolboxNoteData, event.value);
    state.menubarItemToggleToolboxEventData.onChange = event -> state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT, state.menubarItemToggleToolboxEventData, event.value);
    state.menubarItemToggleToolboxPlayerPreview.onChange = event ->
    {
      state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, state.menubarItemToggleToolboxPlayerPreview, event.value);
      state.playerPreviewDirty = event.value;
    }
    state.menubarItemToggleToolboxOpponentPreview.onChange = event ->
    {
      state.setToolboxStateFromMenu(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, state.menubarItemToggleToolboxOpponentPreview, event.value);
      state.opponentPreviewDirty = event.value;
    }

    state.menubarItemCameraEditor.onClick = _ ->
    {
      state.moveToCameraEditor();
    };

    // TODO: Pass specific HaxeUI components to add context menus to them.
    // registerContextMenu(null, Paths.xml('ui/editors/chart-editor/context/test'));
  }

  public static function handleToolboxes(state:ChartEditorState):Void
  {
    state.handleDifficultyToolbox();
    state.handlePlayerPreviewToolbox();
    state.handleOpponentPreviewToolbox();
  }

  public static function handleDifficultyToolbox(state:ChartEditorState):Void
  {
    if (state.difficultySelectDirty)
    {
      state.difficultySelectDirty = false;

      var variationMetadata:Null<SongMetadata> = state.songMetadata.get(state.selectedVariation);
      if (variationMetadata != null) variationMetadata.playData.difficulties.sort(
        SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL)
      );

      var difficultyToolbox:ChartEditorDifficultyToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      difficultyToolbox.updateTree();
    }
  }

  public static function handlePlayerPreviewToolbox(state:ChartEditorState):Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = state.getToolboxUnCast(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;
    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;
    if (state.playerPreviewDirty)
    {
      state.playerPreviewDirty = false;

      if (state.currentSongMetadata.playData.characters.player != charPlayer.charId)
      {
        if (state.healthIconBF != null)
        {
          state.healthIconBF.characterId = state.currentSongMetadata.playData.characters.player;
        }

        charPlayer.loadCharacter(state.currentSongMetadata.playData.characters.player);
        charPlayer.characterType = CharacterType.BF;
        charPlayer.flip = true;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Player Preview - ${charPlayer.charName}';
        charPreviewToolbox.invalidateComponentLayout();
      }
    }

    if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
    {
      charPreviewToolbox.width = charPlayer.width + 32;
      charPreviewToolbox.height = charPlayer.height + 64;
    }
    state.currentPlayerCharacterPlayer = charPlayer;
  }

  public static function handleOpponentPreviewToolbox(state:ChartEditorState):Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = state.getToolboxUnCast(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = charPreviewToolbox.findComponent('charOpponent');
    if (charPlayer == null) return;

    if (state.opponentPreviewDirty)
    {
      state.opponentPreviewDirty = false;

      if (state.currentSongMetadata.playData.characters.opponent != charPlayer.charId)
      {
        if (state.healthIconDad != null)
        {
          state.healthIconDad.characterId = state.currentSongMetadata.playData.characters.opponent;
        }

        charPlayer.loadCharacter(state.currentSongMetadata.playData.characters.opponent);
        charPlayer.characterType = CharacterType.DAD;
        charPlayer.flip = false;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Opponent Preview - ${charPlayer.charName}';
        charPreviewToolbox.invalidateComponentLayout();
      }
    }

    if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
    {
      charPreviewToolbox.width = charPlayer.width + 32;
      charPreviewToolbox.height = charPlayer.height + 64;
    }
    state.currentOpponentCharacterPlayer = charPlayer;
  }

  public static function handleSelectionButtons(state:ChartEditorState):Void
  {
    // Make sure buttons are never nudged out of the correct spot.
    // TODO: Why do these even move in the first place? The camera never moves, LOL.
    state.buttonSelectOpponent.y = ChartEditorState.NOTE_SELECT_BUTTON_Y - 2;
    state.buttonSelectPlayer.y = ChartEditorState.NOTE_SELECT_BUTTON_Y - 2;
    state.buttonSelectEvent.y = ChartEditorState.NOTE_SELECT_BUTTON_Y - 2;
  }

  /**
   * Handles display elements for the playbar at the bottom.
   */
  public static function handlePlaybar(state:ChartEditorState):Void
  {
    if (state.playbarHeadLayout == null) throw 'ERROR: Tried to handle playbar, but playbarHeadLayout is null!';

    if (Conductor.instance == null || state.playbarSongRemaining == null) return;

    // Move the playhead to match the song position, if we aren't dragging it.
    state.playbarHeadLayout.playbarHead.pos = state.currentScrollEase;

    state.playbarHeadLayout.playbarHead.max = state.songLengthInPixels * (FlxG.width - 4) / (FlxG.width - 8);
    @:privateAccess state.playbarHeadLayout.playbarHead.findComponent('range', Range).virtualStart = -4 * state.songLengthInPixels / (FlxG.width - 8);

    // Make sure the playbar is never nudged out of the correct spot.
    state.playbarHeadLayout.x = 0;
    state.playbarHeadLayout.y = FlxG.height - 48 - 8;

    var songPos:Float = ChartEditorTimeScale.pixelsToMs(state.currentScrollEase + state.playheadPositionInPixels);
    var songStepTime:Float = Conductor.instance.getTimeInSteps(songPos - Conductor.instance.instrumentalOffset);
    var songPosMilliseconds:String = Std.string(Math.floor(Math.abs(songPos) % Constants.MS_PER_SEC)).lpad('0', 3).substr(0, 2);
    var songPosSeconds:String = Std.string(Math.floor((Math.abs(songPos) / Constants.MS_PER_SEC) % Constants.SECS_PER_MIN)).lpad('0', 2);
    var songPosMinutes:String = Std.string(Math.floor((Math.abs(songPos) / Constants.MS_PER_SEC) / Constants.SECS_PER_MIN)).lpad('0', 2);
    if (songPos < 0) songPosMinutes = '-' + songPosMinutes;
    var songPosString:String = '${songPosMinutes}:${songPosSeconds}.${songPosMilliseconds}';

    if (state.playbarSongPos.value != songPosString) state.playbarSongPos.value = songPosString;

    var songRemaining:Float = Math.max(state.songLengthInMs - songPos, 0.0);
    var songRemainingMilliseconds:String = Std.string(Math.floor(Math.abs(songRemaining) % Constants.MS_PER_SEC)).lpad('0', 3).substr(0, 2);
    var songRemainingSeconds:String = Std.string(Math.floor((songRemaining / Constants.MS_PER_SEC) % Constants.SECS_PER_MIN)).lpad('0', 2);
    var songRemainingMinutes:String = Std.string(Math.floor((songRemaining / Constants.MS_PER_SEC) / Constants.SECS_PER_MIN)).lpad('0', 2);
    var songRemainingString:String = '-${songRemainingMinutes}:${songRemainingSeconds}.${songRemainingMilliseconds}';

    if (state.playbarSongRemaining.value != songRemainingString) state.playbarSongRemaining.value = songRemainingString;

    state.playbarBeatNum.text = 'Beat: ${FlxStringUtil.formatMoney(songStepTime / Constants.STEPS_PER_BEAT)}';
    state.playbarStepNum.text = 'Step: ${Math.floor(songStepTime)}';

    state.playbarNoteSnap.text = '1/${state.noteSnapQuant}';
    state.playbarZoom.text = '${ChartEditorState.ZOOM_LEVELS[state.zoomLevelIndex]}x';
    var difftext:String = '${state.selectedDifficulty.toTitleCase()}${state.selectedVariation == Constants.DEFAULT_VARIATION ? '' : ' (${state.selectedVariation.toTitleCase()})'}';
    if (difftext.length > 20) difftext = difftext.substring(0, 19) + '...';
    state.playbarDifficulty.text = difftext;
    state.playbarBPM.text = 'BPM: ${(Conductor.instance.bpm ?? 0.0)}${Conductor.instance.timeSignatureNumerator != Constants.DEFAULT_TIME_SIGNATURE_NUM
        || Conductor.instance.timeSignatureDenominator != Constants.DEFAULT_TIME_SIGNATURE_DEN ? ' (${Conductor.instance.timeSignatureNumerator}/${Conductor.instance.timeSignatureDenominator})' : ''}';
  }

  /**
   * Handle update code for the Command Palette.
   */
  public static function handleCommandPalette(state:ChartEditorState):Void
  {
    var canOpenCommandPalette:Bool = (ChartEditorCommandPalette.instance != null || !state.isHaxeUIDialogOpen);

    // CTRL + P = Open Command Palette
    if (state.pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.P && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(state, '');
    }
    // CTRL + SHIFT + P = Show and Run Commands
    if (state.pressingControl() && FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.P && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(state, '>');
    }
    // CTRL + G = Go to Measure
    if (state.pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.G && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(state, ':');
    }
    // CTRL + B = Go to Comment
    if (state.pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.B && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(state, '#');
    }
    // CTRL + W = Open Toolbox
    if (state.pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.W && canOpenCommandPalette)
    {
      ChartEditorCommandPalette.openPalette(state, '%');
    }
  }

  @:nullSafety(Off)
  public static function destroyHaxeUIComponents(state:ChartEditorState):Void
  {
    state.clearNotifications();

    if (state.playbarHeadLayout != null)
    {
      state.remove(state.playbarHeadLayout);
      state.playbarHeadLayout.destroy();
      state.playbarHeadLayout = null;
    }
    for (commentPanel in state.commentPanels)
    {
      state.remove(commentPanel);
      commentPanel.destroy();
    }
    state.commentPanels = [];
    if (state.txtCopyNotif != null)
    {
      state.remove(state.txtCopyNotif);
      state.txtCopyNotif.destroy();
      state.txtCopyNotif = null;
    }
    if (state.buttonSelectPlayer != null)
    {
      state.remove(state.buttonSelectPlayer);
      state.buttonSelectPlayer.destroy();
      state.buttonSelectPlayer = null;
    }
    if (state.buttonSelectPlayer != null)
    {
      state.remove(state.buttonSelectPlayer);
      state.buttonSelectPlayer.destroy();
      state.buttonSelectPlayer = null;
    }
    if (state.buttonSelectEvent != null)
    {
      state.remove(state.buttonSelectEvent);
      state.buttonSelectEvent.destroy();
      state.buttonSelectEvent = null;
    }
    if (state.buttonSelectDummy != null)
    {
      state.remove(state.buttonSelectDummy);
      state.buttonSelectDummy.destroy();
      state.buttonSelectDummy = null;
    }
  }

  /**
   * Handles passive behavior of the menu bar, such as updating labels or enabled/disabled status.
   * Does not handle onClick ACTIONS of the menubar.
   */
  public static function handleMenubar(state:ChartEditorState):Void
  {
    if (state.commandHistoryDirty)
    {
      state.commandHistoryDirty = false;

      // Update the Undo and Redo buttons.
      if (state.undoHistory.length == 0)
      {
        // Disable the Undo button.
        state.menubarItemUndo.disabled = true;
        state.menubarItemUndo.text = 'Undo';
      }
      else
      {
        // Change the label to the last command.
        state.menubarItemUndo.disabled = false;
        state.menubarItemUndo.text = 'Undo ${state.undoHistory[state.undoHistory.length - 1].toString()}';
      }

      if (state.redoHistory.length == 0)
      {
        // Disable the Redo button.
        state.menubarItemRedo.disabled = true;
        state.menubarItemRedo.text = 'Redo';
      }
      else
      {
        // Change the label to the last command.
        state.menubarItemRedo.disabled = false;
        state.menubarItemRedo.text = 'Redo ${state.redoHistory[state.redoHistory.length - 1].toString()}';
      }
    }
    if (state.clipboardDirty)
    {
      state.clipboardDirty = false;

      if (funkin.util.ClipboardUtil.getClipboard() == null || !state.clipboardValid)
      {
        state.menubarItemPaste.disabled = true;
        state.menubarItemPasteUnsnapped.disabled = true;
        state.clipboardValid = false;
      }
      else if (state.clipboardValid)
      {
        state.menubarItemPaste.disabled = false;
        state.menubarItemPasteUnsnapped.disabled = false;
      }
    }

    if (state.editButtonsDirty)
    {
      state.editButtonsDirty = false;

      if (state.currentEventSelection.length > 0 || state.currentNoteSelection.length > 0)
      {
        state.menubarItemCopy.disabled = false;
        state.menubarItemCut.disabled = false;
        state.menubarItemDelete.disabled = false;
        state.menubarItemSelectNone.disabled = false;
      }
      else
      {
        state.menubarItemCopy.disabled = true;
        state.menubarItemCut.disabled = true;
        state.menubarItemDelete.disabled = true;
        state.menubarItemSelectNone.disabled = true;
      }
      if (state.currentNoteSelection.length > 0)
      {
        state.menubarItemFlipNotes.disabled = false;
      }
      else
      {
        state.menubarItemFlipNotes.disabled = true;
      }
    }
  }
}
#end
