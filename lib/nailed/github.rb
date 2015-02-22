module Nailed
  class Github
    attr_reader :client

    def initialize
      Octokit.auto_paginate = true
      @client = Octokit::Client.new(:netrc => true)
    end

    def get_open_pulls
      Nailed.get_config["products"].each do |product,values|
        organization = values["organization"]
        repos = values["repos"]
        repos.each do |repo|
          Nailed.log("info", "#{__method__}: Getting open pullrequests for #{organization}/#{repo}")
          pulls = @client.pull_requests("#{organization}/#{repo}")
          pulls.each do |pr|
            attributes = {:pr_number => pr.number,
                         :title => pr.title,
                         :state => pr.state,
                         :url => pr.html_url,
                         :created_at => pr.created_at,
                         :repository_rname => repo}

            # if pr exists dont create a new record
            pull_to_update = Pullrequest.all(:pr_number => pr.number, :repository_rname => repo)
            if pull_to_update
              if pr.state == "closed"
                # delete record if pr.state changed to "closed"
                pull_to_update.destroy
                Nailed.log("info", "#{__method__}: Destroyed closed pullrequest #{pr.repo} ##{pr.number}")
              else
                # update saves the state, so we dont need a db_handler
                # TODO check return code for true if saved correctly
                pull_to_update.update(attributes)
                Nailed.log("info", "#{__method__}: Updated #{pr.repo} ##{pr.number} with #{attributes.inspect}")
              end
            else
              db_handler = Pullrequest.first_or_create(attributes)
              Nailed.log("info", "#{__method__}: Created new pullrequest #{pr.repo} ##{pr.number} with #{attributes.inspect}")
            end

            Nailed.save_state(db_handler) unless defined? db_handler
            Nailed.log("info", "#{__method__}: Saved #{attributes.inspect}")
          end unless pulls.empty?
          write_pull_trends(repo)
        end unless repos.nil?
      end
    end

    def write_pull_trends(repo)
      Nailed.log("info", "#{__method__}: Writing pull trends for #{repo}")
      open = Pullrequest.count(:repository_rname => repo)
      attributes = {:time => Time.new.strftime("%Y-%m-%d %H:%M:%S"),
                    :open => open,
                    :repository_rname => repo}

      db_handler = Pulltrend.first_or_create(attributes)

      Nailed.save_state(db_handler)
      Nailed.log("info", "#{__method__}: Saved #{attributes.inspect}")
    end
  end
end