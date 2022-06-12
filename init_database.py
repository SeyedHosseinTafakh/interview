
import mysql.connector

mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="1234"
)

mycursor = mydb.cursor()

mycursor.execute("CREATE DATABASE interview_database")

mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="1234",
  database='interview_database'
)

mycursor = mydb.cursor()
mycursor.execute("CREATE TABLE files (id int AUTO_INCREMENT, address VARCHAR(255),stored_name VARCHAR(255),primary key (`id`) )")
