# MiniApivore

MiniApivore is an adaptation of the apivore gem for mini-test instead of rspec. 

Original project: https://github.com/westfieldlabs/apivore

So base credits should go to the apivore authors, this is 50% copy/paste of original project. 
Rem: didn't forked it cause didn't expect it to be a relatively small set of changes.

Code-Test-Document, the idea of how things are need to be done: https://medium.com/@leshchuk/code-test-document-9b79921307a5

## What's new/different
* Swagger schema can be loaded from a file or directly from the specified route. There can be one schema per MiniTestClass. 
* Removed all dependencies of active support and rails. See tests as an example on how 
  to use a mini-apivore outside a rails* (*you need to load schema from file then)
* Didn't implement a custom schema validator ( but I kept the original schema and code from apivore in case of a future need )
* The test for untested routes now added by default at the end of all runnable_methods
* Much more simplified tests against original project, rspec is replaced with minitest
* Removed all rspec dependencies and usage.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mini-apivore'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mini-apivore

## Usage

To start testing routes with mini_apivore you need: 

* ```require 'mini_apivore' ``` in you MiniTest class file
* ```include MiniApivore``` in you MiniTest class 
* ```init_swagger('apidocs.json')``` init swagger-schema to test against,
    '/apidocs.json' -- this should be a file_path OR a rails route. 
**Rem** running init_swagger allows you to test multiple schemas, one per class, 
        but if you want to inherit from those classes and run each resource from schema in it's own class, 
        you need to redefine swagger_checker helper method in the class with init_swagger call
        
* Run ```check_route( :get, '/cards.json', OK )``` against all routes in your swagger schema

You can see example in test/mini_apivore/mini_apivore/api_schemas_test.rb

Here another complete example of testing simple internal REST api for Card model 
with devise integration as authentication framework

```ruby
#mini_apivore_helper.rb
require 'mini_apivore'

# this is simple intermediate class for apivore test classes
class MiniApivoreTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include MiniApivore
  # initialize schema from local file
  init_swagger('apidocs.json')

  # swagger checker initialized once per init_swagger call, 
  # but when you are testing one schema -- you can inherit from this class only ones, 
  # and check resources in dedicated classes. 
  # In that case you need redefine original swagger_checker, to map to exact 
  def swagger_checker;
    SWAGGER_CHECKERS[MiniApivoreTest]
  end
  
end
```

The most readable way to handle check_routes, especially when you have nested resources i.e. like always :), 
is to create a set of named route helpers for the TestClass, may be even extract it to a module if it's a generalized helpers.

Then you need to redefine ```prepare_error_backtrace```, cause assert for correct execution is hidden deep in stack
 and instead of pointing to that exact but useless part of stack with asserted frame 
you need show something upper and with a better context,
 so you should redefine ```prepare_error_backtrace```!

Here is an example how you can handle simple resource route testing. 
As you can see, you can read it without verbosity and a context of a routes structure:
 
```ruby
#cards_api_test.rb
require 'test_helper'
require 'mini_apivore_helper'

class CardsApiTest < MiniApivoreTest
  
   #------- DEFINE CLASS SPECIFIC NAMED ROUTE HELPERS ----------------
    def __get_cards(expectation)
       check_route( :get, '/cards.json', expectation )
    end 

    def __get_card( card, expectation)
      # check_route will use to_param inside
      check_route( :get, '/cards/{id}.json', expectation, id: card )
    end 

    def __update_card( card, expectation, params = {})
      # check_route will use to_param inside
      check_route( :patch, '/cards/{id}.json', expectation, id: card, **params)
    end 

    def __create_card( expectation, params = {})
      check_route( :post, '/cards.json', expectation, params )
    end

    def __delete_card(card, expectation)
      check_route( :delete, '/cards/{id}.json', expectation, id: card )
    end
   #------- DEFINE CLASS SPECIFIC NAMED ROUTE HELPERS DONE -----------
   # 
   # failure need a proper stack frame and a context around:
   def prepare_error_backtrace
     # it will deliver something like this: 
     #"/app/test/helpers/base_routes_helpers.rb:57:in `__create_card'",
     #"/app/test/integration/cards_api_test.rb:71:in `block (2 levels) in <class:CommentsApiTest>'",
     Thread.current.backtrace[2..-1].slice_after{|trc| trc[/check_route/] }.to_a.last[0..1]
   end

  test 'cards unauthorized' do
    card = cards(:valid_card_1)
    __get_cards( NOT_AUTHORIZED )
    __get_card( card, NOT_AUTHORIZED )
    __update_card( card, NOT_AUTHORIZED, _data: { card: { title: '1' } } )
    __create_card( NOT_AUTHORIZED, _data: { card: { title: '1' } } )
    __delete_card( card, NOT_AUTHORIZED )
  end

  test 'cards forbidden' do
    sign_in( :first_user )
    # card with restricted privileges 
    card = cards(:restricted_card)

    __get_card( card, FORBIDDEN )
    __update_card( card, FORBIDDEN, id: card, _data: { card: { title: '1' } } )

    # this may be added if not all users can create cards 
    # check_route( :post, '/cards.json', FORBIDDEN,  _data: { card: { title: '1' } } )

    __delete_card( card, FORBIDDEN)
  end

  test 'cards not_found' do
    sign_in( :first_user )
    card = Card.new(id: -1)
    __get_card( card, NOT_FOUND )
    __update_card( card, NOT_FOUND )
    __delete_card( card, NOT_FOUND  )
  end

  test 'cards REST authorized' do
    sign_in( :first_user )
    __get_cards( OK )
    __get_cards( cards(:valid_card_1), OK )

    assert_difference( -> { Card.count } ) do
      __create_card( OK, _data: {
                     card: { title: 'test card creation', 
                     card_preview_img_attributes: {
                                upload: fixture_file_upload( Rails.root.join('test', 'fixtures', 'files', 'test.png') ,'image/png')
                              }
                     } } )
    end
    created_card = Card.last
    assert_equal( 'test card creation', created_card.title )

    __update_card( created_card, OK, _data: { card: { title: 'Nothing' } } )
    assert_equal( created_card.reload.title, 'Nothing' )

    assert_difference( -> { Card.count }, -1 ) do
       __delete_card( created_card, NO_CONTENT )
    end

  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mini-apivore. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
