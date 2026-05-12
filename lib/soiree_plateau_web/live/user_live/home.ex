defmodule SoireePlateauWeb.UserLive.Home do
  use SoireePlateauWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-screen items-center justify-center gap-6 bg-gray-50 dark:bg-gray-900">
        <div class="w-full rounded-lg bg-white p-8 shadow-lg md:w-1/2 lg:w-1/3">
          <h2 class="mb-6 text-center text-2xl font-bold text-gray-800">
            Bienvenue sur le site Soiree Plateau!
          </h2>
          <p class="mb-4 text-center text-gray-600">
            Découvrez nos soirées à thème et réservez votre place dès maintenant.
          </p>
          <div class="flex flex-col items-center gap-4">
            <a
              href="/users/register"
              class="w-full rounded bg-blue-600 px-4 py-2 text-center text-white hover:bg-blue-700"
            >
              S'inscrire
            </a>
            <a
              href="/users/log-in"
              class="w-full rounded bg-gray-600 px-4 py-2 text-center text-white hover:bg-gray-700"
            >
              Se connecter
            </a>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
