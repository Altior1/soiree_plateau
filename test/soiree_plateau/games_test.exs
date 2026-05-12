defmodule SoireePlateau.GamesTest do
  use SoireePlateau.DataCase

  alias SoireePlateau.Games

  describe "games" do
    alias SoireePlateau.Games.Game

    import SoireePlateau.GamesFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Games.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Games.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        complexity: 3,
        duration: 30,
        nb_players_max: 4,
        nb_players_min: 1
      }

      assert {:ok, %Game{} = game} = Games.create_game(valid_attrs)
      assert game.name == "some name"
      assert game.description == "some description"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Games.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        complexity: 4,
        duration: 45,
        nb_players_max: 5,
        nb_players_min: 2
      }

      assert {:ok, %Game{} = game} = Games.update_game(game, update_attrs)
      assert game.name == "some updated name"
      assert game.description == "some updated description"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Games.update_game(game, @invalid_attrs)
      assert game == Games.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Games.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Games.change_game(game)
    end
  end
end
