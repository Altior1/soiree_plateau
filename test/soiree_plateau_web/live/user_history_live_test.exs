defmodule SoireePlateauWeb.UserLive.HistoryTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.AccountsFixtures

  alias SoireePlateau.Teuf

  setup :register_and_log_in_user

  defp respond_to_my_invitation(user, soiree, status) do
    scope = SoireePlateau.Accounts.Scope.for_user(user)

    invitation =
      SoireePlateau.Repo.get_by!(SoireePlateau.Teuf.Invitation,
        user_id: user.id,
        soiree_id: soiree.id
      )

    {:ok, _} = Teuf.respond_to_invitation(scope, invitation, status)
  end

  describe "GET /users/historique" do
    test "shows the empty state when the user has no past participation", %{conn: conn} do
      {:ok, _live, html} = live(conn, ~p"/users/historique")

      assert html =~ "Mon historique"
      assert html =~ "Tu n&#39;as encore participé à aucune soirée passée"
    end

    test "shows the past soirees the user attended, with their note", %{conn: conn, user: user} do
      host = user_fixture()
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "Mémorable",
          date: ~N[2020-06-15 20:00:00],
          home: "chez moi",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [user.id]
        })

      respond_to_my_invitation(user, soiree, :yes)

      scope = SoireePlateau.Accounts.Scope.for_user(user)
      {:ok, _} = Teuf.cast_vote(scope, soiree, %{rating: 4, game_id: game.id})

      {:ok, _live, html} = live(conn, ~p"/users/historique")

      assert html =~ "Mémorable"
      assert html =~ "Ma note :"
      assert html =~ "4</strong>/5"
      # stats: 1 soirée, 1 jeu distinct, moyenne 4.0
      assert html =~ "history-stats"
    end

    test "cancelled soirees do not appear in the history", %{conn: conn, user: user} do
      host = user_fixture()
      host_scope = SoireePlateau.Accounts.Scope.for_user(host)
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "Annulée silencieusement",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [user.id]
        })

      respond_to_my_invitation(user, soiree, :yes)
      {:ok, _} = Teuf.cancel_soiree(host_scope, soiree)

      {:ok, _live, html} = live(conn, ~p"/users/historique")
      refute html =~ "Annulée silencieusement"
    end
  end
end
