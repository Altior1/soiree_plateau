defmodule SoireePlateauWeb.InvitationLiveTest do
  use SoireePlateauWeb.ConnCase

  import Phoenix.LiveViewTest
  import SoireePlateau.AccountsFixtures

  alias SoireePlateau.Teuf

  setup :register_and_log_in_user

  defp create_pending_invitation(%{user: user}) do
    host = user_fixture()
    host_scope = SoireePlateau.Accounts.Scope.for_user(host)

    {:ok, soiree} =
      Teuf.create_soiree(host_scope, %{
        title: "Soirée test",
        date: ~N[2026-06-01 20:00:00],
        home: "chez Thomas",
        capacity: 5,
        invitee_ids: [user.id]
      })

    %{host: host, host_scope: host_scope, soiree: soiree}
  end

  describe "Index" do
    setup [:create_pending_invitation]

    test "lists pending invitations", %{conn: conn, soiree: soiree} do
      {:ok, _live, html} = live(conn, ~p"/users/invitations")
      assert html =~ "Mes invitations"
      assert html =~ soiree.title
      assert html =~ "En attente"
    end

    test "responding updates the status", %{
      conn: conn,
      scope: scope,
      soiree: soiree,
      host_scope: host_scope
    } do
      {:ok, live, _html} = live(conn, ~p"/users/invitations")

      [invitation] = Teuf.list_invitations_for_user(scope)

      assert live
             |> element("#invitation-#{invitation.id} button", "Oui")
             |> render_click() =~ "Réponse enregistrée"

      [updated] =
        host_scope
        |> Teuf.list_invitations_for_soiree(soiree)
        |> Enum.filter(&(&1.user_id == scope.user.id))

      assert updated.status == :yes
    end

    test "shows empty state when no invitation is received" do
      other = user_fixture()
      other_conn = log_in_user(Phoenix.ConnTest.build_conn(), other)
      {:ok, _live, html} = live(other_conn, ~p"/users/invitations")
      assert html =~ "Aucune invitation"
    end

    test "an invalid status from the UI shows an error flash", %{
      conn: conn,
      scope: scope
    } do
      {:ok, live, _html} = live(conn, ~p"/users/invitations")
      [invitation] = Teuf.list_invitations_for_user(scope)

      result =
        render_hook(live, "respond", %{
          "id" => to_string(invitation.id),
          "status" => "garbage"
        })

      assert result =~ "Statut invalide"
    end

    test "live update via PubSub when another user invites the current user", %{
      conn: conn,
      user: user
    } do
      {:ok, live, _html} = live(conn, ~p"/users/invitations")
      initial = render(live)

      other_host = user_fixture()
      other_host_scope = SoireePlateau.Accounts.Scope.for_user(other_host)

      {:ok, _soiree} =
        Teuf.create_soiree(other_host_scope, %{
          title: "Surprise party",
          date: ~N[2026-12-31 22:00:00],
          home: "secret",
          capacity: 5,
          invitee_ids: [user.id]
        })

      updated = render(live)
      refute initial =~ "Surprise party"
      assert updated =~ "Surprise party"
    end

    test "shows the link to view the soiree", %{conn: conn, soiree: soiree} do
      {:ok, _live, html} = live(conn, ~p"/users/invitations")
      assert html =~ "Voir la soirée"
      assert html =~ "/users/soirees/#{soiree.id}"
    end
  end
end
