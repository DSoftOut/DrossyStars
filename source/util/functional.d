// written in the D programming language
/*
*   This file is part of DrossyStars.
*   
*   DrossyStars is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*   
*   DrossyStars is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*   
*   You should have received a copy of the GNU General Public License
*   along with DrossyStars.  If not, see <http://www.gnu.org/licenses/>.
*/
/**
*   Copyright: © 2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*   More powerful templates for meta-programming than std.typeList provides.
*/
module util.functional;

import std.traits;
import std.typetuple;

/**
*   Simple expression list wrapper.
*
*   See_Also: Expression list at dlang.org documentation.
*/
template List(T...)
{
    alias List = T;
}
/// Example
unittest
{
    static assert([List!(1, 2, 3)] == [1, 2, 3]);
}

/**
*   Sometimes we don't want to auto expand expression Lists.
*   That can be used to pass several lists into templates without
*   breaking their boundaries.
*/
template StrictList(T...)
{
    alias expand = T;
}
/// Example
unittest
{
    template Test(alias T1, alias T2)
    {
        static assert([T1.expand] == [1, 2]);
        static assert([T2.expand] == [3, 4]);
        enum Test = true;
    }
    
    static assert(Test!(StrictList!(1, 2), StrictList!(3, 4)));
}

/**
*   Same as std.typeList.staticMap, but passes two arguments to the first template.
*/
template staticMap2(alias F, T...)
{
    static assert(T.length % 2 == 0);
    
    static if (T.length < 2)
    {
        alias staticMap2 = List!();
    }
    else static if (T.length == 2)
    {
        alias staticMap2 = List!(F!(T[0], T[1]));
    }
    else
    {
        alias staticMap2 = List!(F!(T[0], T[1]), staticMap2!(F, T[2  .. $]));
    }
}
/// Example
unittest
{
    template Test(T...)
    {
        enum Test = T[0] && T[1];
    }
    
    static assert([staticMap2!(Test, true, true, true, false)] == [true, false]);
}

/**
*   Same as std.typeList.allSatisfy, but passes 2 arguments to the first template.
*/
template allSatisfy2(alias F, T...)
{
    static assert(T.length % 2 == 0);
    
    static if (T.length < 2)
    {
        enum allSatisfy2 = true;
    }
    else static if (T.length == 2)
    {
        enum allSatisfy2 = F!(T[0], T[1]);
    }
    else
    {
        enum allSatisfy2 = F!(T[0], T[1]) && allSatisfy2!(F, T[2  .. $]);
    }
}
/// Example
unittest
{
    template Test(T...)
    {
        enum Test = is(typeof(T[0]) == string) && is(typeof(T[1]) == bool);
    }
    
    static assert(allSatisfy2!(Test, "42", true, "108", false));
}

/**
*   Replicates first argument by times specified by second argument.
*/
template staticReplicate(TS...)
{
    static if(is(TS[0]))
        alias T = TS[0];
    else
        enum T = TS[0];
        
    enum n = TS[1];
    
    static if(n > 0)
    {
        alias staticReplicate = List!(T, staticReplicate!(T, n-1));
    }
    else
    {
        alias staticReplicate = List!();
    }
} 
/// Example
unittest
{    
    template isBool(T)
    {
        enum isBool = is(T == bool);
    }
    
    static assert(allSatisfy!(isBool, staticReplicate!(bool, 2))); 
    static assert([staticReplicate!("42", 3)] == ["42", "42", "42"]);
}

/**
*   Static version of std.algorithm.reduce (or fold). Expects that $(B F)
*   takes accumulator as first argument and a value as second argument.
*
*   First value of $(B T) have to be a initial value of accumulator.
*/
template staticFold(alias F, T...)
{
    static if(T.length == 0) // invalid input
    {
        alias staticFold = List!(); 
    }
    else static if(T.length == 1)
    {
        static if(is(T[0]))
            alias staticFold = T[0];
        else
            enum staticFold = T[0];
    }
    else 
    {
        alias staticFold = staticFold!(F, F!(T[0], T[1]), T[2 .. $]);
    }
}
/// Example
unittest
{
    template summ(T...)
    {
        enum summ = T[0] + T[1];
    }
    
    static assert(staticFold!(summ, 0, 1, 2, 3, 4) == 10);
    
    template preferString(T...)
    {
        static if(is(T[0] == string))
            alias preferString = T[0];
        else
            alias preferString = T[1];
    }
    
    static assert(is(staticFold!(preferString, void, int, string, bool) == string));
    static assert(is(staticFold!(preferString, void, int, double, bool) == bool));
}

/**
*   Compile-time variant of std.range.robin for expression Lists.
*   
*   Template expects $(B StrictList) list as paramater and returns
*   new expression list where first element is from first expression List,
*   second element is from second List and so on, until one of input Lists
*   doesn't end.
*/
template staticRobin(SF...)
{
    // Calculating minimum length of all Lists
    private template minimum(T...)
    {
        enum length = T[1].expand.length;
        enum minimum = T[0] > length ? length : T[0];
    }
    
    enum minLength = staticFold!(minimum, size_t.max, SF);
    
    private template robin(ulong i)
    {        
        private template takeByIndex(alias T)
        {
            static if(is(T.expand[i]))
                alias takeByIndex = T.expand[i];
            else
                enum takeByIndex = T.expand[i];
        }
        
        static if(i >= minLength)
        {
            alias robin = List!();
        }
        else
        {
            alias robin = List!(staticMap!(takeByIndex, SF), robin!(i+1));
        }
    }
    
    alias staticRobin = robin!0; 
}
/// Example
unittest
{
    alias test = staticRobin!(StrictList!(int, int, int), StrictList!(float, float));
    static assert(is(test == List!(int, float, int, float)));
    
    alias test2 = staticRobin!(StrictList!(1, 2), StrictList!(3, 4, 5), StrictList!(6, 7));
    static assert([test2]== [1, 3, 6, 2, 4, 7]);
}

/**
*   Checks two expression lists to be equal. 
*   $(B ET1) and $(B ET2) should be wrapped to $(B StrictList).
*/
template staticEqual(alias ET1, alias ET2)
{
    alias T1 = ET1.expand;
    alias T2 = ET2.expand;
    
    static if(T1.length == 0 || T2.length == 0)
    {
        enum staticEqual = T1.length == T2.length;
    }
    else
    {
        static if(is(T1[0]) && is(T2[0]))
        {
            enum staticEqual = is(T1[0] == T2[0]) && 
                staticEqual!(StrictList!(T1[1 .. $]), StrictList!(T2[1 .. $]));
        } else static if(!is(T1[0]) && !is(T2[0]))
        {
            enum staticEqual = T1[0] == T2[0] &&  
                staticEqual!(StrictList!(T1[1 .. $]), StrictList!(T2[1 .. $]));
        } else
        {
            enum staticEqual = false;
        }
    }
}
/// Example
unittest
{
    static assert(staticEqual!(StrictList!(1, 2, 3), StrictList!(1, 2, 3)));
    static assert(staticEqual!(StrictList!(int, float, 3), StrictList!(int, float, 3)));
    static assert(!staticEqual!(StrictList!(int, float, 4), StrictList!(int, float, 3)));
    static assert(!staticEqual!(StrictList!(void, float, 4), StrictList!(int, float, 4)));
    static assert(!staticEqual!(StrictList!(1, 2, 3), StrictList!(1, void, 3)));
    static assert(!staticEqual!(StrictList!(float), StrictList!()));
    static assert(staticEqual!(StrictList!(), StrictList!()));
}

/**
*   Variant of std.traits.hasMember that checks also by member type
*   to handle overloads.
*   
*   $(B T) is a type to be checked. $(B ElemType) is a member type, and 
*   $(B ElemName) is a member name. Template returns $(B true) if $(B T) has
*   element (field or method) of type $(B ElemType) with name $(B ElemName).
*
*   Template returns $(B false) for non aggregates.
*/
template hasOverload(T, ElemType, string ElemName)
{
    static if(is(T == class) || is(T == struct) || is(T == interface) || is(T == union))
    {
        static if(isCallable!ElemType)
        {
            alias retType = ReturnType!ElemType;
            alias paramList = ParameterTypeTuple!ElemType;
            
            private template extractType(alias F)
            {
                alias extractType = typeof(F);
            }
            
            static if(hasMember!(T, ElemName))
                alias overloads = staticMap!(extractType, __traits(getOverloads, T, ElemName));
            else
                alias overloads = List!();
            
            /// TODO: at next realease check overloads by attributes
            //pragma(msg, __traits(getFunctionAttributes, sum));
            
            private template checkType(F)
            {
                static if(is(ReturnType!F == retType))
                {
                    enum checkType = staticEqual!(StrictList!(ParameterTypeTuple!F), StrictList!(paramList));
                } else
                {
                    enum checkType = false;
                }
            }
            
            enum hasOverload = anySatisfy!(checkType, overloads);
        }
        else
        {
            enum hasOverload = staticIndexOf!(ElemName, __traits(allMembers, T)) != -1 &&
                is(typeof(__traits(getMember, T, ElemName)) == ElemType);
        }
    }
    else
    {
        enum hasOverload = false;
    }
}
/// Example
unittest
{
    struct A
    {
        bool method1(string a);
        bool method1(float b);
        string method1();
        
        string field;
    }
    
    static assert(hasOverload!(A, bool function(string), "method1"));
    static assert(hasOverload!(A, bool function(float), "method1"));
    static assert(hasOverload!(A, string function(), "method1"));
    static assert(hasOverload!(A, string, "field"));
    
    static assert(!hasOverload!(A, bool, "field"));
    static assert(!hasOverload!(A, void function(), "method1"));
    static assert(!hasOverload!(A, bool function(), "method1"));
    static assert(!hasOverload!(A, string function(float), "method1"));
    
    /// TODO: at next realease check overloads by attributes
//    struct D
//    {
//        string toString() const {return "";}
//    }
//    
//    static assert(hasOverload!(D, const string function(), "toString"));
//    static assert(!hasOverload!(D, string function(), "toString"));
}

/**
*   More useful version of allMembers trait, that returns only
*   fields and methods of class/struct/interface/union without
*   service members like constructors and Object members.
*
*   Note: if Object methods are explicitly override in $(B T) 
*   (not other base class), then the methods are included into
*   the result.
*/
template fieldsAndMethods(T)  
{
    static if(is(T == class) || is(T == struct) || is(T == interface) || is(T == union))
    {
        /// Getting all inherited members from Object exluding overrided
        private template derivedFromObject()
        {
            alias objectMembers = List!(__traits(allMembers, Object));
            alias derivedMembers = List!(__traits(derivedMembers, T));
            
            private template removeDerived(string name)
            {
                enum removeDerived = staticIndexOf!(name, derivedMembers);
            }
            
            alias derivedFromObject = Filter!(removeDerived, objectMembers);
        }
        
        /// Filter unrelated symbols like constructors and Object methods
        private template filterUtil(string name)
        {
            static if(name == "this")
            {
                enum filterUtil = false;
            } 
            else
            {
                static if(is(T == class))
                {
                    enum filterUtil = staticIndexOf!(name, derivedFromObject!()) == -1;
                }
                else
                {
                    enum filterUtil = true;
                }
            }
        }
        
        alias fieldsAndMethods = Filter!(filterUtil, __traits(allMembers, T));
    }
    else
    {
        alias fieldsAndMethods = List!();
    }
}
/// Example
unittest
{
    struct A
    {
        string a;
        float b;
        void foo();
        string bar(float);
    }
    
    class B
    {
        string a;
        float b;
        void foo() {}
        string bar(float) {return "";}
    }
    
    class C
    {
        override string toString() const {return "";}
    }
    
    static assert(staticEqual!(StrictList!(fieldsAndMethods!A), StrictList!("a", "b", "foo", "bar"))); 
    static assert(staticEqual!(StrictList!(fieldsAndMethods!B), StrictList!("a", "b", "foo", "bar"))); 
    static assert(staticEqual!(StrictList!(fieldsAndMethods!C), StrictList!("toString"))); 
}

/**
*   Template, similar to iota(), but generates a tuple at compile time.
*
*   Useful for "static foreach" loops, where range extrema are compile time constants:
* 	-----------
* 	foreach (i; Iota!(3))
*	a[i] = b[i];
* 
* 	// becomes unrolled and compiled as:
*   a[0] = b[0];
*   a[1] = b[1];
*   a[2] = b[2];
*	-----------
*
*	Source: https://issues.dlang.org/show_bug.cgi?id=4085
*/
template Iota(int stop) {
    static if (stop <= 0)
        alias TypeTuple!() Iota;
    else
        alias TypeTuple!(Iota!(stop-1), stop-1) Iota;
}

/// ditto
template Iota(int start, int stop) {
    static if (stop <= start)
        alias TypeTuple!() Iota;
    else
        alias TypeTuple!(Iota!(start, stop-1), stop-1) Iota;
}

/// ditto
template Iota(int start, int stop, int step) {
    static assert(step != 0, "Iota: step must be != 0");

    static if (step > 0) {
        static if (stop <= start)
            alias TypeTuple!() Iota;
        else
            alias TypeTuple!(Iota!(start, stop-step, step), stop-step) Iota;
    } else {
        static if (stop >= start)
            alias TypeTuple!() Iota;
        else
            alias TypeTuple!(Iota!(start, stop-step, step), stop-step) Iota;
    }
} // End Iota!(a,b,c)

unittest { // Tests of Iota!()
    static assert(Iota!(0).length == 0);

    int[] a;

    foreach (n; Iota!(5))
        a ~= n;
    assert(a == [0, 1, 2, 3, 4]);

    a.length = 0;
    foreach (n; Iota!(-5))
        a ~= n;
    assert(a == new int[0]);

    a.length = 0;
    foreach (n; Iota!(4, 7))
        a ~= n;
    assert(a == [4, 5, 6]);

    a.length = 0;
    foreach (n; Iota!(-1, 4))
        a ~= n;
    static assert(Iota!(-1, 4).length == 5);
    assert(a == [-1, 0, 1, 2, 3]);

    a.length = 0;
    foreach (n; Iota!(4, 2))
        a ~= n;
    assert(a == new int[0]);

    a.length = 0;
    foreach (n; Iota!(0, 10, 2))
        a ~= n;
    assert(a == [0, 2, 4, 6, 8]);

    a.length = 0;
    foreach (n; Iota!(3, 15, 3))
        a ~= n;
    assert(a == [3, 6, 9, 12]);

    a.length = 0;
    foreach (n; Iota!(15, 3, 1))
        a ~= n;
    assert(a == new int[0]);

    a.length = 0;
    foreach (n; Iota!(10, 0, -1))
        a ~= n;
    assert(a == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]);

    a.length = 0;
    foreach (n; Iota!(15, 3, -2))
        a ~= n;
    assert(a == [15, 13, 11, 9, 7, 5]);

    static assert(!is(typeof( Iota!(15, 3, 0) ))); // stride = 0 statically asserts
} // End tests of Iota!()

/// Checks if $(B T1) and $(B T2) have an operator $(B op): T1 op T2
template hasOp(T1, T2, string op)
{
    static if(isIntegral!T1 && isIntegral!T2 && op == "/")
    {
        enum hasOp = true; // to not fall into 0 divizion
    } else
    {
        enum hasOp = __traits(compiles, mixin("T1.init" ~ op ~ "T2.init"));
    }
}
///
unittest
{
    static assert(hasOp!(float, int, "*"));
    static assert(hasOp!(double, double, "/"));
    static assert(!hasOp!(double, void, "/"));
    static assert(hasOp!(int, int, "/"));
    
    struct B {}
    
    struct A
    {
        void opBinary(string op)(B b) if(op == "*") {}
    }
    
    static assert(hasOp!(A, B, "*"));
}