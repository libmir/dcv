module performance.common;

import std.path;
import std.file;
import std.array;
import std.range;
import std.conv;

auto exeDir()
{
    return thisExePath.pathSplitter().array[0 .. $ - 1].join("/");
}

auto getCachePath()
{
    return chainPath(exeDir, ".cache").array.to!string;
}

auto getExampleDataPath()
{
    return chainPath(exeDir, "../../examples/data").array.buildNormalizedPath;
}

auto initCachePath()
{
    auto cachePath = getCachePath();
    if (!cachePath.exists)
    {
        mkdir(cachePath);
    }
}

