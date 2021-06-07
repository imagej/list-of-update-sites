Check that redirects and proxies are in place to keep the V1 Updater working.

The V1 Updater requires that http://imagej.net/ issue a 301 redirect.

  $ curl -A Java -Ifs http://imagej.net/ | grep '^\(HTTP/\|Location:\)'
  HTTP/1.1 301 Moved Permanently
  Location: http://imagej.net/Welcome

The V1 Updater asks for the list of update sites via the MediaWiki API.
When the Updater asks for the list via HTTPS, we want the URLs to be HTTPS.

  $ curl -fs -A Java 'https://imagej.net/api.php?action=query&titles=List+of+update+sites&export=true&exportnowrap=true&format=xml' | grep -A 1 "'''\(ImageJ\|Fiji\|Fiji-Legacy\|Java-8\)'''"
  |'''ImageJ'''
  |https://update.imagej.net/
  --
  |'''Fiji'''
  |https://update.fiji.sc/
  --
  |'''Fiji-Legacy'''
  |https://sites.imagej.net/Fiji-Legacy/
  --
  |'''Java-8'''
  |https://sites.imagej.net/Java-8/

When the Updater asks for the list via HTTP, we want the URLs to be HTTP.

  $ curl -fs -A Java 'http://imagej.net/api.php?action=query&titles=List+of+update+sites&export=true&exportnowrap=true&format=xml' | grep -A 1 "'''\(ImageJ\|Fiji\|Fiji-Legacy\|Java-8\)'''"
  |'''ImageJ'''
  |http://update.imagej.net/
  --
  |'''Fiji'''
  |http://update.fiji.sc/
  --
  |'''Fiji-Legacy'''
  |http://sites.imagej.net/Fiji-Legacy/
  --
  |'''Java-8'''
  |http://sites.imagej.net/Java-8/

When asking for the old list of update sites URL, redirect to the new URL.

  $ curl -Ifs https://imagej.net/List_of_update_sites | grep '^\(HTTP/\|Location:\)'
  HTTP/1.1 301 Moved Permanently
  Location: https://imagej.net/list-of-update-sites

If they ask for it over HTTP, redirect to HTTPS.

  $ curl -Ifs http://imagej.net/List_of_update_sites | grep '^\(HTTP/\|Location:\)'
  HTTP/1.1 301 Moved Permanently
  Location: https://imagej.net/List_of_update_sites

