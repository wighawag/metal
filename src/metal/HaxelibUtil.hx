package metal;

import metal.FileHelper;
import metal.Haxelib;
import metal.Metal.SubLib;

class HaxelibUtil{
	public static function createHaxelibConfiguration(libName : String, meta : Metal, releaseNote : String, version : String):Haxelib{
		var lib = meta.libs[libName];

		return {
			name : libName,
			license : meta.license,
			description : lib.description,
			contributors : meta.contributors,
			releasenote : releaseNote,
			version : version,
			url : lib.url != null && lib.url != "" ? lib.url : meta.url,
			classPath : "src",
			dependencies : lib.dependencies != null ? lib.dependencies : {},
			tags : lib.tags != null ? lib.tags : []
		};
	}

}