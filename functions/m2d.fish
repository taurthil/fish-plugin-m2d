
# Mage2Docker
#
# Plugin for Oh-My-Fish
function __fish_magento_needs_command
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 -a $cmd[1] = 'm2d' ]
    return 0
  end
  return 1
end

function __fish_magento_using_command
  set cmd (commandline -opc)
  if [ (count $cmd) -gt 1 ]
    if [ $argv[1] = $cmd[2] ]
      return 0
    end
  end
  return 1
end

function m2d_commands
  set ids ash ash-user bash-www bash logs magento mage mage-cache mage-reindex mage-di mage-upgrade mage-report mage-log grunt watch rename rm restart stop inspect top mysqldump mysql ip vst varnish-purge redis-flushall nginx-reload stop-all
  echo $ids
end

function fishm2d_usage
  echo "Usage: m2d [containerName] [command] 
" (m2d_commands) | fold -s -w $COLUMNS >&2
end

function docker_get_container_name
  docker ps | awk '{if(NR>1) print $NF}'
end

function docker_get_container_name_2
  docker ps | awk '{if(NR>1) print $NF}' | xargs
end

function mage2docker_magento
  for cmd in (docker exec $argv[1] bin/magento list | sed 's/\[[0-9;]*m//g' | awk '{if(NR > 15 && /:/) print $argv[1]}')
      echo $cmd
  end
end

function mage2docker_mage
  docker exec -it -u 1000 $argv[1] bin/magento $argv[2]
end

function mage2docker_container_ip
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $argv[1]
end

function mage2docker_report
  for file in (docker exec -u 33 $argv[1] ls -tr var/report)
      echo $file
  end
end

function mage2docker_log
  for file in (docker exec -u 33 $argv[1] ls -tr var/log)
      echo $file
  end
end

function mage2docker_mysql_data
  printf '%s ' 'User name:'
  read -l user
  printf '%s ' 'User password:'
  read -l -s password
  printf '%s ' 'Database name:'
  read -l database
  printf '%s ' 'file name:'
  read -l file
end

function mage2docker
  set curcontext $argv[1]
  set state $argv[2]
  set line $argv[3]

  switch $state
      case containerName
          docker_get_container_name
      case command
          echo $argv | m2d_commands
      case options
          switch $argv[3]
              case mage
                  mage2docker_magento $argv[2]
              case mage-report
                  mage2docker_report $argv[2]
              case mage-log
                  mage2docker_log $argv[2]
          end
  end
end

function mage2docker_main
  switch $argv[2]
      case restart stop inspect rm rename top
          echo "cmd=$argv[2]"
          docker $argv[2] $argv[1]
      
      case logs
          docker logs -f $argv[1]
      
      case ash
          docker exec -it -e LINES=(tput lines) -e COLUMNS=(tput cols) -u 0 $argv[1] ash -l
      
      case ash-user
          docker exec -it -e LINES=(tput lines) -e COLUMNS=(tput cols) -u 1000 $argv[1] ash -l

      case bash
          docker exec -it -e LINES=$(tput lines) -e COLUMNS=$(tput cols) -u 0 $argv[1] bash -l
      
      case www
          docker exec -it -e LINES=$(tput lines) -e COLUMNS=$(tput cols) -u 1000 $argv[1] bash -l
      
      case  bash-www
          docker exec -it -e LINES=$(tput lines) -e COLUMNS=$(tput cols) -u 33 $argv[1] bash -l
      
      case magento
          docker exec -it -u 33 $argv[1] bin/magento

      case mage
          mage2docker_mage $argv[1] $argv[3] 
          
      case mage-cache
          mage2docker_mage $argv[1] cache:clean
      case  mage-reindex
          mage2docker_mage $argv[1] indexer:reindex
          
        case mage-upgrade
          mage2docker_mage $argv[1] setup:upgrade
          
        case mage-di
          mage2docker_mage $argv[1] setup:di:compile
          
        case mage-deploy
          mage2docker_mage $argv[1] setup:static-content:deploy
          
        case grunt
          docker exec -it -u 1000 $argv[1] grunt
          
        case watch
          docker exec -it -u 1000 $argv[1] grunt watch
          
        case mage-report
          docker exec -it $argv[1] cat var/report/$argv[3]
          
        case redis-flushall
          docker exec -it $argv[1] redis-cli flushall
          
        case vst
          docker exec -it -e LINES=$(tput lines) -e COLUMNS=$(tput cols) -u 0 $argv[1] varnishstat
          
        case varnish-purge
          docker exec -it $argv[1] varnishadm "ban req.url ~ /"
          
        case nginx-reload
          docker exec $argv[1] nginx -s reload
          
        case mage-log
          docker exec -it -u 33 $argv[1] tail -f var/log/$argv[3]
          
          #new informations
        case ip
          mage2docker_container_ip $argv[1]
          
        case mysqldump
          mage2docker_mysql_data
          docker exec $argv[1] /usr/bin/mysqldump -u $user --password=$password $database > $file.sql
          echo "Success database backup was created"
          
        case mysql
          mage2docker_mysql_data
          docker exec $argv[1] /usr/bin/mysql -u $user --password=$password $database < $file.sql
          echo "Success database restore"
          
        case help
          zshm2d_usage
          

      case stop-all
          docker stop (docker ps -qa)
      
      case '*'
          if not set -q argv[1]
              fishm2d_usage
              docker ps
          else
              docker exec -it -e LINES=(tput lines) -e COLUMNS=(tput cols) -u 1000 $argv[1] bash -l
          end
  end
end

# for subcmd in m2d_commands
  
# end

if type "docker" >/dev/null
  alias m2d='mage2docker_main'
  alias stats_m2d='docker stats (docker inspect -f '{{.Name}}' (docker ps -q) | string sub -s 2)'
else
  echo "mage2docker - docker is not installed"
end

