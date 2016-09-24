module performance.compare;

import std.stdio;
import std.file;
import std.path;
import std.csv;
import std.typecons;
import std.algorithm;
import std.array;
import std.exception : enforce;
import std.conv;

import performance.common;

ulong[string] loadProfileData(string sha = "")
{
    string fpath;
    
    if (sha.empty)
        fpath = chainPath(exeDir, "profile.csv").array.to!string;
    else
        fpath = chainPath(getCachePath(), sha, "tests/performance-tests/profile.csv").array.to!string;

    enforce(fpath.exists, "SHA profile data does not exists at path " ~ fpath);

    ulong[string] data;

    auto file = File(fpath, "r");

    try
    {
        file
            .byLine
            .joiner("\n")
            .csvReader!(Tuple!(string, ulong))
            .each!(record => data[record[0]] = record[1]);
    }
    catch 
    {
        writeln("Failed reading profile data.");
        destroy(data);
    }
    finally
    {
        file.close();
    }

    return data;
}

void compare(string sha)
{
    auto prevData = loadProfileData(sha);
    auto thisData = loadProfileData();

    auto file = File(chainPath(exeDir, "benchmark.csv"), "w");
    foreach(p; prevData.byKeyValue)
    {
        auto key = p.key;
        auto prevValue = float(p.value);

        if (key in thisData)
        {
            auto nextValue = float(thisData[key]);
            float ratio = (prevValue / nextValue) * 100.0f;
            file.writefln("%s,%f,%f,%#.3f%s", key, prevValue, nextValue, ratio, "%");
        }
        else
        {
            file.writefln("%s:not found", key);
        }
    }
    file.close();
}
