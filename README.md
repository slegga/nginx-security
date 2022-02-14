# nginx-security
guard and login perl scripts to use in nginx auth_request system.

# Testing av webfeil
prove -lv 2>&1|perl -ne 'if ($_ =~s/^\#//) {print}' >/tmp/tull.html;firefox file:///tmp/tull.html

# Test user
perl -MMojo::JWT -e 'print Mojo::JWT->new(secret=>"abc")->decode("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVzIjoxNTgxNDQ1NTg4LCJ1c2VyIjoiYWRvZXIifQ.jWwM1eTO1Ng-97tyAM4xh2gB1RLuEXVo0sz5CNa9eig")->{user};

# INSTALL

#. Create session table
#. ssh <server>
#. sudo su - www
#. www@debian:~/etc$ sqlite3 session_store.db < /home/stein/git/nginx-security/sql/table_defs.sql