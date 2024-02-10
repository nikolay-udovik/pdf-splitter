from flask import Flask, request, jsonify, send_file, render_template
from flask_socketio import SocketIO
import subprocess
import os
import shutil
import tempfile
import threading

app = Flask(__name__, static_folder="static")
socketio = SocketIO(app, cors_allowed_origins="*")  # Ensure CORS is appropriately configured

# Thread-safe way to store session IDs for active clients
client_sessions = {}

def process_pdf(input_pdf_path, max_size_kb, part_prefix, temp_dir, original_pdf_name, sid):
    print(f"Thread started for SID: {sid}")
    dir_path = os.path.dirname(os.path.realpath(__file__))
    script_path = os.path.join(dir_path, 'split_pdf.sh')
    cmd = [script_path, '--input-pdf', input_pdf_path,
           '--max-size', max_size_kb, '--part-prefix', part_prefix,
           '--working-dir', temp_dir]
    print("Executing command:", ' '.join(cmd))

    try:
        with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=1, universal_newlines=True) as proc:
            for line in proc.stdout:
                print(f"Script output: {line.strip()}")
                socketio.emit('script_output', {'data': line.strip()}, room=sid)
    except Exception as e:
        print(f"Error executing script: {e}")
        socketio.emit('script_output', {'data': str(e)}, room=sid)

    zip_file_name = f"{part_prefix}_files.zip"
    zip_file_path = os.path.join(temp_dir, zip_file_name)
    download_link = f"/download/{zip_file_name}?temp_dir={temp_dir}"
    socketio.emit('script_complete', {'download_link': download_link}, room=sid)
    print(f"Script completed for SID: {sid}")

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@app.route('/process', methods=['POST'])
def process():
    sid = request.form.get('sid')
    if not sid or sid not in client_sessions:
        return jsonify({'error': 'Invalid or missing session ID'}), 400

    file = request.files.get('pdf_file')
    if not file:
        return jsonify({'error': 'No file provided'}), 400

    max_size_mb = request.form.get('max_size', '10')
    part_prefix = request.form.get('part_prefix', 'part')
    temp_dir = tempfile.mkdtemp()
    input_pdf_path = os.path.join(temp_dir, file.filename)
    file.save(input_pdf_path)

    threading.Thread(target=process_pdf, args=(input_pdf_path, str(int(max_size_mb) * 1024), part_prefix, temp_dir, os.path.splitext(file.filename)[0], sid)).start()
    return jsonify({'message': 'Processing started'})

@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    temp_dir = request.args.get('temp_dir')
    if not temp_dir or not os.path.exists(os.path.join(temp_dir, filename)):
        return jsonify({'error': 'File not found'}), 404
    return send_file(os.path.join(temp_dir, filename), as_attachment=True)

@socketio.on('connect')
def handle_connect():
    sid = request.sid
    client_sessions[sid] = True
    print(f"Client connected with SID: {sid}")

@socketio.on('disconnect')
def handle_disconnect():
    sid = request.sid
    client_sessions.pop(sid, None)
    print(f"Client disconnected with SID: {sid}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True, allow_unsafe_werkzeug=True)
