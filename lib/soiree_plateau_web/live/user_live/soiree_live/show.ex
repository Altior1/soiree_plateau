defmodule SoireePlateauWeb.SoireeLive.Show do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf
  alias SoireePlateau.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Soirée #{@soiree.id}
        <:subtitle>Fiche de la soirée depuis la base de données.</:subtitle>
        <:actions>
          <.button navigate={~p"/users/soirees"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            :if={@is_host}
            variant="primary"
            navigate={~p"/users/soirees/#{@soiree}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Modifier la soirée
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Titre">{@soiree.title}</:item>
        <:item title="Date">{@soiree.date}</:item>
        <:item title="Lieu">{@soiree.home}</:item>
        <:item title="Capacité">{@soiree.capacity}</:item>
        <:item :if={@soiree.game} title="Jeu">{@soiree.game.name}</:item>
      </.list>

      <section :if={@is_host} class="mt-10">
        <h2 class="text-lg font-semibold mb-3">Invités &amp; réponses</h2>
        <%= if @invitations == [] do %>
          <p class="text-sm text-base-content/70">
            Aucun invité pour le moment. Modifie la soirée pour en ajouter.
          </p>
        <% else %>
          <table id="rsvp-table" class="w-full text-sm">
            <thead class="text-left text-base-content/70">
              <tr>
                <th class="py-2">Invité</th>
                <th class="py-2">Statut</th>
                <th class="py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={inv <- @invitations} id={"rsvp-#{inv.id}"} class="border-t">
                <td class="py-2">
                  {inv.user.email}
                  <span :if={inv.user_id == @soiree.host} class="ml-1 text-xs text-base-content/60">
                    (hôte)
                  </span>
                </td>
                <td class="py-2">
                  <span class={[
                    "inline-block rounded-full px-2 py-0.5 text-xs",
                    status_badge(inv.status)
                  ]}>
                    {status_label(inv.status)}
                  </span>
                </td>
                <td class="py-2 text-right">
                  <.link
                    :if={inv.user_id != @soiree.host}
                    phx-click="remove_invitation"
                    phx-value-id={inv.id}
                    data-confirm="Retirer cet invité ?"
                    class="text-error hover:underline"
                  >
                    Retirer
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        <% end %>
      </section>

      <section :if={@can_vote} id="vote-block" class="mt-10">
        <h2 class="text-lg font-semibold mb-2">Noter le jeu</h2>
        <p class="text-sm text-base-content/70 mb-3">
          Donne une note de 1 à 5 à <strong>{@soiree.game.name}</strong>. Tu peux la modifier à tout moment.
        </p>
        <div class="flex flex-wrap items-center gap-2">
          <button
            :for={n <- 1..5}
            type="button"
            phx-click="rate"
            phx-value-rating={n}
            class={[
              "btn",
              if(@current_rating == n, do: "btn-primary", else: "btn-primary btn-soft")
            ]}
          >
            {n}
          </button>
          <span :if={@current_rating} class="ml-2 text-sm text-base-content/70">
            Ta note actuelle : {@current_rating}/5
          </span>
        </div>
      </section>

      <section :if={@is_host and @soiree.game} class="mt-10">
        <h2 class="text-lg font-semibold mb-2">Notes reçues</h2>
        <%= if @votes == [] do %>
          <p class="text-sm text-base-content/70">
            Aucune note pour l'instant.
            <%= if @soiree_past do %>
              Les invités peuvent voter dès maintenant.
            <% else %>
              Le vote sera ouvert après la soirée.
            <% end %>
          </p>
        <% else %>
          <p class="text-sm mb-3">
            Moyenne : <strong>{format_average(@vote_average)}</strong> / 5 ({@votes |> length()} note{plural(@votes)})
          </p>
          <ul id="votes" class="space-y-1 text-sm">
            <li :for={v <- @votes} id={"vote-#{v.id}"} class="flex justify-between border-b py-1">
              <span>{v.user.email}</span>
              <span><strong>{v.rating}</strong>/5</span>
            </li>
          </ul>
        <% end %>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope

    soiree =
      scope
      |> Teuf.get_visible_soiree!(id)
      |> Repo.preload([:game, :user])

    is_host = soiree.host == scope.user.id
    can_vote = not is_host and Teuf.confirmed_invitee?(scope, soiree) and Teuf.soiree_past?(soiree)
    soiree_past = Teuf.soiree_past?(soiree)

    if connected?(socket) do
      Teuf.subscribe_soirees(scope)

      if is_host do
        Teuf.subscribe_soiree_invitations(soiree.id)
        Teuf.subscribe_soiree_votes(soiree.id)
      end
    end

    current_rating =
      if can_vote and soiree.game_id do
        case Teuf.get_user_vote(scope, soiree, soiree.game_id) do
          nil -> nil
          vote -> vote.rating
        end
      end

    {:ok,
     socket
     |> assign(:page_title, "Détails de la soirée")
     |> assign(:soiree, soiree)
     |> assign(:is_host, is_host)
     |> assign(:can_vote, can_vote)
     |> assign(:soiree_past, soiree_past)
     |> assign(:current_rating, current_rating)
     |> assign(:invitations, host_invitations(scope, soiree, is_host))
     |> assign_votes(scope, soiree, is_host)}
  end

  @impl true
  def handle_event("remove_invitation", %{"id" => invitation_id}, socket) do
    soiree = socket.assigns.soiree

    invitation =
      Enum.find(socket.assigns.invitations, fn inv ->
        to_string(inv.id) == to_string(invitation_id)
      end)

    cond do
      is_nil(invitation) ->
        {:noreply, put_flash(socket, :error, "Invitation introuvable.")}

      invitation.user_id == soiree.host ->
        {:noreply, put_flash(socket, :error, "L'hôte ne peut pas être retiré.")}

      true ->
        case Teuf.remove_invitation(socket.assigns.current_scope, invitation) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Invité retiré.")
             |> assign(
               :invitations,
               Teuf.list_invitations_for_soiree(socket.assigns.current_scope, soiree)
             )}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Impossible de retirer l'invité.")}
        end
    end
  end

  def handle_event("rate", %{"rating" => rating}, socket) do
    scope = socket.assigns.current_scope
    soiree = socket.assigns.soiree

    case Teuf.cast_vote(scope, soiree, %{rating: rating, game_id: soiree.game_id}) do
      {:ok, vote} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note enregistrée.")
         |> assign(:current_rating, vote.rating)}

      {:error, :not_invited} ->
        {:noreply, put_flash(socket, :error, "Tu n'es pas invité à cette soirée.")}

      {:error, :soiree_not_finished} ->
        {:noreply,
         put_flash(socket, :error, "Le vote sera ouvert une fois la soirée terminée.")}

      {:error, :invalid_game} ->
        {:noreply, put_flash(socket, :error, "Ce jeu n'est pas associé à la soirée.")}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "Impossible d'enregistrer la note.")}
    end
  end

  @impl true
  def handle_info(
        {:updated, %SoireePlateau.Teuf.Soiree{id: id} = soiree},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    soiree = Repo.preload(soiree, [:game, :user])
    {:noreply, assign(socket, :soiree, soiree)}
  end

  def handle_info(
        {:deleted, %SoireePlateau.Teuf.Soiree{id: id}},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "La soirée a été supprimée.")
     |> push_navigate(to: ~p"/users/soirees")}
  end

  def handle_info({type, %SoireePlateau.Teuf.Soiree{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  def handle_info({invitation_event, %SoireePlateau.Teuf.Invitation{}}, socket)
      when invitation_event in [:invitation_created, :invitation_updated, :invitation_deleted] do
    soiree = socket.assigns.soiree

    {:noreply,
     assign(
       socket,
       :invitations,
       Teuf.list_invitations_for_soiree(socket.assigns.current_scope, soiree)
     )}
  end

  def handle_info({:vote_cast, %SoireePlateau.Teuf.Vote{}}, socket) do
    {:noreply,
     assign_votes(socket, socket.assigns.current_scope, socket.assigns.soiree, socket.assigns.is_host)}
  end

  defp host_invitations(scope, soiree, true),
    do: Teuf.list_invitations_for_soiree(scope, soiree)

  defp host_invitations(_scope, _soiree, false), do: []

  defp assign_votes(socket, scope, soiree, true) do
    votes = Teuf.list_votes_for_soiree(scope, soiree)
    summary = Teuf.vote_summary_for_soiree(soiree)

    average =
      case Enum.find(summary, &(&1.game_id == soiree.game_id)) do
        nil -> nil
        %{average: avg} -> avg
      end

    socket
    |> assign(:votes, votes)
    |> assign(:vote_average, average)
  end

  defp assign_votes(socket, _scope, _soiree, false) do
    socket
    |> assign(:votes, [])
    |> assign(:vote_average, nil)
  end

  defp format_average(nil), do: "—"

  defp format_average(%Decimal{} = d),
    do: d |> Decimal.round(1) |> Decimal.to_string()

  defp format_average(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)

  defp format_average(n), do: to_string(n)

  defp plural(list) when length(list) > 1, do: "s"
  defp plural(_), do: ""

  defp status_label(:pending), do: "En attente"
  defp status_label(:yes), do: "Oui"
  defp status_label(:no), do: "Non"
  defp status_label(:maybe), do: "Peut-être"

  defp status_badge(:pending), do: "bg-gray-200 text-gray-800"
  defp status_badge(:yes), do: "bg-green-200 text-green-800"
  defp status_badge(:no), do: "bg-red-200 text-red-800"
  defp status_badge(:maybe), do: "bg-yellow-200 text-yellow-800"
end
