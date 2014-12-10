package metal;

import metal.FileHelper;
import metal.Haxelib;
import metal.Metal.SubLib;

class HaxelibUtil{
	public static function createHaxelibConfiguration(path : String, libName : String, meta : Metal, releaseNote : String, version : String):Haxelib{
		var lib = meta.libs[libName];

		var dependencies : HaxelibDependencies= lib.dependencies;
		for (otherLibName in meta.libs.keys()){
			if(otherLibName != libName){
				if(FileHelper.findInFiles(path,otherLibName + ".")){
					dependencies[otherLibName] = version;
				}
			}
		}

		return {
			name : libName,
			license : meta.license,
			description : lib.description,
			contributors : meta.contributors,
			releasenote : releaseNote,
			version : version,
			url : lib.url != null && lib.url != "" ? lib.url : meta.url,
			classPath : "src",
			dependencies : dependencies,
			tags : lib.tags
		};
	}
}