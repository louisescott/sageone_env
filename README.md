# SageoneEnv

This gem enables the database yaml file to be configured in each sage application within the directory it is executed from quickly and easily. Once installed it uses command line switches to pass values to, such as the environment and builds targeted.
Default settings are stored in a yaml file such as username and password but these can be overridden. It checks whether the changes have actually taken affect and outputs the result to the user.
The changes can easily be reversed with one call to the gem. It checks whether the reversal has been successful and outputs the result to the user.

## Installation
#To use as a command line application clone the repository and run:

```ruby
rake install
```

Or install it yourself as:

    $ gem install sageone_env

run rbenv rehash after installing

## Usage

The gem has defaults stored for each Sageone app available at the time of its launch. The following is a list of defaults held for each app:
  - database_name: <database name>
  - username: <username>
  - password: <password>

As credentials cannot be stored in source control it would be wise to update the default username and password in the gem before configuring to connect to a database. This is a one time only task. Use:
```ruby
sageone_env --set_defaults -u <username> -p <password>
```
to persist the values.
Once done this means a username and password is not required ot be passed for your favourite connection. For example the obfuscated database which use the same username and password for every instance.

The changes to the database.yml file involves wiping the file initially then writing new keys for the chosen environment. When finished simply call 
```ruby
sageone_env --revert
```
This iterates over all the altered database.yml files and checks them out from git. It checks that this has been successful and outputs the result to the user.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sageone_env.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

