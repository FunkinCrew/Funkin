package funkin.modding;

import polymod.Polymod.ModMetadata;
import polymod.Polymod;
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;

class PolymodHandler
{
	/**
	 * The API version that mods should comply with.
	 	 * Format this with Semantic Versioning; <MAJOR>.<MINOR>.<PATCH>.
	 * Bug fixes increment the patch version, new features increment the minor version.
	 * Changes that break old mods increment the major version.
	 */
	static final API_VERSION = "0.1.0";

	/**
	 * Where relative to the executable that mods are located.
	 */
	static final MOD_FOLDER = "mods";

	/**
	 * Loads the game with ALL mods enabled with Polymod.
	 */
	public static function loadAllMods()
	{
		trace("Initializing Polymod (using all mods)...");
		loadModsById(getAllModIds());
	}

	/**
	 * Loads the game without any mods enabled with Polymod.
	 */
	public static function loadNoMods()
	{
		// We still need to configure the debug print calls etc.
		trace("Initializing Polymod (using no mods)...");
		loadModsById([]);
	}

	public static function loadModsById(ids:Array<String>)
	{
		if (ids.length == 0)
		{
			trace('You attempted to load zero mods.');
		}
		else
		{
			trace('Attempting to load ${ids.length} mods...');
		}
		var loadedModList = polymod.Polymod.init({
			// Root directory for all mods.
			modRoot: MOD_FOLDER,
			// The directories for one or more mods to load.
			dirs: ids,
			// Framework being used to load assets.
			framework: OPENFL,
			// The current version of our API.
			apiVersion: API_VERSION,
			// Call this function any time an error occurs.
			errorCallback: PolymodErrorHandler.onPolymodError,
			// Enforce semantic version patterns for each mod.
			// modVersions: null,
			// A map telling Polymod what the asset type is for unfamiliar file extensions.
			// extensionMap: [],

			frameworkParams: buildFrameworkParams(),

			// List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
			ignoredFiles: Polymod.getDefaultIgnoreList(),

			// Parsing rules for various data formats.
			parseRules: buildParseRules(),

			// Parse hxc files and register the scripted classes in them.
			useScriptedClasses: true,
		});

		if (loadedModList == null)
		{
			trace('[POLYMOD] An error occurred! Failed when loading mods!');
		}
		else
		{
			if (loadedModList.length == 0)
			{
				trace('[POLYMOD] Mod loading complete. We loaded no mods / ${ids.length} mods.');
			}
			else
			{
				trace('[POLYMOD] Mod loading complete. We loaded ${loadedModList.length} / ${ids.length} mods.');
			}
		}

		for (mod in loadedModList)
		{
			trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');
		}

		#if debug
		var fileList = Polymod.listModFiles(PolymodAssetType.IMAGE);
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} images.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles(PolymodAssetType.TEXT);
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} text files.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_MUSIC);
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} music files.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_SOUND);
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} sound files.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles(PolymodAssetType.AUDIO_GENERIC);
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} generic audio files.');
		for (item in fileList)
			trace('  * $item');
		#end
	}

	static function buildParseRules():polymod.format.ParseRules
	{
		var output = polymod.format.ParseRules.getDefault();
		// Ensure TXT files have merge support.
		output.addType("txt", TextFileFormat.LINES);
		// Ensure script files have merge support.
		output.addType("hscript", TextFileFormat.PLAINTEXT);
		output.addType("hxs", TextFileFormat.PLAINTEXT);

		// You can specify the format of a specific file, with file extension.
		// output.addFile("data/introText.txt", TextFileFormat.LINES)
		return output;
	}

	static inline function buildFrameworkParams():polymod.Polymod.FrameworkParams
	{
		return {
			assetLibraryPaths: [
				"songs" => "songs", "shared" => "", "tutorial" => "tutorial", "scripts" => "scripts", "week1" => "week1", "week2" => "week2",
				"week3" => "week3", "week4" => "week4", "week5" => "week5", "week6" => "week6", "week7" => "week7", "week8" => "week8",
			]
		}
	}

	public static function getAllMods():Array<ModMetadata>
	{
		trace('Scanning the mods folder...');
		var modMetadata = Polymod.scan(MOD_FOLDER);
		trace('Found ${modMetadata.length} mods when scanning.');
		return modMetadata;
	}

	public static function getAllModIds():Array<String>
	{
		var modIds = [for (i in getAllMods()) i.id];
		return modIds;
	}
}
