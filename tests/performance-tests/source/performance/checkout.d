module performance.checkout;

import std.stdio;
import std.path;
import std.file;
import std.process;
import std.array;
import std.range;
import std.conv;

import performance.common;

void cleanup()
{
    auto path = getCachePath();
    rmdirRecurse(path);
}

auto checkout(string sha)
{
    initCachePath();

    auto cwd = getcwd();
    string cachePath = getCachePath();

    chdir(cachePath);

    string cmd;

    if (!(cachePath ~ "/" ~ sha).exists)
    {
        cmd ~= "cd " ~ cachePath ~ "\n";
        cmd ~= "git clone https://github.com/libmir/dcv " ~ sha ~ "\n";
        cmd ~= "cd " ~ sha ~ "\n";
        cmd ~= "git checkout " ~ sha ~ "\n";
    }
    else
    {
        cmd ~= "cd " ~ cachePath ~ "/" ~ sha ~ "\n";
    }

    cmd ~= "dub build --compiler=ldc2 --build=release\n";
    cmd ~= "cd tests/performance-tests\n";
    cmd ~= "dub build --compiler=ldc2 --build=release\n";

    auto res = executeShell(cmd);

    return res;
}
