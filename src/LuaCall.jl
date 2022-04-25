module LuaCall

include("../lib/LibLua.jl")

using .LibLua

export lualoadstring, luacall, LUA_STATE, top, @luascope, @luareturn
export LuaState, LuaTable, LuaUserData, LuaThread, LuaFunction
export get_julia, new_table!, get_uservalue, set_uservalue!
export new_userdata!, set_metatable!, get_metatable, pushstack!, getstack
export get_global, set_global!, get_globaltable, new_cfunction!
export iscfunction, get_mainthread, lualoadfile, registry

include("types.jl")
include("luascope.jl")
include("luastate.jl")
include("luadebug.jl")
include("luatable.jl")
include("luauserdata.jl")
include("luafunction.jl")
include("luathread.jl")
include("luastack.jl")
include("juliavalue.jl")


"""
    lualoadstring([LS::LuaState,] str)

Evaluate the given Lua code, return the resulting function.

Lua treats individual chunk as body of an anonymous function, 
you can pass arguments and get return values accordingly. 

Example:
```julia
@luascope LS begin
    f = lualoadstring(LS, s)
    ret = f(args...; multiret=true)
    @luareturn ret...
end
```
"""
function lualoadstring(LS::LuaState, str)
    rc = luaL_loadstring(LS, str)
    rc == LUA_OK || throw(LuaError(LS))
    PopStack(LuaFunction(LS, -1), LS, 1)
end

lualoadstring(str) = lualoadstring(LUA_STATE, str)

"""
    lualoadfile(LS::LuaState, filename, mode="bt")

Load a Lua script, return the parsed chunk.
"""
function lualoadfile(LS::LuaState, filename, mode="bt")
    rc = luaL_loadfilex(LS, filename, mode)
    rc == LUA_OK || throw(LuaError(LS))
    PopStack(LuaFunction(LS, -1), LS, -1)
end

lualoadfile(filename, mode="bt") = lualoadfile(LUA_STATE, filename, mode)


function luacall(LS::LuaState, f::Symbol, args...; ka...)
    g = get_global(LS, f) |> unwrap_popstack
    @assert g isa LuaCallable
    g(args...; ka...)
end

luacall(f::Symbol, args...; ka...) = luacall(LUA_STATE, f, args..., ka...)


const LUA_STATE = LuaStateWrapper(C_NULL)

function __init__()
    init(LUA_STATE)
end

end
