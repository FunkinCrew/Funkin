package funkin.play.event;

import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.PlayState;
import funkin.play.character.CharacterData.HealthIconData;

/**
 * This class represents a handler for set stage events.
 *
 * Example: Set the stage to "Main Stage [Erect]":
 * ```
 * {
 *   'e': 'SetStage',
 * 	 "v": {
 * 	 	 "stageId": "mainStageErect"
 *   }
 * }
 * ```
 */
class SetStageSongEvent extends SongEvent
{
  public function new()
  {
    super('SetStage');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no stage.
    if (PlayState.instance?.currentStage == null) return;

    PlayState.instance.swapStage(data.value.stageId);
  }

  public override function getTitle():String
  {
    return 'Set Stage';
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'stageId',
        title: 'Stage',
        defaultValue: "mainStage",
        type: SongEventFieldType.ENUM,
        keys: generateStageList(),
      }
    ]);
  }

  /**
   * Returns the entry IDs of all stages.
   */
  static function generateStageList():Map<String, String>
  {
    var stageIDs:Array<String> = StageRegistry.instance.listEntryIds();
    var stageMap:Map<String, String> = new Map<String, String>();

    for (stage in stageIDs)
    {
      var stageData:StageData = StageRegistry.instance.parseEntryDataWithMigration(stage, StageRegistry.instance.fetchEntryVersion(stage));
      stageMap.set(stageData.name, stage);
    }
    return stageMap;
  }
}
