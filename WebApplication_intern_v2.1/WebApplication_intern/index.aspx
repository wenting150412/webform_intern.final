<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="index.aspx.cs" Inherits="WebApplication_intern.index" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Cesium map</title>
    <script src="https://cdn.jsdelivr.net/npm/cesium@1.114/Build/Cesium/Cesium.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/cesium@1.114/Build/Cesium/Widgets/widgets.css" rel="stylesheet" />
    <style>
        html, body {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
        }

        /* 整個button位置 */
        #controlPanel {
            position: fixed;
            top: 10px;
            left: 10px;
            z-index: 100;
            padding: 10px;
            border-radius: 5px;
            width: 240px;
            font-size: 14px;
            max-height: 95vh;
            overflow-y: auto;
            height: 300px;
        }

        /* 最外面"3D建築物匯入"、"資料集"、"各縣市屬於哪一部分"的button */
        .accordion {
            background-color: #eee;
            color: #444;
            cursor: pointer;
            padding: 10px;
            width: 100%;
            border: none;
            text-align: left;
            outline: none;
            font-size: 16px;
            transition: 0.4s;
            border-radius: 3px;
            margin-top: 5px;
        }

        .accordion.active, .accordion:hover { background-color: #ccc; }
        .panel {
            padding: 5px;
            display: none;
            background-color: white;
            overflow: hidden;
        }
        .city-group {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }
        .city-btn {
            flex: 1 1 45%;
            padding: 5px;
            background-color: #82a4c8;
            color: white;
            border: none;
            border-radius: 3px;
            cursor: pointer;
            font-size: 14px;
        }
        .city-btn:hover { background-color: #82a4c8; }

    </style>
</head>
<body>
    <div id="cesiumContainer" style="width:100%; height:100%;"></div>

    <div id="controlPanel">
        <button class="accordion">3D 建築物匯入</button>
        <div class="panel">
            <!-- 縣市選擇分類 -->
            <button class="accordion">北部</button>
            <div class="panel">
                <div class="city-group">
                    <button class="city-btn" data-city="taipei">台北市</button>
                    <button class="city-btn" data-city="new_taipei">新北市</button>
                    <button class="city-btn" data-city="keelung">基隆市</button>
                    <button class="city-btn" data-city="taoyuan">桃園市</button>
                    <button class="city-btn" data-city="hsinchu_city">新竹市</button>
                    <button class="city-btn" data-city="hsinchu_county">新竹縣</button>
                    <button class="city-btn" data-city="yilan">宜蘭縣</button>
                </div>
            </div>

            <button class="accordion">中部</button>
            <div class="panel">
                <div class="city-group">
                    <button class="city-btn" data-city="miaoli">苗栗縣</button>
                    <button class="city-btn" data-city="taichung">台中市</button>
                    <button class="city-btn" data-city="changhua">彰化縣</button>
                    <button class="city-btn" data-city="nantou">南投縣</button>
                    <button class="city-btn" data-city="yunlin">雲林縣</button>
                </div>
            </div>

            <button class="accordion">南部</button>
            <div class="panel">
                <div class="city-group">
                    <button class="city-btn" data-city="chiayi_city">嘉義市</button>
                    <button class="city-btn" data-city="chiayi_county">嘉義縣</button>
                    <button class="city-btn" data-city="tainan">台南市</button>
                    <button class="city-btn" data-city="kaohsiung">高雄市</button>
                    <button class="city-btn" data-city="pingtung">屏東縣</button>
                </div>
            </div>

            <button class="accordion">東部</button>
            <div class="panel">
                <div class="city-group">
                    <button class="city-btn" data-city="taitung">台東縣</button>
                    <button class="city-btn" data-city="hualien">花蓮縣</button>
                </div>
            </div>

            <button class="accordion">離島</button>
            <div class="panel">
                <div class="city-group">
                    <button class="city-btn" data-city="kinmen">金門縣</button>
                    <button class="city-btn" data-city="penghu">澎湖縣</button>
                    <button class="city-btn" data-city="lienchiang">連江縣</button>
                </div>
            </div>

            <button id="locateBtn" style="margin-top:5px;width:100%;background-color:#7d92a9;color:white;border:none;padding:5px;border-radius:3px;cursor:pointer;">
                定位並載入建築物
            </button>

            <button id="clearBuildingsBtn" style="margin-top:5px;width:100%;background-color:#CD9D9B;color:white;border:none;padding:5px;border-radius:3px;cursor:pointer;">
                清除地圖建築物
            </button>
        </div>
            <button class="accordion">上傳資料</button>
            <div class="panel">
                <form id="uploadForm" enctype="multipart/form-data">
                  <input type="file" name="excelFile" id="excelFile" accept=".xlsx,.xls" required="required" />
                  <button type="submit">上傳</button>
                </form>
            </div>

            <button class="accordion">載入資料</button>
            <div class="panel">
                <label for="tableSelect">選擇資料表：</label>
                <select id="tableSelect" style="width:100%; margin-bottom:10px;">
                    <option value="">請選擇資料表</option>
                </select>
                <button type="button" id="loadTableDataBtn" style="width: 100%;">載入資料表</button>
            </div>
        </div>

    <div id="toast" style="
        visibility: hidden;
        min-width: 200px;          
        background-color: #333;
        color: #fff;
        text-align: left;
        border-radius: 6px;         
        padding: 15px 20px;         
        position: fixed;
        top: 30px;                  
        right: 30px;                
        transform: none;            
        z-index: 1000;
        font-size: 16px;            
        box-shadow: 0 2px 8px rgba(0,0,0,0.3); 
"></div>

    <form id="form1" runat="server">
        
    <script>
        Cesium.Ion.defaultAccessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiIyNmIzMDE3Yy1mYWQ2LTQ4YTQtOWQ3Ny1lZjgwNTcxOTU5MTkiLCJpZCI6MzIyMjU0LCJpYXQiOjE3NTI3MjY4MjJ9.12vLgFNaTNa4AO8PYo3hByBcXUodMbnX_u--RM59ySg';

        // 初始化 Cesium 三維地圖
        const viewer = new Cesium.Viewer('cesiumContainer', {
            terrain: Cesium.Terrain.fromWorldTerrain(),
            animation: false,
            baseLayerPicker: false,
            timeline: false,
            baseLayer: Cesium.ImageryLayer.fromProviderAsync(
                Cesium.ArcGisMapServerImageryProvider.fromUrl("https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer")
            )
        });

        // 電子地圖圖層 ( 國土測繪圖資網路地圖服務系統」全面開放圖磚(WMTS)服務 )
        const emapWmtsLayer = viewer.imageryLayers.addImageryProvider(
            new Cesium.UrlTemplateImageryProvider({
                url: "https://wmts.nlsc.gov.tw/wmts/EMAP5/default/EPSG:3857/{z}/{y}/{x}.png",
                tilingScheme: new Cesium.WebMercatorTilingScheme(), // 將原本二維平面座標用tileing scheme的方式切成瓦片(tile)來投影到3D地圖上
                maximumLevel: 18
            })
        );
        emapWmtsLayer.show = true;

        // 初始相機位置：台灣
        viewer.scene.postRender.addEventListener(function once() {
            viewer.camera.setView({
                destination: Cesium.Cartesian3.fromDegrees(120.979, 23.755, 600000),
                orientation: {
                    heading: Cesium.Math.toRadians(0),
                    pitch: Cesium.Math.toRadians(-90),
                    roll: 0
                }
            });
            
            viewer.scene.postRender.removeEventListener(once); // postRender 是用以在render後所做的動作，這裡為了確保只執行一次render，所以使用removeEventLiestner來中止前面所做的render行為
        });

        // 提示訊息設定
        function showToast(message, duration = 3000) {
            const toast = document.getElementById('toast');
            toast.textContent = message;
            toast.style.visibility = 'visible';
            setTimeout(() => {
                toast.style.visibility = 'hidden';
            }, duration);
        }

        // 手風琴選單展開收合效果
        document.querySelectorAll(".accordion").forEach(acc => {
            acc.addEventListener("click", function () {
                // 找出屬於accordion層級的其他兄弟節點
                const siblingAccordions = Array.from(this.parentElement.children)
                    .filter(el => el.classList && el.classList.contains("accordion") && el !== this);
                // 移除這些節點的active，也就是收合這些選單
                siblingAccordions.forEach(btn => btn.classList.remove("active"));

                // 找出屬於accordion層級的兄弟節點之下方panel
                const siblingPanels = siblingAccordions.map(acc => acc.nextElementSibling);
                // 把所有兄弟節點的 panel 都關閉
                siblingPanels.forEach(panel => panel.style.display = "none");

                // 切換正在被點擊的button以及其下方panel的active(原本展開的就收合，原本收合的則展開)
                this.classList.toggle("active");
                const panel = this.nextElementSibling;
                panel.style.display = (panel.style.display === "block") ? "none" : "block";
            });
        });

        //--------------------------------- 3D建築物匯入處理 ---------------------------------

        // 縣市對應的 3D Tiles 路徑與定位資訊
        const tilesetConfigs = {
            taipei: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/0/tileset.json', lon: 121.5654, lat: 25.0330, height: 50 },
            taichung: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/1/tileset.json', lon: 120.6839, lat: 24.1371, height: 50 },
            keelung: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/2/tileset.json', lon: 121.7445, lat: 25.1276, height: 50 },
            tainan: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/3/tileset.json', lon: 120.2270, lat: 22.9999, height: 50 },
            kaohsiung: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/4/tileset.json', lon: 120.30261, lat: 22.639690, height: 50 },
            new_taipei: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/5/tileset.json', lon: 121.463675, lat: 25.014281, height: 50 },
            yilan: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/6/tileset.json', lon: 121.774367, lat: 24.677933, height: 50 },
            taoyuan: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/7/tileset.json', lon: 121.225556, lat: 24.953611, height: 50 },
            chiayi_city: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/8/tileset.json', lon: 120.4473, lat: 23.4755, height: 50 },
            hsinchu_county: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/9/tileset.json', lon: 121.0182, lat: 24.8387, height: 50 },
            miaoli: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/10/tileset.json', lon: 120.822444, lat: 24.5699, height: 50 },
            nantou: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/11/tileset.json', lon: 120.966633, lat: 23.968815, height: 50 },
            changhua: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/12/tileset.json', lon: 120.538333, lat: 24.0815, height: 50 },
            hsinchu_city: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/13/tileset.json', lon: 120.9686, lat: 24.8039, height: 50 },
            yunlin: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/14/tileset.json', lon: 120.41656089, lat: 23.7362954, height: 50 },
            chiayi_county: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/15/tileset.json', lon: 120.2550, lat: 23.4518, height: 50 },
            pingtung: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/16/tileset.json', lon: 120.5487, lat: 22.5519, height: 50 },
            hualien: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/17/tileset.json', lon: 121.3542, lat: 23.7569, height: 50 },
            taitung: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/18/tileset.json', lon: 121.12313, lat: 22.793963, height: 50 },
            kinmen: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/19/tileset.json', lon: 118.3171, lat: 24.4321, height: 50 },
            penghu: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/20/tileset.json', lon: 119.6151, lat: 23.5655, height: 100 },
            lienchiang: { url: 'https://3dtiles.nlsc.gov.tw/building/tiles3d/21/tileset.json', lon: 119.9510, lat: 26.1608, height: 100 }
        };

        const loadedTilesets = [];
        let currentTileset = null;
        let userPoint = null;

        // 縣市選單事件
        document.querySelectorAll('.city-btn').forEach(btn => {
            btn.addEventListener('click', async function () {
                const selected = this.dataset.city;

                // 如果目前有載入的 tileset，先從地圖移除，並從 loadedTilesets 陣列刪除，再清空 currentTileset
                if (currentTileset) {
                    viewer.scene.primitives.remove(currentTileset);
                    const index = loadedTilesets.indexOf(currentTileset);
                    if (index > -1) loadedTilesets.splice(index, 1);
                    currentTileset = null;
                }

                // 如果目前沒有已載入的tileset則return
                if (!selected || !tilesetConfigs[selected]) return;

                const config = tilesetConfigs[selected];

                try {
                    // 載入該縣市3D Tiles
                    const tileset = await Cesium.Cesium3DTileset.fromUrl(config.url);
                    currentTileset = tileset;
                    viewer.scene.primitives.add(tileset);
                    loadedTilesets.push(tileset); // 記錄載入的tileset

                    // 設定飛行目標位置（在高度加5000公尺）
                    const center = Cesium.Cartesian3.fromDegrees(config.lon, config.lat, config.height + 5000);

                    viewer.camera.flyTo({
                        destination: center,
                        orientation: {
                            heading: Cesium.Math.toRadians(0.0),
                            pitch: Cesium.Math.toRadians(-90.0),
                            roll: 0.0
                        },
                    });
                } catch (error) {
                    alert("載入失敗：" + error.message);
                    console.error(error);
                }
            });
        });

        // 定位功能
        document.getElementById("locateBtn").addEventListener("click", () => {
            // 檢查瀏覽器是否支援定位功能
            if (!("geolocation" in navigator)) {
                showToast("此瀏覽器不支援定位功能");
                return;
            }
            // 取得使用者經緯度
            navigator.geolocation.getCurrentPosition(async (position) => {
                const lon = position.coords.longitude;
                const lat = position.coords.latitude;
                const height = 800;
                const center = Cesium.Cartesian3.fromDegrees(lon, lat, height); // 將 lon, lat, height 轉換成以三維空間中用 Carrtesian3 表示的點或向量，即代表該地理位置在 Cesium 3D 空間中的位置

                // 定義函式依經緯度找最近的縣市key
                function getNearestCity(lon, lat) {
                    let nearest = null;
                    let minDistance = Number.MAX_VALUE;
                    for (const key in tilesetConfigs) {
                        const city = tilesetConfigs[key];
                        const dist = Math.sqrt(
                            Math.pow(city.lon - lon, 2) +
                            Math.pow(city.lat - lat, 2)
                        );
                        if (dist < minDistance) {
                            minDistance = dist;
                            nearest = key;
                        }
                    }
                    return nearest;
                }

                const cityKey = getNearestCity(lon, lat);
                const config = tilesetConfigs[cityKey];

                // 假設當前有其他縣市的建築物被載入，則先進行remove
                if (currentTileset) viewer.scene.primitives.remove(currentTileset);
                // 再載入使用者該縣市的 3D Tiles
                const tileset = await Cesium.Cesium3DTileset.fromUrl(config.url);
                currentTileset = tileset;
                viewer.scene.primitives.add(tileset);

                viewer.camera.flyTo({
                    destination: center,
                    orientation: {
                        heading: Cesium.Math.toRadians(0.0),
                        pitch: Cesium.Math.toRadians(-90.0),
                        roll: 0.0
                    }
                });

                // 使用者定位標記
                if (userPoint) viewer.entities.remove(userPoint);
                userPoint = viewer.entities.add({
                    position: Cesium.Cartesian3.fromDegrees(lon, lat),
                    billboard: {
                        image: "https://cdn-icons-png.flaticon.com/512/684/684908.png",
                        width: 32,
                        height: 32,
                        verticalOrigin: Cesium.VerticalOrigin.BOTTOM, // 以icon下緣為基準，落在指定的座標點上
                        heightReference: Cesium.HeightReference.CLAMP_TO_GROUND // 避免icon飛在空中，所以要這個icon以"貼地"的方式顯示
                    }
                });

                // 根據相機高度動態調整圖釘大小，避免過大或過小
                viewer.scene.camera.changed.addEventListener(() => {
                    if (!userPoint) return;
                    if (userPoint.billboard) {
                        const cameraHeight = viewer.scene.camera.positionCartographic.height;
                        let newSize = Math.max(8, Math.min(48, 600000 / cameraHeight));
                        userPoint.billboard.width = newSize;
                        userPoint.billboard.height = newSize;
                    }
                });

                console.log("載入的縣市 tileset:", cityKey);
            });
        });

        // 清除地圖上建築物功能
        document.getElementById("clearBuildingsBtn").addEventListener("click", function () {
            if (confirm("確定要清除地圖上的所有建築物嗎？")) {
                // 清除當前 tileset
                if (currentTileset) {
                    viewer.scene.primitives.remove(currentTileset);
                    // 從已載入的 tileset 陣列中移除
                    const index = loadedTilesets.indexOf(currentTileset);
                    if (index > -1) {
                        loadedTilesets.splice(index, 1);
                    }
                    currentTileset = null;
                }

                // 清除定位標記
                if (userPoint) {
                    viewer.entities.remove(userPoint);
                    userPoint = null;
                }

                showToast('已清除地圖上的所有建築物！');

            }
        });

        //--------------------------------- 使用者上傳檔案並匯入資料庫 ---------------------------------
        document.getElementById('excelFile').addEventListener('change', async (e) => {
            const file = document.getElementById('excelFile').files[0];
            if (!file) {
                alert('請先選擇檔案');
                return;
            }
            const formData = new FormData();
            formData.append('excelFile', file);
            try {
                const response = await fetch('/api/data/ExcelUpload', {
                    method: 'POST',
                    body: formData,
                    credentials: 'same-origin'
                });
                const result = await response.json();
                if (!response.ok) throw new Error(result.error || response.statusText);
                alert(`匯入成功：跳過重複筆數：${result.skipRows}，匯入筆數：${result.rows}`);
            } catch (err) {
                alert('匯入失敗：' + err.message);
            }
        });

        //--------------------------------- 從資料庫抓資料並顯示在cesium上 ---------------------------------
        // 載入資料表列表並填入下拉選單
        fetch('/api/Tables')
            .then(res => res.json())
            .then(data => {
                const select = document.getElementById('tableSelect');
                data.forEach(tableName => {
                    const opt = document.createElement('option');
                    opt.value = tableName;
                    opt.textContent = tableName;
                    select.appendChild(opt);
                });
            });

        // 綁定下拉選單改變事件
        document.getElementById('tableSelect').addEventListener('change', function () {
            const selectedTable = this.value;
            if (!selectedTable) return;
            // 請求後端取得暫存 GeoJSON URL
            fetch(`/api/Data?tableName=${encodeURIComponent(selectedTable)}`)
                .then(res => res.json())
                .then(result => {
                    const url = result.url;

                    viewer.dataSources.removeAll(); // 先清除舊資料

                    viewer.dataSources.add(Cesium.GeoJsonDataSource.load(url, {
                        clampToGround: true
                    })).then(dataSource => {
                        viewer.zoomTo(dataSource);

                        dataSource.entities.values.forEach(function (entity) {
                            if (entity.position) {
                                let cartographic = Cesium.Cartographic.fromCartesian(entity.position.getValue(Cesium.JulianDate.now()));
                                cartographic.height = 0;
                                let positionClamp = Cesium.Cartesian3.fromRadians(cartographic.longitude, cartographic.latitude, cartographic.height);
                                entity.position = positionClamp;

                                // 2D 圖示
                                //entity.billboard = new Cesium.BillboardGraphics({
                                //    image: "https://cdn-icons-png.flaticon.com/512/684/684908.png",
                                //    width: 32,
                                //    height: 32,
                                //    verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
                                //    heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
                                //});

                                // 隱藏所有預設點和圖示(藍色方框)
                                entity.point = undefined;
                                entity.billboard = undefined;
                                // 3D 模型
                                entity.model = new Cesium.ModelGraphics({
                                    uri: "streetlamp_glb/street_light_fbx.glb",
                                    minimumPixelSize: 32,
                                    maximumScale: 1.0,
                                    heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
                                });
                            }
                        });

                    }).catch(err => {
                        console.error("載入 GeoJSON 錯誤", err);
                    });
                }).catch(err => {
                    console.error("取得 GeoJSON URL 發生錯誤", err);
                });
        });

        const handler = new Cesium.ScreenSpaceEventHandler(viewer.scene.canvas);

        handler.setInputAction(function (movement) {
            const pickedObject = viewer.scene.pick(movement.endPosition);
            if (Cesium.defined(pickedObject) && pickedObject.id && pickedObject.id.billboard) {
                // 滑鼠移到有點的 Entity 上時將游標變成pointer的樣子
                viewer.container.style.cursor = 'pointer';
            } else {
                // 否則恢復預設游標
                viewer.container.style.cursor = 'default';
            }
        }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);

    </script>
    </form>
</body>
</html>