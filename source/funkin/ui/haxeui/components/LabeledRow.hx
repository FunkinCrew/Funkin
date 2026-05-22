package funkin.ui.haxeui.components;

import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.util.Variant;

/**
 * A horizontal row consisting of a right-aligned label and a slot for any
 * child control. Used by editor properties panels to dedupe the repetitive
 * `<hbox><label/><control/></hbox>` markup.
 *
 * Example:
 *   <LabeledRow text="X Position">
 *     <number-stepper id="myStepper" width="160" />
 *   </LabeledRow>
 */
@:composite(LabeledRowBuilder)
class LabeledRow extends HBox
{
  @:clonable @:behaviour(LabelTextBehaviour)
  public var text:Variant;

  public function new()
  {
    super();
    percentWidth = 100;
  }
}

@:dox(hide) @:noCompletion
private class LabelTextBehaviour extends DataBehaviour
{
  override function validateData():Void
  {
    final row:LabeledRow = cast _component;
    final label:Null<Label> = row.findComponent('labeledRowLabel', Label);
    if (label != null) label.text = _value;
  }
}

@:dox(hide) @:noCompletion
private class LabeledRowBuilder extends CompositeBuilder
{
  var _row:LabeledRow;

  public function new(row:LabeledRow)
  {
    super(row);
    _row = row;
  }

  override public function create():Void
  {
    final label:Label = new Label();
    label.id = 'labeledRowLabel';
    label.verticalAlign = 'center';
    label.horizontalAlign = 'right';
    label.percentWidth = 100;
    _row.addComponent(label);
  }
}
