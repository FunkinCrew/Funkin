package funkin.data.freeplay.player;

import funkin.data.animation.AnimationData;

@:nullSafety
class PlayerData
{
  /**
   * The sematic version number of the player data JSON format.
   * Supports fancy comparisons like NPM does it's neat.
   */
  @:default(funkin.data.freeplay.player.PlayerRegistry.PLAYER_DATA_VERSION)
  public var version:String;

  /**
   * A readable name for this playable character.
   */
  public var name:String = 'Unknown';

  /**
   * The character IDs this character is associated with.
   * Only songs that use these characters will show up in Freeplay.
   */
  @:default([])
  public var ownedChars:Array<String> = [];

  /**
   * Whether to show songs with character IDs that aren't associated with any specific character.
   */
  @:optional
  @:default(false)
  public var showUnownedChars:Bool = false;

  /**
   * Whether this character is unlocked by default.
   * Use a ScriptedPlayableCharacter to add custom logic.
   */
  @:optional
  @:default(true)
  public var unlocked:Bool = true;

  public function new()
  {
    this.version = PlayerRegistry.PLAYER_DATA_VERSION;
  }

  /**
   * Convert this StageData into a JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var writer = new json2object.JsonWriter<PlayerData>();
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = PlayerRegistry.PLAYER_DATA_VERSION;
  }
}
