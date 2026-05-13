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
end
