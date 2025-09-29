# from flask import Flask, request, jsonify
# import os

# app = Flask(__name__) # __name__代表目前執行的模組，儲存目前在哪個模組下執行

# @app.route("/") # Flask會利用route()裝飾器來告訴Flask什麼URL應該觸發我們的函數。
# def home():
#     return "Hello Flask"

# # 如果以主程式執行
# if __name__ == "__main__": 
#     app.run() #立即啟動伺服器