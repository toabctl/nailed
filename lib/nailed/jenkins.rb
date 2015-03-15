module Nailed
  class Jenkins
    def initialize
      @client = JenkinsApi::Client.new(
         :server_ip => Nailed.get_config["jenkins"]["server_ip"],
         :username  => Nailed.get_config["jenkins"]["username"],
         :password  => Nailed.get_config["jenkins"]["password"])
    end

    def test
      @job = "openstack-mkcloud"
      @builds = get_builds(@job)
      puts list_by_status("failure")
    end

    def list_all
      @client.job.list_all
    end

    def list_all_with_details
      @client.job.list_all_with_details
    end

    def list_by_status(status, jobs = [])
      @client.job.list_by_status(status, jobs)
    end

    def get_builds(job_name)
      @client.job.get_builds(job_name)
    end

    def get_current_build_status(job_name)
      @client.job.get_current_build_status(job_name)
    end

    def get_build_params(job_name)
      @client.job.get_build_params(job_name)
    end

    def get_build_details(job_name, build_num)
      @client.job.get_build_details(job_name, build_num)
    end

    def get_console_output(job_name, build_num = 0, start = 0, mode = 'text')
      @client.job.get_console_output(job_name, build_num, start, mode)
    end
  end
end
