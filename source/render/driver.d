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
*/
module render.driver;

import std.traits;
import std.range;

import render.monitor;
import util.cinterface;
import math.vec;

/// Comparison function for depth buffer
enum DepthFunc
{
	Never,
	Less,
	Equal,
	LessEqual,
	Greater,
	NotEqual,
	GreaterEqual,
	Always
}

/**
*   Compile time interface
*/
struct CIDriver
{
    /// Driver name
    immutable string name;
    /// Detail description
    immutable string description;
    
    /// initialization could varies within implementation
    void initialize(T...)(T args);
    
    /// Returns available monitors
    @trasient
    R monitors(R, M)() const
        if(isInputRange!R && is(ElementType!R == M) && isMonitor!M);
    
    /// Returns primary monitor
    @trasient
    M monitor(M)() const
        if(isMonitor!M);
        
    /// Drawing scene to current context
    void draw();
    
    /// Setting scene background color to $(B c) for current context.
    @trasient
	void backgroundColor(Color)(Color c)
		if(isColor!Color);
	
	/// Enables or disables depth buffer
	void setDepthTest(bool flag);
	
	/// Sets comparison function for depth test
	void depthFunc(DepthFunc func);
}

/// Test if $(B T) is actual a driver
template isDriver(T)
{
    static if(hasMember!(T, "monitors") && hasMember!(T, "monitor"))
    {
        alias R1 = ReturnType!(__traits(getMember, T, "monitors"));
        alias R2 = ReturnType!(__traits(getMember, T, "monitor"));
        
        enum hasMonitors = isInputRange!R1 && isMonitor!(ElementType!R1) 
                        && isMonitor!R2;
    } else
    {
        enum hasMonitors = false;
    }
    
    enum isDriver = isExpose!(T, CIDriver) && hasMonitors;
}