## 0.3.0
* rubocop-shopify added and applied
* released https://github.com/alekseyl/mini-apivore/pull/1
* released https://github.com/alekseyl/mini-apivore/pull/2
* released https://github.com/alekseyl/mini-apivore/pull/3
* fixed other issues related to ** and kwargs blocking ruby 3 usage

## 0.2.1
* added default prepare_error_backtrace method

## 0.2.0
* prepare_backtrace extracted as a standalone method, you can play with it to deliver clear failure point, whenever you are wrapping check_route in named helper or just want more context
* Readme update

## 0.1.8
* fix issue when to_param return not string

## 0.1.7 
* message will show the check_routes execution caller line, not the assert inside

## 0.1.5 
* add full path and params causing failure to assertion

## 0.1.4
* add fallbacks for to_param

## 0.1.3
* add NO_CONTENT to http response codes

## 0.1.2 

* check_route now use inside to_param instead of to_s