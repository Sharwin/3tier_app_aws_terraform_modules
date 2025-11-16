#!/bin/bash -xe
# ==============================================================================
# Microblog Application Bootstrap Script
# ==============================================================================
# This script:
#   - Updates system packages
#   - Installs git, python3, and EFS utils
#   - Clones the microblog application
#   - Mounts EFS for shared configuration
#   - Configures database connection
#   - Runs database migrations
#   - Sets up systemd service for the Flask app
# ==============================================================================

# Redirect output to log files
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Microblog Application Setup"
echo "=========================================="

# ------------------------------------------------------------------------------
# System Updates & Package Installation
# ------------------------------------------------------------------------------
echo "[1/8] Updating system packages..."
yum update -y

echo "[2/8] Installing required packages..."
yum install -y git python3 python3-pip amazon-efs-utils mariadb105

# ------------------------------------------------------------------------------
# Application Setup
# ------------------------------------------------------------------------------
APP_DIR="/srv/microblog"
EFS_DIR="$APP_DIR/env"
APP_USER="ec2-user"

echo "[3/8] Cloning microblog application..."
git clone https://github.com/miguelgrinberg/microblog $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR
cd $APP_DIR

echo "[4/8] Setting up Python virtual environment..."
sudo -u $APP_USER python3 -m venv venv

# Upgrade pip and install dependencies
sudo -u $APP_USER $APP_DIR/venv/bin/pip install --upgrade pip
sudo -u $APP_USER $APP_DIR/venv/bin/pip install -r requirements.txt
sudo -u $APP_USER $APP_DIR/venv/bin/pip install pymysql

# ------------------------------------------------------------------------------
# EFS Mount
# ------------------------------------------------------------------------------
echo "[5/8] Mounting EFS file system..."
mkdir -p $EFS_DIR

# Get File System ID from Terraform template
EFS_FS_ID="${efs_fs_id}"

# Mount the EFS file system with TLS encryption
mount -t efs -o tls $EFS_FS_ID:/ $EFS_DIR

# Add to fstab for automatic mounting on reboot
echo "$EFS_FS_ID:/ $EFS_DIR efs _netdev,tls 0 0" >> /etc/fstab

# ------------------------------------------------------------------------------
# Application Configuration
# ------------------------------------------------------------------------------
echo "[6/8] Creating application configuration..."
cat > $EFS_DIR/.env <<EOF
DATABASE_URL=mysql+pymysql://${db_user}:${db_password}@${db_host}/${db_name}
SECRET_KEY=$(openssl rand -hex 32)
EOF

chown $APP_USER:$APP_USER $EFS_DIR/.env
chmod 600 $EFS_DIR/.env

# ------------------------------------------------------------------------------
# Database Verification
# ------------------------------------------------------------------------------
echo "[7/8] Running database migrations..."
# Wait for database to be available
max_attempts=30
attempt=0
until mysql -h ${db_host} -P ${db_port} -u ${db_user} -p${db_password} -e "SELECT 1" &> /dev/null || [ $attempt -eq $max_attempts ]; do
  echo "Waiting for database to be available... ($attempt/$max_attempts)"
  sleep 10
  ((attempt++))
done

if [ $attempt -eq $max_attempts ]; then
  echo "WARNING: Database is not available after $max_attempts attempts"
else
  echo "✅ Database is available! Running migrations..."
  cd $APP_DIR
  sudo -u $APP_USER bash -c "source $APP_DIR/venv/bin/activate && flask db upgrade"
fi

# ------------------------------------------------------------------------------
# Systemd Service Setup
# ------------------------------------------------------------------------------
echo "[8/8] Configuring systemd service..."
cat > /etc/systemd/system/microblog.service <<EOF
[Unit]
Description=Microblog Flask Application
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$EFS_DIR/.env
ExecStart=$APP_DIR/venv/bin/flask run --host=0.0.0.0 --port=5000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl enable microblog.service
systemctl start microblog.service

echo "=========================================="
echo "Microblog Application Setup Complete!"
echo "=========================================="
echo "Service status:"
systemctl status microblog.service --no-pager

