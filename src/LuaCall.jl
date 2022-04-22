module LuaCall

include("../lib/LibLua.jl")

using .LibLua
using .LibLua: liblua

export luaeval, luacall, LUA_STATE, @luascope

include("luastate.jl")
include("luadebug.jl")

const LUA_STATE = LuaStateWraper(C_NULL)

# Directly added to the artifact
@assert ccall((:jl_lua_int_type, liblua), Cint, ()) == LibLua.LUA_INT_TYPE
@assert ccall((:jl_lua_float_type, liblua), Cint, ()) == LibLua.LUA_FLOAT_TYPE

const LuaInt = let t = LibLua.LUA_INT_TYPE
    t == 1 ? Cint :
    t == 2 ? Clong :
    t == 3 ? Clonglong :
    error("unknown Lua integer type")
end

const LuaFloat = let t = LibLua.LUA_FLOAT_TYPE
    t == 1 ? Cfloat :
    t == 2 ? Cdouble :
    t == 3 ? error("Julia does not natively support long doubles") :
    error("unknown Lua float type")
end


"""
    OnStackType

Values of this type are valid only for the current Lua stack frame. For safety, they are always wrapped in a `PopStack` wrapper.
"""
abstract type OnLuaStack end

LS(x::OnLuaStack) = getfield(x, :LS)
idx(x::OnLuaStack) = getfield(x, :idx)

"""
    PopStack{T}

A data type to protect from passing Values on the Lua stack around carelessly.
You should either take care to restore Lua stack, or use `@luascope`
"""
struct PopStack{T}
    data::T
    LS::LuaState
    npop::Cint
end

PopStack(data::T, LS, npop) where {T} = PopStack{T}(data, LS, npop)


include("luascope.jl")
include("luatable.jl")
include("luauserdata.jl")
include("luafunction.jl")
include("luathread.jl")
include("luastack.jl")

function luaL_dostring(LS, s, args...)
    luaeval(LS, s)
    pcall(LS, args...; multiret=true)
end

"""
    luaeval(LS::LuaState, str)

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

macro lua_str(code::String)
    luaL_dostring(LUA_STATE, code)
end


function luacall(f::Symbol, args...)
    g = pushglobal!(LUA_STATE, f)
    @assert unwrap_popstack(g) isa LuaCallable
    # Poped by `pcall`
    pop!(pcall(LUA_STATE, args...)) do ret
        instantiate(ret)
    end
end

"""
    registry(LS::LuaState)

Get the Lua registry.
"""
registry(LS::LuaState) = LuaTable(LS, LUA_REGISTRYINDEX)

function push_metatable!(obj::Union{LuaTable,LuaUserData})
    @assert lua_getmetatable(LS(obj), idx(obj)) == 1
    PopStack(LuaTable(LS(obj), -1), LS(obj), 1)
end

"""
    set_metatable!(obj::Union{LuaTable,LuaUserData}, table)

Set metatable for `obj`, if `table` is `nothing`, unset the metatable.
"""
function set_metatable!(obj::Union{LuaTable,LuaUserData}, table)
    push!(LS(obj), table)
    lua_setmetatable(LS(obj), idx(obj))
end

function stackdump(LS::LuaState)
    [LS[i] for i in 1:top(LS)]
end

include("juliavalue.jl")

function __init__()
    init(LUA_STATE)
    luaL_dostring(LUA_STATE, "function i(x) for k,v in pairs(x) do print('lua', v) end end")
end

end
