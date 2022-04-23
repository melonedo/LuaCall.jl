

function get_userdata(UD::LuaUserData)
    lua_touserdata(LS(UD), idx(UD))
end

function get_uservalue(UD::LuaUserData, i)
    t = lua_getiuservalue(LS(UD), idx(UD), i)
    PopStack(getstack(LS(UD), -1, t), LS(UD), 1)
end

function set_uservalue!(UD::LuaUserData, i, v)
    push!(LS(UD), v)
    lua_setiuservalue(LS(UD), idx(UD), i)
end

function new_userdata!(LS::LuaState, size, num=0)
    lua_newuserdatauv(LS, size, num)
    UD = LuaUserData(LS, -1)
    PopStack(UD, LS, 1)
end
