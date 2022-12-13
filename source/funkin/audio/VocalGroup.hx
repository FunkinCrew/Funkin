package funkin.audio;

import flixel.system.FlxSound;

/**
 * An audio group that allows for specific control of vocal tracks.
 */
class VocalGroup extends FlxAudioGroup
{
	/**
	 * The player's vocal track.
	 */
	var playerVocals:FlxSound;

	/**
	 * The opponent's vocal track.
	 */
	var opponentVocals:FlxSound;

	/**
	 * The volume of the player's vocal track.
     * Nore that this value is multiplied by the overall volume of the group.
	 */
	public var playerVolume(default, set):Float;

	function set_playerVolume(value:Float):Float
	{
		playerVolume = value;
		if (playerVocals != null)
		{
			// Make sure volume is capped at 1.0.
			playerVocals.volume = Math.min(playerVolume * this.volume, 1.0);
		}
		return playerVolume;
	}

	/**
	 * The volume of the opponent's vocal track.
     * Nore that this value is multiplied by the overall volume of the group.
	 */
	public var opponentVolume(default, set):Float;

	function set_opponentVolume(value:Float):Float
	{
		opponentVolume = value;
		if (opponentVocals != null)
		{
			// Make sure volume is capped at 1.0.
			opponentVocals.volume = opponentVolume * this.volume;
		}
		return opponentVolume;
	}

	/**
	 * Sets up the player's vocal track.
	 * Stops and removes the existing player track if one exists.
	 */
	public function setPlayerVocals(sound:FlxSound):FlxSound
	{
		if (playerVocals != null)
		{
			playerVocals.stop();
			remove(playerVocals);
			playerVocals = null;
		}

		playerVocals = add(sound);
		playerVocals.volume = this.playerVolume * this.volume;

		return playerVocals;
	}

	/**
	 * Sets up the opponent's vocal track.
	 * Stops and removes the existing player track if one exists.
	 */
	public function setOpponentVocals(sound:FlxSound):FlxSound
	{
		if (opponentVocals != null)
		{
			opponentVocals.stop();
			remove(opponentVocals);
			opponentVocals = null;
		}

		opponentVocals = add(sound);
		opponentVocals.volume = this.opponentVolume * this.volume;

		return opponentVocals;
	}

    /**
     * In this extension of FlxAudioGroup, there is a separate overall volume
     * which affects all the members of the group.
     */
    var _volume = 1.0;

    override function get_volume():Float
    {
        return _volume;
    }

	override function set_volume(value:Float):Float
	{
        _volume = super.set_volume(value);

		if (playerVocals != null)
		{
			playerVocals.volume = playerVolume * _volume;
		}

		if (opponentVocals != null)
		{
			opponentVocals.volume = opponentVolume * _volume;
		}

		return _volume;
	}
}
