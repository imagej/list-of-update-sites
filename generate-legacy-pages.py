import datetime, re
import jinja2, markdown2, yaml
from bs4 import BeautifulSoup
from xml.sax.saxutils import escape

# NB: Avoid annoying BeautifulSoup warnings of the following kind:
#
# MarkupResemblesLocatorWarning: The input looks more like a URL than markup.
# You may want to use an HTTP client like requests to get the document behind
# the URL, and feed that document to Beautiful Soup.
#
# See: https://stackoverflow.com/a/41496131/1207769
import warnings
from bs4 import MarkupResemblesLocatorWarning
warnings.filterwarnings("ignore", category=MarkupResemblesLocatorWarning)

def html(markdown_string):
    s = markdown2.markdown(markdown_string).rstrip()
    if s.startswith('<p>') and s.endswith('</p>') and s.count('</p>') == 1:
        # Strip containing <p>...</p> tags.
        return s[3:-4]
    return s

def plain(html_string):
    return BeautifulSoup(html_string, features="html.parser").get_text().rstrip()

template_loader = jinja2.FileSystemLoader(searchpath="./")
template_env = jinja2.Environment(loader=template_loader)

now = datetime.datetime.now()
date = now.strftime("%d %B %Y")
time = now.strftime("%H:%M")

# Parse the YAML source to a sites data structure.
with open('sites.yml', 'r') as stream:
    sites = yaml.safe_load(stream)

# Open the XML template.
xml_template = template_env.get_template('sites.xml.template')

# Render sites.xml from the sites data structure.
xml_data = xml_template.render(sites=[{
    # NB: No Markdown or HTML allowed in name or url!
    'name': site['name'],
    'url': site['url'],
    'description': escape(plain(html(site['description']))),
    'maintainer': escape(', '.join([plain(html(m)) for m in site['maintainers']]))
} for site in sites['sites']], date=date, time=time)
with open('sites.xml', 'w') as sites_xml_file:
    sites_xml_file.write(xml_data)

# Tweak the XML: HTTPS -> HTTP for select URLs.
# And write the tweaked result to sites_insecure.xml.
xml_data_insecure = re.sub(
    'https://(update.imagej.net|update.fiji.sc|sites.imagej.net)/',
    'http://\\1/', xml_data)
with open('sites_insecure.xml', 'w') as sites_xml_file_insecure:
    sites_xml_file_insecure.write(xml_data_insecure)

# Validate the resulting XML files.
import xml.dom.minidom as dom
dom.parse('sites_insecure.xml')
dom.parse('sites.xml')

# Open the HTML template.
html_template = template_env.get_template('sites.html.template')

# Render sites.html from the sites data structure.
result = html_template.render(sites=[{
    # NB: No Markdown or HTML allowed in name or url!
    'name': site['name'],
    'url': site['url'],
    'description': html(site['description']),
    'maintainer': ', '.join([html(m) for m in site['maintainers']])
} for site in sites['sites']], date=date, time=time)

with open('sites.html', 'w') as sites_html_file:
    sites_html_file.write(result)
