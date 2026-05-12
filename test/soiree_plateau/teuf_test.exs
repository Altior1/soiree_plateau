defmodule SoireePlateau.TeufTest do
  use SoireePlateau.DataCase

  alias SoireePlateau.Teuf

  describe "soirees" do
    alias SoireePlateau.Teuf.Soiree

    import SoireePlateau.AccountsFixtures, only: [user_scope_fixture: 0]
    import SoireePlateau.TeufFixtures

    @invalid_attrs %{date: nil, home: nil, title: nil, capacity: nil}

    test "list_soirees/1 returns all scoped soirees" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      other_soiree = soiree_fixture(other_scope)
      assert Teuf.list_soirees(scope) == [soiree]
      assert Teuf.list_soirees(other_scope) == [other_soiree]
    end

    test "get_soiree!/2 returns the soiree with given id" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      other_scope = user_scope_fixture()
      assert Teuf.get_soiree!(scope, soiree.id) == soiree
      assert_raise Ecto.NoResultsError, fn -> Teuf.get_soiree!(other_scope, soiree.id) end
    end

    test "create_soiree/2 with valid data creates a soiree" do
      valid_attrs = %{
        date: ~N[2026-05-11 13:00:00],
        home: "some home",
        title: "some title",
        capacity: 42
      }

      game = SoireePlateau.GamesFixtures.game_fixture()
      valid_attrs = Map.put(valid_attrs, :game_id, game.id)
      scope = user_scope_fixture()

      assert {:ok, %Soiree{} = soiree} = Teuf.create_soiree(scope, valid_attrs)
      assert soiree.date == ~N[2026-05-11 13:00:00]
      assert soiree.home == "some home"
      assert soiree.title == "some title"
      assert soiree.capacity == 42
      assert soiree.host == scope.user.id
    end

    test "create_soiree/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Teuf.create_soiree(scope, @invalid_attrs)
    end

    test "update_soiree/3 with valid data updates the soiree" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      update_attrs = %{
        date: ~N[2026-05-12 13:00:00],
        home: "some updated home",
        title: "some updated title",
        capacity: 43
      }

      assert {:ok, %Soiree{} = soiree} = Teuf.update_soiree(scope, soiree, update_attrs)
      assert soiree.date == ~N[2026-05-12 13:00:00]
      assert soiree.home == "some updated home"
      assert soiree.title == "some updated title"
      assert soiree.capacity == 43
    end

    test "update_soiree/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      assert_raise MatchError, fn ->
        Teuf.update_soiree(other_scope, soiree, %{})
      end
    end

    test "update_soiree/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Teuf.update_soiree(scope, soiree, @invalid_attrs)
      assert soiree == Teuf.get_soiree!(scope, soiree.id)
    end

    test "delete_soiree/2 deletes the soiree" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      assert {:ok, %Soiree{}} = Teuf.delete_soiree(scope, soiree)
      assert_raise Ecto.NoResultsError, fn -> Teuf.get_soiree!(scope, soiree.id) end
    end

    test "delete_soiree/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      assert_raise MatchError, fn -> Teuf.delete_soiree(other_scope, soiree) end
    end

    test "change_soiree/2 returns a soiree changeset" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      assert %Ecto.Changeset{} = Teuf.change_soiree(scope, soiree)
    end
  end
end
