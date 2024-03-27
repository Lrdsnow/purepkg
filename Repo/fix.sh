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
        -o APT::FTPArchive::Release::Architectures="appletvos-arm64 darwin-amd64 darwin-arm64 iphoneos-arm iphoneos-arm64 iphoneos-arm64e" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="PurePKG" \
        release . > Release
gpg -abs -u $GPG_KEY -o Release.gpg Release
gpg -abs -u $GPG_KEY --clearsign -o InRelease Release
