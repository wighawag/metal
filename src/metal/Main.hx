package metal;

import haxe.Json;
import metal.Haxelib.HaxelibDependencies;
import metal.Haxelib;
import metal.InputHelper;
import metal.Metal.SubLib;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

import thx.semver.Version;

import haxe.io.Bytes;

using StringTools;

enum ReleaseType
{
Major;
Minor;
Patch;
}

class Main extends mcli.CommandLine{

	public static function main()
    {
        new mcli.Dispatch(Sys.args()).dispatch(new Main());
    }

    /**
        release note
        @alias m
    **/
    public var message:String;

    /**
        release type (major|minor|patch) 
        @alias t
    **/
    public var type:ReleaseType;


    /**
        fake
    **/
    public var fake:Bool;

    /**
        Show this message.
    **/
    public function help()
    {
        Sys.println(this.showUsage());
        Sys.exit(0);
    }

    public function runDefault()
    {
        var args = Sys.args();
        
        //set the current directory if the last argument is a directory (used for "haxelib run")
        if(args.length > 0){
            var last:String = (new Path(args[args.length-1])).toString();
            var slash = last.substr(-1);
            if (slash=="/"|| slash=="\\"){ 
                last = last.substr(0,last.length-1);
            }
            if (FileSystem.exists(last) && FileSystem.isDirectory(last)) {
                Sys.setCwd(last);
            }    
        }
        
    	var metalJsonPath = "metal.json";
    	if(!FileSystem.exists(metalJsonPath)){
    		metalJsonPath = "haxelib.json";
    		if(!FileSystem.exists(metalJsonPath)){
    			error("cannot find metal.json or haxelib.json in current folder");
    		}
    	} 

    	var meta : Metal = Json.parse(File.getContent(metalJsonPath));

        var extraParams = new Map<String,Array<String>>();
        if(FileSystem.exists("extraParams.hxml")){
            var extraParamsFileContent = File.getContent("extraParams.hxml");
            var paramList = extraParamsFileContent.split("\n");
            var currentLibName = null;
            for(param in paramList){
                var trimmedParam = param.trim();
                if(trimmedParam.startsWith("#")){
                    var libName = trimmedParam.substr(1).trim();
                    if(meta.libs.exists(libName)){
                        currentLibName = libName;
                    }else{
                        error("no lib with name " + libName);
                    }
                }else if(currentLibName != null){
                    var extraParamsForLib = extraParams[currentLibName];
                    if(extraParamsForLib == null){
                        extraParamsForLib = new Array<String>();
                        extraParams[currentLibName] = extraParamsForLib;
                    }
                    extraParamsForLib.push(trimmedParam);
                }else{
                    error("extraParams.hxml not following format (need libName as comment before)");
                }
            }
        }

    	var tmpFolder = "_haxelibs_";
        if(FileSystem.exists(tmpFolder)){
            try{
                FileHelper.deleteDirectory(tmpFolder);  
            }catch(e : Dynamic){
                error("error deleting the tmp folder " + tmpFolder);
            }    
        }
    	
    	try{

    		FileSystem.createDirectory(tmpFolder);	
    	}catch(e: Dynamic){
    		error("error creating the tmp folder " + tmpFolder);
    	}
    	

        //TODO support deeper hierarchy (ex: kit.glee kit.sunya ...)
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
                meta.libs[fileName] = fillInDetails(fileName, meta.libs[fileName], meta);
            }
        }

        File.saveContent(metalJsonPath,Json.stringify(meta,null, "  "));


       

        var dummyReleaseNote = "";
        var dummyVersion = "";

        var haxelibs = new Array<Haxelib>();



        for(libName in meta.libs.keys()){
            var haxelib = HaxelibUtil.createHaxelibConfiguration(libName, meta,dummyReleaseNote, dummyVersion);//dummy release note/version as this will be change after getting input from user
            haxelibs.push(haxelib);
        } 

        for(haxelib in haxelibs){
            var regex = new EReg("\\b" + haxelib.name + "\\..+", "");
            for(otherHaxelib in haxelibs){
                if(otherHaxelib.name != haxelib.name){
                    var folderPath = meta.classPath + "/" + otherHaxelib.name;
                    var filePaths = FileHelper.recursiveReadFolder(folderPath);
                    for(filePath in filePaths){
                        if(StringTools.endsWith(filePath, ".hx")){
                            var content = File.getContent(folderPath + "/" + filePath);
                            if(regex.match(content)){
                                trace("found " + haxelib.name + " in " + otherHaxelib.name);
                                if(otherHaxelib.dependencies == null){
                                    otherHaxelib.dependencies = {};
                                }
                                otherHaxelib.dependencies.set(haxelib.name, dummyVersion); //dummy
                                break;
                            }
                        }
                    }
                }
            }
        }

        var ordering = new DependenciesOrdering(haxelibs);
        haxelibs = ordering.order();
        if(haxelibs == null){
            error("found circular dependencies " + ordering.getCirculars());
        }

        var releaseNote = message != null ? message : InputHelper.ask("releaseNote");
        var newVersion : Version = meta.version;
        while (newVersion.equals(meta.version)){
            var change = 
            if(type!= null){
                switch(type){
                    case Major : "major";
                    case Minor : "minor";
                    case Patch : "patch";
                }
            }else{
                InputHelper.ask("What king of change is it? (patch | minor | major)");
            }    
            
            newVersion = switch(change){
                case "patch": ( meta.version : Version).nextPatch();
                case "minor": ( meta.version : Version).nextMinor();
                case "major": ( meta.version : Version).nextMajor();
                default: trace("Please enter one of the following : (patch | minor | major)"); meta.version;
            }
        }
        meta.version = newVersion.toString();
        meta.releasenote = releaseNote;
        
        
        var password =  if(fake){
            "";
        }else{
            InputHelper.ask("Password ",true);    
        }


        var metaHaxelib = HaxelibUtil.createMetaHaxelib(meta, haxelibs);
        haxelibs.push(metaHaxelib);

        for(haxelib in haxelibs){
            //trace("generating haxelib zip for " + haxelib.name + "...");
            if(haxelib.dependencies == null){
                haxelib.dependencies = {};
            }else{
                //reset to new version
                for(dependencyName in haxelib.dependencies.keys()){
                    if(meta.libs.exists(dependencyName)){
                        haxelib.dependencies.set(dependencyName, meta.version);
                    }
                }
            }
            haxelib.version = meta.version;
            haxelib.releasenote = meta.releasenote;
            if(haxelib.classPath != null){
                var filePath = meta.classPath + "/" + haxelib.name;
                var destination = tmpFolder + "/" + haxelib.name + "/src/" + haxelib.name;
                FileSystem.createDirectory(destination);
                FileHelper.copyFolder(filePath, destination);
            }else{
                FileSystem.createDirectory(tmpFolder + "/" + haxelib.name);
            }
            
            var haxelibFilePath = tmpFolder + "/" + haxelib.name + "/haxelib.json";
            var haxelibJsonString = haxe.Json.stringify(haxelib, "  ");
            File.saveContent(haxelibFilePath, haxelibJsonString);
            if(extraParams[haxelib.name] != null){
                File.saveContent(tmpFolder + "/" + haxelib.name + "/extraParams.hxml",extraParams[haxelib.name].join("\n"));    
            }
            var zipPath = tmpFolder + "/" + haxelib.name + ".zip";
            ZipHelper.zipFolder(zipPath, tmpFolder +"/" + haxelib.name);
            
        }

        if(fake){
            File.saveContent(tmpFolder + "/metal.json",Json.stringify(meta,null, "  "));
           
            trace("created haxelib folder and zips as well as the would be 'metal.json' for version " + meta.version + " in " + tmpFolder);
        }else{
            var first = true;
            for(haxelib in haxelibs){
                var zipPath = tmpFolder + "/" + haxelib.name + ".zip";

                trace("submiting " + haxelib.name + " @ " + haxelib.version + " to haxelib ...");
                var process = new Process("haxelib", ["submit", zipPath, password]);
                
                var outputBytes = Bytes.alloc(100);
                var numBytes = process.stdout.readBytes(outputBytes,0,100);
                if (outputBytes.toString().indexOf("Invalid password") != -1){
                    process.kill();
                    errorInTheMiddle("wrong password",meta,metalJsonPath,!first);
                }else{
                    trace(process.stdout.readAll().toString());
                    trace("... done");
                    var exitCode = process.exitCode();
                    if(exitCode != 0){
                        errorInTheMiddle("exit code == " + exitCode + " while submitting " + zipPath,meta,metalJsonPath,!first);
                    }
                }

                first = false;

            }


            File.saveContent(metalJsonPath,Json.stringify(meta,null, "  "));
            trace(meta.name + " @ " + meta.version + " released !");
        }


        
    }

    public static function error(message : String, ?quit : Bool = true) : Void{
        trace("ERROR : " + message);
        if(quit){
            trace("fix and resubmit, no changes made to metal json");
            Sys.exit(1);
        }
    }

    public static function errorInTheMiddle(message : String, meta : Metal, metalJsonPath : String, middle : Bool):Void{
        if(middle){
            trace("ERROR : " + message);        
            File.saveContent(metalJsonPath,Json.stringify(meta,null, "  "));
            trace("The operation failed in the middle of submitting several haxelibs from " + meta.name + " @ " + meta.version + ", version changes has been saved to metal.json/haxelib.json, resubmiting would increase version again, a release of type 'patch' should probably be used");
            Sys.exit(1);    
        }else{
            error(message);
        }
        
    }

    public static function print(message : String) : Void{
        trace(message);   
    }

    public static  function fillInDetails(name : String, lib : SubLib, meta : Metal) : SubLib{

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
            if(tags.length > 0 && tags[0] != ""){
                for (i in 0...tags.length){
                    tags[i] = tags[i].trim();
                }    
                newLib.tags = tags;    
            }else{
                newLib.tags = [];    
            }
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

            var depArray = new Array<String>(); 
            for (depName in dependencies.keys()){
                depArray.push(depName);
                var currentVersion = meta.dependencies[depName];
                if(currentVersion != null){
                    if(currentVersion != dependencies[depName]){
                        error("conflicting version " + currentVersion + " vs " + dependencies[depName]);
                    }
                }else{
                    meta.dependencies[depName] = dependencies[depName];
                }
            }
            newLib.dependencies = depArray;
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