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
    string test;
    size_t iterations = 1_000;

    auto helpInformation = getopt(args, 
            "mode|m", "Mode of the program.", &mode,
            "test|t", "Name of the test to run. If not given, all tests are run.", &test,
            "iterations|i", "Number of test running iterations. Default is 1000", &iterations,
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
            measure(test, iterations);
            break;
        case Mode.compare:
            compare(sha);
            break;
    }
}


