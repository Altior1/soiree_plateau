defmodule SoireePlateau.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    field :description, :string
    field :image_url, :string
    field :nb_players_min, :integer
    field :nb_players_max, :integer
    # durée en minutes
    field :duration, :integer
    # de 1 à 5
    field :complexity, :integer

    has_many :soirees, SoireePlateau.Teuf.Soiree

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :name,
      :description,
      :image_url,
      :nb_players_min,
      :nb_players_max,
      :duration,
      :complexity
    ])
    |> validate_required([
      :name,
      :description,
      :nb_players_min,
      :nb_players_max,
      :duration,
      :complexity
    ])
    |> validate_number(:nb_players_min, greater_than: 0)
    |> validate_number(:nb_players_max, greater_than: 0)
    |> validate_number(:duration, greater_than: 0)
    |> validate_number(:complexity, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_nb_players()
  end

  defp validate_nb_players(changeset) do
    nb_players_min = get_field(changeset, :nb_players_min)
    nb_players_max = get_field(changeset, :nb_players_max)

    if nb_players_min && nb_players_max && nb_players_min > nb_players_max do
      add_error(
        changeset,
        :nb_players_min,
        "must be less than or equal to maximum number of players"
      )
    else
      changeset
    end
  end
end
