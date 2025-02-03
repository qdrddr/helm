#!/bin/bash
MYHELM_REPO_PATH=$PWD
mkdir -p ${MYHELM_REPO_PATH}/build/
GITREPO_NAME=trieve
cd ../${GITREPO_NAME}
git fetch --tags
REPO_VERSION=$(git tag --sort=-v:refname | head -n 1)
echo "GITREPO_NAME: ${GITREPO_NAME} | REPO_VERSION: ${REPO_VERSION}"
git checkout ${REPO_VERSION}

HELM_VERSION=$(grep '^version:' ./helm/Chart.yaml | awk '{print $2}')
echo "HELM_VERSION: ${HELM_VERSION}"

helm package ./helm -d build/
helm repo index ./
# sed 's+build+head+g' ./index.yaml > ./index.yaml

# Crossplatform sed workaround from: https://unix.stackexchange.com/questions/92895/how-can-i-achieve-portability-with-sed-i-in-place-editing
case $(sed --help 2>&1) in
  *GNU*) set sed -i;;
  *) set sed -i '';;
esac

VERSION=$(yq eval ".entries.trieve-helm[] | select(.version == \"$HELM_VERSION\") | .version" index.yaml | head -n 1)
URL0=$(yq eval ".entries.trieve-helm[] | select(.version == \"$HELM_VERSION\") | .urls[0]" index.yaml)
cp ${URL0} ${MYHELM_REPO_PATH}/build/
cp index.yaml ${MYHELM_REPO_PATH}/index-${GITREPO_NAME}.yaml

#https://raw.githubusercontent.com/qdrddr/supabase-helm/refs/tags/${HELM_VERSION}/build

"$@" -e "s+build+https://raw.githubusercontent.com/qdrddr/helm/refs/heads/main/build+g" ${MYHELM_REPO_PATH}/index-trieve.yaml

cd ${MYHELM_REPO_PATH}
cp index.yaml index-previous.yaml
yq eval-all '. as $item ireduce ({}; . *+ $item)' "index-previous.yaml" "index-${GITREPO_NAME}.yaml" > index.yaml

git add *
git commit -m "Update index.yaml & build with ${GITREPO_NAME} for version ${HELM_VERSION}"
git push main