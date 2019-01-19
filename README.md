# township

TownShip

## 使用说明
    git clone https://github.com/aasdpiao/township.git
    cd township
    make

    mysql 依赖
    yum install mysql mysql-server mysql-devel
    service mysql start

    mysql -uroot

    CREATE USER township@localhost IDENTIFIED BY '123456';
    GRANT ALL ON *.* TO township@localhost;
    flush privileges; 

    redis 依赖
    ./start_redis.sh

    ./run.sh

    ./stop.sh

## 缺少依赖
    autoconf        yum install autoconf (centos)

    readline-devel  yum install readline-devel

    gcc             yum install gcc

    make            yum install make

