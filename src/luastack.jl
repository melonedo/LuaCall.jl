"""
    checkstack(LS::LuaState, n::Integer)

Ensure the stack has additional space for `n` elements.

You should call this function before you call any `lua[L]_` function that may push elements to the stack.
"""
function checkstack(LS::LuaState, n::Integer=1)
    rc = lua_checkstack(LS, n)
    iszero(rc) && throw(LuaError("insufficient space on the Lua stack for $n items"))
    nothing
end


function to_julia_type(LS, idx, typeind)
    if typeind == LUA_TNONE
        Missing
    elseif typeind == LUA_TNIL
        Nothing
    elseif typeind == LUA_TBOOLEAN
        Bool
    elseif typeind == LUA_TLIGHTUSERDATA
        Ptr{Cvoid}
    elseif typeind == LUA_TNUMBER
        !iszero(lua_isinteger(LS, idx)) ? LuaInt : LuaFloat
    elseif typeind == LUA_TSTRING
        String
    elseif typeind == LUA_TTABLE
        LuaTable
    elseif typeind == LUA_TFUNCTION
        LuaFunction
    elseif typeind == LUA_TUSERDATA
        LuaUserData
    elseif typeind == LUA_TTHREAD
        LuaThread
    else
        error("Unsupported Lua type: ", unsafe_string(lua_typename(LS, typeind)))
    end
end

getstack(LS::LuaState, idx, ::Type{Missing}) = missing
getstack(LS::LuaState, idx, ::Type{Nothing}) = nothing
getstack(LS::LuaState, idx, ::Type{Bool}) = lua_toboolean(LS, idx)
getstack(LS::LuaState, idx, ::Type{<:Integer}) = lua_tointeger(LS, idx)
getstack(LS::LuaState, idx, ::Type{<:AbstractFloat}) = lua_tonumber(LS, idx)
getstack(LS::LuaState, idx, ::Type{Ptr{Cvoid}}) = lua_touserdata(LS, idx)
getstack(LS::LuaState, idx, T::Type{<:OnLuaStack}) = T(LS, idx)

function getstack(LS::LuaState, idx, ::Type{<:AbstractString})
    len = Ref{Csize_t}()
    ptr = lua_tolstring(LS, idx, len)
    unsafe_string(ptr, len[])
end

"""
    getstack(LS::LuaState, idx=-1, typeind)

Get the value at the given Lua stack index. Does not modify the Lua stack.
"""
getstack(LS::LuaState, idx=-1, typeind::Integer=lua_type(LS, idx)) = getstack(LS, idx, to_julia_type(LS, idx, typeind))


"""
    pushstack!(LS::LuaState, x)

Push a value to the Lua stack and return it. 
"""
function pushstack! end

pushstack!(LS::LuaState, ::Nothing) = lua_pushnil(LS)
pushstack!(LS::LuaState, x::Bool) = lua_pushboolean(LS, x)
pushstack!(LS::LuaState, x::AbstractFloat) = lua_pushnumber(LS, x)
pushstack!(LS::LuaState, x::Integer) = lua_pushinteger(LS, x)
pushstack!(LS::LuaState, x::AbstractString) = lua_pushlstring(LS, x, length(x))
pushstack!(LS::LuaState, x::Ptr) = lua_pushlightuserdata(LS, x)
pushstack!(LS::LuaState, x::Symbol) = pushstack!(LS, string(x))
pushstack!(_::LuaState, _::PopStack) = error("You should not push PopStack")


function stackdump(LS::LuaState)
    [LS[i] for i in 1:top(LS)]
end

function pushstack!(to::LuaState, x::OnLuaStack)
    if to == LS(x)
        lua_pushvalue(to, idx(x))
    else
        lua_pushvalue(LS(x), idx(x))
        lua_xmove(LS(x), to, 1)
    end
end

function return_on_lua_stack(LS::LuaState, idx::Integer, typeind=lua_type(LS, idx))
    x = getstack(LS, idx, typeind)
    if x isa OnLuaStack
        PopStack(x, LS, 1)
    else
        pop!(LS, 1)
        PopStack(x, LS, 0)
    end
end

function return_on_lua_stack(LS::LuaState, range::AbstractVector)
    PopStack([getstack(LS, i) for i in range], LS, length(range))
end

Base.getindex(pop::PopStack) = unwrap_popstack(pop)
