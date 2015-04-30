package metal;

import metal.FileHelper;
import metal.Haxelib;
import metal.Metal.SubLib;

import haxe.DynamicAccess;

class HaxelibUtil{
	public static function createHaxelibConfiguration(libName : String, meta : Metal, releaseNote : String, version : String):Haxelib{
		var lib = meta.libs[libName];

		var dependenciesCopy : DynamicAccess<String> = {};
		if(lib.dependencies != null){
			for(key in lib.dependencies){
				dependenciesCopy[key] = meta.dependencies[key];
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
			dependencies : dependenciesCopy,
			tags : lib.tags != null ? lib.tags : []
		};
	}

	public static function createMetaHaxelib(meta: Metal, haxelibs : Array<Haxelib>):Haxelib{
		

		var dependencies : DynamicAccess<String> = {};
		
		for(haxelib in haxelibs){
			dependencies[haxelib.name] = haxelib.version;
		}

		var tags = new Array<String>();
		for(haxelib in haxelibs){
			tags = tags.concat(haxelib.tags);
		}

		var description = "A meta lib containing : \n";
		for(haxelib in haxelibs){
			description +=  haxelib.name + " : " + haxelib.description + "\n";
		}
	

		return {
			name : meta.name,
			license : meta.license,
			description : description,
			contributors : meta.contributors,
			releasenote : meta.releasenote,
			version : meta.version,
			url : meta.url,
			dependencies : dependencies,
			tags : tags
		};
	}

}