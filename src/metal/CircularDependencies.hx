package metal;

import haxe.DynamicAccess;

class CircularLib{
	public var name(default,null):String;
	private var dependencies:Array<String>;
	public var numDependencies(get,null): Int;
	function get_numDependencies() : Int{
		return dependencies.length;
	}

	public function new(name : String, dependenciesSet : DynamicAccess<String>){
		this.name = name;
		this.dependencies = new Array();
		for (dependency in dependenciesSet.keys()){
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

class CircularDependencies{

	var meta : Metal;

	var libs : Map<String,CircularLib>;
	public function new(meta : Metal){
		libs = new Map();
		for (libName in meta.libs.keys()){
			//trace("adding " + libName);
			var lib = meta.libs[libName];
			libs.set(libName, new CircularLib(libName, lib.dependencies));
		}
	}

	public function isThereAny() : Bool{
		var num : Int = 0;
		var found = true;
		while(found){
			found = false;
			var toRemove = new Array<String>();
			for (libName in libs.keys()){
				var lib = libs[libName];
				if(lib.numDependencies == 0){
					libs.remove(libName);
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
		
		return num > 0;
	}
}