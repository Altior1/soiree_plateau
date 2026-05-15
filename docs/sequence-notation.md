# Diagramme de séquence — Noter un jeu après une soirée

Flow complet du métier "un participant confirmé note le jeu d'une soirée
passée", suggéré par le brief §9 jour 1 comme exemple représentatif.

Couvre US11 : critères d'acceptation + contraintes + cas d'erreur.

## Cas nominal

```mermaid
sequenceDiagram
    autonumber
    participant U as Membre confirmé
    participant Browser
    participant LV as SoireeLive.Show
    participant Teuf as Teuf context
    participant Repo
    participant PubSub
    participant Other as Autres participants

    U->>Browser: Saisit son commentaire et clique sur "4"
    Browser->>LV: phx-submit "rate"<br/>%{rating: "4", comment: "Super soirée"}
    LV->>Teuf: cast_vote(scope, soiree, attrs)

    Note over Teuf: Vérifications métier :<br/>1. soirée non annulée<br/>2. user = invité confirmé (status=:yes)<br/>3. date de soirée < maintenant<br/>4. game_id dans la liste des jeux de la soirée

    Teuf->>Repo: get_by(Vote, user_id, soiree_id, game_id)
    Repo-->>Teuf: nil (premier vote)
    Teuf->>Repo: Vote.changeset(%{rating: 4, comment: "Super soirée", ...})<br/>insert_or_update
    Repo-->>Teuf: {:ok, %Vote{}}
    Teuf->>PubSub: broadcast({:vote_cast, vote})<br/>topic "soiree:<id>:votes"
    Teuf-->>LV: {:ok, vote}

    LV->>LV: assign :current_rating = 4<br/>assign :current_comment = "Super soirée"<br/>refresh_votes()
    LV-->>Browser: diff DOM<br/>(bouton "4" surligné, note visible dans la liste)

    PubSub-->>Other: {:vote_cast, vote}<br/>(via subscribe_soiree_votes)
    Other->>Other: handle_info → refresh_votes<br/>(la note apparaît en direct)
```

## Cas d'erreur

### Tentative sur une soirée future

```mermaid
sequenceDiagram
    participant Browser
    participant LV as SoireeLive.Show
    participant Teuf

    Note over Browser: En théorie le bouton n'est pas affiché<br/>(can_vote=false), mais on défend en profondeur.

    Browser->>LV: phx-submit "rate"<br/>(forcé via dev tools)
    LV->>Teuf: cast_vote(scope, soiree, attrs)
    Teuf-->>LV: {:error, :soiree_not_finished}
    LV->>LV: put_flash(:error, "Le vote sera ouvert<br/>une fois la soirée terminée.")
    LV-->>Browser: diff DOM + toast d'erreur
```

### Tentative par un non-invité ou un invité non-confirmé

```mermaid
sequenceDiagram
    participant Browser
    participant LV as SoireeLive.Show
    participant Teuf

    Browser->>LV: phx-submit "rate"
    LV->>Teuf: cast_vote(scope, soiree, attrs)

    alt Pas d'invitation
        Teuf-->>LV: {:error, :not_invited}
        LV->>LV: put_flash(:error, "Tu n'es pas invité…")
    else Soirée annulée (US10)
        Teuf-->>LV: {:error, :soiree_cancelled}
        LV->>LV: (déjà géré par UI : bandeau "annulée" et form masqué)
    else Commentaire trop long
        Teuf-->>LV: {:error, %Ecto.Changeset{}}
        LV->>LV: put_flash(:error, "Commentaire invalide : …")
    end

    LV-->>Browser: diff DOM + toast
```

## Mise à jour d'une note existante (upsert)

L'utilisateur peut modifier sa note à tout moment (US11 critère
d'acceptation). Le flow nominal est identique, sauf que `Repo.get_by/2`
retourne le `%Vote{}` existant qui est mis à jour via le même changeset.

```mermaid
sequenceDiagram
    participant LV as SoireeLive.Show
    participant Teuf
    participant Repo

    LV->>Teuf: cast_vote(scope, soiree, %{rating: 5, ...})
    Teuf->>Repo: get_by(Vote, user_id, soiree_id, game_id)
    Repo-->>Teuf: %Vote{id: 42, rating: 4, ...}
    Teuf->>Repo: changeset(existing, attrs) → insert_or_update
    Repo-->>Teuf: {:ok, %Vote{id: 42, rating: 5}}
    Note over Teuf: La contrainte unique (user, soiree, game)<br/>aurait rejeté un insert dupliqué —<br/>ici on update, donc pas de collision.
```

## Points évaluables

- Toutes les validations (RSVP, date, statut) sont **côté serveur** dans
  `Teuf.cast_vote/3` — l'UI les double mais ne s'y fie pas.
- L'unicité par triplet est garantie au niveau base **et** au niveau Ecto
  (`unique_constraint`).
- Le temps réel via `PubSub` est un bonus UX, pas une dépendance
  fonctionnelle : le LiveView appelle aussi `refresh_votes/1` synchroniquement
  après le succès du `cast_vote` pour ne pas dépendre du round-trip
  PubSub (cf. fix appliqué après le test cassé).
