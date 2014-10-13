/**
 * @autor rcam
 * @date 30.07.2014.
 * @company Gameduell GmbH
 */
 
package duell.helpers;

import duell.helpers.DuellConfigHelper;
import duell.helpers.GitHelper;
import duell.helpers.PathHelper;
import duell.objects.DuellConfigJSON;
import duell.objects.DuellLibReference;
import duell.objects.Haxelib;

import sys.io.File;
import Reflect;
import sys.FileSystem;
import haxe.io.Error;
import haxe.Json;

class DuellLibListHelper
{
    public static var DEPENDENCY_LIST_FILENAME = "duell_dependencies.json";

	private static var repoListCache : Map<String, DuellLibReference> = null;
    public static function getDuellLibReferenceList() : Map<String, DuellLibReference>
    {
    	if(repoListCache != null)
    		return repoListCache;

        repoListCache = new Map<String, DuellLibReference>();

    	var duellConfig : DuellConfigJSON = DuellConfigJSON.getConfig(DuellConfigHelper.getDuellConfigFileLocation());

        var libListFolder : String = DuellConfigHelper.getDuellConfigFolderLocation() + "/" + "lib_list";

        if(duellConfig.repoListURLs == null || duellConfig.repoListURLs.length == 0)
        {
            LogHelper.error("No repo urls are defined. Run \"duell setup\" to fix this.");
        }

        /// we remove because if the user changes lib lists urls, the result will be very undefined. This way is a bit slower but cleaner.
        if(FileSystem.exists(libListFolder))
        {    
            LogHelper.info("Cleaning up existing lib lists...");

            PathHelper.removeDirectory(libListFolder);
        }

        var repoListIndex = 1;
        for(repoURL in duellConfig.repoListURLs)
        {
            var path = libListFolder + "/" + repoListIndex;
            if(GitHelper.clone(repoURL, path) != 0)
            {
                LogHelper.error("Can't access the repo list in " + repoURL + " or something is wrong with the folder " + path);
            }

            try
            {
                var configContent = File.getContent(path + "/haxe-repo-list.json");
                var configJSON = Json.parse(configContent);

                addLibsToTheRepoCache(configJSON);
            }
            catch (e : Error)
            {
                LogHelper.error("Cannot Parse repo list. Check if this file is correct: " + path + "/haxe-repo-list.json");
            }
        }

        return repoListCache;
    }

    private static function addLibsToTheRepoCache(configJSON : Dynamic) 
    {
        var listOfRepos = Reflect.fields(configJSON);

        var duellLibMap = new Map<String, DuellLibReference>();

        for(repo in listOfRepos)
        {
            var repoInfo = Reflect.field(configJSON, repo);
            if(repoListCache.exists(repo))
            {
                LogHelper.info("Found duplicate for " + repo + " in the repo list URLs. Using " + repoInfo.git_path);
            }

            repoListCache.set(repo, new DuellLibReference(repo, repoInfo.git_path, repoInfo.library_path, repoInfo.destination_path));
        }
    }
}
