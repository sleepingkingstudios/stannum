---
breadcrumbs:
  - name: Documentation
    path: '../../../'
  - name: Versions
    path: '../../'
  - name: '0.4'
    path: '../'
version: '0.4'
---

{% assign root_namespace = site.namespaces | where: "version", page.version | first %}

# Stannum Reference

{% include reference/namespace.md label=false namespace=root_namespace %}

{% include breadcrumbs.md %}
