package metal;

import sys.FileSystem;
import sys.io.File;
import format.zip.Writer;
import format.zip.Data;
import haxe.io.Bytes;
import haxe.crypto.Crc32;

class ZipHelper{
	
	public static function zipFolder(filePath : String, sourcePath:String):Void{
		
		var entries:List<Entry> = convertDirectoryToZipEntries(sourcePath);
		
		var zip = File.write(filePath, true);
		
		var writer = new Writer(zip);
		writer.write(entries);
		
		zip.close();
	}

	public static function convertDirectoryToZipEntries(dirPath:String):List<Entry>{
		var relativeFilePaths:Array<String> = FileHelper.recursiveReadFolder(dirPath);

		var entries:List<Entry> = new List();

		var date = Date.now();
			
		for (relativeFilePath in relativeFilePaths){

			var filePath = dirPath + "/" + relativeFilePath;
			var stat = FileSystem.stat(filePath);

			var isDirectory = FileSystem.isDirectory(filePath);
			var bytes:Bytes = null;
			if (!isDirectory){
				bytes = File.getBytes(filePath);
			}
			
			var name:String = relativeFilePath;

			if (isDirectory){
				name += "/";
			}
			
			
			var entry:Entry = {
				fileTime:date,
				fileName:name,
				fileSize:stat.size,
				data:bytes,
				dataSize:bytes != null ? bytes.length : 0,
				compressed:false,
				crc32:bytes != null ? Crc32.make(bytes) : 0,
				extraFields:new List()
			}


			trace(entry.fileName);
			entries.add(entry);
		}
		
		return entries;
	}	
}
