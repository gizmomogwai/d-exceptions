#!/usr/bin/env rdmd
import std;

auto contextWithString(T)(lazy scope T expression, string s)
{
    try
    {
        return expression();
    }
    catch (Exception e)
    {
        throw new Exception("%s\n%s".format(s, e.msg));
    }
    assert(false);
}

auto contextWithException(T)(lazy scope T expression, Exception delegate(Exception) handler)
{
    Exception newException;
    try
    {
        return expression();
    }
    catch (Exception e)
    {
        newException = handler(e);
    }
    throw newException;
}

JSONValue readConfig1(string s)
{
    // dfmt off
    return s
        .readText
        .parseJSON;
    // dfmt.on
}

JSONValue readConfig2(string s)
{
    // dfmt off
    return s
        .readText
        .parseJSON
        .contextWithString("Cannot process config file %s".format(s));
    // dfmt on
}

JSONValue readConfig3(string s)
{
    // dfmt off
    auto t = s
        .readText;
    return t
        .parseJSON
        .contextWithString("Cannot process config file %s".format(s));
    // dfmt on
}

JSONValue readConfig4(string s)
{
    // dfmt off
    auto t = s
        .readText;
    return t
        .parseJSON
        .contextWithException((Exception e) {
            return new Exception("Cannot process config file%s\n  %s".format(s, e.msg));
        });
    // dfmt on
}

void main()
{
    foreach (file; [
        "normal.txt",
        "missing.txt",
        "broken_json.txt",
        "not_readable.txt",
        "invalid_utf8.txt",
    ])
    {
        writeln("=========================================================================");
        size_t idx = 0;
        foreach (kv; [
            tuple("readConfig1", &readConfig1),
	    tuple("readConfig2", &readConfig2),
	    tuple("readConfig3", &readConfig3),
            tuple("readConfig4", &readConfig4),
        ])
        {
            auto f = kv[1];
            try
            {
                if (idx++ > 0) writeln("-------------------------------------------------------------------------");
                writeln("Working on ", file, " with ", kv[0]);
                f("testfiles/%s".format(file));
            }
            catch (Exception e)
            {
                writeln(e.msg);
            }
        }
    }
}
