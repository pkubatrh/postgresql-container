# Grow partition
echo -e 'n\np\n\n\nw\n' | fdisk /dev/vda
partprobe && pvcreate /dev/vda4 && vgextend VolGroup00 /dev/vda4 && lvextend /dev/VolGroup00/LogVol00 -l 100%FREE -r

ret=0
i=0
while [ $ret -eq 0 ]; do
  docker rm -f $(docker ps -aq --filter="name=postgresql") >/dev/null; # docker rmi -f $(docker images -q) >/dev/null
  docker network ls | grep postgresql | awk "{ print \$1 }" | xargs docker network rm >/dev/null
  docker volume ls -qf dangling=true | xargs -r docker volume rm >/dev/null
  rm -rf /tmp/pg-testdata* /tmp/*postgresql*
  make -j -Otarget VERSIONS="9.4 9.5 9.6" SKIP_SQUASH=1 TEST_CASE="run_master_restart_test run_replication_test" test &> log
  ret=$?
  i=$((i+1))
  echo \($(date +%H:%M)\) run ${i}: $ret
done
