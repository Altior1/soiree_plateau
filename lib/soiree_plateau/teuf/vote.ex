defmodule SoireePlateau.Teuf.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @comment_max_length 500

  schema "votes" do
    field :rating, :integer
    field :comment, :string

    belongs_to :user, SoireePlateau.Accounts.User
    belongs_to :soiree, SoireePlateau.Teuf.Soiree
    belongs_to :game, SoireePlateau.Games.Game

    timestamps(type: :utc_datetime)
  end

  def comment_max_length, do: @comment_max_length

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:rating, :comment, :user_id, :soiree_id, :game_id])
    |> validate_required([:rating, :user_id, :soiree_id, :game_id])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> update_change(:comment, &normalize_comment/1)
    |> validate_length(:comment, max: @comment_max_length)
    |> unique_constraint([:user_id, :soiree_id, :game_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:soiree)
    |> assoc_constraint(:game)
  end

  defp normalize_comment(nil), do: nil

  defp normalize_comment(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_comment(value), do: value
end
