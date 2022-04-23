

function get_userdata(UD::LuaUserData)
    lua_touserdata(LS(UD), idx(UD))
end

function push_uservalue!(UD::LuaUserData, i)
    t = lua_getiuservalue(LS(UD), idx(UD), i)
    PopStack(getstack(LS, -1, t), LS, 1)
end

function set_uservalue!(UD::LuaUserData, i, v)
    push!(LS(UD), v)
    lua_setiuservalue(LS(UD), idx(UD), i)
end

function push_userdata!(LS::LuaState, size, uservalues=())
    checkstack(length(uservalues) + 1)
    @inbounds push!(LS, uservalues...)
    lua_newuserdatauv(LS, size, length(uservalues))
    UD = LuaUserData(LS, -1)
    PopStack(UD, LS, 1)
end
