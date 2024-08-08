from flask import Flask, render_template, send_from_directory
import boto3
import os

app = Flask(__name__)

S3_BUCKET = 'nomad-tictactoe-project'
S3_REGION = 'us-east-1'

s3_client = boto3.client('s3', region_name=S3_REGION)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/download')
def download():
    file_name = 'tictactoe-executable'
    file_path = os.path.join('/tmp', file_name)

    s3_client.download_file(S3_BUCKET, file_name, file_path)

    return send_from_directory('/tmp', file_name)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
