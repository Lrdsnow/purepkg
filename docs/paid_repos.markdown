---
layout: page
title: Using paid repos on tvOS
permalink: /tvOS/paid-repos
---

<div markdown="block">
{: .warning }
This is for advanced users only
</div>

## Getting the token

### Via GUI

1. Open PurePKG and go into payment settings (in settings)
2. Right Click/Hold the Repo you'd like a token for and hit "Get Token"
3. Enter the udid and model identifier for your tv
4. Hit Confirm to copy your Token & Secret

### Via CLI

1. Run `<path to purepkg executable> getToken <repo url> <model identifier> <udid>` on either macOS or Jailbroken iOS
- Model identifier and udid should be from your tv but technically any works as long as they are both from the same device

## Using token in tvOS

### You can either:
- Type in the token & secret manually in PurePKG payment settings on tvOS
or 
- Add the keys for each repo in the Info.plist for PurePKG

### How to do the second method:
1. Get the token & secret you copied
2. Open the Info.plist for PurePKG tvOS in your favorite plist editor
3. Add the keys for your repos in this format: `<repo name>_token` or `<repo name>_secret` with the values being the token or secret as a string
4. Get the Info.plist to your tv
5. Go into PurePKG payment settings and hit the repo that you put a token & secret in for and it'll ask if you'd like to use the values from the info.plist 
