package modding;

#if desktop
import polymod.Polymod.ModMetadata;
import polymod.Polymod;
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;
#end

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
		#if cpp
		trace("Initializing Polymod (using all mods)...");
		loadModsById(getAllModIds());
		#else
		trace("Polymod not initialized; not supported on this platform.");
		#end
	}

	/**
	 * Loads the game without any mods enabled with Polymod.
	 */
	public static function loadNoMods()
	{
		// We still need to configure the debug print calls etc.
		#if cpp
		trace("Initializing Polymod (using no mods)...");
		loadModsById([]);
		#else
		trace("Polymod not initialized; not supported on this platform.");
		#end
	}

	public static function loadModsById(ids:Array<String>)
	{
		#if cpp
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
			errorCallback: onPolymodError,
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
			trace('  * ${mod.title} v${mod.modVersion} [${mod.id}]');

		#if debug
		var fileList = Polymod.listModFiles("IMAGE");
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} images.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles("TEXT");
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} text files.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles("MUSIC");
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} music files.');
		for (item in fileList)
			trace('  * $item');

		fileList = Polymod.listModFiles("SOUND");
		trace('[POLYMOD] Installed mods have replaced ${fileList.length} sound files.');
		for (item in fileList)
			trace('  * $item');
		#end
		#else
		trace("[POLYMOD] Mods are not supported on this platform.");
		#end
	}

	#if cpp
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
				"songs" => "./songs",     "shared" => "./", "tutorial" => "./tutorial", "scripts" => "./scripts", "week1" => "./week1", "week2" => "./week2",
				"week3" => "./week3", "week4" => "./week4",       "week5" => "./week5",     "week6" => "./week6", "week7" => "./week7", "week8" => "./week8",
			]
		}
	}

	static function onPolymodError(error:PolymodError):Void
	{
		// Perform an action based on the error code.
		switch (error.code)
		{
			case MOD_LOAD_PREPARE:
				trace('[POLYMOD] ${error.message}');
			case MOD_LOAD_DONE:
				trace('[POLYMOD] ${error.message}');
			case MISSING_ICON:
				trace('[POLYMOD] A mod is missing an icon. Please add one.');
			default:
				// Log the message based on its severity.
				switch (error.severity)
				{
					case NOTICE:
						trace('[POLYMOD] ${error.message}');
					case WARNING:
						trace('[POLYMOD] ${error.message}');
					case ERROR:
						trace('[POLYMOD] ${error.message}');
				}
		}
	}
	#end

	public static function getAllMods():Array<#if cpp ModMetadata #else Dynamic #end> // this is shitty conditional but ModMetadata isn't imported on HTML5! And I'm too lazy to actually do it properly!
	{
		#if cpp
		trace('Scanning the mods folder...');
		var modMetadata = Polymod.scan(MOD_FOLDER);
		trace('Found ${modMetadata.length} mods when scanning.');
		return modMetadata;
		#else
		return [];
		#end
	}

	public static function getAllModIds():Array<String>
	{
		var modIds = [for (i in getAllMods()) i.id];
		return modIds;
	}
}
