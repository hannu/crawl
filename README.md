Crawl aka. UutisDiff
====================

Crawl is experimental project that tracks popular finnish news sites and reveals what changes are made to the articles since they are published.

Modular structure supports also external site parsers.

GIT is used as a database for the articles. Also changes are detected using GIT. Changes could be browsed using GIT tools, but project also contains web front-end built on [Sinatra](http://www.sinatrarb.com/) and [Backbone.js](http://documentcloud.github.com/backbone/). 

Setup
-----

Install required gems with

<pre>
bundle install
</pre>

Intialize empty GIT repository. Default path is ./repository

<pre>
git init repository
</pre>

Sinatra backend could be started with command

<pre>
bundle exec ruby sinatra-backend.rb
</pre>

Usage
-----

To detect changes crawlers should be executed for example every hour (cron task is recommended)
Run all crawlers in ./crawlers directory with command

<pre>
bundle exec ruby crawler.rb
</pre>

crawler.rb takes also list of files as parameter to run specific crawlers.