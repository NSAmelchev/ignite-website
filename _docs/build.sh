#!/bin/bash

export latest=no
export branch=master
export action=build

export versions_filename="../docs/available-versions.txt"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version=*)
        version="${1#*=}"
        ;;
     --latest)
        latest="yes"
        ;;
    --github-branch=*)
        branch="${1#*=}"
        ;;
    --serve)
      action=serve
      ;;
    *)
      printf "***********************************************************\n"
      printf "* Error: Invalid argument,  *\n"
      printf "***********************************************************\n"
      exit 1
  esac
  shift
done

if [ -z "$version" ]; then
  echo "specify the version: --version=1.0.0"
  exit 1
fi

# there are different repos for version 2 and 3.
export repo_url="https://github.com/apache/ignite.git"
if [[ "${version:0:1}" == "3" ]] ; then
  repo_url="https://github.com/apache/ignite-3.git"
fi

# clone Ignite repo locally to copy only the content for docs. 
#   @todo: is there a way to avoid cloning the entire branch and bring only the docs/ dir?
export tmp_dir=tmp
rm -rf $tmp_dir
mkdir $tmp_dir
git -C $tmp_dir clone --depth 1 --single-branch --branch $branch $repo_url docs_$version
rm -rf _docs _data _plugins
cp -R $tmp_dir/docs_$version/docs/_docs _docs
cp -R $tmp_dir/docs_$version/docs/_data/ _data
cp -R $tmp_dir/docs_$version/docs/_plugins/ _plugins

# update contents for the jekyll config file
if [ "$latest" = "yes" ]; then
 sed  "s/{version}/$version/g;s/{base_url}/\/docs\/latest/g"  _config.template  > _config.yml
else 
  sed  "s/{version}/$version/g;s/{base_url}/\/docs\/$version/g"  _config.template  > _config.yml
fi
# build/serve
bundle install
bundle exec jekyll $action  

# move built files to /docs/ dir under website root dir.
if [ "$action" = "build" ]; then

  rm -rf ../docs/$version
  cp -R _site/docs/$version ../docs/$version
  cp -R _site/assets ../

  # if [ "$latest" = "yes" ]; then
    # rm ../docs/latest
    # ln -s ../docs/$version ../docs/latest
  # fi

  # add the version number to the .txt file used by the version selector dropdown on the UI
  if ! grep -Fxq "$version" "$versions_filename"; then
    # adds the version to the top of the list if 'latest', otherwise to the bottom
    if [ "$latest" = "yes" ]; then
      cat <(echo "$version") "$versions_filename" > ../docs/available-versions.new
      mv ../docs/available-versions.new "$versions_filename"
    else
      #just in case the file doesn't end with an EOL already
      if [ -z "$tail -c 1 <"$versions_filename")" ]; then  
        echo "" >> "$versions_filename"
      fi
     
      echo "$version" >> "$versions_filename"
    fi
  fi
fi

# clean up some stuff
rm -r _config.yml
rm -rf _data
rm -rf _docs
rm -rf _plugins
rm -rf  $tmp_dir
