package funkin.ui.charSelect.characters;

import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectCharacterData;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectData;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectGFData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.group.FunkinGroup;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.ui.charSelect.CharacterSelectState;
import funkin.ui.charSelect.characters.CharSelectCharacter.CharacterAnimation;
import funkin.ui.charSelect.characters.CharSelectCharacter.CharacterSelectType;

/**
 * A `FunkinGroup` that holds all of the characters for the Character Select screen.
 * You can retrieve a character by its ID with `getCharacter()`.
 */
@:nullSafety
@:access(funkin.ui.charSelect.characters.CharSelectCharacter)
class CharSelectCharacterGroup extends FunkinGroup<CharSelectCharacter>
{
  /**
   * The current player character.
   */
  public var player(get, never):CharSelectCharacter;

  function get_player():CharSelectCharacter
  {
    var playerCharacter:Null<CharSelectCharacter> = this.getFirst(
      (character) -> (character.alive && character.visible) && character.characterType != CharacterSelectType.GF);

    if (playerCharacter == null)
    {
      playerCharacter = this.getFirst((character) -> character.alive && character.characterType == CharacterSelectType.GF);
    }

    if (playerCharacter == null)
    {
      throw 'Failed to find player character in character group!';

      // So null-safety is happy.
      return new CharSelectCharacter('unknown', CharacterSelectState.CUTOUT_SIZE, 0, PLAYER, null);
    }

    return playerCharacter;
  }

  /**
   * The current GF character.
   */
  public var gf(get, never):CharSelectCharacter;

  function get_gf():CharSelectCharacter
  {
    var gfCharacter:Null<CharSelectCharacter> = this.getFirst(
      (character) -> (character.alive && character.visible) && character.characterType == CharacterSelectType.GF);

    if (gfCharacter == null)
    {
      gfCharacter = this.getFirst((character) -> character.alive && character.characterType == CharacterSelectType.GF);
    }

    if (gfCharacter == null)
    {
      throw 'Failed to find GF character in character group!';

      // So null-safety is happy.
      return new CharSelectCharacter('unknown', CharacterSelectState.CUTOUT_SIZE, 0, PLAYER, null);
    }

    return gfCharacter;
  }

  /**
   * A static ambience that plays when the Locked character is selected.
   */
  var staticSound:FunkinSound;

  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    staticSound = new FunkinSound();

    staticSound.loadEmbedded(Paths.sound('ui/character-select/sounds/static'));
    staticSound.looped = true;
    staticSound.volume = 0.6;

    FlxG.sound.list.add(staticSound);
  }

  /**
   * Retrieves a character by its ID.
   * @param id The ID of the character to retrieve.
   * @param isGF Whether to retrieve the GF character.
   * @return The character, or null if it doesn't exist.
   */
  public function getCharacter(id:String, isGF:Bool = false):Null<CharSelectCharacter>
  {
    return this.getFirst((char) -> char.playerId == id && (isGF ? char.characterType == CharacterSelectType.GF : true));
  }

  /**
   * Dispatches an event to all characters.
   * @param event The event to dispatch.
   */
  public function dispatchEvent(event:ScriptEvent):Void
  {
    this.forEach((character) -> ScriptEventDispatcher.callEvent(character, event));
  }

  /**
   * Switches the characters in the Character Select screen.
   * @param oldId The ID of the character to switch away from.
   * @param newId The ID of the character to switch to.
   */
  public function setCharacters(oldId:String, newId:String):Void
  {
    var oldPlayer:Null<CharSelectCharacter> = getCharacter(oldId);
    var oldGF:Null<CharSelectCharacter> = getCharacter(oldId, true);
    var newPlayer:Null<CharSelectCharacter> = getCharacter(newId);
    var newGF:Null<CharSelectCharacter> = getCharacter(newId, true);

    if (oldGF != null)
    {
      if (newId == 'locked')
      {
        oldGF.localVisible = false;
      }
      else
      {
        oldGF.kill();
      }
    }

    if (oldPlayer != null)
    {
      oldPlayer.playAnimation(SLIDEOUT, true);
    }

    newPlayer?.revive();
    newPlayer?.playAnimation(SLIDEIN, true);

    if (newGF != null)
    {
      newGF.localVisible = newId != 'locked';
      newGF.revive();
      newGF.playAnimation(IDLE);
    }

    if (newId == 'locked')
    {
      staticSound.play();
    }
    else
    {
      staticSound.stop();
    }
  }

  /**
   * Loads the characters for the Character Select screen.
   * @param startingCharacter The starting character to use.
   * @param characterList A list of all available character IDs.
   */
  public function createCharacters(startingCharacter:String, characterList:Map<Int, String>):Void
  {
    if (!this.isEmpty())
    {
      this.clear();
    }

    var lockedCharacter:CharSelectCharacter = createCharacter('locked', LOCKED_PLAYER, {
      assetPath: 'ui/character-select/characters/locked',
      animations: PlayerCharSelectData.getDefaultAnimations(LOCKED_PLAYER),
      atlasSettings: {
        cacheOnLoad: true,
        filterQuality: 2, // LOW
      }
    });

    // Layer the locked character on top of every other character.
    lockedCharacter.zIndex = 100;

    lockedCharacter.kill();
    add(lockedCharacter);

    // Create the characters for every player in the list.
    for (position => newId in characterList)
    {
      var playerCSData:Null<PlayerCharSelectData> = PlayerRegistry.instance.fetchEntry(newId)?.getCharSelectData();
      if (playerCSData == null) continue;

      var playerParams:PlayerCharSelectCharacterData = {
        assetPath: (playerCSData.characterData?.assetPath ?? playerCSData.assetPath) ?? 'ui/character-select/characters/${newId}',
        renderType: playerCSData.characterData?.renderType ?? 'animateatlas',
        scriptClass: playerCSData.characterData?.scriptClass,
        animations: playerCSData.characterData?.animations,
        atlasSettings: playerCSData.characterData?.atlasSettings,
        danceEvery: playerCSData.characterData?.danceEvery,
        offsets: playerCSData.characterData?.offsets ?? [0, 0]
      };

      // Additional check for if the asset path is blank... somehow.
      if (playerParams.assetPath.isBlank())
      {
        playerParams.assetPath = 'ui/character-select/characters/${newId}';
      }

      var playerCharacter:CharSelectCharacter = createCharacter(newId, PLAYER, playerParams);

      if (newId != startingCharacter) playerCharacter.kill();
      this.add(playerCharacter);

      var girlfriendCSData:PlayerCharSelectGFData = playerCSData.gf;
      if (girlfriendCSData != null)
      {
        var gfParams:PlayerCharSelectCharacterData = {
          assetPath: girlfriendCSData.characterData?.assetPath ?? girlfriendCSData.assetPath,
          renderType: girlfriendCSData.characterData?.renderType ?? 'animateatlas',
          scriptClass: girlfriendCSData.characterData?.scriptClass,
          animations: girlfriendCSData.characterData?.animations,
          atlasSettings: girlfriendCSData.characterData?.atlasSettings,
          danceEvery: girlfriendCSData.characterData?.danceEvery,
          offsets: girlfriendCSData.characterData?.offsets ?? [0, 0]
        };

        var gfCharacter:CharSelectCharacter = createCharacter(newId, GF, gfParams, girlfriendCSData?.visualizer ?? false);

        if (newId != startingCharacter) gfCharacter.kill();
        this.add(gfCharacter);
      }
      else
      {
        // Create a dummy GF character in the off-chance that the player data doesn't have one.
        var gfCharacter:CharSelectCharacter = createCharacter(newId, GF, null, false);
        gfCharacter.kill();

        this.add(gfCharacter);
      }
    }

    this.refresh();
  }

  function createCharacter(playerId:String,
    characterType:CharacterSelectType,
    data:Null<PlayerCharSelectCharacterData>,
    enableVisualizer:Bool = false):CharSelectCharacter
  {
    if (data != null && data.scriptClass != null)
    {
      var scriptedCharacter:Null<CharSelectCharacter> = CharSelectCharacter.scriptInit(
        data.scriptClass,
        playerId,
        0,
        0,
        characterType,
        data,
        enableVisualizer
      );
      if (scriptedCharacter == null) throw 'Failed to initialize scripted character: ${data.scriptClass}';
      return scriptedCharacter;
    }

    return new CharSelectCharacter(playerId, 0, 0, characterType, data, enableVisualizer);
  }
}
