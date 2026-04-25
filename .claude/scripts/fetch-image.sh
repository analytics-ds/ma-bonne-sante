#!/bin/bash
# fetch-image.sh
# Recupere une image libre de droit compatible usage commercial depuis l'API publique
# Openverse (federe Flickr, Wikimedia, etc. — pas d'API key requise).
# Filtre sur les licences autorisant l'usage commercial et la modification (CC BY, CC0, PDM...).
# Telecharge l'image, la convertit en WebP si cwebp dispo, et affiche le chemin Hugo + credit.
#
# Usage : fetch-image.sh "<query>" "<slug>" [output_dir]
# Output stdout (3 lignes) :
#   ligne 1 : chemin Hugo de l'image (ex: /images/blog/mon-slug.webp)
#   ligne 2 : alt text suggere (titre de l'image)
#   ligne 3 : credit (ex: "Photo par <creator> via <source> — <license>")
# Output stderr : messages d'info/erreur
# Exit codes : 0 OK, 1 args, 2 API vide, 3 pas de resultat, 4 download, 5 format

set -e

QUERY="$1"
SLUG="$2"
OUTPUT_DIR="${3:-static/images/blog}"

if [ -z "$QUERY" ] || [ -z "$SLUG" ]; then
    echo "Usage: $0 <query> <slug> [output_dir]" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# URL-encode la query (gere les accents)
QUERY_ENCODED=$(printf '%s' "$QUERY" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))" 2>/dev/null || echo "$QUERY" | sed 's/ /+/g')

USER_AGENT="blog-site-template/1.0 (+https://github.com/analytics-ds)"

# Requete Openverse :
# - license_type=commercial,modification → licences permettant commercial + modification (CC BY, CC0, PDM, CC BY-SA)
# - page_size=10 → on recupere 10 resultats pour avoir du choix
# - mature=false → filtre safe
echo "[fetch-image] Recherche Openverse : $QUERY" >&2
JSON=$(curl -sL --max-time 20 \
    -H "User-Agent: $USER_AGENT" \
    -H "Accept: application/json" \
    "https://api.openverse.org/v1/images/?q=${QUERY_ENCODED}&license_type=commercial,modification&page_size=10&mature=false")

if [ -z "$JSON" ]; then
    echo "[fetch-image] ERREUR : reponse vide d'Openverse" >&2
    exit 2
fi

# Extraction du 1er resultat via python (plus robuste que grep pour du JSON)
RESULT=$(echo "$JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = data.get('results', [])
    # Filtrer les resultats avec une URL valide et des dimensions suffisantes
    valid = [r for r in results if r.get('url') and (r.get('width') or 0) >= 800]
    if not valid:
        valid = [r for r in results if r.get('url')]
    if not valid:
        sys.exit(3)
    r = valid[0]
    print(r.get('url', ''))
    print(r.get('title', '') or '')
    creator = r.get('creator', '') or 'Auteur inconnu'
    source = r.get('source', '') or r.get('provider', '') or ''
    license_name = (r.get('license', '') or '').upper()
    license_version = r.get('license_version', '') or ''
    if license_name and license_version:
        lic = f'CC {license_name} {license_version}'
    elif license_name:
        lic = f'CC {license_name}'
    else:
        lic = 'CC'
    print(f'Photo par {creator} via {source.capitalize()} ({lic})')
except SystemExit:
    raise
except Exception as e:
    print(f'PARSE_ERROR: {e}', file=sys.stderr)
    sys.exit(3)
" 2>/dev/null) || {
    echo "[fetch-image] ERREUR : aucun resultat pour '$QUERY' (licences commercial+modification)" >&2
    exit 3
}

IMAGE_URL=$(echo "$RESULT" | sed -n '1p')
IMAGE_TITLE=$(echo "$RESULT" | sed -n '2p')
IMAGE_CREDIT=$(echo "$RESULT" | sed -n '3p')

if [ -z "$IMAGE_URL" ]; then
    echo "[fetch-image] ERREUR : URL image vide" >&2
    exit 3
fi

# Telecharger l'image
TMP_FILE="/tmp/openverse-${SLUG}.img"
echo "[fetch-image] Telechargement : $IMAGE_URL" >&2
curl -sL --max-time 30 -H "User-Agent: $USER_AGENT" "$IMAGE_URL" -o "$TMP_FILE"

if [ ! -s "$TMP_FILE" ]; then
    echo "[fetch-image] ERREUR : telechargement echoue" >&2
    rm -f "$TMP_FILE"
    exit 4
fi

# Determiner l'extension a partir des magic bytes
FILE_TYPE=$(file -b --mime-type "$TMP_FILE")
case "$FILE_TYPE" in
    image/jpeg) SRC_EXT="jpg" ;;
    image/png)  SRC_EXT="png" ;;
    image/webp) SRC_EXT="webp" ;;
    image/gif)  SRC_EXT="gif" ;;
    *)
        echo "[fetch-image] ERREUR : format non supporte ($FILE_TYPE)" >&2
        rm -f "$TMP_FILE"
        exit 5
    ;;
esac

# Convertir en WebP si cwebp dispo et source non-webp, sinon garder tel quel
if [ "$SRC_EXT" = "webp" ]; then
    OUTPUT_FILE="$OUTPUT_DIR/$SLUG.webp"
    cp "$TMP_FILE" "$OUTPUT_FILE"
    echo "[fetch-image] Image deja en WebP : $OUTPUT_FILE" >&2
elif command -v cwebp >/dev/null 2>&1; then
    OUTPUT_FILE="$OUTPUT_DIR/$SLUG.webp"
    cwebp -quiet -q 85 "$TMP_FILE" -o "$OUTPUT_FILE"
    echo "[fetch-image] Converti en WebP : $OUTPUT_FILE" >&2
else
    OUTPUT_FILE="$OUTPUT_DIR/$SLUG.$SRC_EXT"
    cp "$TMP_FILE" "$OUTPUT_FILE"
    echo "[fetch-image] cwebp absent, conserve en $SRC_EXT : $OUTPUT_FILE" >&2
fi

rm -f "$TMP_FILE"

# Convertir le chemin fichier en chemin Hugo (retirer 'static/' du debut)
HUGO_PATH=$(echo "$OUTPUT_FILE" | sed -E 's|^\.?/?static/|/|')
[[ "$HUGO_PATH" != /* ]] && HUGO_PATH="/$HUGO_PATH"

# Output sur stdout : 3 lignes (path, alt, credit)
echo "$HUGO_PATH"
echo "$IMAGE_TITLE"
echo "$IMAGE_CREDIT"
