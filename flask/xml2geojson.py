import geojson
from lxml import etree

def guess_coords(props):
    # 支援常見欄位名稱，不區分大小寫
    candidates = [
        ('POINT_X', 'POINT_Y'),
        ('LONGITUDE', 'LATITUDE'),
        ('LON', 'LAT'),
        ('X', 'Y'),
        ('lon', 'lat'),
        ('x', 'y')
    ]
    lowerprops = {k.lower(): v for k, v in props.items()}
    for kx, ky in candidates:
        x = lowerprops.get(kx.lower())
        y = lowerprops.get(ky.lower())
        if x and y:
            try:
                return float(x), float(y)
            except Exception:
                continue
    return None, None

def xml_to_geojson(xml_path, geojson_path):
    tree = etree.parse(xml_path)
    root = tree.getroot()
    features = []

    # 找出可能的「每筆資料」節點（假設是所有第二層大於一筆者）
    nodes = []
    for child in root.iter():
        # 子元素皆為同類，且有多筆
        if len(child) > 1 and len(set(e.tag for e in child)) == 1:
            nodes = child
            break
    if not nodes:  # 如果沒找到就抓所有最底層
        nodes = root.findall('.//*')

    for item in nodes:
        props = {}
        # 取所有 direct 子元素（不管欄位名）
        for el in item:
            value = el.text.strip() if el.text else None
            props[el.tag] = value
        # 若該節點為屬性型態（如 <Record x="..." y="...">）也抓取
        for k, v in item.attrib.items():
            props[k] = v
        # 猜欄位當經緯度
        lon, lat = guess_coords(props)
        if lon is not None and lat is not None:
            feature = geojson.Feature(
                geometry=geojson.Point((lon, lat)),
                properties=props
            )
            features.append(feature)
    fc = geojson.FeatureCollection(features)
    with open(geojson_path, 'w', encoding='utf-8') as f:
        geojson.dump(fc, f, ensure_ascii=False, indent=2)

# 使用方法
xml_to_geojson('"D:/Ting/路燈資料/street lamp.xlsx"', 'output.geojson')
