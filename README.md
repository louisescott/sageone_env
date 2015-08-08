# SageoneEnv

This gem enables the database yaml file to be configured in each sage application within the directory it is executed in quickly and easily. Once installed it uses command line switches to pass values to, such as the environment and builds targeted. 
Default settings are stored in a yaml file such as username and password but these can be overridden. It checks whether the changes have actually taken affect and outputs the result to the user.
The changes can easily be reversed with one call to the gem. It checks whether the reversal has been successful and outputs the result to the user.

## Installation

#To use as a command line application clone the repository and run:

```ruby
rake install
```
#To use as a gem add this line to your application's Gemfile:

```ruby
gem 'sageone_env'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sageone_env

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sageone_env.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

