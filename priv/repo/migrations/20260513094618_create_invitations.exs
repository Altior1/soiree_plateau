defmodule SoireePlateau.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add :status, :string, null: false, default: "pending"
      add :soiree_id, references(:soirees, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invitations, [:soiree_id])
    create index(:invitations, [:user_id])
    create unique_index(:invitations, [:soiree_id, :user_id])
  end
end
