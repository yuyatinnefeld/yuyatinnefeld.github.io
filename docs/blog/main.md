---
layout: page
title: Notes
subtitle: 最近のメモ
---

### Contents

<p>Just my posts, newest first:</p>

<ul>
  {% for post in site.posts %}
    <li class="spaced">
      <a href="{{ post.url }}">{{ post.title }}</a> {{ post.date | date_to_long_string }}
    </li>
  {% endfor %}
</ul>
