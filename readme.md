# this project was an interview challenge for getting shape files (.shp) as zip file and showing converting it to map files in html format using server/worker !

for starting the project i assume the user have a running mysql server,rabbitmq server and knows how to connect gunicorn to nginx;

1 - for start after cloning the project from git user should add the user name and password for mysql in two files:
init_database.py and x.py
2- run 

> pip install requirements.txt

3- running celery worker ( -c=1 is number of processis we give celery i gave one because of limited resource), celery works on rabbitmq server on localhost but in case the user wants to change it to reddis follow celery documentation

> celery -A tasks worker -c=1 --loglevel=INFO

4 - initializing database:

> python init_database.py

5-run gunicorn

> gunicorn x:app

urls:

    /upload method = GET
opens a page for user to upload a .zip file contains shape files just like in test sample

    /uploader method = POST
upload submit button send the files to this url and this function unzip data and store it in 'extract_folder' after that read all the files with .shp format and store it in mysql under interview_database.files, and send each file name to celery worker for processing . celery process each file and store the result as html in 'stored_files' with unique name

    /read_files method=GET
read all the records in interview_database.files and show id , name ,and link for the map

    /map/<mapname> method=GET
open map stored in stored_files and return it as view to user to review the map

