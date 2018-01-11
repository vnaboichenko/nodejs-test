yum install -y epel-release
yum install -y git
yum install -y createrepo
yum install -y rpm-build redhat-rpm-config
yum install vim -y
yum install nodejs -y
yum install openssl -y
yum install puppet -y


nodejs_dir='/root/nodejs'
build_dir='/root/rpmbuild'
repo_dir='/root/rpm_repo'

mkdir $repo_dir

rpmbuild $build_dir

git clone https://github.com/heroku/node-js-sample.git $nodejs_dir
cp ${nodejs_dir}/* $build_dir/ -R

cd $build_dir

npm install --save-dev speculate

sed -i '/start/ s/$/,/' package.json
sed -i '/start/ a   "spec": "speculate"' package.json

npm run spec

sed -i '/%post/ a cd /usr/lib/node-js-sample; npm install' ${build_dir}/SPECS/node-js-sample.spec
rpmbuild -bb ${build_dir}/SPECS/node-js-sample.spec


find $build_dir -name *.rpm -exec cp {} /root/rpm_repo/ \;
createrepo $repo_dir



echo -n "
[nodejs]
name=Custom Repository
baseurl=file://${repo_dir}/
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/nodejs.repo
