from flask import Flask, request, send_file, jsonify, after_this_request
from flask_cors import CORS
import os
from werkzeug.utils import secure_filename
import uuid

from xlsx2geojson import xlsx_to_geojson_main

app = Flask(__name__)
CORS(app)  # 允許所有來源跨域請求

# 上傳檔案暫存區設定
BASE_DIR = os.path.dirname(os.path.abspath(__file__)) # 取得程式碼所在目錄
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads') # 組合出 uploads 資料夾絕對路徑
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER # 設定目錄位置
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True) # 如果資料夾尚未存在就建立

# 允許的副檔名
ALLOWED_EXTENSIONS = {'xlsx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/convert', methods=['POST'])
def convert():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    if not allowed_file(file.filename):
        return jsonify({"error": "只接受.xlsx檔案"}), 400

    ext = file.filename.rsplit('.', 1)[1].lower()
    unique_basename = str(uuid.uuid4())  # 避免覆蓋的亂數名

    # 儲存上傳檔案
    upload_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_basename + '.' + ext)
    file.save(upload_path)

    # 設定geojson輸出暫存檔
    geojson_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_basename + '.geojson')

    # 執行檔案轉換
    try:
        if ext == 'xlsx':
            success = xlsx_to_geojson_main(upload_path, geojson_path)  # 傳入上傳檔, 輸出geojson檔的路徑
        else:
            return jsonify({"error": "不支援的檔案格式"}), 400

        if not success:  # 假設失敗會回傳False
            return jsonify({"error": "轉換失敗，請檢查檔案內容"}), 500
            # jsonify 是負責把 Python 字典、列表等格式自動轉成 JSON 格式的 HTTP 回應

        @after_this_request
        def remove_files(response):
            try:
                if os.path.exists(upload_path):
                    os.remove(upload_path)
                if os.path.exists(geojson_path):
                    os.remove(geojson_path)
            except Exception as e:
                app.logger.error(f"刪除檔案錯誤: {e}")
            return response

        return send_file(
            geojson_path,
            as_attachment=True,
            attachment_filename= file.filename.rsplit('.', 1)[0]+".geojson",
            mimetype='application/geo+json' # 指定 HTTP 回傳內容的類型
        )
    except Exception as e:
        app.logger.error(f"轉換過程錯誤: {e}")
        return jsonify({"error": "伺服器內部錯誤"}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
