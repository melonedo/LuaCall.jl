"""
    LuaTable

Wrapper for a Lua table on stack.
"""
struct LuaTable <: OnLuaStack
    LS::LuaState
    idx::Cint
    LuaTable(LS::LuaState, idx) = new(LS, lua_absindex(LS, idx))
end


function Base.getindex(T::LuaTable, k)
    push!(LS(T), k)
    t = lua_gettable(LS(T), idx(T))
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

function Base.getindex(T::LuaTable, k::AbstractString)
    t = lua_getfield(LS(T), idx(T), k)
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

function Base.getindex(T::LuaTable, k::Integer)
    t = lua_geti(LS(T), idx(T), k)
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

# Map property to index, what Lua `T.f` does
Base.getproperty(T::LuaTable, f::Symbol) = T[string(f)]
Base.setproperty!(T::LuaTable, f::Symbol, v) = T[string(f)] = v

"""
    rawget(T::LuaTable, k)

Get table data with raw access.
"""
function rawget(T::LuaTable, k)
    push!(LS(T), k)
    t = lua_rawget(LS(T), idx(T))
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

function rawget(T::LuaTable, k::Integer)
    t = lua_rawgeti(LS(T), idx(T), k)
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

function rawget(T::LuaTable, k::Ptr)
    t = lua_rawgetp(LS(T), idx(T), k)
    PopStack(getstack(LS(T), -1, t), LS(T), 1)
end

function Base.setindex!(T::LuaTable, v, k)
    push!(LS(T), k, v)
    lua_settable(LS(T), idx(T))
end

function Base.setindex!(T::LuaTable, v, k::AbstractString)
    push!(LS(T), v)
    lua_setfield(LS(T), idx(T), k)
end

function Base.setindex!(T::LuaTable, v, k::Integer)
    push!(LS(T), v)
    lua_seti(LS(T), idx(T), k)
end

"""
    rawset(T::LuaTable, k, v)

Set table data with raw access.
"""
function rawset(T::LuaTable, k, v)
    push!(LS(T), k, v)
    lua_rawset(LS(T), idx(T))
end

function rawset(T::LuaTable, k::Integer, v)
    push!(LS(T), v)
    lua_rawseti(LS(T), idx(T), k)
end

function rawset(T::LuaTable, v, k::Ptr)
    push!(LS(T), v)
    lua_rawsetp(LS(T), idx(T), k)
end



"""
    push_table!(LS::LuaState; narr=0, ndict=0)
    push_table!(LS::LuaState, dict::AbstractDict; narr=0, ndict=0)
    push_table(LS::LuaState, arr::AbstractArray; narr=0, ndict=0)
    
Create a Lua table and push it to the stack. Also opy data from `dict` or `arr` into the table.
`narr` and `ndict` are hint for number of sequential elements and other elements.
"""
function push_table!(LS::LuaState; narr=0, ndict=0)
    lua_createtable(LS, narr, ndict)
    PopStack(LuaTable(LS, -1), LS, 1)
end

function push_table!(LS::LuaState, dict::AbstractDict; narr=0, ndict=0)
    t = push_table!(LS; narr, ndict=ndict != 0 ? ndict : length(dict)) |> unwrap_popstack
    for (k, v) in pairs(dict)
        t[k] = v
    end
    PopStack(t, LS, 1)
end

function push_table!(LS::LuaState, arr::AbstractArray; narr=0, ndict=0)
    t = push_table!(LS; narr=narr != 0 ? narr : length(arr), ndict) |> unwrap_popstack
    for (k, v) in enumerate(arr)
        t[k] = v
    end
    PopStack(t, LS, 1)
end
