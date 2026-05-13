defmodule SoireePlateau.Teuf.Invitation do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:pending, :yes, :no, :maybe]

  schema "invitations" do
    field :status, Ecto.Enum, values: @statuses, default: :pending

    belongs_to :soiree, SoireePlateau.Teuf.Soiree
    belongs_to :user, SoireePlateau.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:status, :soiree_id, :user_id])
    |> validate_required([:status, :soiree_id, :user_id])
    |> unique_constraint([:soiree_id, :user_id])
    |> assoc_constraint(:soiree)
    |> assoc_constraint(:user)
  end

  @doc false
  def response_changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, [:yes, :no, :maybe])
  end
end
