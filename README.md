[![Deploy Status](https://github.com/imagej/list-of-update-sites/actions/workflows/deploy.yml/badge.svg)](https://github.com/imagej/list-of-update-sites/actions/workflows/deploy.yml)

# List of Update Sites

In ImageJ2, anyone can open the Updater and install features from a list of available update sites which is populated by this repository.

## Adding / Editing / Removing an Update Site

If you want to add, edit, or remove an update site from this list, please create a pull request.

1. Fork this repository
2. Modify `sites.yml` in your fork
3. Optionally, check your changes locally with `.github/lint.sh` (requires `yamllint`)
4. Create a pull request containing your changes

Before adding a new site, please [create a wiki page](https://imagej.net/editing/):

* If your site primarily ships plugins, then for each plugin, use: `https://imagej.net/plugins/your-plugin-name-in-web-case`
* If you want a dedicated page about your update site itself (perhaps linking to all the plugins it offers), use: `https://imagej.net/update-sites/your-update-site-name-in-web-case`

Need help? Don't worry, and post your question on the [Image.sc Forum](https://forum.image.sc/)!
