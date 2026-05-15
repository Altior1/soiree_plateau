defmodule SoireePlateauWeb.UserLive.History do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Mon historique
        <:subtitle>Les soirées auxquelles tu as participé et les notes que tu as données.</:subtitle>
      </.header>

      <section
        id="history-stats"
        class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-3"
      >
        <div class="rounded-lg border bg-white/60 p-4 shadow-sm">
          <div class="text-xs uppercase tracking-wide text-base-content/60">Soirées</div>
          <div class="mt-1 text-2xl font-semibold">{@stats.soirees_count}</div>
        </div>
        <div class="rounded-lg border bg-white/60 p-4 shadow-sm">
          <div class="text-xs uppercase tracking-wide text-base-content/60">Jeux différents</div>
          <div class="mt-1 text-2xl font-semibold">{@stats.distinct_games}</div>
        </div>
        <div class="rounded-lg border bg-white/60 p-4 shadow-sm">
          <div class="text-xs uppercase tracking-wide text-base-content/60">Note moyenne donnée</div>
          <div class="mt-1 text-2xl font-semibold">
            {format_average(@stats.average_rating)}
          </div>
        </div>
      </section>

      <section id="history-list" class="mt-10">
        <%= if @history == [] do %>
          <div class="rounded-lg border-2 border-dashed p-8 text-center text-base-content/70">
            <p class="text-sm">
              Tu n'as encore participé à aucune soirée passée.
              Réponds <strong>"oui"</strong> à une invitation pour la voir apparaître ici après la soirée.
            </p>
          </div>
        <% else %>
          <ul class="space-y-4">
            <li
              :for={soiree <- @history}
              id={"history-#{soiree.id}"}
              class="rounded-lg border bg-white/60 p-4 shadow-sm"
            >
              <header class="flex flex-wrap items-start justify-between gap-2">
                <div>
                  <.link
                    navigate={~p"/users/soirees/#{soiree.id}"}
                    class="text-base font-semibold hover:underline"
                  >
                    {soiree.title}
                  </.link>
                  <p class="text-sm text-base-content/70">
                    {format_date(soiree.date)} · {soiree.home}
                  </p>
                  <p class="text-xs text-base-content/60 mt-1">
                    Hôte : {soiree.user.email}
                  </p>
                </div>
                <div :if={soiree.game} class="text-right">
                  <p class="text-xs uppercase tracking-wide text-base-content/60">Jeu</p>
                  <p class="text-sm font-medium">{soiree.game.name}</p>
                </div>
              </header>

              <div class="mt-3 text-sm">
                <%= case soiree.my_vote do %>
                  <% nil -> %>
                    <span class="text-base-content/60">Non notée.</span>
                    <.link
                      navigate={~p"/users/soirees/#{soiree.id}"}
                      class="ml-1 text-primary hover:underline"
                    >
                      Noter maintenant →
                    </.link>
                  <% vote -> %>
                    <span>Ma note : <strong>{vote.rating}</strong>/5</span>
                    <p :if={vote.comment} class="mt-1 italic text-base-content/80">
                      "{vote.comment}"
                    </p>
                <% end %>
              </div>
            </li>
          </ul>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:page_title, "Mon historique")
     |> assign(:history, Teuf.list_user_history(scope))
     |> assign(:stats, Teuf.user_history_stats(scope))}
  end

  defp format_date(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  defp format_date(other), do: to_string(other)

  defp format_average(nil), do: "—"

  defp format_average(%Decimal{} = d),
    do: (d |> Decimal.round(1) |> Decimal.to_string()) <> " / 5"

  defp format_average(n) when is_float(n),
    do: :erlang.float_to_binary(n, decimals: 1) <> " / 5"

  defp format_average(n), do: to_string(n) <> " / 5"
end
