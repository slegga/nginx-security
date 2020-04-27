drop table sessions;
create table sessions(sid TEXT PRIMARY KEY, user TEXT, groups TEXT, status TEXT, expires INTEGER);
