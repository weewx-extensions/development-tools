---
title: Setting up GitHub pages
parent: GitHub Pages
#has_children: true
#has_toc: true
nav_order: 1
---

The following steps create the `docs` directory used by GitHub pages.

## Create an 'empty' docs directory in the repository

### Install Jekyll

These [steps](https://jekyllrb.com/docs/installation/ubuntu/) were used to install Jekyll

1. Install ruby
    ```sudo apt-get install ruby-full build-essential zlib1g-dev```

2. Setup to install gems without sudo

    ```bash
    echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    ```

3. Install jekyll and bundler
    ```gem install jekyll bundler```

### Configure the repository to publish (from a branch)

Next the the repository is [configured to publish from a branch](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-from-a-branch).

1. Open `Settings` for the repository.
2. Select `Pages` from the left navigation bar.
3. Select `master` as the branch and `docs` as the directory.
4. Save the settings.

### Set up the repository

Start around [step 6](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/creating-a-github-pages-site-with-jekyll#creating-your-site) to setup the repository.

1. Create the `docs` directory in the repository
2. From within the `docs` directory, run
    ```jekyll new --skip-bundle .```
3. Edit the Gemfile as documented

### Run the build locally

From within the `docs` directory, run
```bundle exec jekyll serve```

For additional information see [building your site locally](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/testing-your-github-pages-site-locally-with-jekyll)

## The  `docs-template` directory

The above steps were followed to create the `docs-template` directory.
The content, the markdown files, was then editted to create a template directory that can be used to seed new repositories.

The `readme` can be used in GitHub Pages and correctly displays 'standalone', for example in GitHub.
This is accomplished because the `readme` template consists of only markdown.
It displays without any processing.
This is accomplished by using a special layout that does not include the footer used when building and deploying GitHub Pages.
Instead a 'copy' of the footer is directly embedded in the readme.
To make that all work, when building the GitHub Pages the readme is actually included from an `index.md` with the appropriate jekyll front matter.

An example home page is also included in the `docs-template` directory.
This can be found in the `home` directory.
The `index.md` within this directory acts as the home page.
The `subpage.md` is an example of creating a subpage using the `just-the-docs` jekyll theme.

The `subpage.md` also has an example of displaying collapsable categories in a page.
