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

  describe "invitations" do
    alias SoireePlateau.Teuf.Invitation

    import SoireePlateau.AccountsFixtures
    import SoireePlateau.TeufFixtures

    test "create_soiree/2 inserts a :yes invitation for the host" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      invitations = Teuf.list_invitations_for_soiree(scope, soiree)
      assert [%Invitation{user_id: host_id, status: :yes}] = invitations
      assert host_id == scope.user.id
    end

    test "create_soiree/2 adds pending invitations for selected invitees" do
      scope = user_scope_fixture()
      guest = user_fixture()
      attrs = %{title: "t", date: ~N[2026-06-01 20:00:00], home: "h", capacity: 5}
      attrs = Map.put(attrs, :invitee_ids, [guest.id])

      {:ok, soiree} = Teuf.create_soiree(scope, attrs)
      invitations = Teuf.list_invitations_for_soiree(scope, soiree)

      statuses_by_user = Map.new(invitations, &{&1.user_id, &1.status})
      assert statuses_by_user[scope.user.id] == :yes
      assert statuses_by_user[guest.id] == :pending
    end

    test "create_soiree/2 ignores the host in invitee_ids" do
      scope = user_scope_fixture()
      attrs = %{title: "t", date: ~N[2026-06-01 20:00:00], home: "h", capacity: 5}
      attrs = Map.put(attrs, :invitee_ids, [scope.user.id])

      {:ok, soiree} = Teuf.create_soiree(scope, attrs)
      assert Teuf.list_invitee_ids(soiree) == []
    end

    test "update_soiree/3 adds new invitees and removes deselected ones" do
      scope = user_scope_fixture()
      kept = user_fixture()
      removed = user_fixture()
      added = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [kept.id, removed.id]
        })

      assert Enum.sort(Teuf.list_invitee_ids(soiree)) == Enum.sort([kept.id, removed.id])

      {:ok, _} =
        Teuf.update_soiree(scope, soiree, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [kept.id, added.id]
        })

      assert Enum.sort(Teuf.list_invitee_ids(soiree)) == Enum.sort([kept.id, added.id])
    end

    test "list_invitations_for_user/1 returns invitations for the invitee" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = user_scope_fixture(guest)

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "Soirée jeux",
          date: ~N[2026-06-01 20:00:00],
          home: "chez moi",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      assert [invitation] = Teuf.list_invitations_for_user(guest_scope)
      assert invitation.soiree_id == soiree.id
      assert invitation.status == :pending
      assert invitation.soiree.title == "Soirée jeux"
    end

    test "respond_to_invitation/3 updates status and broadcasts" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = user_scope_fixture(guest)

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)

      Teuf.subscribe_soiree_invitations(soiree.id)

      assert {:ok, updated} = Teuf.respond_to_invitation(guest_scope, invitation, :yes)
      assert updated.status == :yes
      assert_receive {:invitation_updated, %Invitation{status: :yes}}
    end

    test "respond_to_invitation/3 rejects setting status back to :pending" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = user_scope_fixture(guest)

      {:ok, _soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, invitation} = Teuf.respond_to_invitation(guest_scope, invitation, :yes)

      assert {:error, %Ecto.Changeset{}} =
               Teuf.respond_to_invitation(guest_scope, invitation, :pending)
    end

    test "respond_to_invitation/3 refuses if not the invitee" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      intruder_scope = user_scope_fixture()

      {:ok, _soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      guest_scope = user_scope_fixture(guest)
      [invitation] = Teuf.list_invitations_for_user(guest_scope)

      assert_raise MatchError, fn ->
        Teuf.respond_to_invitation(intruder_scope, invitation, :yes)
      end
    end

    test "remove_invitation/2 refuses to remove the host" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      [host_invitation] = Teuf.list_invitations_for_soiree(scope, soiree)

      assert_raise MatchError, fn ->
        Teuf.remove_invitation(scope, host_invitation)
      end
    end

    test "remove_invitation/2 deletes a guest invitation" do
      host_scope = user_scope_fixture()
      guest = user_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      [invitation] =
        host_scope
        |> Teuf.list_invitations_for_soiree(soiree)
        |> Enum.filter(&(&1.user_id == guest.id))

      assert {:ok, _} = Teuf.remove_invitation(host_scope, invitation)
      assert Teuf.list_invitee_ids(soiree) == []
    end

    test "remove_invitation/2 refuses if scope is not host" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      other_scope = user_scope_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2026-06-01 20:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      [invitation] =
        host_scope
        |> Teuf.list_invitations_for_soiree(soiree)
        |> Enum.filter(&(&1.user_id == guest.id))

      assert_raise MatchError, fn ->
        Teuf.remove_invitation(other_scope, invitation)
      end
    end
  end

  defp past_soiree_with_guest(opts \\ []) do
    import SoireePlateau.AccountsFixtures

    host_scope = user_scope_fixture()
    guest = user_fixture()
    game = SoireePlateau.GamesFixtures.game_fixture()

    attrs = %{
      title: "passed",
      date: opts[:date] || ~N[2020-01-01 18:00:00],
      home: "h",
      capacity: 5,
      game_id: game.id,
      invitee_ids: [guest.id]
    }

    {:ok, soiree} = Teuf.create_soiree(host_scope, attrs)
    soiree = SoireePlateau.Repo.preload(soiree, :game)

    guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
    [invitation] = Teuf.list_invitations_for_user(guest_scope)
    {:ok, _} = Teuf.respond_to_invitation(guest_scope, invitation, :yes)

    %{host_scope: host_scope, guest: guest, guest_scope: guest_scope, soiree: soiree, game: game}
  end

  describe "votes" do
    alias SoireePlateau.Teuf.Vote

    import SoireePlateau.AccountsFixtures
    import SoireePlateau.TeufFixtures

    test "cast_vote/3 inserts a new vote" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      assert {:ok, %Vote{rating: 4}} =
               Teuf.cast_vote(scope, soiree, %{rating: 4, game_id: game.id})
    end

    test "cast_vote/3 updates an existing vote (upsert)" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      {:ok, %Vote{} = first} = Teuf.cast_vote(scope, soiree, %{rating: 2, game_id: game.id})

      {:ok, %Vote{} = updated} =
        Teuf.cast_vote(scope, soiree, %{rating: 5, game_id: game.id})

      assert first.id == updated.id
      assert updated.rating == 5
    end

    test "cast_vote/3 rejects a rating outside 1..5" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      assert {:error, %Ecto.Changeset{}} =
               Teuf.cast_vote(scope, soiree, %{rating: 6, game_id: game.id})

      assert {:error, %Ecto.Changeset{}} =
               Teuf.cast_vote(scope, soiree, %{rating: 0, game_id: game.id})
    end

    test "cast_vote/3 refuses if user is not a confirmed invitee" do
      host_scope = user_scope_fixture()
      stranger_scope = user_scope_fixture()
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id
        })

      assert {:error, :not_invited} =
               Teuf.cast_vote(stranger_scope, soiree, %{rating: 3, game_id: game.id})
    end

    test "cast_vote/3 refuses for an invitee who declined" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, _} = Teuf.respond_to_invitation(guest_scope, invitation, :no)

      assert {:error, :not_invited} =
               Teuf.cast_vote(guest_scope, soiree, %{rating: 3, game_id: game.id})
    end

    test "cast_vote/3 refuses before the soiree happens" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
      game = SoireePlateau.GamesFixtures.game_fixture()

      future = NaiveDateTime.utc_now() |> NaiveDateTime.add(7 * 24 * 3600, :second)

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "future",
          date: future,
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, _} = Teuf.respond_to_invitation(guest_scope, invitation, :yes)

      assert {:error, :soiree_not_finished} =
               Teuf.cast_vote(guest_scope, soiree, %{rating: 3, game_id: game.id})
    end

    test "cast_vote/3 refuses a game not linked to the soiree" do
      %{guest_scope: scope, soiree: soiree} = past_soiree_with_guest()
      other_game = SoireePlateau.GamesFixtures.game_fixture()

      assert {:error, :invalid_game} =
               Teuf.cast_vote(scope, soiree, %{rating: 3, game_id: other_game.id})
    end

    test "cast_vote/3 broadcasts the new vote" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      Teuf.subscribe_soiree_votes(soiree.id)

      assert {:ok, _vote} =
               Teuf.cast_vote(scope, soiree, %{rating: 3, game_id: game.id})

      assert_receive {:vote_cast, %Vote{rating: 3}}
    end

    test "get_user_vote/3 returns the user's existing vote" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()
      assert is_nil(Teuf.get_user_vote(scope, soiree, game.id))

      {:ok, _} = Teuf.cast_vote(scope, soiree, %{rating: 3, game_id: game.id})
      assert %Vote{rating: 3} = Teuf.get_user_vote(scope, soiree, game.id)
    end

    test "list_votes_for_soiree/2 is callable by host and confirmed invitees, refuses strangers" do
      %{host_scope: host_scope, guest_scope: guest_scope, soiree: soiree, game: game} =
        past_soiree_with_guest()

      {:ok, _} = Teuf.cast_vote(guest_scope, soiree, %{rating: 4, game_id: game.id})

      # Host can read
      assert [%Vote{rating: 4}] = Teuf.list_votes_for_soiree(host_scope, soiree)

      # Confirmed invitee can read too (US11 visibility rule)
      assert [%Vote{rating: 4}] = Teuf.list_votes_for_soiree(guest_scope, soiree)

      # A user who is not invited cannot read
      stranger_scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Teuf.list_votes_for_soiree(stranger_scope, soiree)
      end
    end

    test "can_view_votes?/2 reflects host or confirmed-invitee status" do
      %{host_scope: host_scope, guest_scope: guest_scope, soiree: soiree} =
        past_soiree_with_guest()

      stranger_scope = user_scope_fixture()

      assert Teuf.can_view_votes?(host_scope, soiree)
      assert Teuf.can_view_votes?(guest_scope, soiree)
      refute Teuf.can_view_votes?(stranger_scope, soiree)
    end

    test "cast_vote/3 stores an optional comment" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      assert {:ok, %Vote{rating: 4, comment: "Super soirée"}} =
               Teuf.cast_vote(scope, soiree, %{
                 rating: 4,
                 comment: "Super soirée",
                 game_id: game.id
               })
    end

    test "cast_vote/3 normalizes an empty / blank comment to nil" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      assert {:ok, %Vote{comment: nil}} =
               Teuf.cast_vote(scope, soiree, %{
                 rating: 4,
                 comment: "   ",
                 game_id: game.id
               })
    end

    test "cast_vote/3 rejects a comment longer than 500 chars" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()
      too_long = String.duplicate("a", 501)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Teuf.cast_vote(scope, soiree, %{
                 rating: 4,
                 comment: too_long,
                 game_id: game.id
               })

      assert Keyword.has_key?(errors, :comment)
    end

    test "cast_vote/3 updates the comment alongside the rating (upsert)" do
      %{guest_scope: scope, soiree: soiree, game: game} = past_soiree_with_guest()

      {:ok, %Vote{} = first} =
        Teuf.cast_vote(scope, soiree, %{rating: 3, comment: "first", game_id: game.id})

      {:ok, %Vote{} = second} =
        Teuf.cast_vote(scope, soiree, %{rating: 5, comment: "updated", game_id: game.id})

      assert first.id == second.id
      assert second.rating == 5
      assert second.comment == "updated"
    end

    test "vote_summary_for_soiree/1 aggregates ratings" do
      host_scope = user_scope_fixture()
      g1 = user_fixture()
      g2 = user_fixture()
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "p",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [g1.id, g2.id]
        })

      Enum.each([g1, g2], fn user ->
        scope = SoireePlateau.Accounts.Scope.for_user(user)
        [inv] = Teuf.list_invitations_for_user(scope)
        {:ok, _} = Teuf.respond_to_invitation(scope, inv, :yes)
      end)

      g1_scope = SoireePlateau.Accounts.Scope.for_user(g1)
      g2_scope = SoireePlateau.Accounts.Scope.for_user(g2)
      {:ok, _} = Teuf.cast_vote(g1_scope, soiree, %{rating: 4, game_id: game.id})
      {:ok, _} = Teuf.cast_vote(g2_scope, soiree, %{rating: 2, game_id: game.id})

      assert [%{game_id: gid, count: 2, average: avg}] =
               Teuf.vote_summary_for_soiree(soiree)

      assert gid == game.id
      assert Decimal.equal?(Decimal.round(avg, 1), Decimal.new("3.0"))
    end

    test "get_visible_soiree!/2 lets the host access their soiree" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)
      assert Teuf.get_visible_soiree!(scope, soiree.id).id == soiree.id
    end

    test "get_visible_soiree!/2 lets an invitee access the soiree" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "t",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          invitee_ids: [guest.id]
        })

      assert Teuf.get_visible_soiree!(guest_scope, soiree.id).id == soiree.id
    end

    test "get_visible_soiree!/2 raises for a stranger" do
      host_scope = user_scope_fixture()
      stranger_scope = user_scope_fixture()
      soiree = soiree_fixture(host_scope)

      assert_raise Ecto.NoResultsError, fn ->
        Teuf.get_visible_soiree!(stranger_scope, soiree.id)
      end
    end
  end

  describe "cancel_soiree" do
    alias SoireePlateau.Teuf.Soiree

    import SoireePlateau.AccountsFixtures
    import SoireePlateau.TeufFixtures

    test "host can cancel their own soiree" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      assert {:ok, %Soiree{status: :cancelled}} = Teuf.cancel_soiree(scope, soiree)
    end

    test "admin can cancel another user's soiree" do
      host_scope = user_scope_fixture()
      admin = admin_user_fixture()
      admin_scope = SoireePlateau.Accounts.Scope.for_user(admin)
      soiree = soiree_fixture(host_scope)

      assert {:ok, %Soiree{status: :cancelled}} = Teuf.cancel_soiree(admin_scope, soiree)
    end

    test "a non-host non-admin cannot cancel a soiree" do
      host_scope = user_scope_fixture()
      stranger_scope = user_scope_fixture()
      soiree = soiree_fixture(host_scope)

      assert {:error, :unauthorized} = Teuf.cancel_soiree(stranger_scope, soiree)
    end

    test "cancelling an already cancelled soiree returns :already_cancelled" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      {:ok, cancelled} = Teuf.cancel_soiree(scope, soiree)
      assert {:error, :already_cancelled} = Teuf.cancel_soiree(scope, cancelled)
    end

    test "respond_to_invitation refuses on a cancelled soiree" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "to be cancelled",
          date: NaiveDateTime.utc_now() |> NaiveDateTime.add(86_400, :second),
          home: "h",
          capacity: 5,
          game_id: SoireePlateau.GamesFixtures.game_fixture().id,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, _cancelled} = Teuf.cancel_soiree(host_scope, soiree)

      assert {:error, :soiree_cancelled} =
               Teuf.respond_to_invitation(guest_scope, invitation, :yes)
    end

    test "cast_vote refuses on a cancelled soiree" do
      host_scope = user_scope_fixture()
      guest = user_fixture()
      guest_scope = SoireePlateau.Accounts.Scope.for_user(guest)
      game = SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: "passed and cancelled",
          date: ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: [guest.id]
        })

      [invitation] = Teuf.list_invitations_for_user(guest_scope)
      {:ok, _} = Teuf.respond_to_invitation(guest_scope, invitation, :yes)
      {:ok, cancelled} = Teuf.cancel_soiree(host_scope, soiree)

      assert {:error, :soiree_cancelled} =
               Teuf.cast_vote(guest_scope, cancelled, %{rating: 4, game_id: game.id})
    end

    test "cancelled? reflects the soiree state" do
      scope = user_scope_fixture()
      soiree = soiree_fixture(scope)

      refute Teuf.cancelled?(soiree)
      {:ok, cancelled} = Teuf.cancel_soiree(scope, soiree)
      assert Teuf.cancelled?(cancelled)
    end
  end

  describe "user history (US12)" do
    import SoireePlateau.AccountsFixtures
    import SoireePlateau.TeufFixtures

    defp create_past_soiree_with(opts) do
      host_scope = opts[:host_scope] || user_scope_fixture()
      game = opts[:game] || SoireePlateau.GamesFixtures.game_fixture()

      {:ok, soiree} =
        Teuf.create_soiree(host_scope, %{
          title: opts[:title] || "passed",
          date: opts[:date] || ~N[2020-01-01 18:00:00],
          home: "h",
          capacity: 5,
          game_id: game.id,
          invitee_ids: Enum.map(opts[:invitees] || [], & &1.id)
        })

      {host_scope, soiree, game}
    end

    defp respond(user, soiree, status) do
      scope = SoireePlateau.Accounts.Scope.for_user(user)

      invitation =
        SoireePlateau.Repo.get_by!(SoireePlateau.Teuf.Invitation,
          user_id: user.id,
          soiree_id: soiree.id
        )

      {:ok, _} = Teuf.respond_to_invitation(scope, invitation, status)
      scope
    end

    test "list_user_history/1 only returns past, confirmed-yes, non-cancelled soirees" do
      user = user_fixture()

      # 1) past + yes + active → in
      {_h1, kept, _g1} = create_past_soiree_with(invitees: [user], title: "kept")
      respond(user, kept, :yes)

      # 2) past + yes + cancelled → out
      {host2, s2, _g2} =
        create_past_soiree_with(invitees: [user], title: "cancelled")

      respond(user, s2, :yes)
      {:ok, _} = Teuf.cancel_soiree(host2, s2)

      # 3) future + yes + active → out
      future = NaiveDateTime.utc_now() |> NaiveDateTime.add(86_400, :second)

      {_h, future_soiree, _} =
        create_past_soiree_with(invitees: [user], title: "future", date: future)

      respond(user, future_soiree, :yes)

      # 4) past + no + active → out
      {_h, no_soiree, _} = create_past_soiree_with(invitees: [user], title: "declined")
      respond(user, no_soiree, :no)

      # 5) past + maybe → out
      {_h, maybe_soiree, _} = create_past_soiree_with(invitees: [user], title: "maybe")
      respond(user, maybe_soiree, :maybe)

      # 6) past + pending (no response) → out
      _ = create_past_soiree_with(invitees: [user], title: "pending")

      # 7) soirée d'un autre user → out
      _ = create_past_soiree_with(title: "other")

      scope = SoireePlateau.Accounts.Scope.for_user(user)
      history = Teuf.list_user_history(scope)

      titles = Enum.map(history, & &1.title)
      assert titles == ["kept"]
    end

    test "list_user_history/1 attaches my_vote to each entry" do
      user = user_fixture()
      {_host_scope, soiree, game} = create_past_soiree_with(invitees: [user])
      scope = respond(user, soiree, :yes)
      {:ok, _} = Teuf.cast_vote(scope, soiree, %{rating: 4, comment: "fun", game_id: game.id})

      [entry] = Teuf.list_user_history(scope)
      assert entry.id == soiree.id
      assert entry.my_vote.rating == 4
      assert entry.my_vote.comment == "fun"
    end

    test "list_user_history/1 returns nil my_vote when the user did not rate" do
      user = user_fixture()
      {_, soiree, _} = create_past_soiree_with(invitees: [user])
      scope = respond(user, soiree, :yes)

      [entry] = Teuf.list_user_history(scope)
      assert is_nil(entry.my_vote)
    end

    test "list_user_history/1 returns [] for a user with no participation" do
      user = user_fixture()
      _ = create_past_soiree_with(title: "not for them")

      scope = SoireePlateau.Accounts.Scope.for_user(user)
      assert Teuf.list_user_history(scope) == []
    end

    test "user_history_stats/1 aggregates soirees, distinct games and average rating" do
      user = user_fixture()
      game_a = SoireePlateau.GamesFixtures.game_fixture()
      game_b = SoireePlateau.GamesFixtures.game_fixture(%{name: "another"})

      {_h, s1, _} = create_past_soiree_with(invitees: [user], game: game_a, title: "a1")
      scope = respond(user, s1, :yes)
      {_h, s2, _} = create_past_soiree_with(invitees: [user], game: game_a, title: "a2")
      respond(user, s2, :yes)
      {_h, s3, _} = create_past_soiree_with(invitees: [user], game: game_b, title: "b1")
      respond(user, s3, :yes)

      {:ok, _} = Teuf.cast_vote(scope, s1, %{rating: 5, game_id: game_a.id})
      {:ok, _} = Teuf.cast_vote(scope, s2, %{rating: 3, game_id: game_a.id})
      {:ok, _} = Teuf.cast_vote(scope, s3, %{rating: 4, game_id: game_b.id})

      stats = Teuf.user_history_stats(scope)
      assert stats.soirees_count == 3
      assert stats.distinct_games == 2

      # average = (5+3+4)/3 = 4.0
      assert Decimal.equal?(Decimal.round(stats.average_rating, 1), Decimal.new("4.0"))
    end

    test "user_history_stats/1 returns zeros and nil for an empty history" do
      user = user_fixture()
      scope = SoireePlateau.Accounts.Scope.for_user(user)
      stats = Teuf.user_history_stats(scope)

      assert stats.soirees_count == 0
      assert stats.distinct_games == 0
      assert is_nil(stats.average_rating)
    end
  end
end
