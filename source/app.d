#!/usr/bin/env rdmd
import std;

struct S
{
    int a;
    int b;

    void toString(Sink, Format)(Sink sink, Format format) const
    {
        sink("1struct1(");
        sink(")");
    }
    /*void toString(scope void delegate (scope const(char)[]) sink, string fmt)
    {
        sink("struct2(");
        sink(fmt);
        sink(")");
    }
    */
    string toString()
    {
        return "1struct3";
    }

}

class C
{
    void toString(Sink, Format)(Sink sink, Format format) const
    {
        sink("c1(");
        sink(")");
    }

}

class E : Exception
{
    this()
    {
        super("some E");
    }
    override void toString(scope void delegate(in char[]) sink) const
    {
        sink("e1(");
        sink(")");
    }
}

class ContextedException : Exception
{
    private Exception cause;
    private string[string] context;
    this(string msg, Exception cause=null, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
        this.cause = cause;
    }

    auto add(string key, string value)
    {
        context[key] = value;
        return this;
    }

    override void toString(scope void delegate(in char[]) sink) const
    {
        sink("Contexted Exception ");
        sink(message());
        sink(" Context:\n");
        foreach (k, v; context)
        {
            sink(format!("  %s: %s\n")(k, v));
        }
    }
}

auto contextWithString(T)(lazy scope T expression, string s)
{
    try
    {
        return expression();
    }
    catch (Exception e)
    {
        throw new Exception(format!"%s\n%s"(s, e));
    }
    assert(false);
}

auto contextWithException(T, E)(lazy scope T expression, Exception delegate(E) handler)
{
    Exception newException;
    try
    {
        return expression();
    }
    catch (E e)
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
            return new Exception("Cannot process config file%s\n  %s".format(s, e.msg), e);
        });
    // dfmt on
}

JSONValue readConfig5(string s)
{
    // dfmt off
    return  s
        .readText
        .parseJSON
        .contextWithException((UTFException e) {
            return new Exception("Cannot process utf 8 config file%s\n  %s".format(s, e.msg), e);
        })
        .contextWithException((FileException e) {
            return new Exception("Cannot process file config file%s\n %s".format(s, e.msg), e);
        })
    ;
    // dfmt on
}

JSONValue readConfig6(string s)
{
    // dfmt off
    return s
        .readText
        .contextWithString("problem with readtext")
        .parseJSON
        .contextWithString("problem with parseJson");
    // dfmt.on
}

JSONValue readConfig7(string s)
{
    throw new ContextedException("problem").add("key", "value").add("file", "~/blub");
}

void main()
{

    writeln(S().to!string);
    writeln(S());
    writeln(new C().to!string);
    writeln(new C());
    writeln(new E().to!string);
    writeln(new E());
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
            tuple("readConfig2", &readConfig2), // <-- this is the best :)
//            tuple("readConfig3", &readConfig3),
//            tuple("readConfig4", &readConfig4),
//            tuple("readConfig5", &readConfig5),
            //tuple("readConfig6", &readConfig6),
            //      tuple("readConfig7", &readConfig7),
        ])
        {
            
            auto f = kv[1];
            try
            {
                if (idx++ > 0) writeln("-------------------------------------------------------------------------");
                writeln("Working on ", file, " with ", kv[0]);
                f("testfiles/%s".format(file));
            }
            catch (Exception ex)
            {
                writeln(ex);
            }
        }
    }
}
