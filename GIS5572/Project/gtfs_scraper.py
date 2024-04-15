import datetime
import time
import requests
import psycopg2
from google.transit import gtfs_realtime_pb2

db_connection = psycopg2.connect(
            host='35.224.213.143',
            user='postgres',
            password='',
            database='gis5572'
                        )
cursor = db_connection.cursor()

while True:
    try:
        response = requests.get('https://svc.metrotransit.org/mtgtfs/vehiclepositions.pb')
        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(response.content)

        # Process each entity in the feed
        for entity in feed.entity:
            if entity.HasField('vehicle'):
                # Extract information
                vehicle_id = entity.vehicle.vehicle.id
                latitude = entity.vehicle.position.latitude
                longitude = entity.vehicle.position.longitude
                timestamp = entity.vehicle.timestamp
                trip_id = entity.vehicle.trip.trip_id
                start_date = entity.vehicle.trip.start_date
                    
                # Convert timestamp from seconds to formatted date string
                timestamp_dt = datetime.datetime.fromtimestamp(timestamp)
                timestamp_str = timestamp_dt.strftime('%Y-%m-%d %H:%M:%S')

                # Write the information to the CSV file only if the data is clean
                if latitude != 0.0 and longitude != 0.0 and timestamp != 0:
                    insert_query = "INSERT INTO live_bus_data (id, latitude, longitude, timestamp, trip_id, start_date) VALUES (%s, %s, %s, %s, %s, %s)"
                    cursor.execute(insert_query, (vehicle_id, latitude, longitude, timestamp_str, trip_id, start_date))
                    db_connection.commit()
    
    except Exception as e:
         print("Error:", e)
    
    # Wait for 15 seconds before requesting the feed again
    time.sleep(60)
    end_count = end_count + 1