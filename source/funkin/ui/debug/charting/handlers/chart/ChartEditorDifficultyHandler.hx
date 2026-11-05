package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.song.SwitchDifficultyCommand;
import funkin.util.Constants;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorDifficultyHandler
{
  public static function createDifficulty(state:ChartEditorState, variation:String, difficulty:String, scrollSpeed:Float = 1.0):Void
  {
    var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.playData.difficulties.pushUnique(difficulty);

    var resultChartData = state.songChartData.get(variation);
    if (resultChartData == null)
    {
      resultChartData = new SongChartData([difficulty => scrollSpeed], [], [difficulty => []]);
      state.songChartData.set(variation, resultChartData);
    }
    else
    {
      resultChartData.scrollSpeed.set(difficulty, scrollSpeed);
      resultChartData.notes.set(difficulty, []);
    }

    state.difficultySelectDirty = true; // Force the Difficulty toolbox to update.

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
  }

  public static function cloneDifficulty(state:ChartEditorState, variation:String, difficulty:String, newVariation:String, newDifficulty:String, scrollSpeed:Float = 1.0):Void
  {
    var newVariationMetadata:Null<SongMetadata> = state.songMetadata.get(newVariation);
    if (newVariationMetadata == null) return;

    var oldChartData:Null<SongChartData> = state.songChartData.get(variation);
    if (oldChartData == null)
    {
      // If we can't access the difficulty to copy, just create a blank one.
      state.createDifficulty(newVariation, newDifficulty, scrollSpeed);
      return;
    };

    var newNoteData:Null<Array<SongNoteData>> = oldChartData.notes.get(difficulty)?.clone();
    if (newNoteData == null || newNoteData.length == 0)
    {
      // If we can't access the difficulty to copy, just create a blank one.
      state.createDifficulty(newVariation, newDifficulty, scrollSpeed);
      return;
    };

    // Actually add the new difficulty.

    newVariationMetadata.playData.difficulties.pushUnique(newDifficulty);

    var newChartData = state.songChartData.get(newVariation);
    if (newChartData == null)
    {
      newChartData = new SongChartData([newDifficulty => scrollSpeed], [], [newDifficulty => newNoteData]);
      state.songChartData.set(newVariation, newChartData);
    }
    else
    {
      newChartData.scrollSpeed.set(newDifficulty, scrollSpeed);
      newChartData.notes.set(newDifficulty, newNoteData);
    }

    state.difficultySelectDirty = true; // Force the Difficulty toolbox to update.

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  public static function removeDifficulty(state:ChartEditorState, variation:String, difficulty:String):Void
  {
    var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.playData.difficulties.remove(difficulty);

    var resultChartData = state.songChartData.get(variation);
    if (resultChartData != null)
    {
      resultChartData.scrollSpeed.remove(difficulty);
      resultChartData.notes.remove(difficulty);
    }

    // Remove the variation if it is empty.
    var variationEmpty:Bool = variation != Constants.DEFAULT_VARIATION && variationMetadata.playData.difficulties.length == 0;
    if (variationEmpty)
    {
      state.songMetadata.remove(variation);
      state.songChartData.remove(variation);
    }

    if (variation == state.selectedVariation)
    {
      if (variationEmpty) state.selectedVariation = Constants.DEFAULT_VARIATION;
      var remaining:Array<String> = state.songMetadata.get(state.selectedVariation)?.playData.difficulties ?? [];
      if (remaining.length > 0 && !remaining.contains(state.selectedDifficulty)) state.selectedDifficulty = remaining[0];
    }

    state.refreshPlayDataVariations();
    state.difficultySelectDirty = true; // Force the Difficulty toolbox to update.

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  /**
   * Turn typed text into a difficulty or variation ID.
   */
  public static function sanitizeDifficultyId(text:String):Null<String>
  {
    var result:String = ~/[^a-z0-9_-]/g.replace(~/\s+/g.replace(StringTools.trim(text).toLowerCase(), '-'), '');
    return result.length > 0 ? result : null;
  }

  /**
   * Find an ID based on `base` that is not in `taken`.
   */
  public static function uniqueDifficultyId(base:String, taken:Array<String>):String
  {
    if (!taken.contains(base)) return base;
    var index:Int = 2;
    while (taken.contains('$base-$index')) index++;
    return '$base-$index';
  }

  public static function moveMapKey<T>(map:Null<Map<String, T>>, from:String, to:String):Void
  {
    if (map == null || !map.exists(from)) return;
    map.set(to, map.get(from));
    map.remove(from);
  }

  public static function markDifficultiesChanged(state:ChartEditorState):Void
  {
    state.difficultySelectDirty = true;
    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
  }

  /**
   * Give a difficulty a new ID.
   * @return Whether the rename happened.
   */
  public static function renameDifficulty(state:ChartEditorState, variation:String, difficulty:String, newDifficulty:String):Bool
  {
    if (difficulty == newDifficulty) return false;
    var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
    if (variationMetadata == null) return false;
    var difficulties:Array<String> = variationMetadata.playData.difficulties;
    var index:Int = difficulties.indexOf(difficulty);
    if (index == -1 || difficulties.contains(newDifficulty)) return false;

    difficulties[index] = newDifficulty;
    var chartData:Null<SongChartData> = state.songChartData.get(variation);
    if (chartData != null)
    {
      ChartEditorDifficultyHandler.moveMapKey(chartData.scrollSpeed, difficulty, newDifficulty);
      ChartEditorDifficultyHandler.moveMapKey(chartData.notes, difficulty, newDifficulty);
    }
    ChartEditorDifficultyHandler.moveMapKey(variationMetadata.playData.ratings, difficulty, newDifficulty);

    if (variation == state.selectedVariation && state.selectedDifficulty == difficulty) state.selectedDifficulty = newDifficulty;
    state.markDifficultiesChanged();
    return true;
  }

  /**
   * Copy a difficulty into a new difficulty, which can be in another variation.
   * @return Whether the copy was made.
   */
  public static function duplicateDifficulty(state:ChartEditorState, variation:String, difficulty:String, targetVariation:String, newDifficulty:String):Bool
  {
    var targetMetadata:Null<SongMetadata> = state.songMetadata.get(targetVariation);
    if (targetMetadata == null || targetMetadata.playData.difficulties.contains(newDifficulty)) return false;

    var sourceChart:Null<SongChartData> = state.songChartData.get(variation);
    var sourceNotes:Null<Array<SongNoteData>> = sourceChart != null ? sourceChart.notes.get(difficulty) : null;
    var notes:Array<SongNoteData> = sourceNotes != null ? sourceNotes.deepClone() : [];
    var sourceSpeed:Null<Float> = sourceChart != null ? sourceChart.scrollSpeed.get(difficulty) : null;
    var speed:Float = sourceSpeed ?? 1.0;

    targetMetadata.playData.difficulties.push(newDifficulty);
    var targetChart:Null<SongChartData> = state.songChartData.get(targetVariation);
    if (targetChart == null)
    {
      state.songChartData.set(targetVariation, new SongChartData([newDifficulty => speed], [], [newDifficulty => notes]));
    }
    else
    {
      targetChart.scrollSpeed.set(newDifficulty, speed);
      targetChart.notes.set(newDifficulty, notes);
    }

    var rating:Null<Int> = state.songMetadata.get(variation)?.playData.ratings?.get(difficulty);
    if (rating != null && targetMetadata.playData.ratings != null) targetMetadata.playData.ratings.set(newDifficulty, rating);

    state.markDifficultiesChanged();
    return true;
  }

  /**
   * Move a difficulty to another variation, following it if it was the one being edited.
   * @return Whether the move happened.
   */
  public static function moveDifficulty(state:ChartEditorState, variation:String, difficulty:String, targetVariation:String):Bool
  {
    if (variation == targetVariation) return false;
    var targetMetadata:Null<SongMetadata> = state.songMetadata.get(targetVariation);
    if (targetMetadata == null) return false;

    var newDifficulty:String = ChartEditorDifficultyHandler.uniqueDifficultyId(difficulty, targetMetadata.playData.difficulties);
    var wasSelected:Bool = variation == state.selectedVariation && difficulty == state.selectedDifficulty;
    if (!state.duplicateDifficulty(variation, difficulty, targetVariation, newDifficulty)) return false;

    if (wasSelected)
    {
      state.selectedVariation = targetVariation;
      state.selectedDifficulty = newDifficulty;
    }
    state.removeDifficulty(variation, difficulty);
    state.markDifficultiesChanged();
    return true;
  }

  /**
   * Delete a whole variation. The default variation can't be removed.
   */
  public static function removeVariation(state:ChartEditorState, variation:String):Void
  {
    if (variation == Constants.DEFAULT_VARIATION || !state.songMetadata.exists(variation)) return;

    if (variation == state.selectedVariation)
    {
      state.selectedVariation = Constants.DEFAULT_VARIATION;
      state.selectedDifficulty = state.availableDifficulties[0];
    }
    state.songMetadata.remove(variation);
    state.songChartData.remove(variation);

    state.refreshPlayDataVariations();
    state.markDifficultiesChanged();
  }

  public static function incrementDifficulty(state:ChartEditorState, change:Int):Void
  {
    var variatedDifficulty:String = '${state.selectedDifficulty}-${state.selectedVariation}';
    var currentDifficultyIndex:Int = state.availableDifficulties.indexOf(state.selectedDifficulty);
    var currentAllDifficultyIndex:Int = state.allDifficulties.indexOf(variatedDifficulty);

    if (currentDifficultyIndex == -1 || currentAllDifficultyIndex == -1)
    {
      trace('ERROR determining difficulty index!');
    }

    var isFirstDiff:Bool = currentAllDifficultyIndex == 0;
    var isLastDiff:Bool = (currentAllDifficultyIndex == state.allDifficulties.length - 1);

    var isFirstDiffInVariation:Bool = currentDifficultyIndex == 0;
    var isLastDiffInVariation:Bool = (currentDifficultyIndex == state.availableDifficulties.length - 1);

    trace(state.allDifficulties);

    if (change < 0 && isFirstDiff)
    {
      trace('At lowest difficulty! Do nothing.');
      return;
    }

    if (change > 0 && isLastDiff)
    {
      trace('At highest difficulty! Do nothing.');
      return;
    }

    if (change < 0)
    {
      trace('Decrement difficulty.');

      // If we reached this point, we are not at the lowest difficulty.
      if (isFirstDiffInVariation)
      {
        // Go to the previous variation, then last difficulty in that variation.
        var currentVariationIndex:Int = state.availableVariations.indexOf(state.selectedVariation);
        var prevVariation = state.availableVariations[currentVariationIndex - 1];
        var prevVariationDifficulties:Array<String> = state.getAvailableDifficulties(prevVariation);
        var prevDifficulty = prevVariationDifficulties[prevVariationDifficulties.length - 1];

        trace('${state.selectedVariation}:${state.selectedDifficulty} -> ${prevVariation}:${prevDifficulty}');
        state.performCommand(new SwitchDifficultyCommand(state.selectedDifficulty, prevDifficulty, state.selectedVariation, prevVariation));

        Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
        state.updateTimeSignature();

        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to previous difficulty in this variation.
        var prevDifficulty = state.availableDifficulties[currentDifficultyIndex - 1];
        trace('${state.selectedVariation}:${state.selectedDifficulty} -> ${state.selectedVariation}:${prevDifficulty}');
        state.performCommand(new SwitchDifficultyCommand(state.selectedDifficulty, prevDifficulty, state.selectedVariation, state.selectedVariation));

        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
    }
    else
    {
      trace('Increment difficulty.');

      // If we reached this point, we are not at the highest difficulty.
      if (isLastDiffInVariation)
      {
        // Go to next variation, then first difficulty in that variation.
        var currentVariationIndex:Int = state.availableVariations.indexOf(state.selectedVariation);
        var nextVariation = state.availableVariations[currentVariationIndex + 1];
        var nextVariationDifficulties:Array<String> = state.getAvailableDifficulties(nextVariation);
        var nextDifficulty = nextVariationDifficulties[0];

        trace('${state.selectedVariation}:${state.selectedDifficulty} -> ${nextVariation}:${nextDifficulty}');
        state.performCommand(new SwitchDifficultyCommand(state.selectedDifficulty, nextDifficulty, state.selectedVariation, nextVariation));

        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to next difficulty in this variation.
        var nextDifficulty = state.availableDifficulties[currentDifficultyIndex + 1];
        trace('${state.selectedVariation}:${state.selectedDifficulty} -> ${state.selectedVariation}:${nextDifficulty}');
        state.performCommand(new SwitchDifficultyCommand(state.selectedDifficulty, nextDifficulty, state.selectedVariation, state.selectedVariation));

        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
        state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    // Removed this notification because you can see your difficulty in the playbar now.
    // this.success('Switch Difficulty', 'Switched difficulty to ${selectedDifficulty.toTitleCase()}');
  }
}
#end
