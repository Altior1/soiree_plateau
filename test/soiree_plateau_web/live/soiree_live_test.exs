defmodule SoireePlateauWeb.SoireeLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.TeufFixtures

  @create_attrs %{
    date: "2026-05-11T13:00:00",
    home: "some home",
    title: "some title",
    capacity: 42
  }
  @update_attrs %{
    date: "2026-05-12T13:00:00",
    home: "some updated home",
    title: "some updated title",
    capacity: 43
  }
  @invalid_attrs %{date: nil, home: nil, title: nil, capacity: nil}

  setup :register_and_log_in_user

  defp create_soiree(%{scope: scope}) do
    game = SoireePlateau.GamesFixtures.game_fixture()
    attrs = Map.put(@create_attrs, :game_id, game.id)
    soiree = soiree_fixture(scope, attrs)

    %{soiree: soiree}
  end

  describe "Index" do
    setup [:create_soiree]

    test "lists all soirees", %{conn: conn, soiree: soiree} do
      {:ok, _index_live, html} = live(conn, ~p"/users/soirees")

      assert html =~ "Liste des soirées"
      assert html =~ soiree.title
    end

    test "saves new soiree", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/users/soirees")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "Nouvelle soirée")
               |> render_click()
               |> follow_redirect(conn, ~p"/users/soirees/new")

      assert render(form_live) =~ "Nouvelle soirée"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/soirees")

      html = render(index_live)
      assert html =~ "Soirée créée avec succès"
      assert html =~ "some title"
    end

    test "updates soiree in listing", %{conn: conn, soiree: soiree} do
      {:ok, index_live, _html} = live(conn, ~p"/users/soirees")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#soirees-#{soiree.id} a", "Modifier")
               |> render_click()
               |> follow_redirect(conn, ~p"/users/soirees/#{soiree}/edit")

      assert render(form_live) =~ "Modifier la soirée"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/soirees")

      html = render(index_live)
      assert html =~ "Soirée mise à jour avec succès"
      assert html =~ "some updated title"
    end

    test "deletes soiree in listing", %{conn: conn, soiree: soiree} do
      {:ok, index_live, _html} = live(conn, ~p"/users/soirees")

      assert index_live |> element("#soirees-#{soiree.id} a", "Supprimer") |> render_click()
      refute has_element?(index_live, "#soirees-#{soiree.id}")
    end
  end

  describe "Show" do
    setup [:create_soiree]

    test "displays soiree", %{conn: conn, soiree: soiree} do
      {:ok, _show_live, html} = live(conn, ~p"/users/soirees/#{soiree}")

      assert html =~ "Détails de la soirée"
      assert html =~ soiree.title
    end

    test "host sees the vote summary block", %{conn: conn, scope: scope} do
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        SoireePlateau.Teuf.create_soiree(scope, %{
          title: "past",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id
        })

      {:ok, _show_live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      assert html =~ "Notes reçues"
      assert html =~ "Aucune note pour l&#39;instant"
    end

    test "confirmed invitee can rate with a comment and see it back", %{conn: _conn, scope: scope} do
      game = SoireePlateau.GamesFixtures.game_fixture()
      guest = SoireePlateau.AccountsFixtures.user_fixture()

      {:ok, soiree} =
        SoireePlateau.Teuf.create_soiree(scope, %{
          title: "past with guest",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest.id]
        })

      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
      [invitation] = SoireePlateau.Teuf.list_invitations_for_user(guest_scope)
      {:ok, _} = SoireePlateau.Teuf.respond_to_invitation(guest_scope, invitation, :yes)

      guest_conn = Phoenix.ConnTest.build_conn() |> log_in_user(guest)

      {:ok, show_live, html} = live(guest_conn, ~p"/users/soirees/#{soiree}")

      # The guest sees the rating form (with textarea) and the empty notes block.
      assert html =~ "Noter le jeu"
      assert html =~ "vote-comment"
      assert html =~ "Notes reçues"

      # Submit a 4/5 rating with a comment.
      html =
        show_live
        |> form("#rate-form", %{"comment" => "Super soirée"})
        |> render_submit(%{"rating" => "4"})

      assert html =~ "Note enregistrée"
      assert html =~ "Super soirée"
      assert html =~ "4</strong>/5"
    end

    test "stranger (not invited) does not see the notes block", %{conn: _conn, scope: scope} do
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        SoireePlateau.Teuf.create_soiree(scope, %{
          title: "past",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id
        })

      stranger = SoireePlateau.AccountsFixtures.user_fixture()
      stranger_conn = Phoenix.ConnTest.build_conn() |> log_in_user(stranger)

      # `get_visible_soiree!/2` would raise for a non-host non-invitee;
      # asserting that confirms unauthorized users cannot reach the show page.
      assert_raise Ecto.NoResultsError, fn ->
        live(stranger_conn, ~p"/users/soirees/#{soiree}")
      end
    end

    test "updates soiree and returns to show", %{conn: conn, soiree: soiree} do
      {:ok, show_live, _html} = live(conn, ~p"/users/soirees/#{soiree}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Modifier")
               |> render_click()
               |> follow_redirect(conn, ~p"/users/soirees/#{soiree}/edit?return_to=show")

      assert render(form_live) =~ "Modifier la soirée"

      assert form_live
             |> form("#soiree-form", soiree: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#soiree-form", soiree: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/soirees/#{soiree}")

      html = render(show_live)
      assert html =~ "Soirée mise à jour avec succès"
      assert html =~ "some updated title"
    end
  end

  describe "Form" do
    test "create with selected invitees inserts pending invitations", %{conn: conn, scope: scope} do
      guest = SoireePlateau.AccountsFixtures.user_fixture()
      {:ok, form_live, _html} = live(conn, ~p"/users/soirees/new")

      attrs_with_invitees = Map.put(@create_attrs, :invitee_ids, [to_string(guest.id)])

      {:ok, _index_live, _html} =
        form_live
        |> form("#soiree-form", soiree: attrs_with_invitees)
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/soirees")

      [soiree] = SoireePlateau.Teuf.list_soirees(scope)
      assert SoireePlateau.Teuf.list_invitee_ids(soiree) == [guest.id]
    end
  end

  describe "Form edit" do
    setup [:create_soiree]

    test "returns to show when return_to=show", %{conn: conn, soiree: soiree} do
      {:ok, form_live, _html} =
        live(conn, ~p"/users/soirees/#{soiree}/edit?return_to=show")

      assert {:ok, _show_live, html} =
               form_live
               |> form("#soiree-form", soiree: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/soirees/#{soiree}")

      assert html =~ "Soirée mise à jour"
    end

    test "shows changeset errors on invalid submit", %{conn: conn, soiree: soiree} do
      {:ok, form_live, _html} = live(conn, ~p"/users/soirees/#{soiree}/edit")

      html =
        form_live
        |> form("#soiree-form", soiree: @invalid_attrs)
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end
end
