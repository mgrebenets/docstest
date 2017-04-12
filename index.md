---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
# TODO: Remove the "Posts" header
layout: home
---


{% for platform in site.data.frameworks.platforms %}
# {{ platform[1].title }}

{{ platform[1].description }}

---

{% for category in platform[1].categories %}
## {{ category[1].title }}

{{ category[1].description }}

{% for framework in category[1].frameworks %}
{% assign latest_version = framework[1].versions.last %}
### {{ framework[0] }}

{% comment %}
Few pods have incomplete desciption and use "<Description>" placeholder.
This will be fixed as part of documentation, for now have a work-around here.
{% endcomment %}

{% if latest_version.first[1].description != "<Description>" %}
  {{ latest_version.first[1].description }}
{% else %}
  _Description unavailable._
{% endif %}


[Latest version: {{ latest_version.first[0] }}](TODO: link here)

<details><summary>Older versions</summary>
{% assign older_versions = framework[1].versions | reverse %}
{% for older_version in older_versions offset:1 %}
<ul>
  <li><a href="TODO:Link">{{ older_version.first[1].version }}</a></li>
</ul>
{% endfor %}
</details>

---

{% endfor %}
{% endfor %}
{% endfor %}
