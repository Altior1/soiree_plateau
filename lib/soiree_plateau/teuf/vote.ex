defmodule SoireePlateau.Teuf.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :rating, :integer

    belongs_to :user, SoireePlateau.Accounts.User
    belongs_to :soiree, SoireePlateau.Teuf.Soiree
    belongs_to :game, SoireePlateau.Games.Game

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:rating, :user_id, :soiree_id, :game_id])
    |> validate_required([:rating, :user_id, :soiree_id, :game_id])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> unique_constraint([:user_id, :soiree_id, :game_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:soiree)
    |> assoc_constraint(:game)
  end
end
