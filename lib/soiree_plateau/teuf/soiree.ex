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
    |> cast(attrs, [:title, :date, :home, :capacity])
    |> validate_required([:title, :date, :home, :capacity])
    |> put_change(:host, user_scope.user.id)
  end
end
