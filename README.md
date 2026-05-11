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
