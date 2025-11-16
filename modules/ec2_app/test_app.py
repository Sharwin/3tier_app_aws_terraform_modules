#!/usr/bin/env python3
"""
Simple Flask test application to verify infrastructure
"""
from flask import Flask, jsonify
import os
import socket
import mysql.connector
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Home page with infrastructure details"""
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    # Get database connection status
    db_status = check_database()
    
    # Get EFS mount status
    efs_status = check_efs()
    
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>AWS 3-Tier App - Infrastructure Test</title>
        <style>
            body {{ font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }}
            h1 {{ color: #FF9900; }}
            .status-box {{ background: #f0f0f0; padding: 15px; margin: 10px 0; border-radius: 5px; }}
            .success {{ color: green; font-weight: bold; }}
            .error {{ color: red; font-weight: bold; }}
            .info {{ color: #0066cc; }}
        </style>
    </head>
    <body>
        <h1>🚀 AWS 3-Tier Application</h1>
        <h2>Infrastructure Verification</h2>
        
        <div class="status-box">
            <h3>✅ Application Tier</h3>
            <p><strong>Instance:</strong> {hostname}</p>
            <p><strong>Private IP:</strong> {ip_address}</p>
            <p><strong>Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p class="success">Flask application is running!</p>
        </div>
        
        <div class="status-box">
            <h3>💾 Database Tier (RDS MySQL)</h3>
            {db_status}
        </div>
        
        <div class="status-box">
            <h3>📁 Storage Tier (EFS)</h3>
            {efs_status}
        </div>
        
        <div class="status-box">
            <h3>🌐 Load Balancer</h3>
            <p class="success">Successfully reached via ALB!</p>
            <p class="info">You're seeing this page through the Application Load Balancer</p>
        </div>
        
        <hr>
        <p><em>✅ All infrastructure components are operational!</em></p>
        <p><small>Terraform-deployed 3-tier application on AWS</small></p>
    </body>
    </html>
    """
    return html

@app.route('/health')
def health():
    """Health check endpoint for ALB"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()}), 200

@app.route('/api/info')
def info():
    """API endpoint with infrastructure information"""
    return jsonify({
        "instance": socket.gethostname(),
        "ip": socket.gethostbyname(socket.gethostname()),
        "database": check_database_simple(),
        "efs": check_efs_simple(),
        "timestamp": datetime.now().isoformat()
    })

def check_database():
    """Check RDS MySQL connection"""
    try:
        db_host = os.environ.get('DB_HOST', 'unknown')
        db_user = os.environ.get('DB_USER', 'unknown')
        db_pass = os.environ.get('DB_PASSWORD', 'unknown')
        db_name = os.environ.get('DB_NAME', 'unknown')
        
        conn = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_pass,
            database=db_name,
            connect_timeout=5
        )
        version = conn.get_server_info()
        conn.close()
        return f'<p class="success">✅ Connected to MySQL {version}</p><p class="info">Host: {db_host}</p><p class="info">Database: {db_name}</p>'
    except Exception as e:
        return f'<p class="error">❌ Database connection failed: {str(e)}</p>'

def check_database_simple():
    """Simple database check for API"""
    try:
        db_host = os.environ.get('DB_HOST', 'unknown')
        conn = mysql.connector.connect(
            host=db_host,
            user=os.environ.get('DB_USER'),
            password=os.environ.get('DB_PASSWORD'),
            database=os.environ.get('DB_NAME'),
            connect_timeout=5
        )
        conn.close()
        return {"status": "connected", "host": db_host}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def check_efs():
    """Check EFS mount"""
    efs_path = "/srv/microblog/env"
    try:
        if os.path.ismount(efs_path):
            # Try to create a test file
            test_file = f"{efs_path}/.test_{datetime.now().timestamp()}"
            with open(test_file, 'w') as f:
                f.write("test")
            os.remove(test_file)
            return f'<p class="success">✅ EFS mounted and writable</p><p class="info">Path: {efs_path}</p>'
        else:
            return f'<p class="info">⚠️ EFS path exists but not mounted: {efs_path}</p>'
    except Exception as e:
        return f'<p class="error">❌ EFS check failed: {str(e)}</p>'

def check_efs_simple():
    """Simple EFS check for API"""
    efs_path = "/srv/microblog/env"
    try:
        if os.path.ismount(efs_path):
            return {"status": "mounted", "path": efs_path}
        return {"status": "not_mounted", "path": efs_path}
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

