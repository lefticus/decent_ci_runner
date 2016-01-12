require 'win32/service'




# Configure everything
Service.configure(
		:service_name       => 'decent_ci',
		:service_type       => Service::WIN32_OWN_PROCESS,
		:start_type         => Service::AUTO_START,
		:error_control      => Service::ERROR_NORMAL,
		:binary_path_name   => "c:\\Program Files\\Git\\git-bash.exe #{ENV["USERPROFILE"]}\\decent_ci_run.sh #{ENV["USERPROFILE"]}\\decent_ci_config.yaml",
#		:load_order_group   => 'Network',
		:service_start_name => "#{ENV["USERDOMAIN"]}\\#{ENV["USERNAME"]}",
#		:password           => 'XXXXXXX',
		:display_name       => 'decent_ci build system',
		:description        => 'A service for running decent_ci on boot'
		)


