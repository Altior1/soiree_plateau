defmodule SoireePlateau.Teuf.Soiree do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:active, :cancelled]

  schema "soirees" do
    field :title, :string
    field :date, :naive_datetime
    field :home, :string
    field :capacity, :integer
    field :status, Ecto.Enum, values: @statuses, default: :active
    belongs_to :user, SoireePlateau.Accounts.User, foreign_key: :host
    belongs_to :game, SoireePlateau.Games.Game

    has_many :invitations, SoireePlateau.Teuf.Invitation, on_delete: :delete_all
    has_many :invitees, through: [:invitations, :user]
    has_many :votes, SoireePlateau.Teuf.Vote, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(soiree, attrs, user_scope) do
    soiree
    |> cast(attrs, [:title, :date, :home, :capacity])
    |> validate_required([:title, :date, :home, :capacity])
    |> validate_game_exists()
    |> validate_number(:capacity, greater_than: 0)
    |> assoc_constraint(:game)
    |> foreign_key_constraint(:host)
    |> put_change(:host, user_scope.user.id)
    |> put_change(:game_id, attrs[:game_id])
  end

  @doc """
  Changeset used only to transition the soiree to `:cancelled`.

  Refuses to transition an already cancelled soiree (irréversible).
  """
  def cancel_changeset(soiree) do
    soiree
    |> change(%{status: :cancelled})
    |> validate_not_already_cancelled()
  end

  defp validate_not_already_cancelled(changeset) do
    if changeset.data.status == :cancelled do
      add_error(changeset, :status, "soiree is already cancelled")
    else
      changeset
    end
  end

  defp validate_game_exists(changeset) do
    game_id = get_field(changeset, :game_id)

    if game_id && !SoireePlateau.Games.get_game(game_id) do
      add_error(changeset, :game_id, "must reference an existing game")
    else
      changeset
    end
  end
end
