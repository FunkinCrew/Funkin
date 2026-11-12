package funkin.ui.haxeui.components;

import funkin.play.event.CustomSongEvent;
import funkin.play.event.CustomSongEvent.CustomEventParam;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

class CustomEventParamsList extends VBox
{
  static final HEADER_STYLE:String = 'padding: 4px; padding-top: 8px; background-opacity: 0; border-bottom: 1px solid #555555;';
  static final ROW_STYLE:String = 'padding: 2px; padding-left: 4px; background-opacity: 0;';
  static final HOVER_STYLE:String = 'background-color: #888888; background-opacity: 0.2;';
  static final DIM_STYLE:String = 'color: #888888;';

  public var onParamsChanged:Null<Array<CustomEventParam>->Void> = null;

  var params:Array<CustomEventParam> = [];
  var nameFields:Array<TextField> = [];
  var valueFields:Array<TextField> = [];
  var hoverRows:Array<HBox> = [];

  public function new()
  {
    super();
    percentWidth = 100;
    styleString = 'spacing: 1px;';
    registerEvent(MouseEvent.MOUSE_MOVE, e -> updateHover(e.screenX, e.screenY));
    registerEvent(MouseEvent.MOUSE_OUT, _ -> updateHover(null, null));
    rebuild();
  }

  public function setParams(value:Array<CustomEventParam>):Void
  {
    var next:Array<CustomEventParam> = CustomSongEvent.copyParams(value);
    if (next.length != params.length)
    {
      params = next;
      rebuild();
      return;
    }
    params = next;
    for (i in 0...params.length)
    {
      setQuietly(nameFields[i], params[i].name);
      setQuietly(valueFields[i], params[i].value);
    }
  }

  public function getParams():Array<CustomEventParam>
  {
    return CustomSongEvent.copyParams(params);
  }

  static function setQuietly(field:TextField, text:String):Void
  {
    if (field.focus || field.text == text) return;
    field.pauseEvent(UIEvent.CHANGE, true);
    field.text = text;
    field.resumeEvent(UIEvent.CHANGE, true, true);
  }

  function rebuild():Void
  {
    removeAllComponents();
    nameFields = [];
    valueFields = [];
    hoverRows = [];

    var header:HBox = new HBox();
    header.percentWidth = 100;
    header.styleString = HEADER_STYLE;
    var title:Label = new Label();
    title.text = 'Parameters';
    title.percentWidth = 100;
    header.addComponent(title);
    addComponent(header);

    for (i in 0...params.length) addComponent(buildRow(i));

    var add:HBox = new HBox();
    add.percentWidth = 100;
    add.styleString = ROW_STYLE;
    var addText:Label = new Label();
    addText.text = '+ Add parameter';
    addText.styleString = DIM_STYLE;
    add.addComponent(addText);
    add.onClick = _ ->
    {
      params.push({name: '', value: ''});
      rebuild();
      changed();
      var field:Null<TextField> = nameFields[nameFields.length - 1];
      if (field != null) haxe.ui.Toolkit.callLater(() -> field.focus = true);
    };
    hoverRows.push(add);
    addComponent(add);
  }

  function buildRow(index:Int):HBox
  {
    var row:HBox = new HBox();
    row.percentWidth = 100;
    row.styleString = ROW_STYLE;

    var name:TextField = new TextField();
    name.percentWidth = 40;
    name.placeholder = 'name';
    name.text = params[index].name;
    name.onChange = _ ->
    {
      if (params[index].name == name.text) return;
      params[index].name = name.text ?? '';
      changed();
    };
    row.addComponent(name);
    nameFields.push(name);

    var value:TextField = new TextField();
    value.percentWidth = 60;
    value.placeholder = 'value';
    value.text = params[index].value;
    value.onChange = _ ->
    {
      if (params[index].value == value.text) return;
      params[index].value = value.text ?? '';
      changed();
    };
    row.addComponent(value);
    valueFields.push(value);

    var remove:Label = new Label();
    remove.text = 'x';
    remove.styleString = DIM_STYLE + ' padding-left: 4px; padding-right: 4px;';
    remove.verticalAlign = 'center';
    remove.tooltip = 'Remove this parameter';
    remove.onClick = _ ->
    {
      params.splice(index, 1);
      rebuild();
      changed();
    };
    row.addComponent(remove);

    hoverRows.push(row);
    return row;
  }

  function changed():Void
  {
    if (onParamsChanged != null) onParamsChanged(getParams());
  }

  var hoveredRow:Null<HBox> = null;

  function updateHover(screenX:Null<Float>, screenY:Null<Float>):Void
  {
    var target:Null<HBox> = null;
    if (screenX != null && screenY != null) for (row in hoverRows)
    {
      if (row.hitTest(screenX, screenY))
      {
        target = row;
        break;
      }
    }
    if (target == hoveredRow) return;
    if (hoveredRow != null) hoveredRow.styleString = ROW_STYLE;
    if (target != null) target.styleString = ROW_STYLE + HOVER_STYLE;
    hoveredRow = target;
  }
}
