# Skill : Creer des articles evergreen SEO en batch (production locale)

Cette skill produit en **local** (machine de Damien, Opus 4.7 sans limite stream timeout) un **lot d'articles evergreen SEO bilingues FR + EN** a partir d'une roadmap. Les articles sont rediges avec un `publishDate` futur correspondant a leur date de publication prevue dans la roadmap. Hugo (avec `buildFuture: false` par defaut) masque automatiquement les articles dont `publishDate > today` jusqu'a ce que la date arrive.

C'est **la methode 2** du systeme PBN GEO datashake (alternative au CCR cloud `/create-article-auto` utilise sur `como-blog-ai`). Elle permet :
- Opus 4.7 sans risque de Stream idle timeout (bug Anthropic actif sur CCR long tool-use)
- Vraie analyse SERP avec WebFetch des concurrents (sandbox cloud bloque les domaines commerciaux en 503)
- Maillage interne plus riche (cross-batch : articles d'un meme batch peuvent se mailler entre eux)
- Relecture humaine possible avant push

La publication (mise en ligne reelle) se fait via un **GitHub Actions cron** separe (`scheduled-publish.yml`) qui rebuild le site 2x/semaine. Aucune publication active n'est faite par cette skill.

## Quand l'utiliser

- Declenchement manuel : `/create-articles-batch` dans le contexte d'un blog du reseau PBN GEO datashake.
- Frequence cible : 1x/mois pour produire les 8-12 prochains articles.

## Pre-requis dans le blog

- `roadmap.yaml` a la racine du repo, contenant des entrees `status: todo`.
- `hugo.toml` configure avec langue principale + langue EN. **`buildFuture: false`** (defaut Hugo, ne pas changer).
- `data/authors.yaml` present (systeme d'auteurs partage). Si absent, fallback sur les params hugo.toml `default_author_id` ou `author_name`.
- `content/blog/` peut contenir des articles deja publies (servent au maillage interne).
- `.claude/scripts/fetch-image.sh` present (sinon : copier depuis `blog-site-template/.claude/scripts/`).
- Remote git `origin` configure (le push est demande en fin de batch, optionnel).
- MCP `serpapi` configure dans `.mcp.json` ou globalement, accessible via `mcp__serpapi__search`.

## Etape 0 — Questions interactives

Cette skill est **interactive en debut de batch** (pour permettre a Damien de calibrer), puis tourne en autonome jusqu'a la fin.

Poser les 2 questions suivantes a l'utilisateur, attendre les reponses :

### Q1 : Source de la roadmap

Demander :
> "Source de la roadmap pour ce batch ?
>  (1) `roadmap.yaml` a la racine du blog courant [defaut, recommande]
>  (2) Roadmap fournie : colle-la ici (format YAML) OU donne le chemin d'un autre fichier .yaml"

- Si reponse "1", "default", vide : utiliser `<racine du blog>/roadmap.yaml`
- Si reponse "2" : demander de coller le YAML ou de donner le chemin. Parser et valider le format (memes champs que le template).

### Q2 : Nombre d'articles a produire

Demander :
> "Combien d'articles veux-tu produire dans ce batch ? (entier, ex: 8)"

- Valider que c'est un entier > 0
- Si > 20, prevenir : "Batch tres gros, ca va prendre du temps et beaucoup de tokens. Confirme ?"
- Stocker la valeur dans `N`

### Pre-validation avant lancement

Avant de demarrer le batch :
- Verifier les pre-requis listes plus haut (authors.yaml, fetch-image.sh, MCP serpapi)
- Si un manque : signaler a Damien et proposer de le mettre en place (ex: copier fetch-image.sh depuis le template) ou abort
- Lister les N entrees qui vont etre traitees (par ordre de `scheduled_date`) et demander confirmation : "OK pour lancer le batch sur ces N articles ? (oui/non)"

## Etape 1 — Selection des entrees roadmap

1. Lire la roadmap (source choisie a l'etape 0).
2. Filtrer les entrees `status: todo`.
3. Trier par `scheduled_date` croissante.
4. Prendre les N premieres entrees.
5. Stocker la liste : `[{kw, category, scheduled_date, volume, kd}, ...]`.

A partir de ce moment, plus de question utilisateur. La skill tourne en autonome jusqu'a la fin (sauf en cas d'erreur bloquante).

## Etape 2 — Pour chaque entree, derouler le workflow complet

Pour chaque entree de la liste, faire les sous-etapes 2.1 a 2.10 dans l'ordre.

**Important** : la rediaction se fait en sequence, pas en parallele. Apres chaque article rredige, il rejoint le pool de "articles disponibles pour maillage interne" pour les articles suivants du meme batch. Ca permet aux articles du batch de se mailler entre eux.

### 2.1 Analyse SERP (page 1 uniquement)

Appeler `mcp__serpapi__search` avec :
- `q` = `kw`
- `engine` = `google`
- `hl` = langue principale du site (ex: `fr`)
- `gl` = pays cible (ex: `fr`)
- `num` = 10 (page 1 uniquement)
- `location` = pays (ex: `France`)

Extraire :
- `organic_results[0..9]` : URL, title, snippet
- `related_questions` (PAA) si presents
- `related_searches` si presents

### 2.2 Fetch des concurrents (3-5 pertinents)

Boucler sur les `organic_results` dans l'ordre. Pour chaque URL :

1. `WebFetch` le HTML
2. Extraire : balise `<title>`, `<meta name="description">`, H1, H2, H3 (dans l'ordre), longueur du body en mots
3. **Verifier la pertinence** :
   - Langue du contenu == langue principale du site
   - H1 ou title contient le `kw` ou des variantes proches
   - Longueur >= 500 mots (sinon contenu trop pauvre)
   - Pas une page de boutique e-commerce ou un PDF (verifier le content-type ou le DOM)
4. Si pertinent : ajouter au pool de concurrents valides
5. Si pas pertinent : passer au suivant
6. Arreter quand on a **5 concurrents pertinents** OU quand on a essaye toutes les URLs de la page 1

**Minimum requis : 3 concurrents pertinents.** Si moins de 3 apres avoir essaye les 10 URLs :
- Logger l'avertissement
- Continuer la rediaction en mode degradé (basée sur SerpAPI titles+snippets+PAA seuls)
- Marquer dans la roadmap `error: "moins de 3 concurrents pertinents"`

### 2.3 Synthese SERP

A partir des concurrents fetched et des donnees SerpAPI :
- **Intention de recherche** : informationnelle / transactionnelle / mixte (deduite du pattern des H1)
- **Patterns Hn recurrents** : H2 presents chez 2+/5 concurrents
- **Longueur cible** : moyenne des longueurs concurrents +/- 10% (ou 1500-2000 mots par defaut si <3 concurrents valides)
- **FAQ pertinente ?** : VRAI si 50%+ concurrents ont une section FAQ OU si `related_questions` retournees par SerpAPI
- **Tableau pertinent ?** : VRAI si 50%+ concurrents utilisent un tableau, ou si l'intention est comparative (mots "meilleur", "comparatif", "vs", "ou")
- **Liste des questions FAQ** (si pertinente) : extraites des PAA SerpAPI + FAQ concurrents, deduplique et reformule, 4-6 questions retenues
- **Champ semantique** : mots recurrents dans titles + snippets + related_searches

### 2.4 Title et meta description

Regles pixel inline (pas d'appel aux skills /tech-title ni /tech-meta-description).

**Title** :
- <= 60 caracteres
- Contient `kw` en premier tiers
- Format : `[Kw] : [angle distinctif]` ou `[Kw] : [bénéfice ou question]`
- 1 seule option, choix direct

**Meta description** :
- <= 155 caracteres
- Contient `kw`
- Phrase descriptive factuelle, pas de CTA agressif

### 2.5 Structure Hn

Construite a partir des patterns recurrents identifies a 2.3 :
- 1 H1 (genere par Hugo via le `title` frontmatter)
- 4 a 7 H2, dont :
  - 2-4 reprenant les patterns recurrents 3+/5 concurrents
  - 1-2 reprenant les patterns 2+/5 concurrents
  - 1-2 H2 "valeur ajoutee" (angle editorial du blog, deduit du `CLAUDE.md` du blog)
  - Si FAQ pertinente : dernier H2 "Questions frequentes" en accordeon `<details><summary>`
- H3 : 1-3 par H2 si necessaire

Contraintes :
- H2 explicites et auto-suffisants
- Pas de "Introduction", "Conclusion" tels quels (reformuler)
- Pas de `&` dans les H2/H3
- Pas de tiret cadratin (—) ni demi-cadratin (–)

### 2.6 Selection auteur

1. Si `data/authors.yaml` existe :
   - Pour chaque auteur, scorer matching avec `kw` + `category` (via `topics` et `expertise`)
   - Selectionner le score max
   - En cas d'egalite ou score nul : auteur principal du site (defini dans CLAUDE.md du blog)
2. Sinon (pas de authors.yaml) :
   - Utiliser l'auteur defini dans `hugo.toml [params]` (ex: `default_author_id` ou `author_name`)
3. Injecter dans le frontmatter : `author: <id-slug-ou-nom>`

Meme auteur pour les versions FR et EN.

### 2.7 Image hero

Appeler le script existant :
```bash
bash .claude/scripts/fetch-image.sh "<kw traduit en anglais>" "<slug-fr>" "static/images/blog"
```

- Si exit code != 0 : retenter UNE fois avec une query plus generique (`category` traduite en anglais)
- Si toujours KO : skipper l'image et continuer la rediaction sans image hero (le site supportera l'absence)
- Recuperer les 3 sorties : path, alt, credit

### 2.8 Maillage interne

1. Scanner `content/blog/*.md` (articles FR deja publies)
2. **AJOUTER au pool les articles deja produits dans ce batch** (les rediactions precedentes de la session)
3. Pour chaque article candidat, scorer :
   - `category` identique : +3
   - `tags` partages : +1 par tag commun
   - Mots communs entre `kw` : +2
4. Garder les 3 a 5 meilleurs scores
5. Construire les ancres : chaque ancre contient le mot-cle principal de l'article cible
6. Position : insertion contextuelle dans le body (etape 2.9), un par section pertinente

**Maillage intra-langue uniquement** : version FR mail vers `/blog/<slug>/`, version EN mail vers `/en/blog/<slug>/`.

### 2.9 Redaction FR

Produire le fichier `content/blog/<slug-fr>.md`.

#### Frontmatter (REGLE CLE : `publishDate` futur)

```yaml
---
title: "[Title]"
translationKey: "[slug-generique]"
date: "[YYYY-MM-DD]"          # date de redaction (aujourd'hui)
lastmod: "[YYYY-MM-DD]"       # idem
publishDate: "[scheduled_date de la roadmap]"  # CLE : Hugo ne build pas tant que cette date n'est pas atteinte
description: "[Meta description]"
categories: ["[Categorie FR]"]
tags: ["tag1", "tag2", "tag3", "tag4", "tag5"]
author: "[id-slug-ou-nom]"
image: "/images/blog/<slug>.webp"
imageAlt: "[Description FR, max 125 char]"
imageCredit: "[Credit Openverse]"
faq:                          # uniquement si FAQ pertinente
  - question: "[Q1]"
    answer: "[R1, 3-5 phrases]"
  - question: "[Q2]"
    answer: "[R2, 2-4 phrases]"
readingTime: true
---
```

#### Body

- Premier paragraphe : contient `kw` naturellement
- Respecter strictement la structure Hn de 2.5
- Longueur : moyenne concurrents +/- 10% (ou 1500-2000 si mode degrade)
- Densite kw : 1-2%
- Mots-cles en **gras**
- Au moins 1 tableau si "tableau pertinent" a 2.3
- 3-5 liens internes contextuels (de 2.8)
- Ton impersonnel
- Pas de separateur horizontal `---` dans le body
- Pas de tiret cadratin ni demi-cadratin
- Si FAQ pertinente : dernier H2 "Questions frequentes" avec `<details><summary>`. Q/R du body == Q/R du frontmatter.

### 2.10 Redaction EN

Produire le fichier `content/en/blog/<slug-en>.md`.

- **Meme `translationKey`** que la version FR
- **Meme `publishDate`** que la version FR
- Traduction directe (pas de recherche KW EN extensive)
- Slug EN traduit
- Categories et tags traduits selon le mapping du `CLAUDE.md` du blog
- `image`, `imageCredit`, `author` identiques au FR
- `imageAlt` traduit
- FAQ frontmatter et body traduits

### 2.11 Update roadmap

Mettre a jour l'entree dans la roadmap source :
```yaml
  status: queued        # nouveau statut : redige mais pas encore publie
  queued_date: "[YYYY-MM-DD]"  # date de la batch
  # publishDate visible dans le .md, pas dans la roadmap
  error: null           # ou message d'erreur si mode degrade
```

(Note : si la roadmap source est externe, ne pas la modifier. Le statut est applique uniquement si la roadmap est `roadmap.yaml` du blog en cours.)

## Etape 3 — Build Hugo de verification

Apres avoir produit les N articles, lancer :
```bash
hugo
```

Verifier :
- Exit code 0
- Le nombre de pages generees AUGMENTE pas (puisque les articles ont `publishDate` futur, ils sont masques par defaut)
- Pour valider que les articles sont bien dans le repo : `find content/ -name "<slug>.md"` doit les trouver

Si le build echoue : afficher l'erreur, ne pas commit, demander a Damien de corriger manuellement.

## Etape 4 — MEMORY.md

Ajouter une ligne dans `MEMORY.md` (a la racine du blog) pour chaque article du batch, classes par semaine de leur `publishDate` :

```markdown
## Semaine X (DD/MM - DD/MM)
- YYYY-MM-DD | <Titre FR> (FR+EN) | <Categorie> | batch (queued)
```

Le suffixe `batch (queued)` distingue les articles produits par la batch (en attente de publication) des articles produits a la main ou via /create-article-auto.

## Etape 5 — Recap au utilisateur

Afficher dans le chat :

```
Batch termine : N articles produits.

| # | KW | Slug FR | Categorie | publishDate | Mots FR |
|---|----|---------|-----------|-------------|---------|
| 1 | ... | ... | ... | YYYY-MM-DD | ~1700 |
...

Statistiques :
- Concurrents fetched valides en moyenne : X.X / 5
- Articles en mode degrade (<3 concurrents) : N
- Image hero recuperee : N/N
- Maillage interne moyen : X.X liens / article (cross-batch + articles existants)

Prochaines etapes proposees :
1. Relire les articles (suggestion : commencer par les plus competitifs en KD)
2. Commit + push : git add -A && git commit -m "batch: N articles evergreen produits" && git push origin main
   Une fois pushees, GitHub Actions cron prendra le relais pour la publication aux dates definies.
```

## Etape 6 — Commit (optionnel)

Demander a Damien :
> "OK pour commit + push maintenant ? (oui / non / je relis d'abord)"

- Si "oui" : `git add -A && git commit -m "batch: N articles evergreen produits (queued pour publishDate futurs)" && git pull --rebase origin main && git push origin main`
- Si "non" ou "je relis" : laisser en local, ne pas pusher. Damien commitera manuellement apres relecture.

## Gestion des erreurs (transversal)

A n'importe quelle etape, si un article echoue :
1. Logger l'erreur precisement dans `/tmp/batch-<date>.log`
2. Marquer l'entree dans la roadmap : `status: failed` + `error: "<etape> <message>"`
3. Supprimer les fichiers article partiellement ecrits pour cette entree (revenir a un etat propre)
4. **Continuer le batch sur les entrees suivantes** (un echec sur 1 article ne bloque pas les autres)
5. A la fin, signaler dans le recap quelles entrees ont echoue

## Differences avec /create-article-auto (CCR cloud)

| Element | `/create-article-auto` (CCR) | `/create-articles-batch` (local) |
|---|---|---|
| Localisation | Cloud Anthropic CCR | Mac local |
| Modele | Sonnet 4.6 (force, bug Opus stream timeout) | Opus 4.7 |
| Articles par run | 1 | N (batch) |
| Fetch concurrents WebFetch | Bloque par sandbox (503) | Marche normalement |
| MCP SerpAPI | Hack curl direct avec cle dans prompt | Natif via MCP local |
| Maillage cross-batch | Non (1 article seul) | **Oui** (articles du meme batch peuvent se mailler) |
| Publication | Immediate (push apres redaction) | Differee (publishDate futur + GitHub Actions cron) |
| Risque timeout stream | Eleve sur Opus | Aucun |
| Permissions popups | Geres via .claude/settings.json | Geres en local par Damien |
| Frequence | 2x/semaine cron | 1x/mois manuel |
| Use case | Hands-off complet, qualite acceptable | Qualite max, relecture humaine, longue traine |

## Format `roadmap.yaml`

Le format est documente dans `.claude/templates/roadmap-template.yaml`. Champs editables par l'humain : `kw`, `category`, `volume`, `kd`, `scheduled_date`, `status`. Champs remplis par la skill : `queued_date`, `error`. Pas de `published_date` ni `published_url_*` dans cette methode (la publication est implicite via `publishDate` du frontmatter Hugo + GitHub Actions cron).
