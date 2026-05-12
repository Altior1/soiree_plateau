defmodule SoireePlateauWeb.UserGamesLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.GamesFixtures

  defp create_game(_) do
    game = game_fixture()

    %{game: game}
  end

  describe "List (users)" do
    setup [:create_game, :register_and_log_in_user]

    test "lists all games", %{conn: conn, game: game} do
      {:ok, _live, html} = live(conn, ~p"/users/games")

      assert html =~ "Liste des jeux de société"
      assert html =~ game.name
    end
  end

  describe "Show (users)" do
    setup [:create_game, :register_and_log_in_user]

    test "displays game details", %{conn: conn, game: game} do
      {:ok, _live, html} = live(conn, ~p"/users/games/#{game.id}")

      assert html =~ game.name
      assert html =~ game.description
    end
  end
end
