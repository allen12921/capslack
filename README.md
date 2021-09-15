# Capslack

Send notification message to your Slack channel about your Rails Capistrano deployment via Slack webhook.

## Installation

Add this line to your application's Gemfile:

```ruby
 gem 'capslack', git: 'git@github:liuyang12921/capslack.git', require: false
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capslack

## Usage

Add this line to your `Capfile`:

```ruby
require 'capslack', require: false
```

Setup in `config/deploy.rb`. Example:

```ruby
set :slack_config, {
  web_hook: 'https://hooks.slack.com/services/mMg3G3EHP/FqgP4hUR3/uvkJbkYCXm9ALVn7UT3M6u',
  app_name: 'APP_NAME',
  channel: 'SLACK_CHANNEL_NAME'
}

before 'deploy:updating', 'slack:notify:starting_to_deploy' do
  Rake::Task['slack:notify'].invoke('Starting to deploy', false)
end

after 'deploy:finishing', 'slack:notify:deployment_finished' do
  Rake::Task['slack:notify'].invoke('Deployment finished', true)
end

after 'sidekiq:stop', 'slack:notify:sidekiq_stop' do
  Rake::Task['slack:notify'].invoke('Sidekiq stopped', false)
end

after 'sidekiq:start', 'slack:notify:sidekiq_start' do
  Rake::Task['slack:notify'].invoke('Sidekiq started', false)
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flanker/capslack.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
