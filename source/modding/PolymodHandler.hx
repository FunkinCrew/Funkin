package modding;

#if polymod
import polymod.Polymod;

class PolymodHandler
{
    public static var metadataArrays:Array<String> = [];

    public static function loadMods()
    {
        loadModMetadata();

		Polymod.init({
			modRoot:"mods/",
			dirs: ModList.getActiveMods(metadataArrays),
			errorCallback: function(error:PolymodError)
			{
				//trace(error.message);
			},
            frameworkParams: {
                assetLibraryPaths: [
                    "songs" => "songs",
                    "stages" => "stages",
                    "shared" => "shared",
                    "replays" => "replays",
                    "fonts" => "fonts"
                ]
            }
		});
    }

    public static function loadModMetadata()
    {
        metadataArrays = [];

        var tempArray = Polymod.scan("mods/","*.*.*",function(error:PolymodError) {
			//trace(error.message);
		});

        for(metadata in tempArray)
        {
            metadataArrays.push(metadata.id);
            ModList.modMetadatas.set(metadata.id, metadata);
        }
    }
}
#end