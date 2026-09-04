# Hugo Site Factory

Ce repo est un template pour creer des sites blogs statiques avec Hugo, optimises SEO/GEO, heberges gratuitement sur GitHub Pages.

## Comment ca marche

Ce repo ne contient pas de site. Il contient les **instructions et templates** pour que Claude Code genere un site complet automatiquement.

### Premier lancement

1. L'utilisateur connecte Claude Code a ce repo
2. L'utilisateur tape `/create-site`
3. Claude pose les questions necessaires (nom du site, couleurs, categories, etc.)
4. Claude genere tout le site Hugo, les fichiers SEO, et configure le deploiement
5. L'utilisateur push sur GitHub, active GitHub Pages, le site est en ligne

### Utilisation courante

- `/create-article-geo` : creer un nouvel article de blog (choix parmi plusieurs types : article standard, comparatif). Push automatiquement sur GitHub si le repo est configure
- `/create-article-seo` : **production polyvalente locale** d'articles evergreen SEO bilingues FR+EN. Tourne sur le Mac de Damien avec Opus 4.7 (analyse SERP avec fetch concurrents reel, maillage cross-batch). 3 modes au choix : (A) suivre la roadmap.yaml du blog, (B) roadmap externe fournie, (C) KW a la demande dans le chat. 3 strategies de scheduling au choix : garder dates source / cascade depuis date X / prochain slot dispo. Articles ecrits avec `publishDate` futur ou today selon mode. Voir section "Publications evergreen automatiques" plus bas
- `/seo-setup` : generer ou mettre a jour les fichiers SEO techniques de base (robots.txt, llms.txt, sitemap, structured data)
- `/seo` : mode interactif pour modifier/ajouter des elements SEO (meta tags, JSON-LD, audit on-page, etc.)
- `/serve` : lancer le serveur Hugo en local (previsualisation sur `http://localhost:1313/`)
- `/share` : lancer Hugo + ngrok pour partager le site via un lien public (accessible par n'importe qui)
- `/github-setup` : creer un repo GitHub, push le code et activer GitHub Pages (mise en ligne du site)
- `/github-deploy` : push les modifications vers GitHub et declencher le deploiement

## Structure du repo

```
.claude/
├── skills/
│   ├── create-site.md           ← Workflow creation de site complet
│   ├── create-article-geo.md        ← Workflow creation d'article (multi-types)
│   ├── seo-setup.md             ← Workflow fichiers SEO techniques (baseline)
│   ├── seo.md                   ← Mode interactif SEO (modifications ponctuelles)
│   ├── serve.md                 ← Lancer le serveur Hugo en local
│   ├── share.md                 ← Lancer Hugo + ngrok (partage public)
│   ├── github-setup.md          ← Creer un repo GitHub + activer GitHub Pages
│   └── github-deploy.md         ← Push et deployer sur GitHub Pages
└── templates/
    ├── hugo-workflow.yml         ← GitHub Actions CI/CD
    ├── main.css                  ← Design system CSS complet (variables, composants, responsive, a11y)
    ├── articles/                 ← Templates d'articles par type
    │   ├── article-standard.md   ← Article informatif SEO + GEO (type par defaut)
    │   └── geo-comparatif.md     ← Article comparatif avec mise en avant
    ├── seo/                      ← Fichiers SEO techniques (editables)
    │   ├── robots.txt            ← Modele robots.txt
    │   ├── llms.txt              ← Modele llms.txt
    │   └── structured-data/      ← Schemas JSON-LD
    │       ├── article.json      ← Article (avec image et @id croise)
    │       ├── organization.json ← Organization (avec @id, logo, expertise)
    │       ├── author.json       ← Person (auteur)
    │       ├── breadcrumb.json   ← BreadcrumbList
    │       ├── website.json      ← WebSite (avec publisher @id)
    │       └── faq.json          ← FAQPage (genere auto depuis frontmatter)
    ├── layouts/
    │   ├── baseof.html           ← Layout de base (skip-to-content, fonts non-bloquantes, favicon)
    │   ├── home.html             ← Page d'accueil
    │   ├── list.html             ← Pages de liste
    │   ├── single.html           ← Page article (breadcrumb, TOC sticky, image hero, auteur, articles similaires)
    │   ├── sitemap-html.html     ← Page plan du site (liste toutes les pages)
    │   └── 404.html              ← Page 404 custom
    └── partials/
        ├── header.html           ← Header sticky (backdrop-filter, aria-labels, mobile menu)
        ├── footer.html           ← Footer (aria-label, lien plan du site)
        └── seo-head.html         ← Meta tags SEO complets + JSON-LD auto (OG avec image, Twitter, canonical, hreflang, author, article:section, FAQPage auto, Organization @id)
```

## Contexte du site

> Cette section est remplie automatiquement par le skill `/create-site`.
> Elle permet a Claude de connaitre le contexte du site pour les futures actions.

- **Nom du site** : Ma Bonne Sante (anciennement "Meilleures Solutions Naturelles")
- **Description** : Guide expert en sante naturelle et bien-etre : aromatherapie, gemmotherapie, fleurs de Bach, huiles essentielles et complements alimentaires. Des solutions naturelles pour chaque besoin, validees par la science.
- **URL** : https://ma-bonne-sante.com/
- **Couleurs** : Primary #3B7A4A, Primary light #4A8F5B, Primary dark #2E6439, Background #FAFAF6, Background alt #F2F0EA, Accent #6B8F3B, Text #2C2C2C, Border #DDD9D0
- **Polices** : Playfair Display (titres), Lora (corps), DM Sans (UI)
- **Categories domaines (modalites therapeutiques)** : Aromatherapie, Huiles Essentielles, Huiles Vegetales, Gemmotherapie, Fleurs de Bach, Complements Alimentaires
- **Categories besoins (usages sante et bien-etre)** : Immunite et Defenses, Sommeil et Detente, Douleurs et Articulations, Bien-etre Feminin, Digestion et Detox, Minceur et Drainage, Beaute et Soins, Stress et Equilibre emotionnel, Peurs et Angoisses, Confiance et Estime de Soi, Respiration, Nuisibles
- **Langue** : FR (EN prevu en sous-dossier)
- **Auteur principal** : Laura Verdier (ID slug : `laura-verdier`). Source de verite : `data/authors.yaml` (6 personas partages avec le reseau, copiees depuis le template). Frontmatter des articles : `author: laura-verdier`. Le rendu du nom et la fiche schema.org/Person sont resolus automatiquement par les layouts via `.Site.Data.authors`. Avatar : `/images/authors/laura-verdier.webp`.
- **Client principal** : Inula (Pranarom, HerbalGem, Biofloral). Blog pense pour publier du contenu editorial valorisant les produits des 3 marques du groupe. D'autres clients datashake peuvent publier sur ce site si leur thematique rentre dans le champ sante naturelle ou bien-etre.
- **Historique** : site initialement lance sous le nom "Meilleures Solutions Naturelles" (domaine meilleuresolutionnaturelle.fr). Renomme en "Ma Bonne Sante" en avril 2026 avec elargissement de la thematique aux fleurs de Bach et a l'equilibre emotionnel. Le repo GitHub conserve le nom historique "meilleures-solutions-naturelles" par simplicite, mais toute communication utilisateur doit utiliser "Ma Bonne Sante".

## Suivi des publications (MEMORY.md)

Le fichier `MEMORY.md` a la racine trace tous les articles publies, classes par semaine. Il est mis a jour automatiquement par `/create-article-geo` et `/create-article-seo`.

**Repere indicatif : 4 articles par semaine.** C'est un rythme cible pour eviter la publication en masse. **Ce n'est pas un blocage.**

Comportement par skill :
- `/create-article-geo` (creation manuelle interactive) : si 4 articles ou plus deja publies cette semaine, **simple warning** affiche a l'utilisateur. L'utilisateur peut continuer en validant. Ne JAMAIS bloquer.
- `/create-article-seo` (batch local methode 2) : meme principe, warning soft en pre-validation, jamais de blocage.
- `/create-article-auto` (routine cron methode 1, mardi/vendredi) : **la regle ne s'applique pas**. La routine publie systematiquement l'entree eligible de la roadmap, sans lire le quota hebdo. Aucun check, aucun warning.

## Garde-fou cannibalisation a l'ajout dans la roadmap

Quand l'utilisateur (ou Claude pour son compte) ajoute un nouveau mot-cle dans `roadmap.yaml` (ou dans une roadmap externe en mode B/C de `/create-article-seo`), executer un check de cannibalisation **soft** avant insertion :

1. Lire toutes les entrees existantes de `roadmap.yaml` (tous statuts confondus : todo, queued, done, failed).
2. Pour chaque entree existante, comparer le `kw` propose au `kw` existant :
   - Tokeniser les deux KW (lowercase, retirer stop words FR/EN courants : le/la/les/de/du/des/un/une/a/au/aux/the/of/and/or/in/on/for...).
   - Calculer l'overlap : nombre de tokens communs / nombre de tokens du KW le plus court.
   - Drapeau "risque" si overlap >= 50% OU si l'un des KW est sous-string complet de l'autre.
3. Si au moins un drapeau "risque" est leve : afficher un warning a l'utilisateur listant les KW suspects et demander confirmation explicite ("Cannibalisation potentielle avec : [liste]. Ajouter quand meme ? oui/non").
4. Si aucun risque : ajouter directement, pas de warning.

Ce garde-fou est purement informatif. L'utilisateur peut toujours forcer l'ajout. L'objectif est juste de l'avertir avant qu'il ne commande deux articles qui se cannibaliseraient en SERP.

## Regles generales

- Toujours utiliser `relURL` dans les templates Hugo pour les liens (compatibilite GitHub Pages)
- **Les articles FR vont dans `content/fr/blog/`, les articles EN dans `content/en/blog/`.** Ce blog est multilingue avec un `contentDir` par langue declare dans `hugo.toml` (`content/fr` et `content/en`) : le dossier `content/blog/` n'existe PAS. Toute doc ou skill qui parle de `content/blog/` pour la version FR designe en realite `content/fr/blog/` (constate le 2026-08-11, la skill `create-article-geo` porte encore l'ancien chemin par endroits). Les URLs publiques restent `/blog/<slug>/` en FR (langue par defaut, sans prefixe) et `/en/blog/<slug>/` en EN
- Les slugs sont en minuscules, sans accents, mots separes par des tirets
- Ne JAMAIS utiliser `&` dans les noms de categories ou de tags — toujours remplacer par "et" (Hugo genere un double tiret `--` dans le slug, ce qui casse les URLs)
- Le ton des articles est impersonnel (pas de je/tu/nous/vous) sauf instruction contraire
- Les specs d'article (mots minimum, H2, blocs obligatoires) dependent du type choisi — lire les `<!-- NOTES POUR CLAUDE -->` dans chaque template d'article
- Chaque article doit contenir au minimum 3 liens internes contextuels vers d'autres articles du blog. L'ancre de chaque lien doit contenir le mot-cle principal de l'article cible
- L'auteur est ajoute automatiquement dans le frontmatter et affiche sur la page (configure dans `hugo.toml [params]`)
- Les templates SEO dans `.claude/templates/seo/` sont editables par l'utilisateur — toujours lire la version en place avant de generer
- Pour ajouter un nouveau type d'article, creer un `.md` dans `.claude/templates/articles/` — il sera automatiquement propose par `/create-article-geo`
- Pour ajouter un schema JSON-LD, creer un `.json` dans `.claude/templates/seo/structured-data/` et utiliser `/seo` pour l'integrer
- Chaque article doit avoir un champ `lastmod` dans le frontmatter (= date de derniere modification). Il est utilise par le sitemap XML, le sitemap HTML et le schema JSON-LD
- Quand un article est modifie, toujours mettre a jour le champ `lastmod` avec la date du jour
- Le sitemap HTML (`/plan-du-site/`) se regenere automatiquement a chaque build Hugo
- Toujours build et verifier (`hugo`) avant de commit
- Chaque article doit avoir un champ `faq` dans le frontmatter (liste de questions/reponses) pour generer automatiquement le schema FAQPage JSON-LD. Minimum 3 questions
- Le champ `image` du frontmatter porte l'image hero, reprise aussi pour og:image et le schema Article JSON-LD.
- **Image hero OBLIGATOIRE, jamais optionnelle.** Elle est recuperee par `.claude/scripts/fetch-image.sh`, qui suit la **cascade Pexels -> Unsplash -> Openverse -> visuel de charte genere** (`.claude/scripts/make-placeholder.py`) et ne rend jamais la main sans visuel. Revue du 2026-09-04 : Openverse n'est plus la source nominale, il ne produisait que 15 photos pertinentes sur 45 heros mesures. Les cles `PEXELS_API_KEY` et `UNSPLASH_ACCESS_KEY` viennent du **prompt de la routine** ou du `.env` local, **jamais du repo** qui est public ; sans cle la cascade demarre a Openverse et l'article sort quand meme. Le registre `.claude/hero-sources.json` empeche deux articles de porter la meme photo. Si `image` est renseigne, `imageAlt` est obligatoire, et `imageCredit` des que le script renvoie un credit. **Controle visuel obligatoire avant publication, quelle que soit la banque.**
- Les Google Fonts sont chargees en non-bloquant (media="print" + swap JS) pour de meilleures performances
- Le layout inclut un lien "Skip to content" pour l'accessibilite
- Les navigations ont des `aria-label` pour les lecteurs d'ecran
- Le CSS respecte `prefers-reduced-motion` pour desactiver les animations si l'utilisateur le demande
- Les articles affichent une table des matieres (TOC) sticky en sidebar, generee automatiquement par Hugo
- Les articles similaires sont affiches en bas de page, calcules par Hugo via la config `[related]` dans hugo.toml

## Comment repondre a l'utilisateur

- Tutoiement, ton decontracte
- Pas de jargon technique sans explication
- Reponses structurees avec listes a puces
- Pas d'emoji sauf demande explicite




## Regle IMPERATIVE : toute nouvelle URL doit apparaitre dans le sitemap + plan de site

**Chaque fois qu une URL est ajoutee au site (article, page, categorie, auteur...), elle DOIT etre presente dans :**

### 1. Le sitemap XML (robots + bots)

Hugo genere automatiquement les sitemaps via :
- `layouts/sitemapindex.xml` -> `/sitemap.xml` (l index qui reference les sitemaps par langue)
- `layouts/sitemap.xml` -> `/fr/sitemap.xml` + `/en/sitemap.xml` (urlsets par langue)

Verifier apres build :
```bash
hugo
grep "<nouveau-slug>" public/fr/sitemap.xml public/en/sitemap.xml
```

### 2. Le plan de site HTML (utilisateurs + bots)

Page `/plan-du-site/` (FR) et `/en/site-map/` (EN) rendues via `layouts/_default/sitemap-html.html`. Elles listent toutes les pages groupees par section (Pages principales, Blog, Categories, Auteurs, Pages legales). Mise a jour automatique au build Hugo.

**LE LIEN VERS `/plan-du-site/` DOIT ETRE PRESENT DANS LE FOOTER DE TOUTES LES PAGES** (via `layouts/partials/footer.html`).

### 3. La page auteur

Page `/authors/<slug-auteur>/` qui liste automatiquement tous les articles dont le frontmatter contient `author: <slug>`. Verifier que le slug de l auteur dans le frontmatter correspond a un auteur defini dans `data/authors.yaml`.

### 4. La liste du blog

Page `/blog/` qui liste les articles par date decroissante. Hugo l inclut automatiquement si le fichier est dans `content/blog/` (FR) ou `content/en/blog/` (EN).

### 5. Le JSON-LD Article (SEO / schema.org)

L article genere automatiquement son schema.org/Article via `seo-head.html` (date, auteur, headline, image).

### 6. Le fichier llms.txt (referencement IA)

Le fichier `static/llms.txt` a la racine du site liste toutes les URLs strategiques destinees aux LLMs (ChatGPT, Claude, Perplexity, etc.).

**A chaque publication ou modification de contenu, ajouter la nouvelle URL dans la section appropriee du fichier `static/llms.txt`.**

Structure attendue :

```markdown
# Nom du Site

> Description courte et factuelle du site

## A propos

Description editoriale (methodologie, independance, auteurs experts, etc.)

## Articles de reference (FR)

- Titre de l'article 1 : https://domaine.com/blog/slug-1/
- Titre de l'article 2 : https://domaine.com/blog/slug-2/
- [a completer a chaque nouvel article]

## Version anglaise (EN) — si multilingue

- Homepage EN : https://domaine.com/en/
- Blog EN : https://domaine.com/en/blog/
- Title of article 1 : https://domaine.com/en/blog/slug-1/

## Informations techniques

- Generateur : Hugo (site statique)
- Multilingue : francais (defaut) + anglais (si applicable)
- Sitemap : https://domaine.com/sitemap.xml
- RSS : https://domaine.com/index.xml
- Schema.org : Organization, Article, BreadcrumbList, FAQPage, WebSite, CollectionPage, Person

## Contact

- URL : https://domaine.com/
```

Apres chaque nouvel article :
1. Ouvrir `static/llms.txt`
2. Ajouter la ligne `- Titre complet : URL absolue` dans la bonne section (FR ou EN)
3. Commit + push

### Workflow post-publication

```bash
# 1. Build
hugo

# 2. Verifier sitemap
grep "<nouveau-slug>" public/fr/sitemap.xml
grep "<nouveau-slug>" public/en/sitemap.xml  # si multilingue

# 3. Verifier plan de site HTML
grep "<nouveau-slug>" public/plan-du-site/index.html

# 4. Verifier page auteur
grep "<titre>" public/authors/<slug>/index.html

# 5. Verifier le footer (plan-du-site doit etre present)
grep "plan-du-site" public/index.html

# 6. Verifier llms.txt (mise a jour manuelle)
grep "<titre>" static/llms.txt

# 7. Commit + push
git add -A && git commit -m "Article : <titre>" && git push origin main
```

**Si l une des 5 verifications echoue, NE PAS COMMIT et debugger.**

## Publications evergreen automatiques (methode 2 : batch + GitHub Actions cron)

Ce blog utilise la **methode 2** du systeme PBN GEO datashake (par opposition a la methode 1 utilisee sur como-blog-ai qui repose sur des routines CCR cloud). Voir spec master `geo-pbn-create-article-seo` dans 000 Data.

### Principe

- **Production locale polyvalente** : Damien lance `/create-article-seo` sur son Mac (Opus 4.7, sans limite Stream idle timeout). La skill propose 3 modes au debut :
  - **(A) Roadmap du blog** : N premieres entrees `todo` triees par scheduled_date (cas batch mensuel)
  - **(B) Roadmap externe** : roadmap fournie par l'utilisateur (Sheet d'un consultant, KW d'un client)
  - **(C) KW a la demande** : 1 ou plusieurs KW fournis dans le chat (ponctuel)

  Pour chaque mode, 3 strategies de scheduling possibles :
  - Garder les `scheduled_date` source (defaut)
  - Cascade remapping a partir d'une date X (decale en avant les entrees suivantes)
  - Prochain slot dispo dans la cadence (mardi/vendredi non occupe par roadmap.yaml)

- **Stockage** : chaque article est ecrit avec un frontmatter `publishDate` correspondant a la date de publication finale apres scheduling. Si publishDate > today : Hugo (`buildFuture: false`) masque automatiquement l'article jusqu'a la date. Si publishDate <= today (mode C immediate) : visible des le push.

- **Publication automatique** : un GitHub Actions cron (defini dans `.github/workflows/hugo.yml`, schedule `0 1 * * 2,5` = mardi + vendredi 3h Paris) rebuild le site 2x/semaine. Chaque rebuild inclut les articles dont `publishDate <= today`, ce qui les fait apparaitre sur le site public sans intervention humaine.

### Roadmap

Fichier : `roadmap.yaml` a la racine du repo (40 entrees au 25/04/2026, source Haloscan avril 2026). Chaque entree decrit 1 article a publier avec ses metas (kw, category, volume, kd, scheduled_date, status).

**Statuts utilises** :
- `todo` : pas encore traite par la batch
- `queued` : redige par la batch (fichier .md present avec publishDate futur, en attente de publication via cron)
- `failed` : erreur pendant la batch, voir le champ `error`

**Categories valides** (doivent matcher le hugo.toml) : Aromatherapie, Huiles Essentielles, Huiles Vegetales, Gemmotherapie, Fleurs de Bach, Complements Alimentaires, Immunite et Defenses, Sommeil et Detente, Douleurs et Articulations, Bien-etre Feminin, Digestion et Detox, Minceur et Drainage, Beaute et Soins, Stress et Equilibre emotionnel, Peurs et Angoisses, Confiance et Estime de Soi, Respiration, Nuisibles.

### Cycle complet de publication d'un article (timeline type)

1. Damien renseigne le KW dans la roadmap (`status: todo`, scheduled_date dans le futur)
2. 1x/mois, Damien lance `/create-article-seo` -> N articles redings avec `publishDate` futur, status passe a `queued`
3. Damien relit les articles, push sur GitHub
4. Sur push, GitHub Actions rebuild le site (mais les nouveaux articles restent invisibles, publishDate futur)
5. Mardi/vendredi 3h Paris, GitHub Actions cron rebuild le site -> les articles dont publishDate <= today apparaissent automatiquement
6. Damien n'a rien a faire entre la batch et l'apparition publique

### Comment editer la roadmap (humain)

- **Ajouter une entree** : copier un bloc, remplir kw / category / scheduled_date, garder `status: todo`
- **Reporter** : changer `scheduled_date`
- **Debloquer un failed** : corriger la cause indiquee dans `error`, repasser `status: todo`, vider `error`

### Difference avec como-blog-ai (methode 1)

| Aspect | como-blog-ai (methode 1) | ma-bonne-sante (methode 2) |
|---|---|---|
| Skill principale | `/create-article-auto` (CCR cloud) | `/create-article-seo` (local) |
| Frequence run | 2x/sem auto | 1x/mois manuel |
| Modele | Sonnet 4.6 (force, bug Opus stream timeout) | Opus 4.7 |
| Fetch concurrents | Bloque par sandbox cloud | Marche normalement |
| Maillage cross-batch | Non | Oui |
| Publication | Push immediat -> en ligne | Push -> publishDate futur -> apparait au cron |


