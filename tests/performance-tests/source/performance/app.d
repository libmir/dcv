module performance.app;

import std.stdio;
import std.getopt;

import performance.checkout;
import performance.measure;
import performance.compare;

void main(string []args)
{
    enum Mode
    {
        cleanup,
        checkout,
        measure,
        compare
    }

    Mode mode;
    string sha, shaprev, shacurrent;

    auto helpInformation = getopt(args, 
            "mode|m", "Mode of the program.", &mode,
            "shaprev|sp", "Sha of the previous state to be checked out.",&shaprev,
            "shacurrent|sc", "Sha of the current state to be checked out.",&shacurrent,
            "sha|s", "Sha of the state to be checked out.",&sha);

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("DCV Performance Testing App.",
                helpInformation.options);
        return;
    }

    final switch(mode)
    {
        case Mode.cleanup:
            cleanup();
            break;
        case Mode.checkout:
            checkout(sha);
            break;
        case Mode.measure:
            measure();
            break;
        case Mode.compare:
            writeln([shaprev, shacurrent]);
            compare(shaprev, shacurrent);
            break;
    }
}


