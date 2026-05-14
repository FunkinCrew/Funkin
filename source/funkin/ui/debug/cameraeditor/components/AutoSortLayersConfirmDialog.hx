package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import haxe.ui.components.Canvas;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.graphics.ComponentGraphics;

typedef AutoSortPreviewRow =
{
  var name:String;
  var color:Int;
  var events:Array<SongEventData>;
};

typedef AutoSortPreview =
{
  var beforeRows:Array<AutoSortPreviewRow>;
  var afterRows:Array<AutoSortPreviewRow>;
};

/**
 * The confirmation dialog when loading a chart with overlapping layers,
 * prompting the user to reorganize the events automatically.
 */
@:xml('
<dialog width="640">
  <vbox width="100%" style="padding: 12px; spacing: 8px;">
    <label id="messageLabel" width="100%" textAlign="center" />

    <label id="beforeHeader" width="100%" text="Before" style="padding-top: 4px; color: #BBBBBB; font-size: 13px;" />
    <vbox id="beforeContainer" width="100%" style="spacing: 2px;" />

    <label id="afterHeader" width="100%" text="After" style="padding-top: 4px; color: #BBBBBB; font-size: 13px;" />
    <vbox id="afterContainer" width="100%" style="spacing: 2px;" />

    <label id="hintLabel" width="100%" textAlign="center" style="padding-top: 8px; color: #999999;" />
  </vbox>
</dialog>
')
class AutoSortLayersConfirmDialog extends Dialog
{
  public static inline var ROW_HEIGHT:Int = 20;
  public static inline var BLOCK_HEIGHT:Int = 14;
  public static inline var LABEL_WIDTH:Int = 96;
  public static inline var GRID_WIDTH:Int = 500;
  public static inline var MIN_BLOCK_WIDTH_PX:Float = 2.0;
  public static inline var GRID_BG_COLOR:Int = 0x202020;
  public static inline var GRID_BORDER_COLOR:Int = 0x3A3A3A;
  public static inline var LABEL_COLOR:Int = 0xCCCCCC;

  var onSort:Void->Void;

  override public function new(preview:AutoSortPreview, songLengthMs:Float, stepLengthMs:Float, onSort:Void->Void)
  {
    super();

    addClass('no-title');
    this.onSort = onSort;

    messageLabel.text = 'Detected that Camera events in this chart overlap on a single layer.\nWould you like to organize onto separate layers by event type?';
    hintLabel.text = "You can run this later from the 'Generate' menu.";

    var totalMs:Float = computeTotalMs(preview, songLengthMs, stepLengthMs);

    for (row in preview.beforeRows) beforeContainer.addComponent(buildRow(row, totalMs, stepLengthMs));
    for (row in preview.afterRows) afterContainer.addComponent(buildRow(row, totalMs, stepLengthMs));

    var skip:DialogButton = '{{Skip}}';
    var sort:DialogButton = '{{Sort}}';
    buttons = skip | sort;
    defaultButton = '{{Sort}}';
    destroyOnClose = true;
  }

  override public function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == '{{Sort}}' && onSort != null) onSort();

    fn(true);
  }

  function computeTotalMs(preview:AutoSortPreview, songLengthMs:Float, stepLengthMs:Float):Float
  {
    if (songLengthMs > 0) return songLengthMs;

    var fallback:Float = 0;
    for (row in preview.beforeRows)
    {
      for (event in row.events)
      {
        var endMs:Float = event.time + TimelineUtil.getEventDurationSteps(event) * stepLengthMs;
        if (endMs > fallback) fallback = endMs;
      }
    }
    for (row in preview.afterRows)
    {
      for (event in row.events)
      {
        var endMs:Float = event.time + TimelineUtil.getEventDurationSteps(event) * stepLengthMs;
        if (endMs > fallback) fallback = endMs;
      }
    }
    return fallback > 0 ? fallback : 1.0;
  }

  function buildRow(row:AutoSortPreviewRow, totalMs:Float, stepLengthMs:Float):HBox
  {
    var hbox:HBox = new HBox();
    hbox.percentWidth = 100;
    hbox.height = ROW_HEIGHT;
    hbox.customStyle.verticalAlign = "center";

    hbox.addComponent(buildRowLabel(row));
    hbox.addComponent(buildRowGrid(row, totalMs, stepLengthMs));
    return hbox;
  }

  function buildRowLabel(row:AutoSortPreviewRow):Label
  {
    var label:Label = new Label();
    label.text = row.name;
    label.width = LABEL_WIDTH;
    label.height = ROW_HEIGHT;
    label.customStyle.color = LABEL_COLOR;
    label.customStyle.fontSize = 12;
    label.customStyle.textAlign = "right";
    label.customStyle.verticalAlign = "center";
    label.customStyle.paddingRight = 6;
    return label;
  }

  function buildRowGrid(row:AutoSortPreviewRow, totalMs:Float, stepLengthMs:Float):Canvas
  {
    // note: Currently using the Canvas haxeui component to draw the little layer minimap because
    // - we only need to draw it once, not every frame
    // - drawing a the whole timeline preview with buncho `box` components was having performance issues!
    // Perhaps performance could be improved, for now don't need to look into it too much unless we want to figure
    // out how to make timeline minimap more dynamic and crap

    var canvas:Canvas = new Canvas();
    canvas.width = GRID_WIDTH;
    canvas.height = ROW_HEIGHT;

    var g:ComponentGraphics = canvas.componentGraphics;

    g.fillStyle(GRID_BG_COLOR);
    g.rectangle(0, 0, GRID_WIDTH, ROW_HEIGHT);

    g.fillStyle(GRID_BORDER_COLOR);
    g.rectangle(0, 0, GRID_WIDTH, 1);
    g.rectangle(0, ROW_HEIGHT - 1, GRID_WIDTH, 1);
    g.rectangle(0, 0, 1, ROW_HEIGHT);
    g.rectangle(GRID_WIDTH - 1, 0, 1, ROW_HEIGHT);

    g.fillStyle(row.color);
    var blockTop:Float = (ROW_HEIGHT - BLOCK_HEIGHT) / 2;
    for (event in row.events)
    {
      var durationMs:Float = TimelineUtil.getEventDurationSteps(event) * stepLengthMs;
      var leftPx:Float = (event.time / totalMs) * GRID_WIDTH;
      var widthPx:Float = (durationMs / totalMs) * GRID_WIDTH;
      if (leftPx + widthPx > GRID_WIDTH) widthPx = GRID_WIDTH - leftPx;
      if (widthPx < MIN_BLOCK_WIDTH_PX) widthPx = MIN_BLOCK_WIDTH_PX;
      g.rectangle(leftPx, blockTop, widthPx, BLOCK_HEIGHT);
    }

    return canvas;
  }
}
#end
