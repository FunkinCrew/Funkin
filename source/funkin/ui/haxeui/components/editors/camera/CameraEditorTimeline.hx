package funkin.ui.haxeui.components.editors.camera;

import funkin.ui.debug.cameraeditor.CameraEditorState;
import haxe.ui.events.UIEvent;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;

@:xml('
<vbox width="100%">
  <TimelineControls id="timelineControls" hidden="true"/>
  <TimelineLayers id="timelineLayers" hidden="true"/>
  <listview id="timelineEventList" width="100%" height="240" selectionMode="one-item" isScrollableHorizontally="false" />
</vbox>
')
class CameraEditorTimeline extends VBox
{
  /**
   * The CameraEditorState to attach to.
   */
  public var cameraEditorState:CameraEditorState;

  public function new()
  {
    super();
  }

  public function populateEventList(events:Array<SongEventData>):Void
  {
    for (index => event in events)
    {
      if (['FocusCamera', 'ZoomCamera'].contains(event.eventKind))
      {
        var value = {
          id: '${index}',
          text: '${event.eventKind} (${event.time})',
        }
        timelineEventList.dataSource.add(value);
      }
    }
  }

  @:bind(timelineEventList, UIEvent.CHANGE)
  function eventSelected(event:UIEvent):Void
  {
    var currentData = timelineEventList.selectedItem;

    trace('Event selected: ${currentData.text} (${currentData.id})');

    // We currently select the correct event by getting its index in the event list.
    // TODO: Change this to something that won't break if events get reordered.

    var eventIndex:Int = Std.parseInt(currentData.id);
    cameraEditorState.selectSongEventByIndex(eventIndex);
  }

  @:bind(timelineControls.btnAddLayer, MouseEvent.CLICK)
  function clickAdd(_):Void
  {
    timelineLayers.dataSource.add({layerName: 'Layer ${timelineLayers.dataSource.size + 1}'});
  }

  @:bind(timelineControls.btnRemoveLayer, MouseEvent.CLICK)
  function clickRemove(_):Void
  {
    timelineLayers.dataSource.remove(timelineLayers.selectedItem);
  }
}
