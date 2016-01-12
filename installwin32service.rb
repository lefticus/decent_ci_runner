

puts(`mkdir c:\\decent_ci_runner`)
puts(`copy decent_ci_run.sh c:\\decent_ci_runner\\decent_ci_run.sh`)
puts(`elevate nssm install decent_ci_runner "c:\\Program Files\\Git\\bin\\bash.exe" "c:\\decent_ci_runner\\decent_ci_run.sh" "c:\\decent_ci_runner\\decent_ci_config.yaml" false`)


