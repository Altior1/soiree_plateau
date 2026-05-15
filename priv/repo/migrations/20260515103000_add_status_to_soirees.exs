defmodule SoireePlateau.Repo.Migrations.AddStatusToSoirees do
  use Ecto.Migration

  def change do
    alter table(:soirees) do
      add :status, :string, null: false, default: "active"
    end

    create index(:soirees, [:status])
  end
end
