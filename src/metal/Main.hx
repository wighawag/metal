package metal;

import haxe.Json;
import metal.Haxelib.HaxelibDependencies;
import metal.InputHelper;
import metal.Metal.SubLib;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

import thx.semver.Version;

import haxe.io.Bytes;

using StringTools;

class Main extends mcli.CommandLine{

	public static function main()
    {
        new mcli.Dispatch(Sys.args()).dispatch(new Main());
    }

    public function help()
    {
        Sys.println(this.showUsage());
        Sys.exit(0);
    }

    public function runDefault()
    {
    	var metalJsonPath = "metal.json";
    	if(!FileSystem.exists(metalJsonPath)){
    		metalJsonPath = "haxelib.json";
    		if(!FileSystem.exists(metalJsonPath)){
    			Sys.println("cannot find metal.json or haxelib.json in current folder");
    			Sys.exit(1);
    		}
    	} 

    	var meta : Metal = Json.parse(File.getContent(metalJsonPath));

    	var tmpFolder = "_haxelibs_";
        if(FileSystem.exists(tmpFolder)){
            try{
                FileHelper.deleteDirectory(tmpFolder);  
            }catch(e : Dynamic){
                Sys.println("error deleting the tmp folder " + tmpFolder);
                Sys.exit(1);
            }    
        }
    	
    	try{

    		FileSystem.createDirectory(tmpFolder);	
    	}catch(e: Dynamic){
    		Sys.println("error creating the tmp folder " + tmpFolder);
    		Sys.exit(1);
    	}
    	


        var keys = meta.libs.keys();
    	for (libName in keys){
    		var filePath = meta.classPath + "/" + libName;
            if(!FileSystem.exists(filePath) || !FileSystem.isDirectory(filePath)){
                Sys.println("no directory exist for  " + libName + " at " + filePath + " , removing the lib from  the list");
                meta.libs.remove(libName);
            }
    	}

        var fileNames = FileSystem.readDirectory(meta.classPath);
        for (fileName in fileNames){
            var filePath = meta.classPath + "/" + fileName;
            if(FileSystem.isDirectory(filePath)){
                meta.libs[fileName] = fillInDetails(fileName, meta.libs[fileName]);
            }
        }

        //TODO : from that point use full haxelib structure 

        var releaseNote = InputHelper.ask("releaseNote");
        
        var newVersion : Version = meta.version;
        while (newVersion.equals(meta.version)){
            var change = InputHelper.ask("What king of change is it? (patch | minor | major)");
            newVersion = switch(change){
                case "patch": ( meta.version : Version).nextPatch();
                case "minor": ( meta.version : Version).nextMinor();
                case "major": ( meta.version : Version).nextMajor();
                default: meta.version;
            }
        }
        meta.version = newVersion.toString();
        meta.releaseNote = releaseNote;
        
        File.saveContent(metalJsonPath,Json.stringify(meta,null, "  "));


        for(libName in meta.libs.keys()){
            var regex = new EReg("\\b" + libName + "\\..+", "");
            for(otherLibName in meta.libs.keys()){
                if(otherLibName != libName){
                    var folderPath = meta.classPath + "/" + otherLibName;
                    var filePaths = FileHelper.recursiveReadFolder(folderPath);
                    for(filePath in filePaths){
                        if(StringTools.endsWith(filePath, ".hx")){
                            var content = File.getContent(folderPath + "/" + filePath);
                            if(regex.match(content)){
                                //trace("found " + libName + " in " + otherLibName);
                                var metalib = meta.libs[otherLibName];
                                if(metalib.dependencies == null){
                                    metalib.dependencies = {};
                                }
                                metalib.dependencies.set(libName, meta.version); //TODO check version is correct here
                            }
                        }
                    }
                }
            }
        }

        //TODO need to order them so they can be sent to haxelib server without dependencies issues
        var circularFinder = new CircularDependencies(meta);
        if(circularFinder.isThereAny()){
            trace("found circular dependencies");
            Sys.exit(1);
        }

       

        //var meta : Metal = Json.parse(File.getContent(metalJsonPath));


        for(libName in meta.libs.keys()){
            //trace("generating haxelib zip for " + libName + "...");
            var lib = meta.libs[libName];
            if(lib.dependencies == null){
                lib.dependencies = {};
            }
            var filePath = meta.classPath + "/" + libName;
            var destination = tmpFolder + "/" + libName + "/src/" + libName;
            FileSystem.createDirectory(destination);
            FileHelper.copyFolder(filePath, destination);
            var haxelibFilePath = tmpFolder + "/" + libName + "/haxelib.json";
            var haxelibJsonString = haxe.Json.stringify(HaxelibUtil.createHaxelibConfiguration(filePath, libName, meta, meta.releaseNote, meta.version), "  ");
            File.saveContent(haxelibFilePath, haxelibJsonString);
            var zipPath = tmpFolder + "/" + libName + ".zip";
            ZipHelper.zipFolder(zipPath, tmpFolder +"/" + libName);
            
        }

        var password = InputHelper.ask("Password ",true);

        for(libName in meta.libs.keys()){
            var zipPath = tmpFolder + "/" + libName + ".zip";

            trace("submiting " + libName + " to haxelib ...");
            var process = new Process("haxelib", ["submit", zipPath, password]);
            
            var outputBytes = Bytes.alloc(100);
            var numBytes = process.stdout.readBytes(outputBytes,0,100);
            if (outputBytes.toString().indexOf("Invalid password") != -1){
                trace("wrong password");
                process.kill();
                Sys.exit(1);
            }else{
                trace(process.stdout.readAll().toString());
                trace("... done");
                var exitCode = process.exitCode();
                if(exitCode != 0){
                    trace("exit code == " + exitCode + " while submitting " + zipPath);
                    Sys.exit(1);
                }
            }

        }
        
    }

    public static  function fillInDetails(name : String, lib : SubLib) : SubLib{

        var newLib = lib;
        if(newLib == null){
            Sys.println("Library " + name + " not registered in metal.json/haxelib.json file");
            Sys.println("Please fill in the form");
            newLib = {
                description : null,
                tags : null
            };
        }else if(newLib.description == null || newLib.tags == null){
            Sys.println("library " + name + " info not completed, please complete");
        }

        if(newLib.description == null){
            newLib.description = InputHelper.ask("description");    
        }
        
        if(newLib.tags == null){
            var tags = InputHelper.ask("tags (separated by commas)").split(",");
            for (i in 0...tags.length){
                tags[i] = tags[i].trim();
            }    
            newLib.tags = tags;
        }
        
        if(lib == null){
            var dependencyStrings = InputHelper.ask("dependencies (separated by commas and specified via <name>:<version>)").split(",");
            for (i in 0...dependencyStrings.length){
                dependencyStrings[i] = dependencyStrings[i].trim();
            }
            
            var dependencies : HaxelibDependencies = {};
            for (depString in dependencyStrings){
                var split = depString.split(":");
                if(split.length > 1){
                    dependencies[split[0]] = split[1];
                }else{
                    dependencies[split[0]] = "";
                }
            }    
            newLib.dependencies = dependencies;
        }
        
        if(lib == null){
            var url = InputHelper.ask("url (press enter to use meta lib url)");
            if(url != null && url != ""){
                newLib.url = url;
            }
        }
        
        return newLib;
    }


}