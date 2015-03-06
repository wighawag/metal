package metal;

import haxe.DynamicAccess;
import metal.Haxelib;

class CircularLib{
	public var haxelib(default,null) : Haxelib;
	private var dependencies:Array<String>;
	public var numDependencies(get,null): Int;
	function get_numDependencies() : Int{
		return dependencies.length;
	}

	public function new(haxelib : Haxelib){
		this.haxelib = haxelib;
		this.dependencies = new Array();
		for (dependency in haxelib.dependencies.keys()){
			//trace("depends on " + dependency);
			dependencies.push(dependency);
		}
	}

	public function has(dependencyName : String) : Bool{
		return dependencies.indexOf(dependencyName) != -1;
	}

	public function remove(dependencyName : String){
		if(has(dependencyName)){
			dependencies.remove(dependencyName);
		}
	}

}

class DependenciesOrdering{

	var meta : Metal;

	var libs : Map<String,CircularLib>;
	public function new(haxelibs : Array<Haxelib>){
		libs = new Map();
		for (haxelib in haxelibs){
			//trace("adding " + haxelib.name);
			libs.set(haxelib.name, new CircularLib(haxelib));
		}
	}

	public function order() : Array<Haxelib>{
		var haxelibs = new Array<Haxelib>();
		var num : Int = 0;
		var found = true;
		while(found){
			found = false;
			var toRemove = new Array<String>();
			for (libName in libs.keys()){
				var lib = libs[libName];
				if(lib.numDependencies == 0){
					libs.remove(libName);
					haxelibs.push(lib.haxelib);
					toRemove.push(libName);
					//trace("removing " + libName + " as it has no dependencies");
					found = true;
				}
			}

			num = 0;
			for(otherLibName in libs.keys()){

				var otherLib = libs[otherLibName];
				//trace("inspect " + otherLibName + " : " + otherLib);
				for (libToRemove in toRemove){
					otherLib.remove(libToRemove);	
					//trace("removing dependencies " + libToRemove);
				}
				
				num++;
			}
		}
		
		if (num > 0){
			return null;
		}else{
			return haxelibs;
		}
	}

	public function getCirculars() : Array<String>{
		var list = new Array<String>();
		for(libName in libs.keys()){
			list.push(libName);
		}
		return list;
	}
}