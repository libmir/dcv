module performance.measure;

import std.stdio;
import std.range;
import std.algorithm;
import std.datetime;
import std.string;;
import std.traits;
import std.typecons;
import core.time;

import dcv;

immutable imsize = 128;
immutable iterations = 1_000;

alias BenchmarkFunction = Duration function();

BenchmarkFunction[string] funcs;

void measure()
{
    writeln("\n=========================================");
    write("Registering benchmarks...");
    stdout.flush();
    registerBenchmarks();
    writeln("done");

    writeln("\n=========================================");
    writeln("Running benchmarks...\n");
    runBenchmarks("profile.csv");
}

void registerBenchmark(alias fun)()
{
    funcs[fullyQualifiedName!fun.replace("performance.measure.", "").replace("run_", "")] = &fun;
}

void registerBenchmarks()
{
    foreach(m; __traits(allMembers, performance.measure))
    {
        static if (m.length > 4 && m[0 .. 4].equal("run_"))
        {
            registerBenchmark!(__traits(getMember, performance.measure, m));
        }
    }
}

void runBenchmarks(string outputPath)
{
    import std.file;
    import std.format;
    string output;

    foreach(func; funcs.byKeyValue)
    {
        string name = func.key;
        auto fn = func.value;

        std.stdio.write(name, ":");
        stdout.flush();
        auto res = fn();
        std.stdio.writeln(res.total!"usecs");

        output ~= format("%s,%d\n", name, res.total!"usecs");
    }
    write(outputPath, output);
}

auto evalBenchmark(Fn, Args...)(Fn fn, Args args)
{
    Duration dur;
    foreach (i; iota(iterations))
    {
        auto t = Clock.currTime();
        fn(args);
        dur += Clock.currTime - t;
    }
    return dur / iterations;
}

auto run_rgb2gray()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto grey = slice!ubyte(imsize, imsize);

    return evalBenchmark(&rgb2gray!ubyte, rgb, grey, Rgb2GrayConvertion.LUMINANCE_PRESERVE);
}

auto run_rgb2hsv()
{
    auto rgb = slice!ubyte(imsize, imsize, 3);
    auto hsv = slice!float(imsize, imsize, 3);

    return evalBenchmark(&rgb2hsv!(float, ubyte), rgb, hsv);
}

