package funkin.ui.charSelect.characters;

import funkin.data.animation.AnimationData;
import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.group.FunkinGroup;
import funkin.ui.charSelect.CharacterSelectState;
import funkin.ui.charSelect.characters.CharSelectCharacter;
import funkin.util.assets.FlxAnimationUtil;

/**
 * A `FunkinGroup` that holds all of the characters for the Character Select screen.
 */
@:nullSafety @:access(funkin.ui.charSelect.characters.CharSelectCharacter)
class CharSelectCharacterGroup extends FunkinGroup<CharSelectCharacter>
{
  /**
   * The current player character.
   */
  public var player(get, never):CharSelectCharacter;

  function get_player():CharSelectCharacter
  {
    var playerCharacter:Null<CharSelectCharacter> = this.getFirst((character) -> character.alive
      && character.characterType != CharacterSelectType.GF);

    if (playerCharacter == null)
    {
      throw 'Failed to find player character in character group!';

      // So null-safety is happy.
      return new CharSelectCharacter('unknown', CharacterSelectState.CUTOUT_SIZE, 0, false, null);
    }

    return playerCharacter;
  }

  /**
   * The current GF character.
   */
  public var gf(get, never):CharSelectCharacter;

  function get_gf():CharSelectCharacter
  {
    var gfCharacter:Null<CharSelectCharacter> = this.getFirst((character) -> character.alive
      && character.characterType == CharacterSelectType.GF);

    if (gfCharacter == null)
    {
      throw 'Failed to find GF character in character group!';

      // So null-safety is happy.
      return new CharSelectCharacter('unknown', CharacterSelectState.CUTOUT_SIZE, 0, false, null);
    }

    return gfCharacter;
  }

  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);
  }

  /**
   * Switches the characters in the Character Select screen.
   * @param oldId The ID of the character to switch away from.
   * @param newId The ID of the character to switch to.
   */
  public function setCharacters(oldId:String, newId:String):Void
  {
    var oldPlayer:Null<CharSelectCharacter> = this.getFirst((char) -> char.playerId == oldId
      && char.characterType != CharacterSelectType.GF);
    var oldGF:Null<CharSelectCharacter> = this.getFirst((char) -> char.playerId == oldId && char.characterType == CharacterSelectType.GF);
    var newPlayer:Null<CharSelectCharacter> = this.getFirst((char) -> char.playerId == newId
      && char.characterType != CharacterSelectType.GF);
    var newGF:Null<CharSelectCharacter> = this.getFirst((char) -> char.playerId == newId && char.characterType == CharacterSelectType.GF);

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
    newPlayer?.playAnimation(SLIDEIN);

    if (newGF != null)
    {
      newGF.localVisible = newId != 'locked';
      newGF.revive();
      newGF.playAnimation(IDLE);
    }
  }

  /**
   * Loads the characters for the Character Select screen.
   * @param startingCharacter The starting character to use.
   * @param characterList A list of all available character IDs.
   */
  public function createCharacters(startingCharacter:String, characterList:Map<Int, String>):Void
  {
    var lockedCharacter:CharSelectCharacter = createCharacter('locked', false, {
      assetPath: 'ui/character-select/characters/locked',
      animations: PlayerCharSelectData.getDefaultAnimations(LOCKED_PLAYER),
      atlasSettings: {
        cacheOnLoad: true
      }
    });
    @:privateAccess
    lockedCharacter.__backwardsCompatibility = true;
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
      };

      // Additional check for if the asset path is blank... somehow.
      if (playerParams.assetPath.isBlank())
      {
        playerParams.assetPath = 'ui/character-select/characters/${newId}';
      }

      var playerCharacter:CharSelectCharacter = createCharacter(newId, false, playerParams);

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
          danceEvery: girlfriendCSData.characterData?.danceEvery
        };

        var gfCharacter:CharSelectCharacter = createCharacter(newId, true, gfParams, girlfriendCSData?.visualizer ?? false);

        if (newId != startingCharacter) gfCharacter.kill();
        this.add(gfCharacter);
      }
    }
  }

  function createCharacter(playerId:String, isGf:Bool = false, data:Null<PlayerCharSelectCharacterData>, enableVisualizer:Bool = false):CharSelectCharacter
  {
    if (data != null && data.scriptClass != null)
    {
      return ScriptedCharSelectCharacter.scriptInit(data.scriptClass, playerId, CharacterSelectState.CUTOUT_SIZE, 0, isGf, data, enableVisualizer);
    }

    return new CharSelectCharacter(playerId, CharacterSelectState.CUTOUT_SIZE, 0, isGf, data, enableVisualizer);
  }
}
