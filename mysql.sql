CREATE USER township@localhost IDENTIFIED BY '123456';

GRANT ALL ON *.* TO township@localhost;

flush privileges; 

