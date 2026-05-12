defmodule SoireePlateau.Teuf do
  @moduledoc """
  The Teuf context.
  """

  import Ecto.Query, warn: false
  alias SoireePlateau.Repo

  alias SoireePlateau.Teuf.Soiree
  alias SoireePlateau.Accounts.Scope

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
  Creates a soiree.

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
end
