React in Rails
==============
React is Awesome! Rails is Awesome! React in Rails should be Awesome Squared... and yet it seems so difficult. This article seeks to provide a decent framework for using React in Rails, with all Node packages, JEST test functionality, and react_ujs Rails helpers. We accomplish this with two awesome gems: react-rails and browserify-rails.

Basic Rails Setup
=================
This article assumes a working knowledge of Rails. However, as a simple scaffolding upon with to build, we will be using the following setup.

1. rails new rex -T
  This gives an empty Rails project with the following Gemfile:
  ```
  # Gemfile
  source 'https://rubygems.org'

  gem 'rails', '4.1.8'
  gem 'sqlite3'

  gem 'sass-rails', '~> 4.0.3'
  gem 'coffee-rails', '~> 4.0.0'
  gem 'uglifier', '>= 1.3.0'
  gem 'therubyracer',  platforms: :ruby

  gem 'jquery-rails'
  gem 'jbuilder', '~> 2.0'

  gem 'spring',        group: :development
  gem 'thin'
  ```

Outline
# Basic Setup
# React-Rails
# Browserify-Rails
# Potential Issues
