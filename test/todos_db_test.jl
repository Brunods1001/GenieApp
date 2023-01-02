using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation, SearchLight.Exceptions

try
    SearchLight.Migrations.init()
catch
end

SearchLight.config.db_migrations_folder = abspath(normpath(joinpath("..", "db", "migrations")))
SearchLight.Migrations.all_up!!()

@testset "Todo DB tests" begin
    t = Todo()
    @testset "Invalid todo is not saved" begin
        @test !save(t)
        @test_throws(InvalidModelException{Todo}, save!(t))
    end
    @testset "valid todo is saved" begin
        t.todo = "Buy milk"
        @test save(t)
        tx = save!(t)
        @test ispersisted(tx)
        tx2 = findone(Todo, todo = "Buy milk")
        @test pk(tx) == pk(tx2)
    end
end;

SearchLight.Migrations.all_down!!(confirm = false)