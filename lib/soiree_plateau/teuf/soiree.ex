defmodule SoireePlateau.Teuf.Soiree do
  use Ecto.Schema
  import Ecto.Changeset

  schema "soirees" do
    field :title, :string
    field :date, :naive_datetime
    field :home, :string
    field :capacity, :integer
    belongs_to :user, SoireePlateau.Accounts.User, foreign_key: :host
    belongs_to :game, SoireePlateau.Games.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(soiree, attrs, user_scope) do
    soiree
    |> cast(attrs, [:title, :date, :home, :capacity, :game_id])
    |> validate_required([:title, :date, :home, :capacity])
    |> validate_game_exists()
    |> validate_number(:capacity, greater_than: 0)
    |> assoc_constraint(:game)
    |> foreign_key_constraint(:host)
    |> put_change(:host, user_scope.user.id)
    |> put_change(:game_id, attrs[:game_id])
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
