# docker-cncjs

## Github Actions dockerhub.yml

Deploy Docker image to Docker Hub

1. Commit & push changes
2. Add Tag e.g. `git tag -a 1.0.1 -m 'cncjs version 1.10.3 update'`
3. Commit tag `git push origin --tags`

Build image locally

1. Build `docker build ca-f Dockerfile -t mxpicture/cncjs:latest`
2. Deploy to Docker Hub `docker push mxpicture/cncjs:latest`

Build without cache `docker build --no-cache --build-arg CACHEBUST=$(date +%s) .`

Util

Get last cncjs/cncjs version (get_last_cncjs_version.sh, also in dockerfile)

1. Get cncjs tags `git ls-remote --tags https://github.com/cncjs/cncjs` --> result (multiple lines) e.g. `5e1dc9abffb48d34c8e0e32364c9191f7c75bad7	refs/tags/v1.10.3`
2. Split in order to get version `| cut -f 2 | cut -d "/" -f 3` --> result (multiple lines) e.g. `v1.9.0-alpha` and `v1.9.0`
3. Filter versions with additional property and remove "v" `| awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}'` --> result (multiple lines) e.g. `1.9.22`
4. Add 1000 to each part in order to sort it `| awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}'` --> result (multiple lines) e.g. `1001.1009.1022`
5. Sort descending `| sort -r` --> result (multiple lines) newest version is first item
6. Subtract 1000 and concat download url `| awk -F'[/.]' '{print "https://github.com/cncjs/cncjs/archive/refs/tags/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}'` --> result (multiple lines) e.g. `https://github.com/cncjs/cncjs/archive/refs/tags/v0.5.4.tar.gz`
7. Get first line (newest) `| head -n 1` --> result (single line) e.g. `https://github.com/cncjs/cncjs/archive/refs/tags/v1.10.3.tar.gz`
8. Download result `| xargs wget -O cncjs.tar.gz`
9. Create tmp directory `mkdir cncjs_tmp`
10. Extract `tar -xvzf cncjs.tar.gz --directory cncjs_tmp`
11. Move content to cncjs `mv cncjs_tmp/$(ls --color=none cncjs_tmp) cncjs`
12. Remove tmp directory `rmdir cncjs_tmp`
13. Remove archive `rm cncjs.tar.gz`
14. Go go cncjs dir `cd cncjs`
15. Install `yarn install`
16. Build `yarn build-prod`

download all at once (Step 1 to 8): `git ls-remote --tags https://github.com/cncjs/cncjs | cut -f 2 | cut -d "/" -f 3 | awk -F'[v]' '/^v[0-9]+\.[0-9]+\.[0-9]+$/ {print $2}' | awk -F'[/.]' '{print $1+1000 "." $2+1000 "." $3+1000}' | sort -r | awk -F'[/.]' '{print "https://github.com/cncjs/cncjs/archive/refs/tags/v" $1-1000 "." $2-1000 "." $3-1000 ".tar.gz"}' | head -n 1 | xargs wget -O cncjs.tar.gz`
