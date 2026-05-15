defmodule SoireePlateauWeb.VoteLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.AccountsFixtures

  alias SoireePlateau.Teuf

  setup :register_and_log_in_user

  defp setup_invitation(%{user: user}, opts) do
    host = user_fixture()
    host_scope = SoireePlateau.Accounts.Scope.for_user(host)
    game = SoireePlateau.GamesFixtures.game_fixture()
    date = Keyword.fetch!(opts, :date)
    answer = Keyword.get(opts, :answer, :yes)

    {:ok, soiree} =
      Teuf.create_soiree(host_scope, %{
        title: "soirée test",
        date: date,
        home: "chez Thomas",
        capacity: 5,
        game_id: game.id,
        invitee_ids: [user.id]
      })

    scope = SoireePlateau.Accounts.Scope.for_user(user)
    [invitation] = Teuf.list_invitations_for_user(scope)
    {:ok, _} = Teuf.respond_to_invitation(scope, invitation, answer)

    %{host: host, host_scope: host_scope, soiree: soiree, game: game}
  end

  describe "Invitee on past soiree" do
    test "sees the vote block and can cast a rating", %{conn: conn, user: user} = ctx do
      %{soiree: soiree, game: game} =
        setup_invitation(ctx, date: ~N[2020-01-01 18:00:00])

      {:ok, live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      assert html =~ "Noter le jeu"
      assert html =~ game.name

      assert live
             |> element("#vote-block button", "4")
             |> render_click() =~ "Note enregistrée"

      scope = SoireePlateau.Accounts.Scope.for_user(user)
      assert %SoireePlateau.Teuf.Vote{rating: 4} = Teuf.get_user_vote(scope, soiree, game.id)
    end

    test "can update an existing vote", %{conn: conn, user: user} = ctx do
      %{soiree: soiree, game: game} =
        setup_invitation(ctx, date: ~N[2020-01-01 18:00:00])

      scope = SoireePlateau.Accounts.Scope.for_user(user)
      {:ok, _} = Teuf.cast_vote(scope, soiree, %{rating: 2, game_id: game.id})

      {:ok, live, _html} = live(conn, ~p"/users/soirees/#{soiree}")
      assert render(live) =~ "Ta note actuelle : 2/5"

      live |> element("#vote-block button", "5") |> render_click()
      assert %SoireePlateau.Teuf.Vote{rating: 5} = Teuf.get_user_vote(scope, soiree, game.id)
    end
  end

  describe "Invitee on future soiree" do
    test "does not see the vote block", %{conn: conn} = ctx do
      future = NaiveDateTime.utc_now() |> NaiveDateTime.add(7 * 24 * 3600, :second)
      %{soiree: soiree} = setup_invitation(ctx, date: future)

      {:ok, _live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      refute html =~ "Noter le jeu"
    end
  end

  describe "Invitee who declined" do
    test "does not see the vote block", %{conn: conn} = ctx do
      %{soiree: soiree} =
        setup_invitation(ctx, date: ~N[2020-01-01 18:00:00], answer: :no)

      {:ok, _live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      refute html =~ "Noter le jeu"
    end
  end

  describe "Stranger" do
    test "cannot access the soiree", %{conn: conn} do
      host = user_fixture()
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "private",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id
        })

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/users/soirees/#{soiree}")
      end
    end
  end

  describe "Host viewing a past soiree with votes" do
    test "sees average + per-vote list" do
      host = user_fixture()
      host_conn = log_in_user(Phoenix.ConnTest.build_conn(), host)
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      game = SoireePlateau.GamesFixtures.game_fixture()
      guest_a = user_fixture()
      guest_b = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "passed",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest_a.id, guest_b.id]
        })

      for user <- [guest_a, guest_b] do
        scope = SoireePlateau.Accounts.Scope.for_user(user)
        [inv] = Teuf.list_invitations_for_user(scope)
        {:ok, _} = Teuf.respond_to_invitation(scope, inv, :yes)
      end

      a_scope = SoireePlateau.Accounts.Scope.for_user(guest_a)
      b_scope = SoireePlateau.Accounts.Scope.for_user(guest_b)
      {:ok, _} = Teuf.cast_vote(a_scope, soiree, %{rating: 4, game_id: game.id})
      {:ok, _} = Teuf.cast_vote(b_scope, soiree, %{rating: 2, game_id: game.id})

      {:ok, _live, html} = live(host_conn, ~p"/users/soirees/#{soiree}")
      assert html =~ "Notes reçues"
      assert html =~ "Moyenne"
      assert html =~ guest_a.email
      assert html =~ guest_b.email
      assert html =~ "2 notes"
    end

    test "summary updates live when an invitee votes" do
      host = user_fixture()
      host_conn = log_in_user(Phoenix.ConnTest.build_conn(), host)
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      game = SoireePlateau.GamesFixtures.game_fixture()
      guest = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "live update",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest.id]
        })

      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
      [inv] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, _} = Teuf.respond_to_invitation(guest_scope, inv, :yes)

      {:ok, live, _html} = live(host_conn, ~p"/users/soirees/#{soiree}")
      refute render(live) =~ "Moyenne"

      {:ok, _} = Teuf.cast_vote(guest_scope, soiree, %{rating: 5, game_id: game.id})
      assert render(live) =~ "Moyenne"
      assert render(live) =~ guest.email
    end
  end

  describe "Host invitee management on show page" do
    test "remove invitation reflects in the list", %{conn: conn, user: host} do
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      guest = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "future",
          date: NaiveDateTime.utc_now() |> NaiveDateTime.add(86_400, :second),
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      {:ok, live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      assert html =~ guest.email

      [invitation] =
        host_scope
        |> Teuf.list_invitations_for_soiree(soiree)
        |> Enum.filter(&(&1.user_id == guest.id))

      live |> element("#rsvp-#{invitation.id} a", "Retirer") |> render_click()
      refute render(live) =~ guest.email
    end

    test "shows badges for each RSVP status", %{conn: conn, user: host} do
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      yes_user = user_fixture()
      no_user = user_fixture()
      maybe_user = user_fixture()
      pending_user = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "rsvp colors",
          date: NaiveDateTime.utc_now() |> NaiveDateTime.add(86_400, :second),
          home: "h",
          capacity: 10,
          invitee_ids: [yes_user.id, no_user.id, maybe_user.id, pending_user.id]
        })

      for {user, status} <- [{yes_user, :yes}, {no_user, :no}, {maybe_user, :maybe}] do
        scope = SoireePlateau.Accounts.Scope.for_user(user)
        [inv] = Teuf.list_invitations_for_user(scope)
        {:ok, _} = Teuf.respond_to_invitation(scope, inv, status)
      end

      {:ok, _live, html} = live(conn, ~p"/users/soirees/#{soiree}")
      assert html =~ "Oui"
      assert html =~ "Non"
      assert html =~ "Peut-être"
      assert html =~ "En attente"
    end
  end

  describe "Rate event error handling" do
    test "rejects a vote on a future soiree (UI bypass)", %{conn: conn} = ctx do
      future = NaiveDateTime.utc_now() |> NaiveDateTime.add(86_400, :second)
      %{soiree: soiree, game: game} = setup_invitation(ctx, date: future)

      # The vote block is not rendered, but we hit the LiveView directly to
      # exercise the error path of the rate handler.
      {:ok, live, _html} = live(conn, ~p"/users/soirees/#{soiree}")

      result =
        render_hook(live, "rate", %{"rating" => "3", "game_id" => to_string(game.id)})

      assert result =~ "Le vote sera ouvert"
    end
  end
end
