#!/usr/bin/env rdmd

import std.algorithm;
import std.stdio;
import std.file;
import std.path;
import std.array;
import std.string;
import std.regex;
import std.parallelism;
import std.process;

immutable ignoreList = [
    "fast_9.d", "fast_10.d", "fast_11.d", "fast_12.d", "nonmax.d", "gl.d", "glfw.d"
];

immutable includes = [
    "../source", "/home/relja/.dub/packages/ffmpeg-d-2.5.0/ffmpeg-d/source",
    "/home/relja/.dub/packages/imageformats-5.2.0/imageformats"
];

immutable setupDdoc = "export DDOCFILE=\"dcv.ddoc\"\n";

string compileDoc(string docDir, string srcDir, Module mod)
{
    if (ignoreList.find(mod.name)!= [])
    {
        writeln("Skipping documentation generation for module ", mod);
        return "";
    }

    string docs;
    string outPath = docDir;


    string command = setupDdoc;

    command ~= "dmd -c -o- -w -D";
    command ~= " -Dd" ~ outPath;

    foreach (i; includes)
    {
        command ~= " -I" ~ i;
    }

    string srcPath = cast(string)(chainPath(srcDir, mod.toString()).array);
    command ~= " " ~ srcPath;

    auto doc = executeShell(command);

    if (doc.status != 0)
        writeln("Documentation generation failed:\n", doc.output);
    else
    {
        string docres = cast(string)(chainPath(outPath, mod.name[0 .. $ - 1] ~ "html").array);
        string docname = "dcv" ~ cast(string)(mod.packets.join("_")) ~ "_" ~ mod.name[0 .. $ - 1] ~ "html";
        docs = cast(string)(chainPath(outPath, docname).array);
        command = "mv " ~ docres ~ " " ~ docs;
        doc = executeShell(command);
        if (doc.status != 0) {
            writeln("Documentation renaming failed: ", doc.output);
        }
        writeln("Documentation generation success for module ", mod.name, ": ", docs);
        docs = docname;
    }

    return docs;
}

void main(string[] args)
{
    string dcvPath = cast(string)((getcwd() ~ "/../source").asNormalizedPath().array);
    string docPath = "doc/";

    Module[] modules = collectModules(dcvPath);

    string [] jsdirs;
    foreach (mod; modules)
    {
        string d = compileDoc(docPath, dcvPath, mod);
        if (d != "")
        {
            synchronized
            {
                jsdirs ~= d;
            }
        }
    }
    jsdirs.sort();

    string js = "var docs = [";
    foreach(d; jsdirs)
    {
        js ~= "\n    \"../" ~ d ~ "\", ";
    }
    js = js[0 .. $ - 2] ~ "\n];";

    std.file.write("docs.js", js);
}

Module[] collectModules(string dir)
{

    Module[] modules;
    foreach (DirEntry e; dirEntries(dir, "*.{d}", SpanMode.depth))
    {
        string[] tokens = e.name.split("/dcv");
        if (tokens.length == 0)
            continue;

        tokens = tokens[$ - 1].split("/");
        Module mod = new Module;
        foreach (t; tokens[0 .. $ - 1])
        {
            mod.packets ~= t;
        }
        mod.name = tokens[$ - 1];
        modules ~= mod;
    }
    return modules;
}

class Module
{
    string[] packets;
    string name;

    pure string dir() const
    {
        string str = "dcv";
        foreach (p; packets)
        {
            str ~= p ~ "/";
        }
        return str;
    }

    override pure string toString() const
    {
        return dir() ~ name;
    }
}
