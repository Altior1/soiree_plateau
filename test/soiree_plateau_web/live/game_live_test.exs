defmodule SoireePlateauWeb.GameLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.GamesFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    nb_players_min: 1,
    nb_players_max: 4,
    duration: 30,
    complexity: 3
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    nb_players_min: 2,
    nb_players_max: 5,
    duration: 45,
    complexity: 4
  }
  @invalid_attrs %{name: nil, description: nil}
  defp create_game(_) do
    game = game_fixture()

    %{game: game}
  end

  describe "Index" do
    setup [:create_game, :register_and_log_in_user_admin]

    test "lists all games", %{conn: conn, game: game} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/games")

      assert html =~ "Liste des jeux"
      assert html =~ game.name
    end

    test "saves new game", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Nouveau jeu")
               |> render_click()
               |> follow_redirect(conn, ~p"/admin/games/new")

      assert render(form_live) =~ "Nouveau jeu"

      assert form_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#game-form", game: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/admin/games")

      html = render(index_live)
      assert html =~ "Jeu créé avec succès"
      assert html =~ "some name"
    end

    test "updates game in listing", %{conn: conn, game: game} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#games-#{game.id} a", "Modifier")
               |> render_click()
               |> follow_redirect(conn, ~p"/admin/games/#{game}/edit")

      assert render(form_live) =~ "Modifier le jeu"

      assert form_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#game-form", game: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/admin/games")

      html = render(index_live)
      assert html =~ "Jeu modifié avec succès"
      assert html =~ "some updated name"
    end

    test "deletes game in listing", %{conn: conn, game: game} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/games")

      assert index_live |> element("#games-#{game.id} a", "Supprimer") |> render_click()
      refute has_element?(index_live, "#games-#{game.id}")
    end
  end

  describe "Show" do
    setup [:create_game, :register_and_log_in_user_admin]

    test "displays game", %{conn: conn, game: game} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/games/#{game}")

      assert html =~ "Détails du jeu"
      assert html =~ game.name
    end

    test "updates game and returns to show", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/games/#{game}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Modifier")
               |> render_click()
               |> follow_redirect(conn, ~p"/admin/games/#{game}/edit?return_to=show")

      assert render(form_live) =~ "Modifier le jeu"

      assert form_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#game-form", game: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/admin/games/#{game}")

      html = render(show_live)
      assert html =~ "Jeu modifié avec succès"
      assert html =~ "some updated name"
    end
  end
end
