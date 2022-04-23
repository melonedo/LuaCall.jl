module LuaCall

include("../lib/LibLua.jl")

using .LibLua
using .LibLua: liblua

export luaeval, luacall, LUA_STATE, top, @luascope, @luareturn
export LuaState, LuaTable, LuaUserData, LuaThread, LuaFunction
export get_julia, new_table!, get_uservalue, set_uservalue!
export new_userdata!, set_metatable!, get_metatable, pushstack!, getstack
export get_global, set_global!, get_globaltable

include("types.jl")
include("luascope.jl")
include("luastate.jl")
include("luadebug.jl")
include("luatable.jl")
include("luauserdata.jl")
include("luafunction.jl")
include("luathread.jl")
include("luastack.jl")


const LUA_STATE = LuaStateWraper(C_NULL)


"""
    luaeval([LS::LuaState, ]str)

Evaluate the given Lua code, return the resulting function.

Lua treats individual chunk as body of an anonymous function, 
you can pass arguments and get return values accordingly. 

Example:
```julia
@luascope LS begin
    f = luaeval(LS, s)
    ret = f(args...; multiret=true)
    @luareturn ret...
end
```
"""
function luaeval(LS::LuaState, str)
    rc = luaL_loadstring(LS, str)
    rc == LUA_OK || throw(LuaError(LS))
    PopStack(getstack(LS, -1, LuaFunction), LS, 1)
end

luaeval(str) = luaeval(LUA_STATE, str)


function luacall(f::Symbol, args...)
    g = get_global(LUA_STATE, f) |> unwrap_popstack
    @assert g isa LuaCallable
    g(args...)
end

function stackdump(LS::LuaState)
    [LS[i] for i in 1:top(LS)]
end

include("juliavalue.jl")

function __init__()
    init(LUA_STATE)
end

end
