from flask import Flask, render_template, request
from werkzeug.utils import secure_filename
import zipfile
import os
import glob
import mysql.connector
import uuid


mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="1234",
  database='interview_database'
)

mycursor = mydb.cursor()

app = Flask(__name__)
app.config['UPLOAD_EXTENSIONS'] = ['zip']

@app.route('/upload')
def upload_file():
   return render_template('upload.html')
	
@app.route('/uploader', methods = [ 'POST'])
def upload_filer():
   if request.method == 'POST':
      f = request.files['file']
      file_name = f.filename
      if file_name !='':
         file_ext = file_name.split('.')[1]
         if file_ext not in app.config['UPLOAD_EXTENSIONS']:
             return "file should be zip"
      f.save(secure_filename(f.filename))
      with zipfile.ZipFile(secure_filename(f.filename), "r") as zip_ref:
         zip_ref.extractall("extract_folder")
      shp_files =(glob.glob('extract_folder/Test Sample/*.shp'))

      for each in shp_files:
          sql = "INSERT INTO files (address) values (%s) "
          mycursor.execute(sql, [each.split('/')[1]])
      mydb.commit()
      return 'file uploaded successfully'


if __name__ == '__main__':
   app.run(debug = True)
