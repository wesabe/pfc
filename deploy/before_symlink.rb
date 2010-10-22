run "rake assets:roll"
run "test -e #{shared_path}/fixofx && ln -nfs #{shared_path}/fixofx #{release_path}/fixofx"