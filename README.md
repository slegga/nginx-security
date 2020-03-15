# nginx-security
guard and login perl scripts to use in nginx auth_request system.

# Testing av webfeil
prove -lv 2>&1|perl -ne 'if ($_ =~s/^\#//) {print}' >/tmp/tull.html;firefox file:///tmp/tull.html

