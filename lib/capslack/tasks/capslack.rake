namespace :slack do

  def post_to_slack message, full_format: false
    require 'net/http'
    require 'openssl'
    require 'json'

    stage = fetch(:stage)
    branch = fetch(:branch)
    local_user = fetch(:local_user)
    slack_config = fetch(:slack_config)
    time = Time.now.to_s
    $global_stime = Time.now unless defined? $global_stime
    duration = Time.at(Time.now - $global_stime).utc.strftime("%H:%M:%S")
    repo_url = fetch(:repo_url)
    base_url = 'https://'+repo_url[4..-5].gsub(':','/')
    current_version = fetch(:current_revision,'default')

    unless defined? $global_old_version
     on primary(:app) do
         within current_path do
           $global_old_version = capture :cat, 'REVISION'
         end
     end
    end

    uri = URI(slack_config[:web_hook])
    payload = {
      channel: slack_config[:channel],
      icon_emoji: ':rocket:',
      username: 'Capistrano',
      pretty: 1
    }

    message_with_app_name = "*[#{slack_config[:app_name]}]*: #{message}"

    if full_format
      payload[:fallback] = "#{message_with_app_name}. (branch *#{branch}* on *#{stage}*)"
      payload[:color] = 'good'
      payload[:pretext] = message_with_app_name
      if message.include?('finished')
         payload[:fields] = [
         {title: 'App Name', value: slack_config[:app_name], short: true},
         {title: 'User', value: local_user, short: true},
         {title: 'Branch', value: branch, short: true},
         {title: 'Environment', value: stage, short: true},
         {title: 'Duration', value: duration, short: true},
         {title: 'Diff', value: base_url+'/compare/'+$global_old_version+'...'+current_version, short: true},
         {title: 'Time At', value: Time.now.to_s, short: true}
       ]
      else
        payload[:fields] = [
        {title: 'App Name', value: slack_config[:app_name], short: true},
         {title: 'User', value: local_user, short: true},
        {title: 'Branch', value: branch, short: true},
        {title: 'Environment', value: stage, short: true},
        {title: 'Time At', value: Time.now.to_s, short: true}
        ]
      end
    else
      payload[:text] = "#{message_with_app_name}. (branch *#{branch}* on *#{stage}*)"
    end

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new uri.request_uri
      request.add_field('Content-Type', 'application/json')
      request.add_field('Accept', 'application/json')
      request.body = payload.to_json
      http.request request
    end
  end

  desc 'Send message to slack chennel'
  task :notify, [:message, :full_format] do |_t, args|
    message = args[:message]
    full_format = args[:full_format]

    run_locally do
      with rails_env: fetch(:rails_env) do
        post_to_slack message, full_format: full_format
      end
    end

    Rake::Task['slack:notify'].reenable
  end

end
