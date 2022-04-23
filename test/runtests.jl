using LuaCall
using Test

@testset "JuliaModule" begin
    @luascope LUA_STATE begin
        A = [2 1; 8 9]

        B1 = inv(A)
        lua_inv = luaeval("return julia.inv(...)")
        B2 = lua_inv(A)
        @test B1 == getjulia(B2)

        C1 = A + A
        lua_add = luaeval("local A = ...; return A + A")
        C2 = lua_add(A)
        @test C1 == getjulia(C2)

        D1 = A^2
        lua_square = luaeval("local A = ...; return A ^ 2")
        D2 = lua_square(A)
        @test D1 == getjulia(D2)

        E1 = A[3]
        lua_index = luaeval("local A, i = ...; return A[i]")
        E2 = lua_index(A, 3)
        @test E1 == getjulia(E2)

        A = [1, 3, 5]
        keysum1, valsum1 = 0, 0
        for (k, v) in pairs(A)
            keysum1 += k
            valsum1 += v
        end
        lua_iter = luaeval("""
            local A = ...
            local keysum, valsum = 0, 0
            for _, value in pairs(julia.pairs(A)) do
                keysum, valsum = keysum + value[1], valsum + value[2]
            end
            return keysum, valsum
        """)
        keysum2, valsum2 = lua_iter(A; multiret=true)
        @test keysum1 == keysum2
        @test valsum1 == valsum2
    end
    @test top(LUA_STATE) == 0
end

@testset "LuaTable" begin
    @luascope LUA_STATE begin
        d = Dict((1 => "hello", "str" => 1234, Ptr{Cvoid}(4321) => 234))
        t1 = push_table!(LUA_STATE, d)
        for (k, v) in d
            @luascope LUA_STATE begin
                v2 = t1[k]
                @test v2 == v
            end
        end

        t1.field = 4321
        f = t1.field
        @test f == 4321

        t2 = push_table!(LUA_STATE)
        for (k, v) in d
            LuaCall.rawset!(t2, k, v)
        end

        for (k, v) in d
            @luascope LUA_STATE begin
                v2 = LuaCall.rawget(t2, k)
                @test v2 == v
            end
        end

        a = [4 3 2 1]
        t3 = push_table!(LUA_STATE, a)
        foreach(t3) do k, v
            @test a[k] == v
        end
    end
end

@testset "GC" begin
    @luascope LUA_STATE begin
        luacall(:collectgarbage, "collect")
        f = luaeval("local x; for _, v in pairs(...) do x = julia.Base end")
        f(1:100)
        luacall(:collectgarbage, "collect")
    end
    @test LuaCall.check_gc_root() == 1
end
