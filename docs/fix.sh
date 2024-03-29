# update purepkg
rm -rf ./debs/uwu.lrdsnow.purepkg*.deb
cp /Users/*/Library/Developer/Xcode/DerivedData/PurePKG-*/Build/Build/* ./debs
for deb in ./debs/uwu.lrdsnow.purepkg*.deb; do
    filename=$(basename "$deb")
    version=$(dpkg-deb -I "$deb" | awk '/Version:/ {print $2}')
    new_filename=$(echo "$filename" | sed "s/uwu\.lrdsnow\.purepkg/uwu.lrdsnow.purepkg_$version/")
    mv "$deb" "$(dirname "$deb")/$new_filename"
done
# update repo
apt-ftparchive packages ./debs > Packages
apt-ftparchive contents ./debs > Contents
gzip -k Packages
gzip -k Contents
apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="PurePKG" \
        -o APT::FTPArchive::Release::Label="PurePKG" \
        -o APT::FTPArchive::Release::Suite="stable" \
        -o APT::FTPArchive::Release::Version="1.0" \
        -o APT::FTPArchive::Release::Codename="purepkg" \
        -o APT::FTPArchive::Release::Architectures="xros-arm64 watchos-arm appletvos-arm64 darwin-amd64 darwin-arm64 iphoneos-arm iphoneos-arm64 iphoneos-arm64e" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="PurePKG" \
        release . > Release
gpg -abs -u $GPG_KEY -o Release.gpg Release
gpg -abs -u $GPG_KEY --clearsign -o InRelease Release
