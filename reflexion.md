on doit résonner "métier"

-> on a deux contexte principaux, les jeux d'un côté, et les soirées de l'autre.

En point d'attention, il faut que 
    - un user puisse créer une soirée ( donc une soirée est relié à un user hôte)
    - cet user va définir dans le catalogue un jeu qui va être le thème de la soirée. Ce thème peut être modifié après, mais il doit toujours y avoir un thème.
    

Est ce que je dois justifier mon SGBDR ? 
Si oui, quel est le gros argument ?
-> base de donnée relationnel car on a peu d'information sur les entités en soient, et surtout que ce qui est intérressant est plus la relation entre eux ( le nom de mon user est important, mais l'information cruciale pour moi est que cet user a commenté tel jeu et va à tel soirée)



Pourquoi j'ai dockerisé au lieu d'utilisé Release ?
-> facilité de déploiement sur un plus large pannel de solution
-> + permet d'éviter pour un ordinateur sans ASDF l'installation d'une version précise d'Elixir


