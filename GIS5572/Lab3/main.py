import os
import json
import psycopg2
from flask import Flask

app = Flask(__name__)

 
@app.route("/elevation", methods=["GET"]) 
def elevation():
    
    conn = psycopg2.connect( 
        host=os.environ.get("DB_HOST"), 
        database=os.environ.get("DB_NAME"), 
        user=os.environ.get("DB_USER"), 
        password=os.environ.get("DB_PASSWORD"), 
        port=os.environ.get("DB_PORT"), 
    )
    
    with conn.cursor() as cur:
        
        query = """
            SELECT 
                jsonb_build_object(
                    'type', 'FeatureCollection',
                    'features', jsonb_agg(feature)
                ) AS geojson
            FROM (
                SELECT 
                    'Feature'::text AS type,
                    ST_AsGeoJSON(shape)::jsonb AS geometry,
			jsonb_build_object(
			'grid_code', grid_code
                    ) AS properties
                FROM 
                    kriging_points_elevation
            ) AS feature
	    LIMIT 10;	

"""
        cur.execute(query) 
        data = cur.fetchone()[0]
        
    conn.close()

    response_data = json.dumps(data)
     
    return response_data

@app.route("/elevation_assessment", methods=["GET"]) 
def elevation_assessment():
    
    conn = psycopg2.connect( 
        host=os.environ.get("DB_HOST"), 
        database=os.environ.get("DB_NAME"), 
        user=os.environ.get("DB_USER"), 
        password=os.environ.get("DB_PASSWORD"), 
        port=os.environ.get("DB_PORT"), 
    )
    
    with conn.cursor() as cur:
        
        query = """
            SELECT 
                jsonb_build_object(
                    'type', 'FeatureCollection',
                    'features', jsonb_agg(feature)
                ) AS geojson
            FROM (
                SELECT 
                    'Feature'::text AS type,
                    ST_AsGeoJSON(shape)::jsonb AS geometry,
		    jsonb_build_object(
			'kriging_residual', kriging_residual
 		    ) AS properties
                FROM 
                    kriging_points_elevation_assessment
            ) AS feature
	    LIMIT 10;

"""
        cur.execute(query) 
        data = cur.fetchone()[0]
        
    conn.close()

    response_data = json.dumps(data)
     
    return response_data

@app.route("/temperature", methods=["GET"]) 
def temperature():
    
    conn = psycopg2.connect( 
        host=os.environ.get("DB_HOST"), 
        database=os.environ.get("DB_NAME"), 
        user=os.environ.get("DB_USER"), 
        password=os.environ.get("DB_PASSWORD"), 
        port=os.environ.get("DB_PORT"), 
    )
    
    with conn.cursor() as cur:
        
        query = """
            SELECT 
                jsonb_build_object(
                    'type', 'FeatureCollection',
                    'features', jsonb_agg(feature)
                ) AS geojson
            FROM (
                SELECT 
                    'Feature'::text AS type,
                    ST_AsGeoJSON(shape)::jsonb AS geometry,
		        jsonb_build_object(
			'grid_code', grid_code
                    ) AS properties
                FROM 
                    kriging_points_temperature
            ) AS feature
	    LIMIT 10;

"""
        cur.execute(query) 
        data = cur.fetchone()[0]
        
    conn.close()

    response_data = json.dumps(data)
     
    return response_data

@app.route("/temperature_assessment", methods=["GET"]) 
def temperature_assessment():
    
    conn = psycopg2.connect( 
        host=os.environ.get("DB_HOST"), 
        database=os.environ.get("DB_NAME"), 
        user=os.environ.get("DB_USER"), 
        password=os.environ.get("DB_PASSWORD"), 
        port=os.environ.get("DB_PORT"), 
    )
    
    with conn.cursor() as cur:
        
        query = """
            SELECT 
                jsonb_build_object(
                    'type', 'FeatureCollection',
                    'features', jsonb_agg(feature)
                ) AS geojson
            FROM (
                SELECT 
                    'Feature'::text AS type,
                    ST_AsGeoJSON(shape)::jsonb AS geometry,
		    jsonb_build_object(
			'kriging_residual', kriging_residual
 		    ) AS properties
                FROM 
                    kriging_points_temperature_assessment
            ) AS feature
	    LIMIT 10;

"""
        cur.execute(query) 
        data = cur.fetchone()[0]
        
    conn.close()

    response_data = json.dumps(data)
     
    return response_data

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
