package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import haxe.ui.components.Button;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import funkin.util.VersionUtil;
import funkin.util.FileUtil;
import openfl.net.FileReference;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import funkin.data.song.SongData.SongNoteData;
import funkin.util.DiffCalcUtil;
import funkin.ui.debug.charting.commands.SwitchDifficultyCommand;
import funkin.ui.debug.charting.handlers.ChartEditorContextMenuHandler;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.containers.Frame;
import haxe.ui.components.TextField;
import funkin.play.stage.Stage;
import haxe.ui.containers.Box;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.core.Screen;
import haxe.ui.events.FocusEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which lists every variation and difficulty of the song.
 * Click a difficulty to switch to it, double-click to rename it, and right-click for everything else.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/difficulty.xml'))
class ChartEditorDifficultyToolbox extends ChartEditorBaseToolbox implements ChartEditorListKeyTarget
{
  static final ROW_STYLE:String = 'padding: 4px; padding-left: 18px; background-opacity: 0;';
  static final ADD_VARIATION_STYLE:String = 'padding: 4px; padding-top: 8px; background-opacity: 0;';
  static final HEADER_STYLE:String = 'padding: 4px; padding-top: 12px; background-opacity: 0; border-bottom: 1px solid #555555;';
  static final SELECTED_STYLE:String = 'background-color: #3C8DF0; background-opacity: 0.45;';
  static final HOVER_STYLE:String = 'background-color: #888888; background-opacity: 0.2;';
  static final DIM_STYLE:String = 'color: #888888;';

  var difficultyToolboxRows:VBox;
  var difficultyToolboxDetails:Frame;
  var difficultyLabelScrollSpeed:Label;
  var difficultyInputScrollSpeed:Slider;
  var difficultyInputRating:NumberStepper;
  var difficultyEstimateRating:haxe.ui.components.Button;

  /**
   * Set while the detail inputs are being filled in, so that doesn't count as an edit.
   */
  var refreshingDetails:Bool = false;

  /**
   * The note count and speed label of each difficulty row, keyed `variation:difficulty`.
   */
  var infoLabels:Map<String, Label> = [];

  /**
   * The difficulty being renamed, as `variation:difficulty`, or the variation getting a new difficulty, as `variation:`.
   */
  var editingKey:Null<String> = null;

  /**
   * Closes the open text field, if there is one. Pass `true` to keep what was typed.
   */
  var closeActiveField:Null<Bool->Void> = null;

  var hoverRows:Array<{row:HBox, style:String}> = [];
  var hoveredRow:Null<HBox> = null;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    this.onDialogClosed = onClose;

    difficultyToolboxRows.registerEvent(MouseEvent.MOUSE_MOVE, function(event:MouseEvent)
    {
      updateHover(event.screenX, event.screenY);
    });
    difficultyToolboxRows.registerEvent(MouseEvent.MOUSE_OUT, function(_)
    {
      updateHover(null, null);
    });

    difficultyInputScrollSpeed.onChange = function(event:UIEvent)
    {
      if (refreshingDetails) return;
      var value:Null<Float> = event.target.value;
      chartEditorState.currentSongChartScrollSpeed = (value != null && value > 0) ? value : 1.0;
      refreshDetails();
    };
    difficultyInputScrollSpeed.onRightClick = _ ->
    {
      chartEditorState.currentSongChartScrollSpeed = 1.0;
      refreshDetails();
    };
    difficultyEstimateRating.onClick = function(_)
    {
      var rating:Null<Float> = DiffCalcUtil.calculate(chartEditorState.currentSongChartNoteData ?? [], chartEditorState.currentSongChartScrollSpeed);
      if (rating == null)
      {
        chartEditorState.warning('Cannot Estimate', 'The chart needs at least two player notes.');
        return;
      }
      chartEditorState.currentSongChartDifficultyRating = Math.round(rating);
      refreshDetails();
    };
    difficultyInputRating.onChange = function(event:UIEvent)
    {
      if (refreshingDetails || event.target.value == null) return;
      chartEditorState.currentSongChartDifficultyRating = Std.int(event.target.value);
    };

    updateTree();
  }

  /**
   * Fill in the panel below the list for the difficulty being edited.
   */
  public function refreshDetails():Void
  {
    var speed:Float = chartEditorState.currentSongChartScrollSpeed;
    refreshingDetails = true;
    difficultyToolboxDetails.text = 'Difficulty: ${chartEditorState.selectedDifficulty.toTitleCase()}';
    if (difficultyInputScrollSpeed.value != speed) difficultyInputScrollSpeed.value = speed;
    difficultyLabelScrollSpeed.text = 'Scroll speed: ${Math.round(speed * 100) / 100}x';
    var rating:Int = chartEditorState.currentSongChartDifficultyRating;
    if (difficultyInputRating.value != rating) difficultyInputRating.value = rating;
    refreshingDetails = false;

    updateInfo(chartEditorState.selectedVariation, chartEditorState.selectedDifficulty);
  }

  function infoText(variation:String, difficulty:String):String
  {
    var chartData:Null<SongChartData> = chartEditorState.songChartData.get(variation);
    var noteCount:Int = chartData?.notes.get(difficulty)?.length ?? 0;
    var speed:Float = chartData?.scrollSpeed.get(difficulty) ?? 1.0;
    return '$noteCount notes, ${Math.round(speed * 100) / 100}x';
  }

  function updateInfo(variation:String, difficulty:String):Void
  {
    var label:Null<Label> = infoLabels.get('$variation:$difficulty');
    if (label == null) return;
    var text:String = infoText(variation, difficulty);
    if (label.text != text) label.text = text;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxDifficulty.selected = false;
  }

  /**
   * Rebuild the list from the song metadata.
   */
  public function updateTree():Void
  {
    if (editingKey != null) return;
    rebuildList();
  }

  function rebuildList():Void
  {
    difficultyToolboxRows.removeAllComponents();
    infoLabels.clear();
    hoverRows = [];
    hoveredRow = null;

    var songName:String = chartEditorState.songMetadata.get(Constants.DEFAULT_VARIATION)?.songName ?? 'Song';
    var title:Label = new Label();
    title.text = songName;
    title.styleString = 'font-bold: true; padding: 2px;';
    difficultyToolboxRows.addComponent(title);

    for (variation in chartEditorState.availableVariations)
    {
      var metadata:Null<SongMetadata> = chartEditorState.songMetadata.get(variation);
      if (metadata == null) continue;

      difficultyToolboxRows.addComponent(buildVariationRow(variation, metadata.playData.difficulties.length));
      for (difficulty in metadata.playData.difficulties)
      {
        if (editingKey == '$variation:$difficulty') difficultyToolboxRows.addComponent(buildNameField(variation, difficulty));
        else
          difficultyToolboxRows.addComponent(buildDifficultyRow(variation, difficulty));
      }

      if (editingKey == '$variation:') difficultyToolboxRows.addComponent(buildNameField(variation, null));
      else
        difficultyToolboxRows.addComponent(buildAddRow('+ Add difficulty', ROW_STYLE, () -> startEditing('$variation:')));
    }

    difficultyToolboxRows.addComponent(buildAddRow('+ Add variation', ADD_VARIATION_STYLE, () -> { chartEditorState.openAddVariationDialog(true); }));

    refreshDetails();
  }

  function buildVariationRow(variation:String, count:Int):HBox
  {
    var row:HBox = makeRow(HEADER_STYLE, false, false);

    var name:Label = new Label();
    name.text = variation.toUpperCase();
    name.styleString = 'font-bold: true; color: #8FB8F0;';
    name.percentWidth = 100;
    row.addComponent(name);

    var info:Label = new Label();
    info.text = count == 1 ? '1 difficulty' : '$count difficulties';
    info.styleString = DIM_STYLE;
    row.addComponent(info);

    row.onRightClick = _ -> { openVariationMenu(variation); };
    return row;
  }

  function buildDifficultyRow(variation:String, difficulty:String):HBox
  {
    var selected:Bool = variation == chartEditorState.selectedVariation && difficulty == chartEditorState.selectedDifficulty;
    var row:HBox = makeRow(ROW_STYLE, selected);

    var name:Label = new Label();
    name.text = difficulty.toTitleCase();
    name.percentWidth = 100;
    row.addComponent(name);

    var info:Label = new Label();
    info.text = infoText(variation, difficulty);
    info.styleString = DIM_STYLE;
    row.addComponent(info);
    infoLabels.set('$variation:$difficulty', info);

    row.onClick = _ ->
    {
      chartEditorState.listKeyTarget = this;
      switchTo(variation, difficulty);
    };
    row.onDblClick = _ -> { startEditing('$variation:$difficulty'); };
    row.onRightClick = _ ->
    {
      chartEditorState.listKeyTarget = this;
      openDifficultyMenu(variation, difficulty);
    };
    return row;
  }

  function buildAddRow(text:String, style:String, action:Void->Void):HBox
  {
    var row:HBox = makeRow(style, false);
    var label:Label = new Label();
    label.text = text;
    label.styleString = DIM_STYLE;
    row.addComponent(label);
    row.onClick = _ -> { action(); };
    return row;
  }

  /**
   * A text field in place of a row.
   * @param difficulty The difficulty being renamed, or `null` to add a new one.
   */
  function buildNameField(variation:String, difficulty:Null<String>):HBox
  {
    var row:HBox = makeRow(ROW_STYLE, false);
    var field:TextField = new TextField();
    field.percentWidth = 100;
    field.text = difficulty ?? '';
    field.placeholder = 'Difficulty name';
    row.addComponent(field);

    var done:Bool = false;
    var onScreenMouseDown:Null<MouseEvent->Void> = null;
    function close(confirm:Bool):Void
    {
      if (done) return;
      done = true;
      Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
      closeActiveField = null;
      if (FocusManager.instance.focus == field) FocusManager.instance.focus = null;
      if (confirm) submitName(variation, difficulty, field.text ?? '');
    }
    function finish(confirm:Bool):Void
    {
      if (done) return;
      close(confirm);
      editingKey = null;
      rebuildList();
    }
    onScreenMouseDown = function(event:MouseEvent):Void
    {
      if (!field.hitTest(event.screenX, event.screenY)) finish(true);
    };
    closeActiveField = close;

    field.registerEvent(KeyboardEvent.KEY_DOWN, function(event:KeyboardEvent)
    {
      if (event.keyCode != 13 && event.keyCode != 27) return;
      chartEditorState.textInputJustClosed = true;
      finish(event.keyCode == 13);
    });
    field.registerEvent(UIEvent.READY, function(_)
    {
      haxe.ui.Toolkit.callLater(function()
      {
        if (done) return;
        field.focus = true;
        Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
      });
    });
    return row;
  }

  function makeRow(style:String, selected:Bool, hoverable:Bool = true):HBox
  {
    var row:HBox = new HBox();
    row.percentWidth = 100;
    row.styleString = selected ? style + SELECTED_STYLE : style;
    if (hoverable && !selected) hoverRows.push({row: row, style: style});
    return row;
  }

  /**
   * Highlight the row under the mouse.
   */
  function updateHover(screenX:Null<Float>, screenY:Null<Float>):Void
  {
    var target:Null<HBox> = null;
    if (screenX != null) for (entry in hoverRows)
    {
      if (entry.row.hitTest(screenX, screenY))
      {
        target = entry.row;
        break;
      }
    }
    if (target == hoveredRow) return;

    for (entry in hoverRows)
    {
      if (entry.row == hoveredRow) entry.row.styleString = entry.style;
      else if (entry.row == target) entry.row.styleString = entry.style + HOVER_STYLE;
    }
    hoveredRow = target;
  }

  function startEditing(key:String):Void
  {
    if (closeActiveField != null) closeActiveField(true);
    editingKey = key;
    rebuildList();
  }

  function submitName(variation:String, difficulty:Null<String>, text:String):Void
  {
    var id:Null<String> = ChartEditorState.sanitizeDifficultyId(text);
    if (id == null || id == difficulty) return;

    var taken:Array<String> = chartEditorState.songMetadata.get(variation)?.playData.difficulties ?? [];
    if (taken.contains(id))
    {
      chartEditorState.error('Difficulty Exists', '"$id" already exists in ${variation.toTitleCase()}.');
      return;
    }

    if (difficulty == null)
    {
      chartEditorState.createDifficulty(variation, id, chartEditorState.currentSongChartScrollSpeed);
      switchTo(variation, id);
    }
    else
    {
      chartEditorState.renameDifficulty(variation, difficulty, id);
    }
  }

  function switchTo(variation:String, difficulty:String):Void
  {
    if (variation == chartEditorState.selectedVariation && difficulty == chartEditorState.selectedDifficulty) return;
    chartEditorState.performCommand(new SwitchDifficultyCommand(chartEditorState.selectedDifficulty, difficulty, chartEditorState.selectedVariation, variation));
    updateTree();
  }

  function openDifficultyMenu(variation:String, difficulty:String):Void
  {
    var menu:Menu = makeMenu();
    addMenuItem(menu, 'Rename', () -> startEditing('$variation:$difficulty'));
    addMenuItem(menu, 'Duplicate', function()
    {
      var taken:Array<String> = chartEditorState.songMetadata.get(variation)?.playData.difficulties ?? [];
      var copy:String = ChartEditorState.uniqueDifficultyId('$difficulty-copy', taken);
      if (chartEditorState.duplicateDifficulty(variation, difficulty, variation, copy)) startEditing('$variation:$copy');
    });

    var others:Array<String> = chartEditorState.availableVariations.filter(v -> v != variation);
    if (others.length > 0)
    {
      var copyMenu:Menu = new Menu();
      copyMenu.text = 'Copy to';
      var moveMenu:Menu = new Menu();
      moveMenu.text = 'Move to';
      for (target in others)
      {
        addMenuItem(copyMenu, target.toTitleCase(), function()
        {
          var taken:Array<String> = chartEditorState.songMetadata.get(target)?.playData.difficulties ?? [];
          chartEditorState.duplicateDifficulty(variation, difficulty, target, ChartEditorState.uniqueDifficultyId(difficulty, taken));
        });
        addMenuItem(moveMenu, target.toTitleCase(), () -> { chartEditorState.moveDifficulty(variation, difficulty, target); });
      }
      menu.addComponent(copyMenu);
      menu.addComponent(moveMenu);
    }

    menu.addComponent(new MenuSeparator());
    var deleteItem:MenuItem = addMenuItem(menu, 'Delete', () -> confirmRemoveDifficulty(variation, difficulty));
    deleteItem.disabled = isLastDifficulty(variation);
    showMenu(menu);
  }

  function openVariationMenu(variation:String):Void
  {
    var menu:Menu = makeMenu();
    addMenuItem(menu, 'Add Difficulty', () -> startEditing('$variation:'));
    menu.addComponent(new MenuSeparator());
    addMenuItem(menu, 'Save Metadata File', () -> saveMetadata(variation));
    addMenuItem(menu, 'Save Chart File', () -> saveChart(variation));
    addMenuItem(menu, 'Load Metadata File', () -> loadMetadata(variation));
    addMenuItem(menu, 'Load Chart File', () -> loadChart(variation));
    if (variation != Constants.DEFAULT_VARIATION)
    {
      menu.addComponent(new MenuSeparator());
      addMenuItem(menu, 'Delete Variation', () -> confirm('Delete the ${variation.toTitleCase()} variation and all of its difficulties? This cannot be undone.', 'Delete Variation',
        () -> chartEditorState.removeVariation(variation)));
    }
    showMenu(menu);
  }

  function makeMenu():Menu
  {
    var menu:Menu = new Menu();
    menu.left = FlxG.mouse.viewX;
    menu.top = FlxG.mouse.viewY;
    return menu;
  }

  function addMenuItem(menu:Menu, text:String, action:Void->Void):MenuItem
  {
    var item:MenuItem = new MenuItem();
    item.text = text;
    item.onClick = _ -> { action(); };
    menu.addComponent(item);
    return item;
  }

  function showMenu(menu:Menu):Void
  {
    ChartEditorContextMenuHandler.openCustomContextMenu(chartEditorState, menu);
  }

  /**
   * The default variation has to keep at least one difficulty.
   */
  function isLastDifficulty(variation:String):Bool
  {
    if (variation != Constants.DEFAULT_VARIATION) return false;
    return (chartEditorState.songMetadata.get(variation)?.playData.difficulties.length ?? 0) <= 1;
  }

  function confirmRemoveDifficulty(variation:String, difficulty:String):Void
  {
    if (isLastDifficulty(variation)) return;
    confirm('Delete ${difficulty.toTitleCase()} from ${variation.toTitleCase()}? This cannot be undone.', 'Delete Difficulty',
      () -> chartEditorState.removeDifficulty(variation, difficulty));
  }

  /**
   * The difficulty that was last copied with Ctrl+C, including its variation and difficulty ID.
   */
  static var copiedDifficulty:Null<{variation:String, difficulty:String}> = null;

  public function containsMouse():Bool
  {
    return hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  public function isListShown():Bool
  {
    return haxe.ui.core.Screen.instance.rootComponents.contains(this) && !hidden;
  }

  public function copySelection():Void
  {
    copiedDifficulty = {variation: chartEditorState.selectedVariation, difficulty: chartEditorState.selectedDifficulty};
    chartEditorState.success('Copied Difficulty', 'Copied ${copiedDifficulty.difficulty.toTitleCase()} (${copiedDifficulty.variation.toTitleCase()}).');
  }

  /**
   * Paste the copied difficulty into the variation being edited, as a new difficulty.
   */
  public function pasteSelection():Void
  {
    var source = copiedDifficulty;
    if (source == null) return;
    var target:String = chartEditorState.selectedVariation;
    var taken:Array<String> = chartEditorState.songMetadata.get(target)?.playData.difficulties ?? [];
    var base:String = source.variation == target ? '${source.difficulty}-copy' : source.difficulty;
    var id:String = ChartEditorState.uniqueDifficultyId(base, taken);
    if (chartEditorState.duplicateDifficulty(source.variation, source.difficulty, target, id)) updateTree();
  }

  public function deleteSelection():Void
  {
    confirmRemoveDifficulty(chartEditorState.selectedVariation, chartEditorState.selectedDifficulty);
  }

  function confirm(message:String, title:String, action:Void->Void):Void
  {
    Dialogs.messageBox(message, title, MessageBoxType.TYPE_YESNO, true, function(button:DialogButton)
    {
      if (button == DialogButton.YES) action();
    });
  }

  function variationSuffix(variation:String):String
  {
    return variation != Constants.DEFAULT_VARIATION ? '-$variation' : '';
  }

  function writeFile(fileName:String, contents:String, label:String):Void
  {
    FileUtil.writeFileReference(fileName, contents, function(notification:String)
    {
      switch (notification)
      {
        case 'success':
          chartEditorState.success('Saved $label', 'Successfully wrote file ($fileName).');
        case 'info':
          chartEditorState.info('Canceled Save $label', '($fileName)');
        case 'error':
          chartEditorState.error('Failure', 'Failed to write file ($fileName).');
      }
    });
  }

  function saveMetadata(variation:String):Void
  {
    var metadata:Null<SongMetadata> = chartEditorState.songMetadata.get(variation);
    if (metadata == null) return;
    writeFile('${chartEditorState.currentSongId}-metadata${variationSuffix(variation)}.json', metadata.serialize(), 'Metadata');
  }

  function saveChart(variation:String):Void
  {
    var chartData:Null<SongChartData> = chartEditorState.songChartData.get(variation);
    if (chartData == null) return;
    writeFile('${chartEditorState.currentSongId}-chart${variationSuffix(variation)}.json', chartData.serialize(), 'Chart Data');
  }

  function loadMetadata(variation:String):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference)
    {
      var data = fileReference.data.toString();
      if (data == null) return;

      var version:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(data);
      var metadata:Null<SongMetadata> = null;
      if (VersionUtil.validateVersion(version, SongRegistry.SONG_METADATA_VERSION_RULE)) metadata = SongRegistry.instance.parseEntryMetadataRawWithMigration(data,
        fileReference.name, version);

      if (metadata == null)
      {
        chartEditorState.error('Failure', 'Failed to load metadata file (${fileReference.name})');
        return;
      }

      chartEditorState.songMetadata.set(variation, metadata);
      chartEditorState.healthIconsDirty = true;
      chartEditorState.playerPreviewDirty = true;
      chartEditorState.opponentPreviewDirty = true;
      chartEditorState.markDifficultiesChanged();
      chartEditorState.success('Replaced Metadata', 'Replaced metadata with file (${fileReference.name})');
    });
  }

  function loadChart(variation:String):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference)
    {
      var data = fileReference.data.toString();
      if (data == null) return;

      var version:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(data);
      var chartData:Null<SongChartData> = null;
      if (VersionUtil.validateVersion(version, SongRegistry.SONG_CHART_DATA_VERSION_RULE)) chartData = SongRegistry.instance.parseEntryChartDataRawWithMigration(data,
        fileReference.name, version);

      if (chartData == null)
      {
        chartEditorState.error('Failure', 'Failed to load chart data file (${fileReference.name})');
        return;
      }

      chartEditorState.songChartData.set(variation, chartData);
      if (variation == chartEditorState.selectedVariation)
      {
        chartEditorState.currentNoteSelection = [];
        chartEditorState.currentEventSelection = [];
        chartEditorState.notePreviewViewportBoundsDirty = true;
      }
      chartEditorState.markDifficultiesChanged();
      chartEditorState.success('Loaded Chart Data', 'Loaded chart data file (${fileReference.name})');
    });
  }

  override public function refresh():Void
  {
    super.refresh();

    if (editingKey == null) updateTree();
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorDifficultyToolbox
  {
    return new ChartEditorDifficultyToolbox(chartEditorState);
  }
}
#end
