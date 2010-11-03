run "rake assets:roll"
run "test -e #{shared_path}/fixofx && ln -nfs #{shared_path}/fixofx #{release_path}/fixofx"
run "test -e #{shared_path}/ssu    && ln -nfs #{shared_path}/ssu    #{release_path}/vendor/ssu"
