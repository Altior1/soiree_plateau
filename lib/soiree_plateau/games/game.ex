defmodule SoireePlateau.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :description, :string
    field :image_url, :string
    field :nb_players_min, :integer
    field :nb_players_max, :integer
    field :duration, :integer # durée en minutes
    field :complexity, :integer # de 1 à 5

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
