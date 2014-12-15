Setting up Rails for React and Jest
===================================

[React](http://facebook.github.io/react/) is Awesome! [Rails](http://rubyonrails.org/) is Awesome! [Jest](https://facebook.github.io/jest/) is awesome! Using Jest with React in Rails should be Awesome Cubed... and yet it seems so difficult. This article seeks to provide a decent setup for using React in Rails, with all Node packages, Jest test functionality, and react_ujs Rails helpers. We accomplish this using two sweet gems, [react-rails](https://github.com/reactjs/react-rails) and [browserify-rails](https://github.com/browserify-rails/browserify-rails), and a little bit of glue.

*All of the code used in this article is available on [GitHub](https://github.com/HurricaneJames/rex).*

Outline
-------

- [Basic Rails Setup](#user-content-basic-rails-setup)
- [React-Rails](#user-content-add-in-react-rails)
- [Browserify-Rails](#user-content-browserify-rails)
- [Fixing Browserify/React-Rails](#user-content-fixing-browserifyreact-rails)
- [Jest](#user-content-jest)
- [Gotchas](#user-content-gotchas-with-jquery-and-other-gem-based-assets)
- [Conclusion](#user-content-conclusion)

Basic Rails Setup
=================
We assume a working knowledge of [Rails](http://rubyonrails.org/). However, as a simple scaffolding upon which to build, we will be using the following setup.

1. `rails new rex -T`

2. Remove Turbolinks *technically optional*
  * from the `Gemfile`

      ```ruby
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

  * from `application.js`

      ```javascript
      // app/assets/javascripts/application.js
      //= require jquery
      //= require jquery_ujs
      //= require_tree .
      ```

3. `cd rex; bundle install`

4. `rails generate controller pages index --no-helper --no-assets --no-controller-specs --no-view-specs`

5. Update Rails routes root to new `pages#index`.

    ```ruby
    # config/routes.rb
    Rails.application.routes.draw do
      get 'pages/index'
      root to: 'pages#index'
    end
    ```

Add in React-Rails
==================
The best part of [React-Rails](https://github.com/reactjs/react-rails) is the React UJS and the view helpers. However, the stable versions of react-rails only contain react.js. Hopefully the react-rails project will correct this shortcoming in the future as react_ujs is the most valuable part of the gem. In the meantime, use the 1.0.0.pre branch directly from [GitHub](https://github.com/).

1. Add 'react-rails' to the Gemfile.
    
    echo "gem 'react-rails', '~> 1.0.0.pre', github: 'reactjs/react-rails'" >> Gemfile

2. `bundle install`

3. Add react-rails to the application config.

    ```ruby
    # config/application.rb
    config.react.variant      = :production
    config.react.addons       = true
    ```

4. Setup react-rails for development mode.

    ```ruby
    # config/environments/development.rb
    config.react.variant = :development
    ```

5. Add React to application by adding react via two sprocket includes `//= require react` and `//= require react_ujs`. This will change in the next section, but only slightly.

  * First, create a new `componetns.js` file which will include all of our React components.

    ```javascript
    // app/assets/javascripts/components.js
    //= require react
    //= require react_ujs
    ```

  * Then update `application.js` by removing the `require_tree` directive and including the new `components.js` code.

    ```javascript
    // app/assets/javascripts/application.js
    //= require jquery
    //= require jquery_ujs
    //= require components
    ```

At this point it is possible to create React components by placing them in the `components.js` file and calling them with `react_component 'ComponentName', {props}`. However, it has some limitations. First, it cannot make use of Jest for testing, though Jasmine and full integration tests should work. Second, it is not possible to `require` any node packages like, for example, the [reflux](https://www.npmjs.com/package/reflux) package.

Browserify-Rails
================
The general solution for adding CommonJS and `require` for React is to use a package like [browserify](http://browserify.org/). Fortunately, there's a gem for that: [browserify-rails](https://github.com/browserify-rails/browserify-rails). Installation is fairly straight forward.

1. Verify that [Node](http://nodejs.org/) is installed.

2. Add browserify-rails to the gemfile.

    echo "gem 'browserify-rails', '~>0.5'" >> Gemfile

3. `bundle install`

4. Create a package.json file.

    ```json
    {
      "name": "rex-app",
      "devDependencies": {
        "browserify": "~>6.3",
        "reactify": "^0.17.1"
      },
      "license": "MIT",
      "engines": {
        "node": ">=0.10.0"
      },
    }
    ```

5. `npm install`
  * Note: add `/node_modules` to the .gitignore file if git is being used.

6. Enable converstion of JSX to JS by adding the following param to `config/application.rb`

    ```ruby
    config.browserify_rails.commandline_options = "--transform reactify --extension=\".jsx\""
    ```

7. Create a `components/` directory in `app/assets/javascripts/`. All React components will go in this directory.

8. Add components.

    ```javascript
    // app/assets/javascripts/components/DemoComponent.jsx
    var DemoComponent = React.createClass({displayName: 'Demo Component',
      render: function() {
        return <div>Demo Component</div>;
      }
    });

    // each file will export exactly one component
    module.exports = DemoComponent;
    ```

9. Update `components.js` to link required modules from the components directory.

    ```javascript
    // note that this is a global assignment, it will be discussed further below
    DemoComponent = require('./components/DemoComponent');
    ```

10. Add the demo component into our view.

    ```html
    <h1>/app/views/pages/index.html.erb</h1>
    <%= react_component 'DemoComponent', {} %>
    ```

There are some things to note about this setup. First, do not `require('react')` via CommonJS `require()`. React is being loaded globaly by react-rails. Second, each and every single component that should be available globally needs to be `require()`d in components.js. CommonJS does not have an equivalent to the sprocket `//= require_tree` directive.

Fixing Browserify/React-Rails
=============================
Problem, `require('react')` is necessary if we want to use Jest. The solution so far gives `require()`, but not `require('react')`. So, how to get this crucial last requirement. Presently, the only workable solution is to ignore the react.js asset provided by react-rails and use the Node version instead.

1. Replace `//= require react` with `require('react')` in component.js

    ```javascript
    // app/assets/javascripts/components.js
    //= require_self
    //= require react_ujs

    React = require('react');

    // put components here
    DemoComponent = require('./components/DemoComponent');
    ```

    `//= require_self` is called before `//= require react_ujs`. This allows react.js to be loaded from node modules instead of react-rails.

2. Update `package.json` with the following in `devDependencies`:

    ```json
    "react": "^0.12.0",
    "react-tools": "^0.12.1"
    ```

3. Run `npm install` again.

4. Add `var React = require('react');` to your top of each of your components. For example:

    ```javascript
    // app/assets/javascripts/components/DemoComponent.jsx
    var React = require('react');

    var DemoComponent = React.createClass({displayName: 'Demo Component',
      render: function() {
        return <div>Demo Component</div>;
      }
    });

    module.exports = DemoComponent;
    ```

Now we can `require('react')`, export the component via `module.exports`, and inject components with `react_component` Rails view helpers.

Jest
====
We can finally get going with [Jest](https://facebook.github.io/jest/). Jest is based on Jasmine and used by Facebook to test React. It automatically mocks out all modules except those being tested, it can run tests in parallel, and it runs in a fake DOM implementation. Bottom line, Jest is awesome.

However, Jest really wants a CommonJS structure where everything is included via `require()`. That is why we had to go through all the trouble in the previous sections. Fortunately, now that the hard work is done, making Jest work is relatively easy. It requires updating `package.json`, creating a new directory, and adding a couple of script files.

1. Create a directory for the tests in `app/assets/javascripts/components/__tests__`.
    
    Note that Rails generally puts tests in a `test/` or `spec/` directory. However, it is easier to put Jest tests in a `__tests__` directory closer to the actual components. Placing the tests here has one slight complication, sprocket's `//= require_tree` will include the tests as part of the build. This should not be an issue as the `components/` directory should not be part of any `//= require_tree` directive anyway, as that would break the CommonJS structure we use anyway.

2. Create a file `app/assets/components/javascripts/__tests__/preprocessor.js` to convert any JSX to JS (remember that browserify-rails does this via reactify when running via Rails).

  ```javascript
  // app/assets/javascripts/components/__tests__/preprocessor.js
  var ReactTools = require('react-tools');

  module.exports = {
    process: function(src) {
      return ReactTools.transform(src);
    }
  };
  ```

3. Add and configure Jest in the `package.json`

  ```json
  "devDependencies": {
    "jest-cli": "^0.2.0",
  },
  "scripts": {
    "test": "node ./node_modules/jest-cli/bin/jest.js"
  },
  "jest": {
    "rootDir": "./app/assets/javascripts/components",
    "scriptPreprocessor": "<rootDir>/__tests__/preprocessor.js",
    "moduleFileExtensions": [ "js", "jsx"],
    "unmockedModulePathPatterns": [
      "react"
    ],
    "testFileExtensions": ["js", "jsx"],
    "testPathIgnorePatterns": [ "preprocessor.js" ]
  }
  ```

    * rootDir points to the components directory (Jest will automatically load the __tests__ path by default).
    * scriptPreprocessor points to our JSX preprocessor script.
    * umockedModulePathPatterns tells Jest not to mock out React, which we need for our components to work.
    * testPathIgnorePatterns tells Jest to ignore our JSX preprocessor. If we had placed it in a different directory we would not need this pattern.

4. `npm install`

5. Create a test for our demo component.

    ```javascript
    // app/assets/javascripts/components/__tests__/DemoComponent-test.jsx
    jest.dontMock('../DemoComponent');

    describe('DemoComponent', function() {
      it('should tell use it is a demo component', function() {
        var React = require('react/addons');
        var TestUtils = React.addons.TestUtils;
        var DemoComponent = require('../DemoComponent');
        var demoComponent = TestUtils.renderIntoDocument(<DemoComponent/>);
        
        expect(demoComponent.getDOMNode().textContent).toBe('Demo Component');
      });
    });
    ```

5. `npm test`

Gotchas with jQuery and other Gem-based Assets
==============================================
The basic Rails application uses the `jquery-rails` gem. `jquery-rails` has the same problem with `require('jquery')` that `react-rails` has with `require('react')`. This will be a problem with any application that adds assets via gems and tries to use both `//= require` and `require()` for that asset. Fortunately, jQuery is resilient to multiple includes, so the biggest concern is bloat.

The maintainers of `browserify-rails` know about the [problem](https://github.com/browserify-rails/browserify-rails/issues/9). Hopefully, they come up with a solution. In the mean time, one potential solution is to remove the `jquery-rails` gem, `//= require jquery` and `//= require jquery_ujs`. A better solution would be to add jQuery to `application.js` the way react.js is added to `components.js`.

```javascript
//= require self
//= require jquery_ujs
//= components

$ = jQuery = require('jquery');
```

Then add jQuery to the devDependencies of `package.json`.

```json
"devDependencies": {
    "jquery": "^2.1.1"
}
```

Conclusion
==========
We have setup Rails to work with React, Node packages, and Jest. To use this setup, simply add React components to the `app/assets/javascript/components/` directory and put any global components that the `react_ujs` `react_component` view helper might need in `app/assets/javascripts/components.js'. Tests are simple Jest tests in the `app/assets/javascripts/components/__tests/` directory. Rspec/Cucumber integration tests should work as expected too.

I hope this article has been useful to help setup a foundation for using React and Jest in your Rails application.
