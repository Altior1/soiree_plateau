defmodule SoireePlateauWeb.UserLive.Home do
  use SoireePlateauWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="relative overflow-hidden bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800">
        <div class="mx-auto max-w-7xl px-4 py-24 sm:px-6 lg:flex lg:items-center lg:gap-12 lg:px-8">
          <div class="mx-auto max-w-2xl lg:mx-0 lg:flex-1">
            <h1 class="text-3xl font-extrabold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
              Soirées jeux de société — Partagez, jouez, créez des souvenirs
            </h1>
            <p class="mt-6 text-lg leading-8 text-gray-600 dark:text-gray-300">
              Rejoignez des soirées thématiques, trouvez des joueurs et réservez votre place en quelques clics.
            </p>
            <div class="mt-8 flex max-w-md gap-3">
              <.link
                href={~p"/users/register"}
                class="inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700"
              >
                S'inscrire
              </.link>
              <.link
                href={~p"/users/log-in"}
                class="inline-flex items-center justify-center rounded-md bg-gray-600 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700"
              >
                Se connecter
              </.link>
            </div>
          </div>

          <div class="hidden lg:block lg:flex-1">
            <div class="ml-10 w-full max-w-md rounded-lg bg-white/60 p-8 shadow-lg dark:bg-gray-800/60">
              <h3 class="text-lg font-semibold text-gray-800 dark:text-white">Événement à la une</h3>
              <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                Soirée «Mystères & stratégies» — places limitées.
              </p>
              <div class="mt-4">
                <.link href={~p"/soirees"} class="text-sm font-medium text-blue-600 hover:underline">
                  Voir les soirées
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
