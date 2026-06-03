package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.util.Color;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;

/**
 * A dialog which allows the user to select a color with an intuitive wheel interface.
 */
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/dialogs/color-picker.xml'))
class ChartEditorColorPicker extends ChartEditorBaseDialog
{
  /**
   * Called when the user has selected a color.
   */
  public var onColorSelected:Null<Color->Void>;

  /**
   * The preset colors displayed in the palette at the bottom.
   */
  public var paletteColors(default, set):Array<Color> = [];

  function set_paletteColors(colors:Array<Color>):Array<Color>
  {
    this.paletteColors = colors;

    updatePaletteColors();

    return this.paletteColors;
  }

  public function new(chartEditorState2:ChartEditorState, params2:DialogParams)
  {
    super(chartEditorState2, params2);

    colorPalette1.onClick = (_) -> colorPicker.currentColor = colorPalette1.backgroundColor;
    colorPalette2.onClick = (_) -> colorPicker.currentColor = colorPalette2.backgroundColor;
    colorPalette3.onClick = (_) -> colorPicker.currentColor = colorPalette3.backgroundColor;
    colorPalette4.onClick = (_) -> colorPicker.currentColor = colorPalette4.backgroundColor;
    colorPalette5.onClick = (_) -> colorPicker.currentColor = colorPalette5.backgroundColor;
    colorPalette6.onClick = (_) -> colorPicker.currentColor = colorPalette6.backgroundColor;
    colorPalette7.onClick = (_) -> colorPicker.currentColor = colorPalette7.backgroundColor;
    colorPalette8.onClick = (_) -> colorPicker.currentColor = colorPalette8.backgroundColor;
  }

  function updatePaletteColors():Void
  {
    colorPalette1.backgroundColor = paletteColors[0] ?? Color.fromString('#FFFFFF');
    colorPalette2.backgroundColor = paletteColors[1] ?? Color.fromString('#FFFFFF');
    colorPalette3.backgroundColor = paletteColors[2] ?? Color.fromString('#FFFFFF');
    colorPalette4.backgroundColor = paletteColors[3] ?? Color.fromString('#FFFFFF');
    colorPalette5.backgroundColor = paletteColors[4] ?? Color.fromString('#FFFFFF');
    colorPalette6.backgroundColor = paletteColors[5] ?? Color.fromString('#FFFFFF');
    colorPalette7.backgroundColor = paletteColors[6] ?? Color.fromString('#FFFFFF');
    colorPalette8.backgroundColor = paletteColors[7] ?? Color.fromString('#FFFFFF');
  }

  @:bind(buttonCancel, MouseEvent.CLICK)
  function onClickButtonCancel(_:MouseEvent):Void
  {
    this.hideDialog(DialogButton.CANCEL);
  }

  @:bind(buttonApply, MouseEvent.CLICK)
  function onClickButtonApply(_:MouseEvent):Void
  {
    this.hideDialog(DialogButton.APPLY);
  }

  override public function onClose(event:DialogEvent):Void
  {
    if (event.button == DialogButton.APPLY)
    {
      // User applied the selected color.
      if (onColorSelected != null)
      {
        onColorSelected(colorPicker.currentColor);
      }
    }
    else
    {
      // User cancelled the dialog, don't apply changes.
    }
  }

  /**
   * Construct and display a color picker.
   *
   * @param chartEditorState The ChartEditorState to display the dialog over.
   * @param closable Whether the dialog can be closed by the user without selecting a color.
   * @param modal Whether the dialog covers stuff behind it.
   * @return ChartEditorColorPicker
   */
  public static function build(chartEditorState:ChartEditorState, closable:Bool = true, modal:Bool = true):ChartEditorColorPicker
  {
    var dialog = new ChartEditorColorPicker(chartEditorState, {
      closable: closable,
      modal: modal
    });

    dialog.showDialog(modal);

    return dialog;
  }
}
#end
