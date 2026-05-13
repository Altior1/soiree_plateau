defmodule SoireePlateau.Teuf do
  @moduledoc """
  The Teuf context.
  """

  import Ecto.Query, warn: false
  alias SoireePlateau.Repo

  alias SoireePlateau.Teuf.{Soiree, Invitation}
  alias SoireePlateau.Accounts.{Scope, User}

  @doc """
  Subscribes to scoped notifications about any soiree changes.

  The broadcasted messages match the pattern:

    * {:created, %Soiree{}}
    * {:updated, %Soiree{}}
    * {:deleted, %Soiree{}}

  """
  def subscribe_soirees(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(SoireePlateau.PubSub, "user:#{key}:soirees")
  end

  @doc """
  Subscribes to invitation changes for a given soiree (host-side live updates).

  Broadcasted messages:

    * {:invitation_updated, %Invitation{}}
    * {:invitations_changed, soiree_id}
  """
  def subscribe_soiree_invitations(soiree_id) when is_integer(soiree_id) do
    Phoenix.PubSub.subscribe(SoireePlateau.PubSub, "soiree:#{soiree_id}:invitations")
  end

  @doc """
  Subscribes to invitation changes for the current user (invitee-side live updates).

  Broadcasted messages:

    * {:invitation_created, %Invitation{}}
    * {:invitation_updated, %Invitation{}}
    * {:invitation_deleted, %Invitation{}}
  """
  def subscribe_user_invitations(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(SoireePlateau.PubSub, "user:#{key}:invitations")
  end

  require Logger

  defp broadcast_soiree(%Scope{} = scope, message) do
    key = scope.user.id

    case Phoenix.PubSub.broadcast(SoireePlateau.PubSub, "user:#{key}:soirees", message) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Failed to broadcast soiree event: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp broadcast_invitation_to_soiree(soiree_id, message) do
    Phoenix.PubSub.broadcast(
      SoireePlateau.PubSub,
      "soiree:#{soiree_id}:invitations",
      message
    )
  end

  defp broadcast_invitation_to_user(user_id, message) do
    Phoenix.PubSub.broadcast(
      SoireePlateau.PubSub,
      "user:#{user_id}:invitations",
      message
    )
  end

  @doc """
  Returns the list of soirees.

  ## Examples

      iex> list_soirees(scope)
      [%Soiree{}, ...]

  """
  def list_soirees(%Scope{} = scope) do
    Repo.all_by(Soiree, host: scope.user.id)
  end

  @doc """
  Gets a single soiree.

  Raises `Ecto.NoResultsError` if the Soiree does not exist.

  ## Examples

      iex> get_soiree!(scope, 123)
      %Soiree{}

      iex> get_soiree!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_soiree!(%Scope{} = scope, id) do
    Repo.get_by!(Soiree, id: id, host: scope.user.id)
  end

  @doc """
  Creates a soiree. The host is automatically added as a confirmed invitee.

  ## Examples

      iex> create_soiree(scope, %{field: value})
      {:ok, %Soiree{}}

      iex> create_soiree(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_soiree(%Scope{} = scope, attrs) do
    with {:ok, soiree = %Soiree{}} <-
           %Soiree{}
           |> Soiree.changeset(attrs, scope)
           |> Repo.insert() do
      # The host is always an invitee with status :yes
      ensure_host_invitation(soiree)
      sync_invitees(scope, soiree, extract_invitee_ids(attrs))
      broadcast_soiree(scope, {:created, soiree})
      {:ok, soiree}
    end
  end

  @doc """
  Updates a soiree.

  ## Examples

      iex> update_soiree(scope, soiree, %{field: new_value})
      {:ok, %Soiree{}}

      iex> update_soiree(scope, soiree, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_soiree(%Scope{} = scope, %Soiree{} = soiree, attrs) do
    true = soiree.host == scope.user.id

    with {:ok, soiree = %Soiree{}} <-
           soiree
           |> Soiree.changeset(attrs, scope)
           |> Repo.update() do
      ensure_host_invitation(soiree)
      sync_invitees(scope, soiree, extract_invitee_ids(attrs))
      broadcast_soiree(scope, {:updated, soiree})
      {:ok, soiree}
    end
  end

  @doc """
  Deletes a soiree.

  ## Examples

      iex> delete_soiree(scope, soiree)
      {:ok, %Soiree{}}

      iex> delete_soiree(scope, soiree)
      {:error, %Ecto.Changeset{}}

  """
  def delete_soiree(%Scope{} = scope, %Soiree{} = soiree) do
    true = soiree.host == scope.user.id

    with {:ok, soiree = %Soiree{}} <-
           Repo.delete(soiree) do
      broadcast_soiree(scope, {:deleted, soiree})
      {:ok, soiree}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking soiree changes.

  ## Examples

      iex> change_soiree(scope, soiree)
      %Ecto.Changeset{data: %Soiree{}}

  """
  def change_soiree(%Scope{} = scope, %Soiree{} = soiree, attrs \\ %{}) do
    true = soiree.host == scope.user.id

    Soiree.changeset(soiree, attrs, scope)
  end

  ## Invitations

  @doc """
  Returns users selectable as invitees for a form (everyone except the host).

  ## Examples

      iex> list_users_for_invitation(scope)
      [{"alice@example.com", 1}, ...]
  """
  def list_users_for_invitation(%Scope{} = scope) do
    host_id = scope.user.id

    Repo.all(
      from u in User,
        where: u.id != ^host_id,
        order_by: u.email,
        select: {u.email, u.id}
    )
  end

  @doc """
  Returns the list of user_ids currently invited to the given soiree
  (host excluded).
  """
  def list_invitee_ids(%Soiree{} = soiree) do
    host_id = soiree.host

    Repo.all(
      from i in Invitation,
        where: i.soiree_id == ^soiree.id and i.user_id != ^host_id,
        select: i.user_id
    )
  end

  @doc """
  Returns the list of invitations for the given soiree, with the user preloaded.
  Only callable by the host.
  """
  def list_invitations_for_soiree(%Scope{} = scope, %Soiree{} = soiree) do
    true = soiree.host == scope.user.id

    Repo.all(
      from i in Invitation,
        where: i.soiree_id == ^soiree.id,
        join: u in assoc(i, :user),
        order_by: u.email,
        preload: [user: u]
    )
  end

  @doc """
  Returns the list of invitations received by the current user (with soiree preloaded).
  Pending invitations come first, then sorted by soiree date.
  """
  def list_invitations_for_user(%Scope{} = scope) do
    user_id = scope.user.id

    Repo.all(
      from i in Invitation,
        where: i.user_id == ^user_id,
        join: s in assoc(i, :soiree),
        order_by: [
          asc: fragment("CASE WHEN ? = 'pending' THEN 0 ELSE 1 END", i.status),
          asc: s.date
        ],
        preload: [soiree: {s, [:user, :game]}]
    )
  end

  @doc """
  Fetches the invitation for the current user. Raises if not found.
  """
  def get_user_invitation!(%Scope{} = scope, invitation_id) do
    user_id = scope.user.id

    Repo.one!(
      from i in Invitation,
        where: i.id == ^invitation_id and i.user_id == ^user_id,
        join: s in assoc(i, :soiree),
        preload: [soiree: {s, [:user, :game]}]
    )
  end

  @doc """
  Records the invitee's response (`:yes`, `:no`, or `:maybe`) on an invitation.
  Only the invitee can respond to their own invitation.
  """
  def respond_to_invitation(%Scope{} = scope, %Invitation{} = invitation, status) do
    true = invitation.user_id == scope.user.id

    with {:ok, updated} <-
           invitation
           |> Invitation.response_changeset(%{status: status})
           |> Repo.update() do
      updated = Repo.preload(updated, [:user, soiree: [:user, :game]])
      broadcast_invitation_to_soiree(updated.soiree_id, {:invitation_updated, updated})
      broadcast_invitation_to_user(updated.user_id, {:invitation_updated, updated})
      {:ok, updated}
    end
  end

  @doc """
  Removes an invitation. Only the host can remove it. The host can't remove themselves.
  """
  def remove_invitation(%Scope{} = scope, %Invitation{} = invitation) do
    soiree = Repo.get!(Soiree, invitation.soiree_id)
    true = soiree.host == scope.user.id
    true = invitation.user_id != soiree.host

    with {:ok, deleted} <- Repo.delete(invitation) do
      broadcast_invitation_to_soiree(deleted.soiree_id, {:invitation_deleted, deleted})
      broadcast_invitation_to_user(deleted.user_id, {:invitation_deleted, deleted})
      {:ok, deleted}
    end
  end

  defp ensure_host_invitation(%Soiree{} = soiree) do
    case Repo.get_by(Invitation, soiree_id: soiree.id, user_id: soiree.host) do
      nil ->
        %Invitation{}
        |> Invitation.changeset(%{
          soiree_id: soiree.id,
          user_id: soiree.host,
          status: :yes
        })
        |> Repo.insert!()

      %Invitation{} = inv ->
        inv
    end
  end

  defp sync_invitees(%Scope{} = _scope, %Soiree{} = soiree, desired_ids) do
    desired = desired_ids |> Enum.uniq() |> Enum.reject(&(&1 == soiree.host))
    existing = list_invitee_ids(soiree)

    to_add = desired -- existing
    to_remove = existing -- desired

    Enum.each(to_add, fn user_id ->
      case %Invitation{}
           |> Invitation.changeset(%{
             soiree_id: soiree.id,
             user_id: user_id,
             status: :pending
           })
           |> Repo.insert() do
        {:ok, inv} ->
          inv = Repo.preload(inv, [:user, soiree: [:user, :game]])
          broadcast_invitation_to_user(user_id, {:invitation_created, inv})
          broadcast_invitation_to_soiree(soiree.id, {:invitation_created, inv})

        {:error, _} ->
          :noop
      end
    end)

    Enum.each(to_remove, fn user_id ->
      case Repo.get_by(Invitation, soiree_id: soiree.id, user_id: user_id) do
        nil ->
          :noop

        %Invitation{} = inv ->
          {:ok, deleted} = Repo.delete(inv)
          broadcast_invitation_to_user(user_id, {:invitation_deleted, deleted})
          broadcast_invitation_to_soiree(soiree.id, {:invitation_deleted, deleted})
      end
    end)

    :ok
  end

  defp extract_invitee_ids(attrs) do
    raw = attrs["invitee_ids"] || attrs[:invitee_ids] || []

    raw
    |> List.wrap()
    |> Enum.map(&parse_id/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_id(nil), do: nil
  defp parse_id(""), do: nil
  defp parse_id(id) when is_integer(id), do: id

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, _} -> int
      :error -> nil
    end
  end
end
