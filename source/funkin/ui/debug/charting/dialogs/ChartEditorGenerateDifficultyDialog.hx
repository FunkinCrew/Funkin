package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongChartEditorData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.handlers.chart.ChartEditorDifficultyHandler;
import funkin.ui.debug.charting.handlers.chart.ChartEditorSubBeatHandler;
import funkin.util.DiffCalcUtil;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;

/**
 * Makes an easier difficulty from an existing one by cutting the notes that are finer than a snap.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGenerateDifficultyDialog extends Dialog
{
  /**
   * How close, in milliseconds, a note has to be to the snap limit to count as on it.
   */
  static final ON_SNAP_MS:Float = 2;

  var chartEditorState:ChartEditorState;
  var variation:String;
  var difficulty:String;

  var sourceNotes:Array<SongNoteData>;
  var scrollSpeed:Float;
  var conductor:Conductor;
  var editorData:Null<SongChartEditorData>;

  var inputName:TextField;
  var inputSnap:DropDown;
  var inputCut:NumberStepper;
  var labelPreview:Label;

  public function new(chartEditorState:ChartEditorState, variation:String, difficulty:String)
  {
    super();
    this.chartEditorState = chartEditorState;
    this.variation = variation;
    this.difficulty = difficulty;

    var chart:Null<SongChartData> = chartEditorState.songChartData.get(variation);
    sourceNotes = chart?.notes.get(difficulty) ?? [];
    scrollSpeed = chart?.scrollSpeed.get(difficulty) ?? 1.0;
    editorData = chart?.editorData;

    conductor = new Conductor();
    var metadata:Null<SongMetadata> = chartEditorState.songMetadata.get(variation);
    if (metadata != null) conductor.mapTimeChanges(metadata.timeChanges);

    title = 'Generate from ${difficulty.toTitleCase()}';
    closable = true;
    destroyOnClose = true;
    width = 320;

    var body:VBox = new VBox();
    body.percentWidth = 100;
    addComponent(body);

    var taken:Array<String> = metadata?.playData.difficulties ?? [];
    inputName = new TextField();
    inputName.text = ChartEditorDifficultyHandler.uniqueDifficultyId('$difficulty-generated', taken);
    inputName.percentWidth = 100;
    body.addComponent(row('Difficulty name', inputName));

    inputSnap = new DropDown();
    inputSnap.dataSource = new ArrayDataSource();
    for (quant in ChartEditorState.SNAP_QUANTS) inputSnap.dataSource.add({text: '1/$quant', value: quant});
    inputSnap.selectedIndex = ChartEditorState.SNAP_QUANTS.indexOf(8);
    inputSnap.percentWidth = 100;
    body.addComponent(row('Snap limit', inputSnap));

    inputCut = new NumberStepper();
    inputCut.min = 0;
    inputCut.max = 100;
    inputCut.step = 5;
    inputCut.pos = 100;
    inputCut.percentWidth = 100;
    body.addComponent(row('Cut finer notes (%)', inputCut));

    labelPreview = new Label();
    labelPreview.percentWidth = 100;
    body.addComponent(labelPreview);

    var buttons:HBox = new HBox();
    buttons.horizontalAlign = 'right';
    var cancel:Button = new Button();
    cancel.text = 'Cancel';
    cancel.onClick = _ -> hideDialog(null);
    var generate:Button = new Button();
    generate.text = 'Generate';
    generate.onClick = _ -> submit();
    buttons.addComponent(cancel);
    buttons.addComponent(generate);
    body.addComponent(buttons);

    inputSnap.onChange = _ -> updatePreview();
    inputCut.onChange = _ -> updatePreview();
    onDialogClosed = _ -> chartEditorState.isHaxeUIDialogOpen = false;
    updatePreview();
  }

  function row(text:String, input:haxe.ui.core.Component):HBox
  {
    var box:HBox = new HBox();
    box.percentWidth = 100;
    var label:Label = new Label();
    label.text = text;
    label.percentWidth = 50;
    label.verticalAlign = 'center';
    input.percentWidth = 50;
    box.addComponent(label);
    box.addComponent(input);
    return box;
  }

  function snapQuant():Int
  {
    var value:Null<Int> = inputSnap.selectedItem?.value;
    return value ?? 8;
  }

  /**
   * The source notes with the given share of the ones finer than the snap limit taken out.
   */
  function generateNotes():Array<SongNoteData>
  {
    var snapSteps:Float = ChartEditorState.BASE_QUANT / snapQuant();
    var cut:Float = inputCut.pos / 100;
    var result:Array<SongNoteData> = [];
    var share:Float = 0;
    for (note in sourceNotes)
    {
      var onSnap:Bool = isOnSnapLimit(note.time, snapSteps);
      if (!onSnap)
      {
        share += cut;
        if (share >= 1 - 0.0001)
        {
          share -= 1;
          continue;
        }
      }
      result.push(note.clone());
    }
    return result;
  }

  /**
   * Whether a note is on the snap limit. A note on a sub-beat counts as the line of the snap the sub-beat was placed with,
   * and one on a sub-beat with no known snap counts as the nearest line of the limit, so it's kept.
   */
  function isOnSnapLimit(time:Float, snapSteps:Float):Bool
  {
    var step:Float = conductor.getTimeInSteps(time);
    var subBeat:Null<Float> = subBeatAt(time);
    if (subBeat != null)
    {
      var placedQuant:Null<Int> = ChartEditorSubBeatHandler.subBeatSnapOf(editorData, subBeat);
      if (placedQuant == null) return true;
      var placedSteps:Float = ChartEditorState.BASE_QUANT / placedQuant;
      step = Math.fround(step / placedSteps) * placedSteps;
      time = conductor.getStepTimeInMs(step);
    }
    var snappedStep:Float = Math.fround(step / snapSteps) * snapSteps;
    return Math.abs(conductor.getStepTimeInMs(snappedStep) - time) <= ON_SNAP_MS;
  }

  /**
   * The sub-beat a note sits on, if any.
   */
  function subBeatAt(time:Float):Null<Float>
  {
    for (subBeat in editorData?.subBeats ?? [])
    {
      if (Math.abs(subBeat - time) <= 1) return subBeat;
    }
    return null;
  }

  static function formatRating(rating:Null<Float>):String
  {
    return (rating == null) ? '-' : '${Math.round(rating * 10) / 10}';
  }

  function updatePreview():Void
  {
    var notes:Array<SongNoteData> = generateNotes();
    var before:Null<Float> = DiffCalcUtil.calculate(sourceNotes, scrollSpeed);
    var after:Null<Float> = DiffCalcUtil.calculate(notes, scrollSpeed);
    labelPreview.text = 'Notes: ${sourceNotes.length} -> ${notes.length}\nEstimate: ${formatRating(before)} -> ${formatRating(after)}';
  }

  function submit():Void
  {
    var id:Null<String> = ChartEditorDifficultyHandler.sanitizeDifficultyId(inputName.text ?? '');
    if (id == null)
    {
      chartEditorState.error('Invalid Name', 'Enter a name for the new difficulty.');
      return;
    }
    var taken:Array<String> = chartEditorState.songMetadata.get(variation)?.playData.difficulties ?? [];
    if (taken.contains(id))
    {
      chartEditorState.error('Difficulty Exists', '"$id" already exists in ${variation.toTitleCase()}.');
      return;
    }

    var notes:Array<SongNoteData> = generateNotes();
    var rating:Null<Float> = DiffCalcUtil.calculate(notes, scrollSpeed);
    var source:String = difficulty;
    var target:String = variation;
    chartEditorState.performDifficultyChange('Generate Difficulty', function()
    {
      if (!chartEditorState.duplicateDifficulty(target, source, target, id)) return false;
      chartEditorState.songChartData.get(target)?.notes.set(id, notes);
      var ratings = chartEditorState.songMetadata.get(target)?.playData.ratings;
      if (rating != null && ratings != null) ratings.set(id, Math.round(rating));

      // Switched to here instead of with a command, so undo takes both back in one step.
      chartEditorState.selectedVariation = target;
      chartEditorState.selectedDifficulty = id;
      return true;
    });
    hideDialog(null);
  }

  /**
   * Open the panel for a difficulty.
   */
  public static function open(chartEditorState:ChartEditorState, variation:String, difficulty:String):ChartEditorGenerateDifficultyDialog
  {
    var dialog:ChartEditorGenerateDifficultyDialog = new ChartEditorGenerateDifficultyDialog(chartEditorState, variation, difficulty);
    dialog.zIndex = 1000;
    chartEditorState.isHaxeUIDialogOpen = true;
    dialog.showDialog(true);
    return dialog;
  }
}
#end
