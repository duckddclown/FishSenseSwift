import json
import pymysql
import os
import time

def lambda_handler(event, context):
    # Authentication check
    headers = event.get('headers', {})
    api_key = headers.get('x-api-key')
    app_id = headers.get('x-app-id')
    device_id = headers.get('x-device-id')
    timestamp = headers.get('x-timestamp')
    
    # Verify API key
    expected_api_key = os.environ.get('API_KEY')
    if api_key != expected_api_key:
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Invalid API key'
            })
        }
    
    # Verify app ID
    if app_id != 'fishsense-ios-app':
        return {
            'statusCode': 401,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': 'Invalid app ID'
            })
        }
    
    # Check timestamp (prevent old requests - within 5 minutes)
    if timestamp:
        try:
            request_time = int(timestamp)
            current_time = int(time.time())
            if abs(current_time - request_time) > 300:  # 5 minutes
                return {
                    'statusCode': 401,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'success': False,
                        'error': 'Request timestamp too old'
                    })
                }
        except:
            pass  # Ignore timestamp validation errors for now
    
    # Database connection parameters from environment variables
    host = os.environ['DB_HOST']
    user = os.environ['DB_USER']
    password = os.environ['DB_PASSWORD']
    database = os.environ['DB_NAME']
    
    try:
        # Connect to MySQL (without specifying database first)
        connection = pymysql.connect(
            host=host,
            user=user,
            password=password,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with connection.cursor() as cursor:
            # Create database if it doesn't exist
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {database}")
            cursor.execute(f"USE {database}")
            
            # Create photos table matching your local SQLite structure
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS photos (
                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                utc_unix_timestamp BIGINT NOT NULL,
                rgb_path VARCHAR(255) NOT NULL,
                depth_bytes LONGBLOB,
                depth_width INT,
                depth_height INT,
                confidence_bytes LONGBLOB,
                confidence_width INT,
                confidence_height INT,
                estimated_length FLOAT DEFAULT 0.0,
                fish_found BOOLEAN DEFAULT FALSE,
                synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_timestamp (utc_unix_timestamp)
            )
            """
            
            cursor.execute(create_table_sql)
            connection.commit()
            
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': True,
                'message': 'Table created successfully'
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }
    
    finally:
        if 'connection' in locals():
            connection.close()

# import json
# import pymysql
# import os

# def lambda_handler(event, context):
#     try:
#         host = os.environ['DB_HOST']
#         user = os.environ['DB_USER']
#         password = os.environ['DB_PASSWORD']
#         database = os.environ['DB_NAME']
        
#         connection = pymysql.connect(
#             host=host,
#             user=user,
#             password=password,
#             charset='utf8mb4',
#             cursorclass=pymysql.cursors.DictCursor
#         )
        
#         with connection.cursor() as cursor:
#             # Check if database exists
#             cursor.execute("SHOW DATABASES")
#             databases = cursor.fetchall()
            
#             # Use the database
#             cursor.execute(f"USE {database}")
            
#             # Show tables
#             cursor.execute("SHOW TABLES")
#             tables = cursor.fetchall()
            
#             # Describe photos table if it exists
#             table_structure = None
#             try:
#                 cursor.execute("DESCRIBE photos")
#                 table_structure = cursor.fetchall()
#             except:
#                 table_structure = "Table doesn't exist"
            
#         return {
#             'statusCode': 200,
#             'headers': {
#                 'Content-Type': 'application/json',
#                 'Access-Control-Allow-Origin': '*'
#             },
#             'body': json.dumps({
#                 'success': True,
#                 'databases': databases,
#                 'tables': tables,
#                 'photos_table_structure': table_structure
#             })
#         }
        
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': json.dumps({
#                 'error': str(e)
#             })
#         }
#     finally:
#         if 'connection' in locals():
#             connection.close()


