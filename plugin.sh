#!/busybox/sh

set -euo pipefail

REGISTRY=${PLUGIN_REGISTRY:-index.docker.io}
TARPATH=${PLUGIN_TARPATH:-image.tar}

if [ "${PLUGIN_USERNAME:-}" ] || [ "${PLUGIN_PASSWORD:-}" ]; then
    crane auth login -u "${PLUGIN_USERNAME}" -p "${PLUGIN_PASSWORD}" "${REGISTRY}"
fi

# auto_tag, if set auto_tag: true, auto generate .tags file
# support format Major.Minor.Release or start with `v`
# docker tags: Major, Major.Minor, Major.Minor.Release and latest
if [[ "${PLUGIN_AUTO_TAG:-}" == "true" ]]; then
    TAG="${DRONE_TAG:-}"

    echo -n "latest" > .tags
    if [ -n "${TAG:-}" ]; then
        while true; do
	    #crane tag "${REGISTRY}/${PLUGIN_REPO}:latest" "${TAG}"
	    echo -n ",${TAG}" >> .tags
            V=${TAG%.*}
            [ ${V%.*} = ${TAG} ] && break
            TAG=${V}
        done
    fi
    echo "" >> .tags
fi

if [ -n "${PLUGIN_TAGS:-}" ]; then
    DESTINATIONS=$(echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "${tag} "; done)
elif [ -f .tags ]; then
    DESTINATIONS=$(cat .tags| tr ',' '\n' | while read tag; do echo "${tag} "; done)
elif [ -n "${PLUGIN_REPO:-}" ]; then
    DESTINATIONS="latest"
else
    DESTINATIONS=""
fi

PUSHED=""
[ -n "${DESTINATIONS}" ] && echo "${DESTINATIONS}" | while read tag; do
    echo "Pushing to ${REGISTRY}/${PLUGIN_REPO}:${tag}"
    if [ -n "${PUSHED}" ]; then
        crane tag "${PUSHED}" "${tag}"
    else
	PUSHED="${REGISTRY}/${PLUGIN_REPO}:${tag}"
        crane push "${TARPATH}" "${PUSHED}"
    fi
done
