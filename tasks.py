import mysql.connector

import geopandas as gpd
from shapely.geometry import Polygon
import folium
from PIL import Image
import io
import uuid
from celery import Celery

app = Celery('tasks', broker='pyamqp://guest@localhost//')

mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  password="1234",
  database='interview_database'
)

mycursor = mydb.cursor()



def read_data(file_name):
    sql = "select * from files where address = %s"
    mycursor.execute(sql,[file_name])

    myresult = mycursor.fetchall()

    for x in myresult:
      return x
@app.task
def write_data(file_name):

    #print(read_data(file_name))
    g_df = gpd.read_file(file_name)
    #print(g_df.head())

    lat_point_list = g_df.centroid.x[::2] / 10000.0
    lon_point_list = g_df.centroid.y[::2] / 10000.0

    polygon_geom = Polygon(zip(lon_point_list, lat_point_list))
    crs = {'init': 'epsg:4326'}
    polygon = gpd.GeoDataFrame(index=[0], crs=crs, geometry=[polygon_geom])
    m = folium.Map([g_df.centroid.x[0] / 10000.0, g_df.centroid.y[0] / 10000.0], zoom_start=12, tiles='cartodbpositron')
    folium.GeoJson(polygon).add_to(m)
    folium.LatLngPopup().add_to(m)
    sql="update files set stored_name = %s where id = %s"
    
    stored_file_name = str(uuid.uuid1())
    print(stored_file_name)
    print(read_data(file_name)[0])
    val = [stored_file_name+'.html',read_data(file_name)[0]]
    mycursor.execute(sql,val)
    m.save('stored_files/'+stored_file_name+'.html')

