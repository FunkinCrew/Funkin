package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.NoteParamData;
import funkin.data.song.SongData.SongNoteData;
import funkin.play.notes.notekind.NoteKind.NoteKindParam;
import funkin.play.notes.notekind.NoteKind.NoteKindParamType;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.debug.charting.commands.notes.CustomNoteKindCommand;
import funkin.ui.debug.charting.commands.notes.SetNoteKindCommand;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.handlers.ui.ChartEditorContextMenuHandler;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.Frame;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.core.Component;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which lists the note kinds.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/note-data.xml'))
class ChartEditorNoteDataToolbox extends ChartEditorBaseToolbox
{
  static final ROW_STYLE:String = 'padding: 4px; padding-left: 8px; background-opacity: 0;';
  static final SELECTED_STYLE:String = 'background-color: #3C8DF0; background-opacity: 0.45;';
  static final HOVER_STYLE:String = 'background-color: #888888; background-opacity: 0.2;';
  static final DIM_STYLE:String = 'color: #888888;';

  /**
   * The id the Custom row stands for in the row list.
   */
  static final CUSTOM_ROW:String = '~CUSTOM~';

  var toolboxNotesSummary:Label;
  var toolboxNotesKindScroll:ScrollView;
  var toolboxNotesKindRows:VBox;
  var toolboxNotesCustomBox:HBox;
  var toolboxNotesCustomKind:TextField;
  var toolboxNotesParamsFrame:Frame;
  var toolboxNotesParamsGrid:Grid;

  var rowViews:Array<{kind:String, row:HBox, tag:Label, name:Label, count:Label}> = [];
  var hoveredRow:Null<HBox> = null;

  /**
   * Custom kinds typed in this session.
   */
  var customKinds:Array<String> = [];

  /**
   * The kind the list was last scrolled to, so it only scrolls when the shown kind changes.
   */
  var scrolledKind:Null<String> = '~';

  var builtKinds:String = '';
  var builtParamsKey:String = '~';

  var paramComponents:Array<Component> = [];
  var refreshing:Bool = false;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    this.onDialogClosed = onClose;

    toolboxNotesKindRows.registerEvent(MouseEvent.MOUSE_MOVE, function(event:MouseEvent)
    {
      updateHover(event.screenX, event.screenY);
    });
    toolboxNotesKindRows.registerEvent(MouseEvent.MOUSE_OUT, function(_)
    {
      updateHover(null, null);
    });

    toolboxNotesCustomKind.registerEvent(FocusEvent.FOCUS_OUT, function(_)
    {
      submitCustomKind();
    });
    toolboxNotesCustomKind.registerEvent(KeyboardEvent.KEY_DOWN, function(event:KeyboardEvent)
    {
      if (event.keyCode != 13) return;
      chartEditorState.textInputJustClosed = true;
      submitCustomKind();
    });

    refresh();
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxNoteData.selected = false;
  }

  /**
   * The notes edits apply to.
   */
  var selectedNotes(get, never):Array<SongNoteData>;

  function get_selectedNotes():Array<SongNoteData>
  {
    return chartEditorState.currentNoteSelection;
  }

  /**
   * The current kind being edited.
   */
  function activeKind():Null<String>
  {
    var notes:Array<SongNoteData> = selectedNotes;
    if (notes.length == 0) return chartEditorState.noteKindToPlace ?? '';
    var kind:String = notes[0].kind ?? '';
    for (note in notes)
    {
      if ((note.kind ?? '') != kind) return null;
    }
    return kind;
  }

  /**
   * Default, every registered kind, then custom kinds this chart uses.
   */
  function listKinds():Array<String>
  {
    var registered:Array<String> = NoteKindManager.listNoteKinds().copy();
    registered.sort((a, b) -> Reflect.compare(ChartEditorNoteUtil.noteKindName(a).toLowerCase(), ChartEditorNoteUtil.noteKindName(b).toLowerCase()));
    var kinds:Array<String> = [''].concat(registered);

    var custom:Array<String> = customKinds.copy();
    for (note in chartEditorState.currentSongChartNoteData)
    {
      var kind:String = note.kind ?? '';
      if (!kinds.contains(kind) && !custom.contains(kind)) custom.push(kind);
    }
    var placeKind:String = chartEditorState.noteKindToPlace ?? '';
    if (!kinds.contains(placeKind) && !custom.contains(placeKind)) custom.push(placeKind);
    custom.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
    return kinds.concat(custom);
  }

  static function isCustomKind(kind:String):Bool
  {
    return kind.length > 0 && NoteKindManager.getNoteKind(kind) == null;
  }

  /**
   * Remove a custom kind. Its notes go back to Default as one undo step.
   */
  function deleteCustomKind(kind:String):Void
  {
    var notes:Array<SongNoteData> = chartEditorState.currentSongChartNoteData.filter(note -> note.kind == kind);
    chartEditorState.performCommand(new CustomNoteKindCommand(kind, false, notes));
  }

  public function hasCustomKind(kind:String):Bool
  {
    return customKinds.contains(kind);
  }

  public function addCustomKind(kind:String):Void
  {
    if (!customKinds.contains(kind)) customKinds.push(kind);
  }

  public function removeCustomKind(kind:String):Void
  {
    customKinds.remove(kind);
  }

  override public function refresh():Void
  {
    super.refresh();

    // Picking notes changes the kind new notes get, so their params have to match it.
    var placeKind:String = chartEditorState.noteKindToPlace ?? '';
    if (chartEditorState.noteParamsToPlace.length != NoteKindManager.getParams(placeKind).length) chartEditorState.noteParamsToPlace = defaultParams(placeKind);

    var kinds:Array<String> = listKinds();
    var signature:String = kinds.join('\n');
    if (signature != builtKinds) rebuildRows(kinds);

    var counts:Map<String, Int> = [];
    for (note in chartEditorState.currentSongChartNoteData)
    {
      var kind:String = note.kind ?? '';
      counts.set(kind, (counts.get(kind) ?? 0) + 1);
    }

    var notes:Array<SongNoteData> = selectedNotes;
    var active:Null<String> = activeKind();
    setText(toolboxNotesSummary, notes.length == 0 ? 'NEW NOTES' : (notes.length == 1 ? '1 NOTE PICKED' : '${notes.length} NOTES PICKED'));
    for (view in rowViews)
    {
      if (view.kind != CUSTOM_ROW)
      {
        var count:Int = counts.get(view.kind) ?? 0;
        setText(view.count, count == 0 ? '' : '$count');
      }
      styleRow(view.row, view.kind == active || (view.kind == CUSTOM_ROW && !toolboxNotesCustomBox.hidden));
    }
    scrollToKind(active);

    refreshParams(active);
  }

  /**
   * Scroll the list so the shown kind's row is in view, like picking a note does.
   */
  function scrollToKind(kind:Null<String>):Void
  {
    if (kind == scrolledKind) return;
    scrolledKind = kind;
    if (kind == null) return;
    for (view in rowViews)
    {
      if (view.kind != kind) continue;
      var row:HBox = view.row;
      // Waits a frame, since new rows have no position until HaxeUI lays them out.
      haxe.ui.Toolkit.callLater(() -> toolboxNotesKindScroll.ensureVisible(row));
      return;
    }
  }

  function rebuildRows(kinds:Array<String>):Void
  {
    builtKinds = kinds.join('\n');
    toolboxNotesKindRows.removeAllComponents();
    rowViews = [];
    hoveredRow = null;

    for (kind in kinds.concat([CUSTOM_ROW]))
    {
      var row:HBox = new HBox();
      row.percentWidth = 100;
      row.styleString = ROW_STYLE;

      var tag:Label = new Label();
      tag.width = 26;
      var name:Label = new Label();
      name.percentWidth = 100;
      var count:Label = new Label();
      count.styleString = DIM_STYLE;

      if (kind == CUSTOM_ROW)
      {
        tag.text = '+';
        name.text = 'Custom kind...';
        name.styleString = DIM_STYLE;
      }
      else
      {
        // The same tag and color the notes of this kind show on the grid.
        tag.text = kind.length == 0 ? '' : ChartEditorNoteUtil.noteKindTag(kind);
        tag.styleString = 'font-bold: true; color: ${ChartEditorNoteUtil.noteKindColor(kind).toWebString()};';
        name.text = ChartEditorNoteUtil.noteKindName(kind);
        if (kind.length > 0 && NoteKindManager.getNoteKind(kind) == null) name.tooltip = 'Not a registered note kind: $kind';
        else if (kind.length > 0) name.tooltip = kind;
      }
      row.addComponent(tag);
      row.addComponent(name);
      row.addComponent(count);

      row.onClick = _ -> clickRow(kind);
      row.onDblClick = _ -> if (kind != CUSTOM_ROW) selectNotesOfKind(kind);
      row.onRightClick = _ -> if (kind != CUSTOM_ROW) openRowMenu(kind);

      toolboxNotesKindRows.addComponent(row);
      rowViews.push({kind: kind, row: row, tag: tag, name: name, count: count});
    }
  }

  function clickRow(kind:String):Void
  {
    if (kind == CUSTOM_ROW)
    {
      toolboxNotesCustomBox.hidden = false;
      toolboxNotesCustomKind.focus = true;
      refresh();
      return;
    }
    toolboxNotesCustomBox.hidden = true;
    applyKind(kind);
  }

  function submitCustomKind():Void
  {
    if (toolboxNotesCustomBox.hidden) return;
    var kind:String = StringTools.trim(toolboxNotesCustomKind.text ?? '');
    if (kind.length == 0) return;
    toolboxNotesCustomKind.text = '';
    toolboxNotesCustomBox.hidden = true;
    ChartEditorToolboxHandler.clearHaxeUIFocus();
    // A registered id typed in here is just picked like its row.
    if (!isCustomKind(kind))
    {
      applyKind(kind);
      return;
    }
    // Undoable, so undo takes away a kind made by mistake.
    chartEditorState.performCommand(new CustomNoteKindCommand(kind, true, selectedNotes.copy()));
  }

  /**
   * Apply the kind.
   */
  function applyKind(kind:String):Void
  {
    chartEditorState.noteKindToPlace = kind.length == 0 ? null : kind;
    chartEditorState.noteParamsToPlace = defaultParams(kind);

    var notes:Array<SongNoteData> = selectedNotes.copy();
    if (notes.length > 0)
    {
      var kinds:Array<Null<String>> = [for (note in notes) kind.length == 0 ? null : kind];
      var params:Array<Array<NoteParamData>> = [
        for (note in notes)
          (note.kind ?? '') == kind ? note.params : defaultParams(kind)
      ];
      chartEditorState.performCommand(new SetNoteKindCommand(notes, kinds, params));
    }
    builtParamsKey = '~';
    refresh();
  }

  static function defaultParams(kind:String):Array<NoteParamData>
  {
    return [for (param in NoteKindManager.getParams(kind)) new NoteParamData(param.name, param.data?.defaultValue)];
  }

  function selectNotesOfKind(kind:String):Void
  {
    var notes:Array<SongNoteData> = chartEditorState.currentSongChartNoteData.filter(note -> (note.kind ?? '') == kind);
    chartEditorState.performCommand(new SetItemSelectionCommand(notes, []));
  }

  function openRowMenu(kind:String):Void
  {
    var menu:Menu = new Menu();
    menu.left = FlxG.mouse.viewX;
    menu.top = FlxG.mouse.viewY;
    addMenuItem(menu, 'Select notes of this kind', () -> selectNotesOfKind(kind));
    var pickedItem:MenuItem = addMenuItem(menu, 'Change picked notes to this kind', () -> applyKind(kind));
    pickedItem.disabled = selectedNotes.length == 0;
    menu.addComponent(new MenuSeparator());
    addMenuItem(menu, 'Use for new notes only', () ->
    {
      chartEditorState.noteKindToPlace = kind.length == 0 ? null : kind;
      chartEditorState.noteParamsToPlace = defaultParams(kind);
      refresh();
    });
    if (isCustomKind(kind))
    {
      menu.addComponent(new MenuSeparator());
      addMenuItem(menu, 'Delete custom kind', () -> deleteCustomKind(kind));
    }
    ChartEditorContextMenuHandler.openCustomContextMenu(chartEditorState, menu);
  }

  /**
   * Fill the params frame for the shown kind.
   */
  function refreshParams(kind:Null<String>):Void
  {
    var paramDefs:Array<NoteKindParam> = kind == null ? [] : NoteKindManager.getParams(kind);
    toolboxNotesParamsFrame.hidden = paramDefs.length == 0;
    if (kind == null) return;

    var source:Array<NoteParamData> = selectedNotes.length > 0 ? selectedNotes[0].params : chartEditorState.noteParamsToPlace;
    var key:String = kind + '|' + selectedNotes.length + '|' + (selectedNotes.length > 0 ? Std.string(selectedNotes[0].time) : '');
    if (key != builtParamsKey)
    {
      builtParamsKey = key;
      buildParams(kind, paramDefs);
    }

    refreshing = true;
    toolboxNotesParamsFrame.text = '${ChartEditorNoteUtil.noteKindName(kind)} params';
    for (i in 0...paramComponents.length)
    {
      var value:Dynamic = (i < source.length) ? source[i].value : paramDefs[i].data?.defaultValue;
      if (value != null && paramComponents[i].value != value) paramComponents[i].value = value;
    }
    refreshing = false;
  }

  function buildParams(kind:String, paramDefs:Array<NoteKindParam>):Void
  {
    toolboxNotesParamsGrid.removeAllComponents();
    paramComponents = [];

    for (i in 0...paramDefs.length)
    {
      var param:NoteKindParam = paramDefs[i];

      var label:Label = new Label();
      label.text = param.description;
      label.verticalAlign = 'center';

      var component:Null<Component> = null;
      switch (param.type)
      {
        case NoteKindParamType.INT | NoteKindParamType.FLOAT:
          var stepper:NumberStepper = new NumberStepper();
          stepper.percentWidth = 100;
          stepper.step = param.data?.step ?? 1.0;

          if (param.data?.min != null) stepper.min = param.data.min;
          if (param.data?.max != null) stepper.max = param.data.max;
          if (param.data?.precision != null) stepper.precision = param.data.precision;
          stepper.onChange = _ -> if (!refreshing) setParam(kind, i, stepper.value);
          component = stepper;

        case NoteKindParamType.STRING:
          var field:TextField = new TextField();
          field.percentWidth = 100;
          field.registerEvent(FocusEvent.FOCUS_OUT, _ -> if (!refreshing) setParam(kind, i, field.text));
          component = field;
      }
      if (component == null) continue;

      toolboxNotesParamsGrid.addComponent(label);
      toolboxNotesParamsGrid.addComponent(component);
      paramComponents.push(component);
    }
  }

  /**
   * Change one param for new notes.
   */
  function setParam(kind:String, index:Int, value:Dynamic):Void
  {
    if (index < chartEditorState.noteParamsToPlace.length && (chartEditorState.noteKindToPlace ?? '') == kind)
    {
      chartEditorState.noteParamsToPlace[index].value = value;
    }

    var notes:Array<SongNoteData> = selectedNotes.filter(note -> (note.kind ?? '') == kind && index < note.params.length);
    if (notes.length == 0) return;
    var params:Array<Array<NoteParamData>> = [
      for (note in notes)
      {
        var copy:Array<NoteParamData> = ChartEditorNoteUtil.cloneNoteParams(note.params);
        copy[index].value = value;
        copy;
      }
    ];
    chartEditorState.performCommand(new SetNoteKindCommand(notes, [for (note in notes) note.kind], params, 'Set Note Param'));
  }

  function styleRow(row:HBox, selected:Bool):Void
  {
    var style:String = ROW_STYLE + (selected ? SELECTED_STYLE : (row == hoveredRow ? HOVER_STYLE : ''));
    if (row.styleString != style) row.styleString = style;
  }

  /**
   * Highlight the row under the mouse.
   */
  function updateHover(screenX:Null<Float>, screenY:Null<Float>):Void
  {
    var target:Null<HBox> = null;
    if (screenX != null)
    {
      for (view in rowViews)
      {
        if (view.row.hitTest(screenX, screenY))
        {
          target = view.row;
          break;
        }
      }
    }
    if (target == hoveredRow) return;
    hoveredRow = target;

    var active:Null<String> = activeKind();
    for (view in rowViews)
      styleRow(view.row, view.kind == active || (view.kind == CUSTOM_ROW && !toolboxNotesCustomBox.hidden));
  }

  static function setText(label:Label, text:String):Void
  {
    if (label.text != text) label.text = text;
  }

  function addMenuItem(menu:Menu, text:String, action:Void->Void):MenuItem
  {
    var item:MenuItem = new MenuItem();
    item.text = text;
    item.onClick = _ -> { action(); };
    menu.addComponent(item);
    return item;
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorNoteDataToolbox
  {
    return new ChartEditorNoteDataToolbox(chartEditorState);
  }
}
#end
