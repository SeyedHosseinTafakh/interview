import mysql.connector

import geopandas as gpd
from shapely.geometry import Polygon
import folium
from PIL import Image
import io

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
      return x[1]
@app.task
def write_data(file_name):

    g_df = gpd.read_file(read_data(file_name=file_name))
    print(g_df.head())

    lat_point_list = g_df.centroid.x[::2] / 10000.0
    lon_point_list = g_df.centroid.y[::2] / 10000.0

    polygon_geom = Polygon(zip(lon_point_list, lat_point_list))

    crs = {'init': 'epsg:4326'}
    polygon = gpd.GeoDataFrame(index=[0], crs=crs, geometry=[polygon_geom])
    m = folium.Map([g_df.centroid.x[0] / 10000.0, g_df.centroid.y[0] / 10000.0], zoom_start=12, tiles='cartodbpositron')
    folium.GeoJson(polygon).add_to(m)
    folium.LatLngPopup().add_to(m)

    m.save('x.html')

