


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
    # lua_setfield may implicitly push a new field, what???
    checkstack(LS(T), 2)
    @inbounds push!(LS(T), v)
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
function rawset!(T::LuaTable, k, v)
    push!(LS(T), k, v)
    lua_rawset(LS(T), idx(T))
end

function rawset!(T::LuaTable, k::Integer, v)
    push!(LS(T), v)
    lua_rawseti(LS(T), idx(T), k)
end

function rawset!(T::LuaTable, k::Ptr, v)
    push!(LS(T), v)
    lua_rawsetp(LS(T), idx(T), k)
end



"""
    new_table!(LS::LuaState; narr=0, ndict=0)
    new_table!(LS::LuaState, dict::AbstractDict; narr=0, ndict=0)
    new_table(LS::LuaState, arr::AbstractArray; narr=0, ndict=0)
    
Create a Lua table and push it to the stack. Also opy data from `dict` or `arr` into the table.
`narr` and `ndict` are hint for number of sequential elements and other elements.
"""
function new_table!(LS::LuaState; narr=0, ndict=0)
    checkstack(LS, 1)
    lua_createtable(LS, narr, ndict)
    PopStack(LuaTable(LS, -1), LS, 1)
end

function new_table!(LS::LuaState, dict::AbstractDict; narr=0, ndict=0)
    t = new_table!(LS; narr, ndict=ndict != 0 ? ndict : length(dict)) |> unwrap_popstack
    for (k, v) in pairs(dict)
        t[k] = v
    end
    PopStack(t, LS, 1)
end

function new_table!(LS::LuaState, arr::AbstractArray; narr=0, ndict=0)
    t = new_table!(LS; narr=narr != 0 ? narr : length(arr), ndict) |> unwrap_popstack
    for (k, v) in enumerate(arr)
        t[k] = v
    end
    PopStack(t, LS, 1)
end

const LuaIterable = Union{LuaTable,LuaUserData}

function Base.foreach(f, t::LuaIterable)
    checkstack(LS(t), 2)
    @inbounds push!(LS(t), nothing)
    while !iszero(lua_next(LS(t), idx(t)))
        f(LS(t)[-2], LS(t)[-1])
        pop!(LS(t), 1)
    end
end
