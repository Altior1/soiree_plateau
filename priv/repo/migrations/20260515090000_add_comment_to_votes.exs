defmodule SoireePlateau.Repo.Migrations.AddCommentToVotes do
  use Ecto.Migration

  def change do
    alter table(:votes) do
      add :comment, :string, size: 500
    end
  end
end
