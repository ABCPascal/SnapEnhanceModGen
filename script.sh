#!/bin/bash

UserAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"

# Get Latest Version
page1=$(curl --fail-early --connect-timeout 2 --max-time 5 -sL -A "$UserAgent" "https://www.apkmirror.com/uploads/?appcategory=Snapchat" 2>&1)
readarray -t versions < <(pup -p 'div.widget_appmanager_recentpostswidget h5 a.fontBlack text{}' <<<"$page1")

for version in "${versions[@]}"; do
    if [[ ! "$version" == *"Beta" ]] && [[ ! "$version" == *"beta" ]]; then
        # Extract version number and replace spaces and dots with hyphens
        version=$(echo "$version" | tr ' ' '-' | tr '.' '-' | tr '[:upper:]' '[:lower:]')
        echo "$version"

        # Provide the apkmirror link
        apkmirror_link="https://www.apkmirror.com/apk/snap-inc/snapchat/$version-release"

        page1=$(curl -vsL -A "$UserAgent" "$apkmirror_link" 2>&1)

        canonicalUrl=$(pup -p --charset utf-8 'link[rel="canonical"] attr{href}' <<<"$page1")
        if [[ "$canonicalUrl" == *"apk-download"* ]]; then
            url1=("${canonicalUrl/"https://www.apkmirror.com/"//}")
        else
            grep -q 'class="error404"' <<<"$page1" && continue

            page2=$(pup -p --charset utf-8 ':parent-of(:parent-of(span:contains("APK")))' <<<"$page1")

            [[ "$(pup -p --charset utf-8 ':parent-of(div:contains("noarch"))' <<<"$page2")" == "" ]] || arch=noarch
            [[ "$(pup -p --charset utf-8 ':parent-of(div:contains("universal"))' <<<"$page2")" == "" ]] || arch=universal

            readarray -t url1 < <(pup -p --charset utf-8 ":parent-of(div:contains(\"$arch\")) a.accent_color attr{href}" <<<"$page2")

            [ "${#url1[@]}" -eq 0 ] && continue
        fi
        echo "1/3 url1: $url1"

        url2=$(curl -sL -A "$UserAgent" "https://www.apkmirror.com${url1[-1]}" | pup -p --charset utf-8 'a:contains("Download APK") attr{href}')

        [ "$url2" == "" ] && continue
        echo "2/3 url2: $url2"

        url3=$(curl -sL -A "$UserAgent" "https://www.apkmirror.com$url2" | pup -p --charset UTF-8 'a[rel="nofollow"][data-google-interstitial="false"] attr{href}')

        [ "$url3" == "" ] && continue
        echo "3/3 url3: $url3"

        echo "https://www.apkmirror.com$url3" >&2
        echo "Downloading APK from: https://www.apkmirror.com$url3"

        # Make Directory for APK file
        mkdir snapchatapk
        # Download the APK file and save it as snap.apk
        wget -U "$UserAgent" -O snapchatapk/$version.apk "https://www.apkmirror.com$url3"
        if [ $? -eq 0 ]; then
            echo "APK downloaded successfully as $version.apk"
            exit 0
        else
            echo "Failed to download APK" >&2
            exit 1
        fi
    fi
done

echo "No suitable version found."
exit 1