# Directly added to the artifact
@assert LibLua.jl_lua_int_type() == LUA_INT_TYPE
@assert LibLua.jl_lua_float_type() == LUA_FLOAT_TYPE

const LuaInt = let t = LUA_INT_TYPE
    t == 1 ? Cint :
    t == 2 ? Clong :
    t == 3 ? Clonglong :
    error("unknown Lua integer type")
end

const LuaFloat = let t = LUA_FLOAT_TYPE
    t == 1 ? Cfloat :
    t == 2 ? Cdouble :
    t == 3 ? error("Julia does not natively support long doubles") :
    error("unknown Lua float type")
end


mutable struct LuaStateWrapper
    L::Ptr{lua_State}
    debug::Bool
    stacktrace::Vector{Any}
end

Base.unsafe_convert(::Type{Ptr{lua_State}}, LS::LuaStateWrapper) = getfield(LS, :L)

"""
    LuaState

Julia interface for `lua_State` (or `LuaStateWrapper`). Supports access to the Lua stack and Lua global variabls.

Low-level stack interface:
- `pop!(LS, n)`: pop `n` elements from the Lua stack.
- `top(LS)`: maximum index for the stack.

High-level stack interface:
- `LS[idx]` or `getstack(LS, idx)`: get Julia wrapper for element at stack position `idx`.positive `idx` if count from the bottom (1), 
negative `idx` if count from the top(-1). This function does not mutate any Lua state.
- `pushstack(LS, x)` push `x` to the Lua stack and return its Julia wrapper.
- `push!(LS, args...)`: push `args...` to the Lua stack.

Global variable interface:
- `LS.var` or `get_global(LS, :var)`: push global variable `var` to the Lua stack.
- `LS.var = x` or `set_gloabl!(LS, :var, x)`: set global variable `var` to `x`.
"""
const LuaState = Union{Ptr{lua_State},LuaStateWrapper}



struct LuaError <: Exception
    msg::String
    stacktrace::Vector{Any}
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


struct LuaFunction <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaFunction(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end


struct LuaTable <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaTable(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end


struct LuaThread <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaThread(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end


struct LuaUserData <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaUserData(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end

function Base.:(==)(obj1::OnLuaStack, obj2::OnLuaStack)
    LS(obj1) == LS(obj2) || return false
    lua_rawequal(LS(obj1), idx(obj1), idx(obj2)) |> !iszero
end
