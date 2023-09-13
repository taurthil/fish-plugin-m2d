set -l commands ash ash-user bash-www bash logs magento mage mage-cache mage-reindex mage-di mage-upgrade mage-report mage-log grunt watch rename rm restart stop inspect top mysqldump mysql ip vst varnish-purge redis-flushall nginx-reload stop-all
complete -f --exclusive --condition __fish_use_subcommand -c m2d -a "(docker_get_container_name)"
complete -c m2d -n "__fish_seen_subcommand_from (docker_get_container_name)" -f -r -a "$commands"