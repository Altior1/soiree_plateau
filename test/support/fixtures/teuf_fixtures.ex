defmodule SoireePlateau.TeufFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SoireePlateau.Teuf` context.
  """

  @doc """
  Generate a soiree.
  """
  def soiree_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        capacity: 42,
        date: ~N[2026-05-11 13:00:00],
        home: "some home",
        title: "some title"
      })

    case SoireePlateau.Teuf.create_soiree(scope, attrs) do
      {:ok, soiree} ->
        soiree

      {:error, changeset} ->
        raise "Failed to create soiree fixture: #{inspect(changeset.errors)}"
    end
  end
end
