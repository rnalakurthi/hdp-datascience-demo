set -e

#HOME_DIR=$1
HOME_DIR=/home/demo
PROJECT_DIR=$HOME_DIR/hdp-datascience-demo


echo 'M2_HOME=/usr/share/maven/latest' >> ~/.bashrc
echo 'M2=$M2_HOME/bin' >> ~/.bashrc
echo 'PATH=$PATH:$M2' >> ~/.bashrc

export M2_HOME=/usr/share/maven/latest
export M2=$M2_HOME/bin
export PATH=$PATH:$M2

#install sqllite
echo "Installing SQLlite"
cd $HOME_DIR 
wget http://www.sqlite.org/2014/sqlite-autoconf-3080600.tar.gz
tar xvfz sqlite-autoconf-3080600.tar.gz 
cd sqlite-autoconf-3080600 
./configure --prefix=$HOME_DIR/.sqlite3 
make && make install

#install python
echo "Installing Python..."
cd $HOME_DIR 
wget https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz 
xz -d Python-2.7.8.tar.xz && tar -xvf Python-2.7.8.tar 
cd Python-2.7.8 
#./configure --prefix=$HOME_DIR/.python LDFLAGS='-L$HOME_DIR/sqlite-autoconf-3080600/.libs' CPPFLAGS='-I$HOME_DIR/sqlite-autoconf-3080600/' 
./configure --prefix=$HOME_DIR/.python LDFLAGS='-L/home/demo/sqlite-autoconf-3080600/.libs' CPPFLAGS='-I/home/demo/sqlite-autoconf-3080600/' 
make && make altinstall

# Install Python’s package management: easy_install and pip
echo "Installing python pip..."
cd $HOME_DIR 
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py 
.python/bin/python2.7 ez_setup.py 
.python/bin/easy_install-2.7 pip

# Install and activate VirtualEnv
echo "Installing python virtualenv..."
.python/bin/pip2.7 install virtualenv 
.python/bin/virtualenv-2.7 pyenv 
chmod +x ./pyenv/bin/activate 
source ./pyenv/bin/activate
echo "source $HOME_DIR/pyenv/bin/activate" >> $HOME_DIR/.bashrc


#Install data-science related Python package - this can take 10min
echo "Installing python packages: numpy scipy pandas scikit-learn..."
pip install numpy scipy pandas scikit-learn

#Install matplotlib (for graphics in Python)
cd $HOME_DIR
wget http://sourceforge.net/projects/freetype/files/freetype2/2.5.0/freetype-2.5.0.tar.gz
tar xvfz freetype-2.5.0.tar.gz


cd $HOME_DIR/freetype-2.5.0
sudo ./configure --prefix=/usr --disable-static && make
sudo make install 
sudo install -v -m755 -d /usr/share/doc/freetype-2.5.0 
sudo cp -v -R docs/* /usr/share/doc/freetype-2.5.0


cd $HOME_DIR
source ./pyenv/bin/activate
pip install matplotlib

# Install ipython
easy_install ipython

#Install PYDOOP – package to enable Hadoop access from Python.
echo "Installing pydoop..."
wget http://sourceforge.net/projects/pydoop/files/Pydoop-0.12/pydoop-0.12.0.tar.gz 
tar xzvf pydoop-0.12.0.tar.gz 
cd pydoop-0.12.0

#https://github.com/ZEMUSHKA/pydoop/commit/414a2e52390a873e4766633891190ffede937d90
#vi pydoop/hadoop_utils.py 
mv $HOME_DIR/pydoop-0.12.0/pydoop/hadoop_utils.py $HOME_DIR/pydoop-0.12.0/pydoop/hadoop_utils.py.bak
cp -f $PROJECT_DIR/setup/hadoop_utils.py $HOME_DIR/pydoop-0.12.0/pydoop

#https://github.com/ZEMUSHKA/pydoop/commit/e3d3378ae9921561f6c600c79364c2ad42ec206d
#vi setup.py
mv $HOME_DIR/pydoop-0.12.0/setup.py $HOME_DIR/pydoop-0.12.0/setup.py.bak
cp -f $PROJECT_DIR/setup/setup.py $HOME_DIR/pydoop-0.12.0

if [ -e /usr/hdp/2.2*/hadoop/bin/hdfs ]
then
	export HADOOP_HOME=/usr/hdp/2.2*/hadoop
	export HADOOP_VERSION=hadoop-2.2.0
else
	export HADOOP_HOME=/usr/lib/hadoop
fi

export JDK_VER=`ls /usr/jdk64/`
export JAVA_HOME=/usr/jdk64/$JDK_VER
echo "export HADOOP_HOME=$HADOOP_HOME" >> $HOME_DIR/.bashrc
echo "export HADOOP_HOME=$HADOOP_VERSION" >> $HOME_DIR/.bashrc
echo "export JAVA_HOME=/usr/jdk64/$JDK_VER"  >> $HOME_DIR/.bashrc 
 
# build PyDoop 
python setup.py build 
python setup.py install --skip-build


#Setup default IPython notebook profile
pip install tornado pyzmq ipython pygments matplotlib jinja2
ipython profile create default

echo "c.IPKernelApp.pylab = 'inline'" >> $HOME_DIR/.ipython/profile_default/ipython_notebook_config.py
echo "c.NotebookApp.ip = '*' " >> $HOME_DIR/.ipython/profile_default/ipython_notebook_config.py
echo "c.NotebookApp.open_browser = False" >> $HOME_DIR/.ipython/profile_default/ipython_notebook_config.py
echo "c.NotebookApp.port = 9999" >> $HOME_DIR/.ipython/profile_default/ipython_notebook_config.py


echo "Installing ISpark..."
cd $HOME_DIR
git clone https://github.com/tribbloid/ISpark
cd ISpark/
mvn package
source ../pyenv/bin/activate
ipython profile create spark


echo "import os" >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
echo "SPARK_HOME = os.environ['SPARK_HOME']" >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
echo "MASTER = 'yarn-client'" >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
#echo 'c.KernelManager.kernel_cmd = [SPARK_HOME+"/bin/spark-submit",   "--master", MASTER,  "--class", "org.tribbloid.ispark.Main",   "--executor-memory", "2G", "$HOME_DIR/ISpark/core/target/ispark-core-assembly-0.1.0-SNAPSHOT.jar",   "--profile", "{connection_file}",  "--interp", "Spark",  "--parent"]' >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
echo 'c.KernelManager.kernel_cmd = [SPARK_HOME+"/bin/spark-submit",   "--master", MASTER,  "--class", "org.tribbloid.ispark.Main",   "--executor-memory", "2G", "/home/demo/ISpark/core/target/ispark-core-assembly-0.1.0-SNAPSHOT.jar",   "--profile", "{connection_file}",  "--interp", "Spark",  "--parent"]' >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
echo "c.NotebookApp.ip = '*' " >> $HOME_DIR/.ipython/profile_spark/ipython_config.py
echo "c.NotebookApp.open_browser = False" >> $HOME_DIR/.ipython/profile_spark/ipython_config.py


echo "Downloading Spark..."
cd
wget http://public-repo-1.hortonworks.com/HDP-LABS/Projects/spark/1.1.0/spark-1.1.0.2.1.5.0-702-bin-2.4.0.2.1.5.0-695.tgz
tar xvfz spark-1.1.0.2.1.5.0-702-bin-2.4.0.2.1.5.0-695.tgz
export YARN_CONF_DIR=/etc/hadoop/conf
export SPARK_HOME=$HOME_DIR/spark-1.1.0.2.1.5.0-702-bin-2.4.0.2.1.5.0-695
export HADOOP_CONF_DIR=/etc/hadoop/conf
echo "export YARN_CONF_DIR=/etc/hadoop/conf" >> ~/.bashrc
echo "export HADOOP_CONF_DIR=/etc/hadoop/conf" >> ~/.bashrc
echo "export SPARK_HOME=$HOME_DIR/spark-1.1.0.2.1.5.0-702-bin-2.4.0.2.1.5.0-695" >> ~/.bashrc



#configure ~/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "import os" >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "import sys" >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "spark_home = os.environ.get(‘SPARK_HOME’, None) " >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "sys.path.insert(0, os.path.join(spark_home, ‘python’)) " >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "sys.path.insert(0, os.path.join(spark_home, ‘python/lib/py4j-0.8.1-src.zip’)) " >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py
echo "execfile(os.path.join(spark_home, ‘python/pyspark/shell.py’))" >> $HOME_DIR/.ipython/profile_spark/startup/00-pyspark-setup.py

cd $HOME_DIR
rm -f *.tgz *.gz *.zip *.tar

#create HDFS dirs
sudo -u hdfs hadoop fs -mkdir /user/demo
sudo -u hdfs hadoop fs -chown demo:demo /user/demo
hadoop fs -mkdir /user/demo/airline
hadoop fs -mkdir /user/demo/airline/delay
hadoop fs -mkdir /user/demo/airline/weather

#Get the data files and upload to HDFS
echo "Downloading delay data to HDFS...."
cd $PROJECT_DIR/demo
mkdir airline
cd airline
mkdir delay
cd delay
wget http://stat-computing.org/dataexpo/2009/2007.csv.bz2
bzip2 -d 2007.csv.bz2
wget http://stat-computing.org/dataexpo/2009/2008.csv.bz2
bzip2 -d 2008.csv.bz2
hadoop fs -put $PROJECT_DIR/demo/airline/delay/*.csv /user/demo/airline/delay
#delete copy of data from local FS to save space
rm $PROJECT_DIR/demo/airline/delay/*.csv

echo "Downloading weather data to HDFS...."
cd $PROJECT_DIR/demo/airline
mkdir weather
cd  $PROJECT_DIR/demo/airline/weather
wget ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/2007.csv.gz
gunzip -d 2007.csv.gz
wget ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/2008.csv.gz
gunzip -d 2008.csv.gz
hadoop fs -put $PROJECT_DIR/demo/airline/weather/*.csv /user/demo/airline/weather
#delete copy of data from local FS to save space
rm $PROJECT_DIR/demo/airline/weather/*.csv

cd $PROJECT_DIR/demo

echo "The demo setup is complete" 
echo "To run the python demo execute"
echo "source ~/.bashrc"
echo "cd /home/demo/hdp-datascience-demo/demo"
echo "ipython notebook"
echo "Then navigate to http://sandbox.hortonworks.com:<port>"
echo ""
echo "To run the Scala/Spark demo execute"
echo "source ~/.bashrc"
echo "cd /home/demo/hdp-datascience-demo/demo"
echo "ipython notebook --profile spark"
echo "Then navigate to http://sandbox.hortonworks.com:<port>"

