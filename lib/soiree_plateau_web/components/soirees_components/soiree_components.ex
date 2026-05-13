defmodule SoireePlateauWeb.Components.SoireeComponents do
  @moduledoc """
  Ce module contient le composant de carte pour le détails des soirées ainsi que
  la soirée à la une sur la page d'accueil.
  """
  use Phoenix.Component

  attr :soiree, :map, required: true, doc: "La soirée à afficher dans la carte"

  def soiree_card(assigns) do
    ~H"""
    <div class="mt-4 rounded-lg bg-white/60 p-6 shadow-lg dark:bg-gray-800/60">
      <div class="flex items-center gap-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-800 dark:text-white">{@soiree.title}</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">{@soiree.date} • {@soiree.home}</p>
          <p>Il y a de la place pour {@soiree.capacity} joueurs</p>
        </div>
      </div>
    </div>
    """
  end
end
