#!/bin/bash
GITREPO_NAME=supabase-kubernetes
GITREPO_CHART_PATH=charts/supabase
HELM_CHART_NAME=supabase

####################
MYHELM_REPO_PATH=$PWD
mkdir -p ${MYHELM_REPO_PATH}/build/
#cd .. ; git clone https://github.com/supabase-community/supabase-kubernetes.git
cd ../${GITREPO_NAME}
git pull
#git fetch --tags
#REPO_VERSION=$(git tag --sort=-v:refname | head -n 1)
#echo "GITREPO_NAME: ${GITREPO_NAME} | REPO_VERSION: ${REPO_VERSION}"
#git checkout ${REPO_VERSION}

HELM_VERSION=$(grep '^version:' ./${GITREPO_CHART_PATH}/Chart.yaml | awk '{print $2}')
echo "HELM_VERSION: ${HELM_VERSION}"

helm package ./${GITREPO_CHART_PATH} -d build/
helm repo index ./
# sed 's+build+head+g' ./index.yaml > ./index.yaml

# Crossplatform sed workaround from: https://unix.stackexchange.com/questions/92895/how-can-i-achieve-portability-with-sed-i-in-place-editing
case $(sed --help 2>&1) in
  *GNU*) set sed -i;;
  *) set sed -i '';;
esac

#VERSION=$(yq eval ".entries.supabase[] | select(.version == \"$HELM_VERSION\") | .version" index.yaml | head -n 1)
#echo "VERSION: ${VERSION}"
URL0=$(yq eval ".entries.supabase[] | select(.version == \"$HELM_VERSION\") | .urls[0]" index.yaml)
echo "URL0: ${URL0}"
cp ${URL0} ${MYHELM_REPO_PATH}/build/
cp index.yaml ${MYHELM_REPO_PATH}/index-${GITREPO_NAME}.yaml

#https://raw.githubusercontent.com/qdrddr/supabase-helm/refs/tags/${HELM_VERSION}/build

"$@" -e "s+build+https://raw.githubusercontent.com/qdrddr/helm/refs/heads/main/build+g" ${MYHELM_REPO_PATH}/index-${GITREPO_NAME}.yaml

cd ${MYHELM_REPO_PATH}
cp index.yaml index-previous.yaml
#Merge index.yaml files
yq eval-all '. as $item ireduce ({}; . *+ $item)' "index-previous.yaml" "index-${GITREPO_NAME}.yaml" > index.yaml

git add *
git status
git commit -m "Update index.yaml & build with ${GITREPO_NAME} for helm version ${HELM_VERSION}"
git push

#verify
helm repo add qdrddr https://raw.githubusercontent.com/qdrddr/helm/refs/heads/main
helm repo update qdrddr
helm search repo qdrddr/${HELM_CHART_NAME}