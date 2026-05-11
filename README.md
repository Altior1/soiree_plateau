# Soiree Plateau

## objectif
Les fonctionnalites principales de ce projet sont:
- [ ] permettre la connexion et l'authentification des utilisateurs
- [ ] creer des soirees jeux de societe ( des rdvs)
- [ ] RSVP des invités
- [ ] Selectionner les jeux parmis un catalogue
- [ ] notation des jeux apres soirees
- [ ] differenciation admin/ user


## Comment faire fonctionner le projet
-> pour l'environnement de production ( qui sert de démonstration) pour éviter d'avoir à installer Phoenix, il "suffit" de lancer le docker-compose.yml

-> pour lancer uniquement une db et faire tourner le projet et avoir accès au logs, on peut utiliser le docker-compose-dev.yml

Pour faire les choses proprement, une branche doit être créer avec en nom la user-Story qui va être implémenter. Les choix techniques pure ( si modification de la CI, des dockers..), on peut les merge directement afin de gagner du temps.

## Choix techniques
Pourquoi avoir choisi Elixir/ Phoenix pour ce projet :
- une technologie qui gere les concurrences de facon native ( donc deux personnes qui consulte la meme soiree, un admin qui modifie un jeu en meme temps qu'un autre)
- connaissance de la technologie en amont

# les explication du README genere par phoenix

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

## Organisation du code et checklist pour relecture

Arborescence principale (points d'entrée):

- `lib/` : code Elixir principal
	- `lib/soiree_plateau/` : logique applicative, contextes, schémas Ecto
	- `lib/soiree_plateau_web/` : endpoint, router, LiveViews, controllers, templates, composants
- `config/` : configuration par environnement (`config.exs`, `dev.exs`, `prod.exs`, `runtime.exs`)
- `assets/` : front-end (JS/CSS)
	- `assets/js/app.js` : point d'entrée JS
	- `assets/css/app.css` : point d'entrée CSS (Tailwind import)
- `priv/repo/` : migrations et données persistantes
- `test/` : tests unitaires et d'intégration
- `deps/` : dépendances vendorisées (si présentes localement)

Points à vérifier pour une relecture (checklist):

- **Installation & démarrage** : `mix setup`, `iex -S mix phx.server`
- **Conventions Elixir** : vérifier l'usage d'`Enum.at` pour accès index, immutabilité, noms de fonctions prédicats se terminant par `?`, absence de `String.to_atom/1` sur input utilisateur.
- **Architecture Phoenix / LiveView** : s'assurer que :
	- les routes LiveView sont placées dans les `live_session` appropriés (`:require_authenticated_user` vs `:current_user`) et justifier pourquoi;
	- `current_scope` est passé et utilisé (`@current_scope.user` pour accéder à l'utilisateur) conformément à l'auth infrastructure;
	- les composants et templates utilisent `<Layouts.app flash={@flash}>` et `<.icon>` / `<.input>` quand approprié.
- **Sécurité & Auth** : contrôler les plugs et redirections d'authentification, la séparation des routes publiques/privées, et l'usage de `current_scope` pour filtrer les requêtes.
- **Ecto & DB** : vérifier les requêtes Ecto, préchargements (`preload`) pour éviter N+1, usage correct de `changeset` et `Ecto.Changeset.get_field/2`, migrations dans `priv/repo/migrations`.
- **Forms & Templates HEEx** : valider que les formulaires utilisent `to_form/2` assignés par le LiveView, que `<.form for={@form}>` et `<.input field={@form[:field]}>` sont utilisés, et éviter `phx-no-curly-interpolation` erreurs.
- **LiveView Streams** : si utilisés, vérifier `phx-update="stream"`, l'id parent et consommation via `@streams.name`, et s'assurer que les états vides/comptes sont gérés séparément.
- **JS/CSS** : vérifier l'usage de Tailwind (syntaxe d'import recommandée), éviter les scripts inline dans templates, et s'assurer que les hooks JS utilisent `phx-update="ignore"` si nécessaire.
- **Tests** : s'assurer d'une couverture minimale pour les flows critiques (authentification, création/RSVP de soirée, permissions). Exécuter `mix test` pour valider.
- **Qualité du code** : exécuter `mix format`, `mix credo` (si présent), et vérifier warnings de compilation et dialyzer si configuré.
- **Dépendances & CI** : vérifier `mix.exs` pour dépendances sensibles, et que la CI/`mix precommit` passe.
- **Documentation & README** : vérifier que les modules publics ont `@moduledoc`, les fonctions importantes ont `@doc`, et que les instructions de démarrage sont claires.

Conseils rapides pour le relecteur:

- Commencer par lancer l'app localement (ou via Docker) et parcourir les principales pages LiveView.
- Inspecter le router pour comprendre les scopes et plugs actifs.
- Exécuter les tests ciblés pour les zones modifiées.
- Reproduire manuellement les scénarios critiques (connexion, création/modif d'une soirée, RSVP, droits admin).

Si vous voulez, je peux créer une checklist en TODO issue, ajouter des badges dans le README, ou générer un guide de contribution plus détaillé.
