/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package duell.helpers;

import duell.objects.DuellProcess;
import duell.objects.DuellLib;
import duell.helpers.PlatformHelper;
import haxe.io.Path;

using duell.helpers.HashHelper;
using StringTools;

class DirHashHelper
{

	public static function getHashOfDirectory(path: String, filters: Array<EReg> = null): Int
	{
		var process: DuellProcess;

		if (PlatformHelper.hostPlatform == Platform.WINDOWS)
		{
		    var duellLibPath: String = DuellLib.getDuellLib("duell").getPath();
			// ls binary is bundled for windows
			process = new DuellProcess(Path.join([duellLibPath, "bin"]), "ls.exe", ["-lp", path],
			{
				systemCommand : true,
				block : true,
				shutdownOnError : true,
				errorMessage: "hashing folder structure"
			});
		}
		else
		{
			process = new DuellProcess(null, "ls", ["-lp", path],
			{
				systemCommand : true,
				block : true,
				shutdownOnError : true,
				errorMessage: "hashing folder structure"
			});
		}

		var output = process.getCompleteStdout().toString();

		/// splits by newline
		var outputSplit = output.split("\n");

		/// remove total line
		outputSplit.shift();

		/// remove empty newlines
		outputSplit = outputSplit.filter(function(s) return s != "");

		/// cleanup
		outputSplit = outputSplit.map(function(s) return s.trim());

		/// remove directories
		outputSplit = outputSplit.filter(function(s) return s.charAt(s.length - 1) != "/");

		if (filters == null)
			filters = [];

		var outputSplitFiltered = outputSplit.filter(function(s) {
			for (filter in filters)
			{
				if (filter.match(s))
					return false;
			}
			return true;
		});

		output = outputSplitFiltered.join("\n");

		return output.getFnv32IntFromString();
	}
}
