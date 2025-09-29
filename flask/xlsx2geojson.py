#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
XLSX to GeoJSON 轉換器
支援平面座標系統轉換為經緯度座標
"""

import pandas as pd
import json
import pyproj
from pyproj import Transformer
import argparse
import sys
from pathlib import Path
import logging
import math

# 設定日誌
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class XLSXToGeoJSONConverter:
    def __init__(self):
        # 常用的台灣座標系統
        self.taiwan_crs_options = {
            'TWD97_TM2_121': 'EPSG:3826',  # TWD97 橫麥卡托 TM2 中央經線 121度
            'TWD97_TM2_119': 'EPSG:3825',  # TWD97 橫麥卡托 TM2 中央經線 119度  
            'TWD67_TM2_121': 'EPSG:3828',  # TWD67 橫麥卡托 TM2 中央經線 121度
            'TWD67_TM2_119': 'EPSG:3827',  # TWD67 橫麥卡托 TM2 中央經線 119度
            'UTM_51N': 'EPSG:32651',       # UTM Zone 51N (WGS84)
            'UTM_50N': 'EPSG:32650',       # UTM Zone 50N (WGS84)
        }
        
    def detect_coordinate_system(self, x_values, y_values):
        """
        自動偵測座標系統
        根據座標範圍判斷可能的座標系統
        """
        x_min, x_max = min(x_values), max(x_values)
        y_min, y_max = min(y_values), max(y_values)
        
        logger.info(f"座標範圍: X({x_min:.2f} ~ {x_max:.2f}), Y({y_min:.2f} ~ {y_max:.2f})")
        
        # 判斷是否為經緯度 (大概範圍)
        if (-180 <= x_min <= 180) and (-90 <= y_min <= 90) and (-180 <= x_max <= 180) and (-90 <= y_max <= 90):
            if 119 <= x_min <= 122 and 21 <= y_min <= 26:  # 台灣地區經緯度範圍
                logger.info("偵測到經緯度座標 (台灣地區)")
                return 'EPSG:4326'
            else:
                logger.info("偵測到經緯度座標")
                return 'EPSG:4326'
        
        # 判斷台灣平面座標系統
        if 160000 <= x_min <= 380000 and 2420000 <= y_min <= 2800000:
            logger.info("偵測到可能的 TWD97 TM2 121度座標系統")
            return 'EPSG:3826'
        elif 80000 <= x_min <= 300000 and 2420000 <= y_min <= 2800000:
            logger.info("偵測到可能的 TWD97 TM2 119度座標系統")
            return 'EPSG:3825'
        elif 200000 <= x_min <= 800000 and 2400000 <= y_min <= 2900000:
            logger.info("偵測到可能的 UTM Zone 51N 座標系統")
            return 'EPSG:32651'
        
        # 預設返回最常用的台灣座標系統
        logger.warning("無法自動偵測座標系統，使用預設的 TWD97 TM2 121度")
        return 'EPSG:3826'
    
    def transform_coordinates(self, x_values, y_values, source_crs, target_crs='EPSG:4326'):
        """
        座標轉換 (修正緯度錯誤)
        """
        if source_crs == target_crs:
            return x_values, y_values
            
        try:
            transformer = Transformer.from_crs(source_crs, target_crs, always_xy=True)
            # 正確逐筆轉換
            lon_lat = [transformer.transform(float(x), float(y)) for x, y in zip(x_values, y_values)]
            lon_transformed, lat_transformed = zip(*lon_lat)
            logger.info(f"座標轉換成功: {source_crs} -> {target_crs}")
            return lon_transformed, lat_transformed
        except Exception as e:
            logger.error(f"座標轉換失敗: {e}")
            return x_values, y_values

    def read_xlsx_file(self, file_path, sheet_name=None):
        """
        讀取 XLSX 文件
        """
        try:
            if sheet_name:
                df = pd.read_excel(file_path, sheet_name=sheet_name)
            else:
                df = pd.read_excel(file_path)
            logger.info(f"成功讀取文件: {file_path}")
            logger.info(f"資料筆數: {len(df)}")
            logger.info(f"欄位: {list(df.columns)}")
            return df
        except Exception as e:
            logger.error(f"讀取文件失敗: {e}")
            return None
    
    def identify_coordinate_columns(self, df, x_col=None, y_col=None):
        if x_col and y_col:
            return x_col, y_col

        # 常見的座標欄位名稱
        x_candidates = ['POINT_X', 'longitude', 'lon', 'lng', 'x', 'X', 'east', '經度', 'X座標', 'x座標']
        y_candidates = ['POINT_Y', 'latitude', 'lat', 'y', 'Y', 'north', '緯度', 'Y座標', 'y座標']

        # 先找完全相同的欄位
        for col in df.columns:
            if col in x_candidates:
                x_col_found = col
                break
        else:
            # 找不到完全匹配，再用模糊匹配
            x_col_found = next((col for col in df.columns 
                                if any(c.lower() in col.lower() for c in x_candidates)), None)

        for col in df.columns:
            if col in y_candidates:
                y_col_found = col
                break
        else:
            y_col_found = next((col for col in df.columns 
                                if any(c.lower() in col.lower() for c in y_candidates)), None)

        if not x_col_found or not y_col_found:
            logger.warning("無法自動識別座標欄位，請手動指定")
            logger.info(f"可用欄位: {list(df.columns)}")

        return x_col_found, y_col_found

    
    def convert_to_geojson(self, df, x_col, y_col, source_crs=None, properties_cols=None):
        if x_col not in df.columns or y_col not in df.columns:
            logger.error(f"找不到指定的座標欄位: {x_col}, {y_col}")
            return None
            
        df_clean = df.dropna(subset=[x_col, y_col]).copy()
        if len(df_clean) == 0:
            logger.error("沒有有效的座標資料")
            return None
            
        logger.info(f"有效座標資料筆數: {len(df_clean)}")
        
        x_values = df_clean[x_col].values
        y_values = df_clean[y_col].values
        
        if source_crs is None:
            source_crs = self.detect_coordinate_system(x_values, y_values)
        
        # 正確轉換座標 (lon, lat)
        x_transformed, y_transformed = (
            self.transform_coordinates(x_values, y_values, source_crs, 'EPSG:4326')
            if source_crs != 'EPSG:4326' else (x_values, y_values)
        )
        
        if properties_cols is None:
            properties_cols = [col for col in df_clean.columns if col not in [x_col, y_col]]
        
        features = []
        for i, row in enumerate(df_clean.itertuples(index=False)):
            properties = {}
            for col in properties_cols:
                val = getattr(row, col)
                # 把 NaN / Infinity 轉成 None
                if isinstance(val, float) and (math.isnan(val) or math.isinf(val)):
                    val = None
                properties[col] = val

            feature = {
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [float(x_transformed[i]), float(y_transformed[i])]
                },
                "properties": properties
            }
            features.append(feature)
        
        geojson = {
            "type": "FeatureCollection",
            "crs": {
                "type": "name",
                "properties": {"name": "EPSG:4326"}
            },
            "features": features
        }
        
        logger.info("GeoJSON 轉換完成")
        return geojson

    def save_geojson(self, geojson_data, output_path):
        """
        儲存 GeoJSON 檔案
        """
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                json.dump(geojson_data, f, ensure_ascii=False, indent=2)
            logger.info(f"GeoJSON 檔案已儲存: {output_path}")
            return True
        except Exception as e:
            logger.error(f"儲存檔案失敗: {e}")
            return False
    
    def convert(self, input_file, output_file=None, x_col=None, y_col=None, 
                source_crs=None, sheet_name=None, properties_cols=None):
        """
        主要轉換函數
        """
        # 設定輸出檔案名稱
        if output_file is None:
            input_path = Path(input_file)
            output_file = input_path.with_suffix('.geojson')
        
        # 讀取 XLSX 檔案
        df = self.read_xlsx_file(input_file, sheet_name)
        if df is None:
            return False
        
        # 識別座標欄位
        x_col, y_col = self.identify_coordinate_columns(df, x_col, y_col)
        if not x_col or not y_col:
            logger.error("無法識別座標欄位")
            return False
        
        logger.info(f"使用座標欄位: X={x_col}, Y={y_col}")
        
        # 轉換為 GeoJSON
        geojson_data = self.convert_to_geojson(
            df, x_col, y_col, source_crs, properties_cols
        )
        
        if geojson_data is None:
            return False
        
        # 儲存檔案
        return self.save_geojson(geojson_data, output_file)
    
def xlsx_to_geojson_main(infile, outfile):
    """
    包裝主流程給Flask用
    infile: 上傳的xlsx檔案路徑
    outfile: 要輸出的geojson檔案路徑
    return: True (成功) / False (失敗)
    """
    try:
        converter = XLSXToGeoJSONConverter()
        return converter.convert(input_file=infile, output_file=outfile)
    except Exception as e:
        logger.error(f'轉換過程出錯: {e}')
        return False


def main():
    parser = argparse.ArgumentParser(description='XLSX to GeoJSON 轉換器')
    parser.add_argument('input_file', help='輸入的 XLSX 檔案路徑')
    parser.add_argument('-o', '--output', help='輸出的 GeoJSON 檔案路徑')
    parser.add_argument('-x', '--x_col', help='X座標欄位名稱')
    parser.add_argument('-y', '--y_col', help='Y座標欄位名稱')
    parser.add_argument('-s', '--source_crs', help='來源座標系統 (例: EPSG:3826)')
    parser.add_argument('--sheet', help='指定工作表名稱')
    parser.add_argument('-p', '--properties', nargs='*', help='屬性欄位名稱')
    
    args = parser.parse_args()
    
    # 檢查輸入檔案是否存在
    if not Path(args.input_file).exists():
        logger.error(f"找不到輸入檔案: {args.input_file}")
        sys.exit(1)
    
    # 建立轉換器並執行轉換
    converter = XLSXToGeoJSONConverter()
    
    success = converter.convert(
        input_file=args.input_file,
        output_file=args.output,
        x_col=args.x_col,
        y_col=args.y_col,
        source_crs=args.source_crs,
        sheet_name=args.sheet,
        properties_cols=args.properties
    )
    
    if success:
        logger.info("轉換完成!")
        sys.exit(0)
    else:
        logger.error("轉換失敗!")
        sys.exit(1)

if __name__ == "__main__":
    main()

# 因為是在anaconda裡面跑，所以可以直接執行下面這樣
# & D:/Anacoda/envs/ting/python.exe 原始檔案路徑 "xlsx檔案名稱" -o "轉換後欲設定之檔案名稱"