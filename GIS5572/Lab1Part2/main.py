import os
import psycopg2

app = Flask(__name__)

 
@app.route("/data", methods=["GET"]) 
def data():
    
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
                    ST_AsGeoJSON(geom)::jsonb AS geometry,
                    '{}'::jsonb AS properties
                FROM 
                    your_table_name
            ) AS feature;

"""
        cur.execute(query) 
        data = cur.fetchall()
        
    conn.close() 
     
    return data

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
