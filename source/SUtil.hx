package;

#if android
import android.Permissions;
import android.content.Context;
import android.os.Build;
import android.widget.Toast;
#end
import haxe.CallStack;
import haxe.io.Path;
import lime.system.System as LimeSystem;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.utils.Assets;

using StringTools;

#if (sys && !ios)
import sys.FileSystem;
import sys.io.File;
#end

enum StorageType
{
	ANDROID_DATA;
	ROOT;
}

/**
 * ...
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
        //Suit Up Video Here xd - mcagabe19
        static final videoFiles:Array<String> = [
                "armorsteve"
        ];

	/**
	 * A simple function that checks for storage permissions and game files/folders.
	 */
	public static function check():Void
	{
		#if android
		if (!Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE)
			&& !Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE))
		{
			if (VERSION.SDK_INT >= VERSION_CODES.M)
			{
				Permissions.requestPermissions([Permissions.WRITE_EXTERNAL_STORAGE, Permissions.READ_EXTERNAL_STORAGE]);

				/**
				 * Basically for now i can't force the app to stop while its requesting a android permission, so this makes the app to stop while its requesting the specific permission
				 */
				Lib.application.window.alert('You needed grant storage permission for save crash logs'
					+ '\nPress Ok to contiune',
					'Permissions?');
			}
			else
			{
				Lib.application.window.alert('Please grant the game storage permissions in app settings' + '\nPress Ok to close the app', 'Permissions?');
				LimeSystem.exit(1);
			}
		}

		if (Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE)
			&& Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE))
		{
			if (!FileSystem.exists(SUtil.getPath()))
			FileSystem.createDirectory(SUtil.getPath());

                        if (!FileSystem.exists(SUtil.getPath() + 'assets'))
		        FileSystem.createDirectory(SUtil.getPath() + 'assets');

		        for (vid in videoFiles)
			copyContent(Paths.video(vid), SUtil.getStorageDirectory() + Paths.video(vid));
		}
		#end
	}

	/**
	 * This returns the external storage path that the game will use by the type.
	 */
	public static function getStorageDirectory(type:StorageType = ANDROID_DATA):String
	{
		#if android
		var daPath:String = '';

		switch (type)
		{
			case ANDROID_DATA:
				daPath = Context.getExternalFilesDir(null) + '/';
			case ROOT:
				daPath = Context.getFilesDir() + '/';
		}

		SUtil.mkDirs(Path.directory(daPath));

		return daPath;
		#else
		return '';
		#end
	}

	/**
	 * Uncaught error handler, original made by: sqirra-rng
	 */
	public static function uncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(u:UncaughtErrorEvent)
		{
			var callStack:Array<StackItem> = CallStack.exceptionStack(true);
			var errMsg:String = '';

			for (stackItem in callStack)
			{
				switch (stackItem)
				{
					case CFunction:
						errMsg += 'a C function\n';
					case Module(m):
						errMsg += 'module ' + m + '\n';
					case FilePos(s, file, line, column):
						errMsg += file + ' (line ' + line + ')\n';
					case Method(cname, meth):
						errMsg += cname == null ? "<unknown>" : cname + '.' + meth + '\n';
					case LocalFunction(n):
						errMsg += 'local function ' + n + '\n';
				}
			}

			errMsg += u.error;

			#if (sys && !ios)
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory() + 'logs'))
					FileSystem.createDirectory(SUtil.getStorageDirectory() + 'logs');

				File.saveContent(SUtil.getStorageDirectory()
					+ 'logs/'
					+ Lib.application.meta.get('file')
					+ '-'
					+ Date.now().toString().replace(' ', '-').replace(':', "'")
					+ '.log',
					errMsg
					+ '\n');
			}
			#if android
			catch (e:Dynamic)
			Toast.makeText("Error!\nClouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
			#end
			#end

			println(errMsg);
			Lib.application.window.alert(errMsg, 'Error!');
			LimeSystem.exit(1);
		});
	}

	/**
	 * This is mostly a fork of https://github.com/openfl/hxp/blob/master/src/hxp/System.hx#L595
	 */
	public static function mkDirs(directory:String):Void
	{
		if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
			return;

		var total:String = '';

		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');

		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				if (FileSystem.exists(total) && !FileSystem.isDirectory(total))
					FileSystem.deleteFile(total);

				if (!FileSystem.exists(total))
					FileSystem.createDirectory(total);
			}
		}
	}

	#if (sys && !ios)
	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'you forgot to add something in your code lol'):Void
	{
		try
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'saves'))
				FileSystem.createDirectory(SUtil.getStorageDirectory() + 'saves');

			File.saveContent(SUtil.getStorageDirectory() + 'saves/' + fileName + fileExtension, fileData);
			#if android
			Toast.makeText("File Saved Successfully!", Toast.LENGTH_LONG);
			#end
		}
		#if android
		catch (e:Dynamic)
		Toast.makeText("Error!\nClouldn't save the file because:\n" + e, Toast.LENGTH_LONG);
		#end
	}

	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try
		{
			if (!FileSystem.exists(savePath) && Assets.exists(copyPath))
			{
				SUtil.mkDirs(Path.directory(savePath));
				File.saveBytes(savePath, Assets.getBytes(copyPath));
			}
		}
		#if android
		catch (e:Dynamic)
		Toast.makeText("Error!\nClouldn't copy the file because:\n" + e, Toast.LENGTH_LONG);
		#end
	}
	#end

	private static function println(msg:String):Void
	{
		#if sys
		Sys.println(msg);
		#else
		// Pass null to exclude the position.
		haxe.Log.trace(msg, null);
		#end
	}
}
