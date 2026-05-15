# Mesures de sécurité

Synthèse des protections mises en place et de leurs limites. Couvre les
exigences du brief §7.2.

## 1. Authentification

- **Mécanisme** : sessions Phoenix signées (cookies HMAC) + magic link, fourni
  par `phx.gen.auth`. La session est stockée côté serveur via la table
  `users_tokens`, ce qui permet une révocation effective au logout (pas
  uniquement un cookie expirant côté client).
- **Mots de passe** : hashés avec **bcrypt** via `:bcrypt_elixir`. Jamais
  stockés en clair, jamais en MD5/SHA1.
- **Politique de mot de passe** : 8 caractères minimum (cf. `User.changeset/2`
  dans `accounts/user.ex`). À renforcer en backlog si compte démo /
  production.
- **Lien magique** : généré pour 30 minutes, à usage unique, signé. Permet
  d'éviter le stockage côté client.

## 2. Autorisation

### Scope-based

Le projet utilise le **scope** introduit par `phx.gen.auth` : chaque
contexte reçoit un `%Scope{}` en premier argument et filtre les requêtes
sur l'utilisateur courant. Exemples concrets :

```elixir
def list_soirees(%Scope{} = scope) do
  Repo.all_by(Soiree, host: scope.user.id)
end

def update_soiree(%Scope{} = scope, soiree, attrs) do
  true = soiree.host == scope.user.id  # défense en profondeur
  ...
end
```

Cela empêche un membre d'accéder ou modifier les ressources d'un autre.

### Rôle admin

- Contrôlé **côté serveur** via le plug `:require_authenticated_admin`
  (`SoireePlateauWeb.UserAuth`).
- Toutes les routes d'administration sont dans le scope router `/admin`,
  qui monte un `live_session :current_user_admin`.
- Le rôle est aussi vérifié dans la couche métier pour les actions de
  type `Teuf.cancel_soiree/2` (host **ou** admin). Jamais sur la seule base
  de l'UI.

### Tableau récapitulatif des contrôles

| Action                               | Vérification                                | Réponse en cas d'échec |
|--------------------------------------|---------------------------------------------|------------------------|
| Lecture des soirées d'autres users   | `host = current_user_id` dans la query      | Résultat vide          |
| Modifier une soirée                  | `soiree.host == scope.user.id` côté context | `MatchError` (500) — à raffiner |
| Annuler une soirée                   | `host or admin` dans le context             | `{:error, :unauthorized}` |
| Voter sur une soirée                 | `confirmed_invitee? + soiree_past?`         | `{:error, …}` + flash  |
| CRUD du catalogue                    | `require_authenticated_admin` (plug)        | Redirect 302 / 403     |

## 3. Validation des entrées

- **Tous les changesets** définissent leurs `validate_required`,
  `validate_number`, `validate_length`, `validate_inclusion`. Voir
  `Vote.changeset/2` pour un exemple complet (rating 1-5, commentaire ≤ 500,
  trim de la chaîne vide).
- **Aucune** conversion `String.to_atom/1` sur input utilisateur (risque
  d'épuisement de l'atom table).
- **Codes HTTP** : violations renvoient `400` (validation), `403` (auth),
  `404` (ressource invisible). Les LiveView refusent et affichent un flash
  utilisateur.

## 4. Protections OWASP

| Risque OWASP            | Mesure                                                              |
|-------------------------|---------------------------------------------------------------------|
| **A01 — Broken Access** | Scope + contrôles dans les contextes (cf. ci-dessus).               |
| **A02 — Cryptographic Failures** | bcrypt sur mots de passe, cookies signés, HTTPS attendu en prod. |
| **A03 — Injection SQL** | Ecto utilise des **requêtes paramétrées** systématiquement. Aucune concaténation SQL dans le code. |
| **A03 — Injection (XSS)** | HEEx **échappe par défaut** tout `{...}` et `<%= ... %>`. Pas de `raw/1` dans le code applicatif. |
| **A05 — Security Misconfiguration** | Headers sécurisés via `plug :put_secure_browser_headers`. Pas de mode debug en prod. |
| **A07 — Auth Failures** | Lock-out implicite par bcrypt cost factor élevé + magic link à usage unique. Pas de message qui révèle si l'email existe (§US02 contrainte). |
| **CSRF**                | `plug :protect_from_forgery` actif dans la pipeline `:browser`. Les LiveView WebSocket utilisent le CSRF token initial. |

## 5. Gestion des secrets

- **Aucun** secret en dur dans le code source.
- Valeurs lues depuis l'environnement dans `config/runtime.exs` :
  - `SECRET_KEY_BASE` — signe les cookies et les tokens.
  - `DATABASE_URL` ou `POSTGRES_*` — DSN base.
  - Mode d'envoi mail.
- Fichier `.env` ignoré par `.gitignore` ; un gabarit `.env.exemple` est
  versionné pour faciliter l'onboarding.
- Vérification recommandée : `git log --all -p -- .env` doit renvoyer vide.

## 6. CORS

Pas de politique CORS spécifique car l'application n'expose **pas d'API
publique** : le frontend est servi par le même endpoint que le backend.
Si une API REST était ajoutée en backlog, il faudrait poser un `plug Corsica`
avec une whitelist d'origines.

## 7. Limites identifiées (dette de sécurité)

- **Pas de rate limiting** sur le login / la création de compte. À ajouter
  via `Hammer` ou similaire avant exposition publique.
- **Pas de Content Security Policy** explicite — Phoenix applique des
  headers raisonnables par défaut mais une CSP stricte serait préférable.
- **`is_admin` modifiable directement en base** — pas d'audit. À documenter
  pour l'admin opérationnel.
- **Pas de 2FA**. Le magic link offre déjà une bonne UX sans mot de passe,
  mais reste inférieur à du TOTP.

Ces points sont **explicitement laissés en backlog** comme améliorations
hors scope du livrable d'une semaine.
