

function get_userdata(UD::LuaUserData)
    lua_touserdata(LS(UD), idx(UD))
end

function get_uservalue(UD::LuaUserData, i)
    t = lua_getiuservalue(LS(UD), idx(UD), i)
    return_on_lua_stack(LS(UD), -1, t)
end

function set_uservalue!(UD::LuaUserData, i, v)
    push!(LS(UD), v)
    lua_setiuservalue(LS(UD), idx(UD), i)
end

"""
    new_userdata!(LS::LuaState, size, nuservalue=0)

Create a userdata with given number of bytes and given number of uservalue.
"""
function new_userdata!(LS::LuaState, size, nuservalue=0)
    lua_newuserdatauv(LS, size, nuservalue)
    UD = LuaUserData(LS, -1)
    PopStack(UD, LS, 1)
end
