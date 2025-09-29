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
            background: rgba(255,255,255,0.9);
            padding: 10px;
            border-radius: 5px;
            width: 240px;
            font-size: 14px;
            max-height: 95vh;
            overflow-y: auto;
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

        /* 自訂圖示相關樣式 */
        .icon-upload-section {
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 10px;
            margin: 10px 0;
            background-color: #f9f9f9;
        }

        .icon-preview {
            width: 50px;
            height: 50px;
            object-fit: cover;
            border: 2px solid #ddd;
            border-radius: 3px;
            margin: 5px;
        }

        .custom-icon-item {
            display: flex;
            align-items: center;
            margin: 5px 0;
            padding: 5px;
            border: 1px solid #ddd;
            border-radius: 3px;
            background: white;
        }

        .custom-icon-item img {
            width: 30px;
            height: 30px;
            margin-right: 10px;
            object-fit: cover;
        }

        .custom-icon-item .icon-info {
            flex: 1;
            font-size: 12px;
        }

        .custom-icon-item .delete-btn {
            background: #dc3545;
            color: white;
            border: none;
            border-radius: 3px;
            padding: 2px 6px;
            cursor: pointer;
            font-size: 10px;
        }

        .scale-input {
            width: 60px;
            margin-left: 10px;
        }

        /* 清除地圖建築物button */
        .clear-building-btn {
            margin-top: 5px;
            width: 100%;
            background-color: #9a8fb4;
            color: #212529;
            border: none;
            padding: 5px;
            border-radius: 3px;
            cursor: pointer;
            font-weight: bold;
        }

        .clear-building-btn:hover {
            background-color: #aca2c2;
        }

        /* 清除全部內容button */
        .clear-all-btn {
            margin-top: 10px;
            width: 100%;
            background-color: #b9535d;
            color: white;
            border: none;
            padding: 8px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
        }

        .clear-all-btn:hover {
            background-color: #b9535d;
        }
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

            <button id="clearBuildingsBtn" class="clear-building-btn">
                清除地圖建築物
            </button>
            </div>

              <button class="accordion">資料集</button>
            <div class="panel">
                <label for="RepairFileInput">上傳資料集</label>
                <input type="file" id="RepairFileInput" accept=".json,.geojson" style="width:100%;margin-bottom:5px;"/>
            
                <div id="iconChooser" style="margin-bottom:5px;">
                    <strong>選擇圖示：</strong>
                
                    <!-- 預設圖示 -->
                    <div style="margin: 5px 0;">
                        <strong style="font-size: 12px;">預設圖示：</strong>
                        <div id="defaultIcons" style="display:flex;gap:4px;margin-top:4px;"></div>
                    </div>
                
                    <!-- 自訂圖示上傳 -->
                    <div class="icon-upload-section">
                        <strong style="font-size: 12px;">自訂圖示：</strong>
                        <div style="margin: 5px 0;">
                            <strong style="font-size: 11px;">2D 模型上傳：</strong>
                            <div>
                                <label for="iconFileInput" style="font-size: 12px;">上傳 2D 圖示 (PNG/JPG)：</label>
                                <input type="file" id="iconFileInput" accept=".png,.jpg,.jpeg" style="width:100%;font-size:11px;"/>
                            </div>
                        </div>
                        <div style="margin: 5px 0;">
                            <strong style="font-size: 11px;">3D 模型上傳：</strong>
                            <!-- GLB 檔案上傳 -->
                            <div style="margin: 5px 0;">
                                <label for="glbFileInput" style="font-size: 12px;">上傳 GLB 檔案：</label>
                                <input type="file" id="glbFileInput" accept=".glb" style="width:100%;font-size:11px;"/>
                            </div>
                            <!-- GLTF 上傳，因為GLTF除了這個檔之外還需要.bin、.txt等等的檔案，所以需要允許上傳一整個資料夾 -->
                            <div style="margin: 5px 0;">
                                <label for="gltfFolderInput" style="font-size: 11px;">上傳 GLTF 資料夾：</label>
                                <input type="file" id="gltfFolderInput" webkitdirectory="webkitdirectory"  multiple="multiple" accept=".gltf,.glb" style="width:100%;font-size:11px;"/>
                            </div>                        
                            <div style="font-size: 10px; color: #666; margin-top: 2px;">
                                • GLB：直接選擇 .glb 檔案<br />
                                • GLTF：選擇包含 .gltf、.bin、圖片檔的整個資料夾
                            </div>
                        </div>
                        <!-- 縮放比例輸入欄位 -->
                        <div style="margin: 5px 0;">
                            <label for="modelScale" style="font-size: 11px;">3D 模型縮放比例：</label>
                            <input type="number" id="modelScale" value="1.0" min="0.01" max="100" step="0.01" style="width:100%;font-size:11px;"/>
                            <div style="font-size: 10px; color: #666; margin-top: 2px;">
                                預設為 1.0，可調整模型大小（例如：0.5 為縮小一半，2.0 為放大兩倍）
                            </div>
                        </div>
                        <button id="uploadIconBtn" style="width:100%;background:#28a745;color:white;border:none;padding:5px;border-radius:3px;cursor:pointer;font-size:11px;">
                            添加自訂圖示
                        </button>
                    </div>
                
                    <!-- 自訂圖示清單 -->
                    <div id="customIconsList" style="margin: 5px 0;">
                        <strong style="font-size: 12px;">已上傳圖示：</strong>
                        <div id="customIconsContainer"></div>
                    </div>
                </div>
            
                <button id="confirmImportBtn" style="width:100%">確認匯入</button>
                <div>
                    <strong>已匯入資料集：</strong>
                    <ul id="datasetsList" style="padding-left:20px;"></ul>
                </div>
                <button id="flyToBtn" style="margin-top:5px;width:100%;background-color:#718b8e;color:white;border:none;padding:5px;border-radius:3px;cursor:pointer;">
                    飛到資料位置
                </button>
                <button id="clearBtn" style="margin-top:5px;width:100%;background-color:#b9535d;color:white;border:none;padding:5px;border-radius:3px;cursor:pointer;">
                    清除資料
                </button>
            </div>

            <!-- 讓使用者上傳xlsx檔以轉成geojson檔 -->
            <button class="accordion" id="uploadBtn">轉換檔案格式</button>
            <div class="panel">
                <button id="selectFileBtn">選擇檔案</button>
                <input type="file" id="fileInput" accept=".xlsx" style="display:none" />
                <span id="fileNameDisplay" style="margin-left: 10px; font-weight: bold;"></span>

                <!-- 轉換按鈕 -->
                <button id="convertBtn" disabled="disabled">轉換成 GeoJSON</button>

                <!-- 下載連結，放在選擇檔案按鈕下面 -->
                <div style="margin-top: 10px;">
                    <a id="downloadLink" style="display:none; cursor:pointer;">下載轉換後的 GeoJSON</a>
                </div>
            </div>

            <!-- 清除全部按鈕 -->
            <button id="clearAllBtn" class="clear-all-btn">
                🗑️ 清除全部內容
            </button>
        </div>

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

        // 電子地圖圖層 (「國土測繪圖資網路地圖服務系統」全面開放圖磚(WMTS)服務 )
        const emapWmtsLayer = viewer.imageryLayers.addImageryProvider(
            new Cesium.UrlTemplateImageryProvider({
                url: "https://wmts.nlsc.gov.tw/wmts/EMAP5/default/EPSG:3857/{z}/{y}/{x}.png",
                tilingScheme: new Cesium.WebMercatorTilingScheme(),
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
            viewer.scene.postRender.removeEventListener(once);
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
                const center = Cesium.Cartesian3.fromDegrees(lon, lat, height);

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
                // 再載入使用者該縣市的3D Tiles
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
                        verticalOrigin: Cesium.VerticalOrigin.BOTTOM,
                        heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
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

        //--------------------------------- 資料集上傳處理 ---------------------------------

        // 狀態變數
        let pendingGeojson = null, pendingName = '';
        let datasets = {}; // 儲存多組資料
        let currentDataSource = null;
        let selectedIconType = "", selectedIconValue = "", selectedIconScale = 1.0;

        // 預設圖示選項
        const defaultIconOptions = [
            {
                type: "image",
                label: "警示點",
                img: "https://cdn-icons-png.flaticon.com/512/3756/3756712.png",
                value: "https://cdn-icons-png.flaticon.com/512/3756/3756712.png"
            },
            {
                type: "image",
                label: "地點標記",
                img: "https://cdn-icons-png.flaticon.com/512/684/684908.png",
                value: "https://cdn-icons-png.flaticon.com/512/684/684908.png"
            },
            {
                type: "model",
                label: "3D路燈",
                img: "streetlamp_glb/images.jpg",
                value: "streetlamp_glb/street_light_fbx.glb",
                scale: 1 // 調整模型倍率
            }
        ];

        // 自訂圖示儲存
        let customIconOptions = [];

        // 建立預設圖示選擇器
        function buildDefaultIconChooser() {
            const container = document.getElementById("defaultIcons");
            container.innerHTML = "";
            defaultIconOptions.forEach((opt, idx) => {
                const img = document.createElement("img");
                img.src = opt.img;
                img.width = 32;
                img.height = 32;
                img.className = "icon-option";
                img.dataset.type = opt.type;
                img.dataset.value = opt.value;
                img.dataset.scale = opt.scale || "1.0";
                img.title = opt.label;
                img.style.cursor = "pointer"; // 滑鼠變成可點擊的樣子
                // 判斷是否為第一個圖示(預設)被點選，是的話邊框設定為藍色，其餘的邊框為透明
                img.style.border = idx === 0 ? "2px solid #007BFF" : "2px solid transparent";
                // 點擊其他圖式的處理方式
                img.onclick = function () {
                    // 先把所有的圖示都重置成透明邊框(表示取消選擇)
                    document.querySelectorAll(".icon-option, .custom-icon-option").forEach(i => i.style.border = "2px solid transparent");
                    // 選擇的圖示邊框改為藍色
                    img.style.border = "2px solid #007BFF";
                    // 修改被選中的圖示之格式
                    selectedIconType = opt.type;
                    selectedIconValue = opt.value;
                    selectedIconScale = parseFloat(opt.scale || "1.0");
                };
                container.appendChild(img);
            });

            // 預設選擇第一個
            if (defaultIconOptions.length > 0) {
                selectedIconType = defaultIconOptions[0].type;
                selectedIconValue = defaultIconOptions[0].value;
                selectedIconScale = parseFloat(defaultIconOptions[0].scale || "1.0");
            }
        }

        // 建立自訂圖示清單
        function buildCustomIconsList() {
            const container = document.getElementById("customIconsContainer");
            container.innerHTML = "";

            customIconOptions.forEach((opt, idx) => {
                const item = document.createElement("div");
                item.className = "custom-icon-item";

                const img = document.createElement("img");
                img.src = opt.img;
                img.className = "custom-icon-option";
                img.dataset.type = opt.type;
                img.dataset.value = opt.value;
                img.dataset.scale = opt.scale || "1.0";
                img.title = opt.label;
                img.style.cursor = "pointer"; // 滑鼠指標顯示表示成可點擊
                img.style.border = "2px solid transparent";
                img.onclick = function () {
                    document.querySelectorAll(".icon-option, .custom-icon-option").forEach(i => i.style.border = "2px solid transparent");
                    img.style.border = "2px solid #007BFF";
                    selectedIconType = opt.type;
                    selectedIconValue = opt.value;
                    selectedIconScale = parseFloat(opt.scale || "1.0");
                };

                const info = document.createElement("div");
                info.className = "icon-info";
                info.innerHTML = `
                    <div>${opt.label}</div>
                    <div style="color: #666;">
                        ${opt.type === 'model' ? '3D模型' : '2D圖示'}
                        ${opt.type === 'model' ? ' (比例: ' + opt.scale + ')' : ''}
                    </div>
                `;

                // 建立刪除圖示按鈕
                const deleteBtn = document.createElement("button");
                deleteBtn.className = "delete-btn";
                deleteBtn.textContent = "刪除";
                deleteBtn.onclick = function (e) {
                    e.stopPropagation();
                    customIconOptions.splice(idx, 1); // 從自訂圖示陣列刪除此項目
                    buildCustomIconsList(); // 重新建立列表，更新畫面

                    // 如果刪除的是當前選中的圖示，重置為預設
                    if (selectedIconValue === opt.value) {
                        if (defaultIconOptions.length > 0) {
                            selectedIconType = defaultIconOptions[0].type;
                            selectedIconValue = defaultIconOptions[0].value;
                            selectedIconScale = parseFloat(defaultIconOptions[0].scale || "1.0");
                            buildDefaultIconChooser();
                        }
                    }
                };

                item.appendChild(img);
                item.appendChild(info);
                item.appendChild(deleteBtn);
                container.appendChild(item);
            });
        }

        // 初始化圖示選擇器
        buildDefaultIconChooser();
        buildCustomIconsList();

        // 自訂圖示上傳處理
        document.getElementById("uploadIconBtn").addEventListener("click", function () {
            const iconFile = document.getElementById("iconFileInput").files[0];
            const glbFiles = document.getElementById("glbFileInput").files;
            const gltfFiles = document.getElementById("gltfFolderInput").files;
            const scaleElement = document.getElementById("modelScale");
            const scale = scaleElement ? parseFloat(scaleElement.value) || 1.0 : 1.0;

            if (!iconFile && glbFiles.length === 0 && gltfFiles.length === 0) {
                showToast("請選擇要上傳的圖示或模型檔案！");
                return;
            }

            // 檢查是否同時選擇了多種類型的檔案
            const fileTypeCount = (iconFile ? 1 : 0) + (glbFiles.length > 0 ? 1 : 0) + (gltfFiles.length > 0 ? 1 : 0);
            if (fileTypeCount > 1) {
                showToast("請一次只上傳一種類型的檔案！");
                return;
            }

            // 處理 2D icon
            if (iconFile) {
                const reader = new FileReader();
                reader.onload = function (e) {
                    // 建立一個自訂圖示的物件
                    const customIcon = {
                        type: "image",
                        label: iconFile.name.replace(/\.[^/.]+$/, ""), // 去除副檔名作為標籤名稱
                        img: e.target.result, // 以base64的編碼方式當作圖片資料
                        value: e.target.result,
                        scale: 1.0
                    };
                    
                    customIconOptions.push(customIcon); // 加入自訂圖示陣列
                    buildCustomIconsList(); // 更新UI清單
                    showToast('2D 圖示 "${customIcon.label}" 已添加！');

                    // 清空輸入
                    document.getElementById("iconFileInput").value = '';
                };
                reader.readAsDataURL(iconFile);
            }

            // 處理 GLB 檔案
            if (glbFiles.length > 0) {
                const glbFile = glbFiles[0];

                // 確認副檔名是否為.glb
                if (!glbFile.name.toLowerCase().endsWith('.glb')) {
                    showToast('請選擇 .glb 格式的檔案！');

                    return;
                }

                const reader = new FileReader();
                reader.onload = function (e) {
                    const blob = new Blob([e.target.result], {
                        type: 'model/gltf-binary'
                    });
                    const modelUrl = URL.createObjectURL(blob);

                    // 建立自訂圖示物件（model類型代表3D model）
                    const customIcon = {
                        type: "model",
                        label: glbFile.name.replace(/\.[^/.]+$/, ""),
                        img: "https://cdn-icons-png.flaticon.com/512/2103/2103633.png", // 預設圖片
                        value: modelUrl,
                        scale: scale,
                        fileName: glbFile.name
                    };
                    customIconOptions.push(customIcon);
                    buildCustomIconsList();
                    showToast(`3D 模型 "${customIcon.label}" 已添加！縮放比例: ${scale}`);


                    // 清空輸入
                    document.getElementById("glbFileInput").value = '';
                    if (scaleElement) scaleElement.value = '1.0';
                };
                reader.readAsArrayBuffer(glbFile);
                return;
            }

            // 處理 GLTF 資料夾
            if (gltfFiles.length > 0) {
                const files = Array.from(gltfFiles);

                // 檢查 GLTF 資料夾是否包含必要檔案
                const gltfFile = files.find(f => f.name.toLowerCase().endsWith('.gltf'));
                const binFiles = files.filter(f => f.name.toLowerCase().endsWith('.bin'));
                const textureFiles = files.filter(f =>
                    f.name.toLowerCase().endsWith('.png') ||
                    f.name.toLowerCase().endsWith('.jpg') ||
                    f.name.toLowerCase().endsWith('.jpeg')
                );

                // 若gltf資料夾不包含哪一種格式的檔案則跳出
                if (!gltfFile) {
                    alert("請確保資料夾中包含 .gltf 檔案！");
                    return;
                }

                if (binFiles.length === 0) {
                    alert("請確保資料夾中包含 .bin 檔案！");
                    return;
                }

                if (textureFiles.length === 0) {
                    alert("請確保資料夾中包含貼圖檔案（.png 或 .jpg）！");
                    return;
                }

                // 整理檔案後呼叫 GLTF 處理 function
                processGltfFiles(files, gltfFile, scale);
                return;
            }
        });

        // 處理 GLTF 檔案和相關資源的function
        function processGltfFiles(files, gltfFile, scale) {
            const fileUrls = {};
            let processedCount = 0;

            // 為每個檔案創建 Blob URL
            files.forEach(file => {
                const reader = new FileReader();
                reader.onload = function (e) {
                    let mimeType = 'application/octet-stream';

                    if (file.name.toLowerCase().endsWith('.gltf')) {
                        mimeType = 'model/gltf+json';
                    } else if (file.name.toLowerCase().endsWith('.bin')) {
                        mimeType = 'application/octet-stream';
                    } else if (file.name.toLowerCase().endsWith('.png')) {
                        mimeType = 'image/png';
                    } else if (file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.jpeg')) {
                        mimeType = 'image/jpeg';
                    }

                    const blob = new Blob([e.target.result], { type: mimeType });
                    const url = URL.createObjectURL(blob);

                    // 使用檔案的完整路徑作為 key，但也保留檔名作為備用
                    const fileName = file.name;
                    const relativePath = file.webkitRelativePath || file.name;
                    fileUrls[fileName] = url;
                    fileUrls[relativePath] = url;

                    processedCount++;

                    // 所有檔案都處理完畢後
                    if (processedCount === files.length) {
                        // 讀取並修改 GLTF 檔案內容
                        const gltfReader = new FileReader();
                        gltfReader.onload = function (e) {
                            try {
                                const gltfContent = JSON.parse(e.target.result);

                                // 更新 GLTF 中的 URI 參考
                                if (gltfContent.buffers) {
                                    gltfContent.buffers.forEach(buffer => {
                                        if (buffer.uri) {
                                            // 先嘗試完整檔名匹配，再嘗試只用檔名
                                            const matchedUrl = fileUrls[buffer.uri] ||
                                                fileUrls[buffer.uri.split('/').pop()] ||
                                                fileUrls[buffer.uri.split('\\').pop()];
                                            if (matchedUrl) {
                                                console.log(`找到匹配的 URL: ${matchedUrl}`);
                                                buffer.uri = matchedUrl;
                                            } else {
                                                console.warn(`找不到匹配的檔案: ${buffer.uri}`);
                                            }
                                        }
                                    });
                                }

                                if (gltfContent.images) {
                                    gltfContent.images.forEach(image => {
                                        if (image.uri) {
                                            // 先嘗試完整檔名匹配，再嘗試只用檔名
                                            const matchedUrl = fileUrls[image.uri] ||
                                                fileUrls[image.uri.split('/').pop()] ||
                                                fileUrls[image.uri.split('\\').pop()];
                                            if (matchedUrl) {
                                                console.log(`找到匹配的圖片 URL: ${matchedUrl}`);
                                                image.uri = matchedUrl;
                                            } else {
                                                console.warn(`找不到匹配的圖片檔案: ${image.uri}`);
                                            }
                                        }
                                    });
                                }

                                // 創建修改後的 GLTF Blob
                                const modifiedGltfBlob = new Blob([JSON.stringify(gltfContent)], {
                                    type: 'model/gltf+json'
                                });
                                const gltfUrl = URL.createObjectURL(modifiedGltfBlob);

                                // 選擇picture作為預覽圖
                                const textureFile = files.find(f =>
                                    f.name.toLowerCase().endsWith('.png') ||
                                    f.name.toLowerCase().endsWith('.jpg') ||
                                    f.name.toLowerCase().endsWith('.jpeg')
                                );

                                // 預設 3d 模型的圖示
                                let previewImg = "https://cdn-icons-png.flaticon.com/512/2103/2103633.png";
                                if (textureFile) {
                                    const textureUrl = fileUrls[textureFile.name];
                                    if (textureUrl) {
                                        previewImg = textureUrl;
                                    }
                                }

                                // 建立自訂圖示物件，包含修改後GLTF URL及縮放比等資訊
                                const customIcon = {
                                    type: "model",
                                    label: gltfFile.name.replace(/\.[^/.]+$/, ""),
                                    img: previewImg,
                                    value: gltfUrl,
                                    scale: scale,
                                    fileName: gltfFile.name,
                                    relatedUrls: [gltfUrl, ...Object.values(fileUrls)] // 包含主要 URL 和所有相關 URL
                                };

                                customIconOptions.push(customIcon);
                                buildCustomIconsList();
                                showToast(`3D 模型 "${customIcon.label}" 已添加！縮放比例: ${scale}`);

                                // 重置輸入欄位、縮放值
                                const gltfFolderInput = document.getElementById("gltfFolderInput");
                                if (gltfFolderInput) gltfFolderInput.value = '';
                                const scaleElement = document.getElementById("modelScale");
                                if (scaleElement) scaleElement.value = '1.0';

                            } catch (error) {
                                alert("GLTF 檔案格式錯誤：" + error.message);
                                console.error("GLTF parsing error:", error);

                                // 錯誤發生時清除已創建的Blob URL避免記憶體爆炸
                                Object.values(fileUrls).forEach(url => {
                                    if (url && typeof url === 'string' && url.startsWith('blob:')) {
                                        URL.revokeObjectURL(url);
                                    }
                                });
                            }
                        };
                        gltfReader.readAsText(gltfFile);
                    }
                };

                if (file.name.toLowerCase().endsWith('.gltf')) {
                    reader.readAsText(file);
                } else {
                    reader.readAsArrayBuffer(file);
                }
            });
        }

        // 檔案上傳讀取
        document.getElementById("RepairFileInput").addEventListener("change", function (event) {
            const file = event.target.files[0];
            if (!file) return;
            const reader = new FileReader();
            reader.onload = function (e) {
                try {
                    pendingGeojson = JSON.parse(e.target.result);
                    pendingName = file.name.replace(/\.[^/.]+$/, "");
                    showToast('檔案 "' + pendingName + '" 已暫存，可選圖示後點確認匯入。');

                } catch {
                    alert('檔案格式錯誤');
                    pendingGeojson = null;
                    pendingName = '';
                }
            };
            reader.readAsText(file);
        });

        // 載入資料及圖示檢查
        document.getElementById("confirmImportBtn").onclick = async function () {
            // 如果沒有暫存的 GeoJSON，則跳出提示
            if (!pendingGeojson) {
                showToast('請先上傳資料集！');


                return;
            }
            // 如果沒有選擇圖示，也跳出提示並停止
            if (!selectedIconValue) {
                showToast('請先選擇圖示！');

                return;
            }

            const dsId = `ds_${Date.now()}`;
            try {
                // 載入 GeoJSON 資料到 Cesium，設定地形貼合地面
                const dataSource = await Cesium.GeoJsonDataSource.load(pendingGeojson, {
                    clampToGround: true
                });

                // 對資料集中每筆資料進行處理，依選擇的圖示類型設定展示出來
                dataSource.entities.values.forEach(entity => {
                    if (selectedIconType === "image") {
                        entity.model = undefined; // 移除實體中的3D模型設定，確保不跟2D圖示衝突
                        entity.billboard = new Cesium.BillboardGraphics({
                            image: selectedIconValue,
                            width: 32,
                            height: 32,
                            verticalOrigin: Cesium.VerticalOrigin.CENTER,
                            heightReference: Cesium.HeightReference.CLAMP_TO_GROUND
                        });
                    } else if (selectedIconType === "model") {
                        entity.billboard = undefined; // 移除影像標記，避免與3D模型重疊
                        entity.model = new Cesium.ModelGraphics({
                            uri: selectedIconValue,
                            scale: selectedIconScale,
                            minimumPixelSize: 1,
                            heightReference: Cesium.HeightReference.CLAMP_TO_GROUND,
                            runAnimations: false
                        });
                    }
                });

                // 找對應的圖示資訊（用於儲存）
                let iconInfo = defaultIconOptions.find(opt => opt.value === selectedIconValue);
                // 如果預設圖示找不到，就去自訂圖示陣列找相同條件的
                if(!iconInfo) {
                    iconInfo = customIconOptions.find(opt => opt.value === selectedIconValue);
                }

                // 將資料集資訊記錄到 global datasets 物件，方便管理與後續操作
                datasets[dsId] = {
                    id: dsId,
                    name: pendingName,
                    data: pendingGeojson,
                    iconType: selectedIconType,
                    iconValue: selectedIconValue,
                    iconScale: selectedIconScale,
                    iconInfo: iconInfo, 
                    dataSource: dataSource
                };

                // 更新前端資料集列表顯示（例如側邊欄清單
                updateDatasetsList();
                showToast('資料集 "' + pendingName + '" 已匯入，可點選顯示！');

                pendingGeojson = null;
                pendingName = '';
                document.getElementById("RepairFileInput").value = '';
            } catch (e) {
                showToast('GeoJSON 載入失敗: ' + e.message);
                console.error(e);
            }
        };

        // 只在刪除該資料集時才釋放Blob URL
        function removeDataset(id) {
            if (datasets[id]) {
                if (datasets[id].dataSource === currentDataSource) {
                    viewer.dataSources.remove(currentDataSource);
                    currentDataSource = null;
                }

                if (datasets[id].iconType === 'model' && datasets[id].iconValue.startsWith('blob:')) {
                    URL.revokeObjectURL(datasets[id].iconValue);
                }

                delete datasets[id];
                updateDatasetsList();
            }
        }

        // 更新資料集清單
        function updateDatasetsList() {
            const list = document.getElementById("datasetsList");
            list.innerHTML = '';
            for (const id in datasets) {
                const dataset = datasets[id];
                const li = document.createElement('li');

                // 創建資料集項目，包含圖示預覽
                const itemDiv = document.createElement('div');
                itemDiv.style.display = 'flex';
                itemDiv.style.alignItems = 'center';
                itemDiv.style.marginBottom = '5px';
                itemDiv.style.cursor = 'pointer';
                itemDiv.onclick = () => showDataset(id);

                // 圖示預覽
                const iconPreview = document.createElement('img');
                if (dataset.iconInfo && dataset.iconInfo.img) {
                    iconPreview.src = dataset.iconInfo.img;
                } else {
                    // 備用圖示
                    iconPreview.src = dataset.iconType === 'model'
                        ? "https://cdn-icons-png.flaticon.com/512/2103/2103633.png"
                        : "https://cdn-icons-png.flaticon.com/512/684/684908.png";
                }
                iconPreview.width = 20;
                iconPreview.height = 20;
                iconPreview.style.marginRight = '8px';
                iconPreview.style.objectFit = 'cover';

                // 放資料集名稱和圖示資訊
                const textDiv = document.createElement('div');
                textDiv.style.flex = '1';
                textDiv.innerHTML = `
                     <div style="font-weight: bold; font-size: 12px;">
                        ${dataset.name} - ${dataset.iconInfo && dataset.iconInfo.label ? dataset.iconInfo.label : ''}
                    </div>
                    <div style="font-size: 10px; color: #666;">
                        ${dataset.iconType === 'model' ? '3D模型' : '2D圖示'}
                        ${dataset.iconType === 'model' ? ` (比例: ${dataset.iconScale})` : ''}
                    </div>
                `;

                // 刪除按鈕
                const delBtn = document.createElement('button');
                delBtn.textContent = '刪除';
                delBtn.style.marginLeft = '10px';
                delBtn.style.fontSize = '10px';
                delBtn.style.padding = '2px 6px';
                delBtn.style.background = '#dc3545';
                delBtn.style.color = 'white';
                delBtn.style.border = 'none';
                delBtn.style.borderRadius = '3px';
                delBtn.style.cursor = 'pointer';
                delBtn.onclick = (e) => {
                    e.stopPropagation();
                    removeDataset(id);
                };

                // 為新增的資料append到itemDiv裡來顯示在清單中
                itemDiv.appendChild(iconPreview);
                itemDiv.appendChild(textDiv);
                itemDiv.appendChild(delBtn);
                li.appendChild(itemDiv);
                list.appendChild(li);
            }
        }

        // 點選資料並顯示
        function showDataset(id) {
            if (currentDataSource) {
                viewer.dataSources.remove(currentDataSource);
            }
            currentDataSource = datasets[id].dataSource;
            viewer.dataSources.add(currentDataSource);

            viewer.flyTo(currentDataSource, {
                duration: 2,
                offset: new Cesium.HeadingPitchRange(0, Cesium.Math.toRadians(-90), 5000)
            });
        }

        // 刪除單一筆資料集
        function removeDataset(id) {
            if (datasets[id]) {
                if (datasets[id].dataSource === currentDataSource) {
                    viewer.dataSources.remove(currentDataSource);
                    currentDataSource = null;
                }

                // 如果是自訂模型，釋放 Blob URL
                if (datasets[id].iconType === 'model' && datasets[id].iconValue.startsWith('blob:')) {
                    URL.revokeObjectURL(datasets[id].iconValue);
                }

                delete datasets[id];
                updateDatasetsList();
            }
        }

        // 清除資料集中所有資料(所有上傳的資料集、自訂圖示、Blob URL)
        document.getElementById('clearBtn').onclick = function () {
            if (confirm('確定清除所有資料？這將同時清除自訂圖示。')) {
                // 清除所有資料集
                Object.values(datasets).forEach(ds => {
                    viewer.dataSources.remove(ds.dataSource);
                    // 釋放自訂模型的 Blob URL
                    if (ds.iconType === 'model' && ds.iconValue && ds.iconValue.startsWith('blob:')) {
                        URL.revokeObjectURL(ds.iconValue);
                    }
                    // 清理資料集中可能的相關 URL
                    if (ds.iconInfo && ds.iconInfo.relatedUrls) {
                        ds.iconInfo.relatedUrls.forEach(url => {
                            if (url && url.startsWith('blob:')) {
                                URL.revokeObjectURL(url);
                            }
                        });
                    }
                });
                datasets = {};

                // 清除自訂圖示
                customIconOptions.forEach(opt => {
                    if (opt.type === 'model' && opt.value && opt.value.startsWith('blob:')) {
                        URL.revokeObjectURL(opt.value);
                    }
                    // 清理 GLTF 相關的所有 URL
                    if (opt.relatedUrls && Array.isArray(opt.relatedUrls)) {
                        opt.relatedUrls.forEach(url => {
                            if (url && url.startsWith('blob:')) {
                                URL.revokeObjectURL(url);
                            }
                        });
                    }
                });

                // 重置預設選擇
                customIconOptions = [];
                pendingGeojson = null;
                pendingName = '';
                updateDatasetsList();
                buildCustomIconsList();
                buildDefaultIconChooser(); 
            }
        };

        // 飛到目前資料集
        document.getElementById("flyToBtn").onclick = function () {
            if (currentDataSource) {
                viewer.flyTo(currentDataSource, {
                    duration: 2,
                    offset: new Cesium.HeadingPitchRange(0, Cesium.Math.toRadians(-90), 5000)
                });
            } else {
                viewer.camera.flyTo({
                    destination: Cesium.Cartesian3.fromDegrees(120.979, 23.755, 300000),
                    orientation: {
                        heading: Cesium.Math.toRadians(0),
                        pitch: Cesium.Math.toRadians(-90),
                        roll: 0
                    }
                });
            }
        };

        //--------------------------------- 清除全部功能（包含建築物和資料集） ---------------------------------

        document.getElementById("clearAllBtn").addEventListener("click", function () {
            if (confirm("⚠️ 確定要清除全部內容嗎？\n\n這將清除：\n• 地圖上的所有建築物\n• 所有已匯入的資料集\n• 所有自訂圖示\n• 定位標記\n\n此操作無法復原！")) {

                // 1. 清除建築物
                if (currentTileset) {
                    viewer.scene.primitives.remove(currentTileset);
                    currentTileset = null;
                }
                loadedTilesets.forEach(tileset => {
                    viewer.scene.primitives.remove(tileset);
                });
                loadedTilesets.length = 0;

                // 2. 清除定位標記
                if (userPoint) {
                    viewer.entities.remove(userPoint);
                    userPoint = null;
                }

                // 3. 清除所有資料集
                Object.values(datasets).forEach(ds => {
                    viewer.dataSources.remove(ds.dataSource);
                    // 釋放自訂模型的 Blob URL
                    if (ds.iconType === 'model' && ds.iconValue.startsWith('blob:')) {
                        URL.revokeObjectURL(ds.iconValue);
                    }
                });
                datasets = {};
                currentDataSource = null;

                // 4. 清除自訂圖示
                customIconOptions.forEach(opt => {
                    if (opt.type === 'model' && opt.value.startsWith('blob:')) {
                        URL.revokeObjectURL(opt.value);
                    }
                });
                customIconOptions = [];

                // 5. 重置待處理資料
                pendingGeojson = null;
                pendingName = '';
                document.getElementById("RepairFileInput").value = '';

                // 6. 更新 UI
                updateDatasetsList();
                buildCustomIconsList();
                buildDefaultIconChooser();

                // 7. 相機回到台灣俯視圖
                viewer.camera.flyTo({
                    destination: Cesium.Cartesian3.fromDegrees(120.979, 23.755, 600000),
                    orientation: {
                        heading: Cesium.Math.toRadians(0),
                        pitch: Cesium.Math.toRadians(-90),
                        roll: 0
                    }
                });

                showToast("已清除全部內容！地圖已重置。");
            }
        });

        // 點擊地圖上的資料點以顯示內容
        viewer.cesiumWidget.screenSpaceEventHandler.setInputAction(function (click) {
            const picked = viewer.scene.pick(click.position);
            if (Cesium.defined(picked) && picked.id) {
                const entity = picked.id;
                if (entity.description) {
                    viewer.selectedEntity = entity;
                }
            }
        }, Cesium.ScreenSpaceEventType.LEFT_CLICK);

        // 滑鼠移動顯示label
        const handler = new Cesium.ScreenSpaceEventHandler(viewer.scene.canvas);
        handler.setInputAction((movement) => {
            let picked = viewer.scene.pick(movement.endPosition);
            Object.values(datasets).forEach(ds => {
                ds.dataSource.entities.values.forEach((entity) => {
                    if (entity.label) {
                        entity.label.show = (picked && picked.id === entity);
                    }
                });
            });
        }, Cesium.ScreenSpaceEventType.MOUSE_MOVE);

        // Home 鍵(地球)自訂
        viewer.homeButton.viewModel.command.beforeExecute.addEventListener(e => {
            e.cancel = true;
            viewer.camera.flyTo({
                destination: Cesium.Cartesian3.fromDegrees(120.979, 23.755, 500000),
                orientation: {
                    heading: Cesium.Math.toRadians(0),
                    pitch: Cesium.Math.toRadians(-90),
                    roll: 0
                }
            });
        });

        //--------------------------------- 檔案上傳並轉換成geojson file處理 ---------------------------------

        document.addEventListener('DOMContentLoaded', () => {
            let selectedFile = null;
            let geojsonUrl = null;  // 用來存放 Blob URL，方便釋放

            const selectFileBtn = document.getElementById('selectFileBtn');
            const fileInput = document.getElementById('fileInput');
            const fileNameDisplay = document.getElementById('fileNameDisplay');
            const convertBtn = document.getElementById('convertBtn');
            const downloadLink = document.getElementById('downloadLink');
            const clearfileBtn = document.getElementById('clearfileBtn');

            // 檔案選擇
            selectFileBtn.addEventListener('click', () => {
                fileInput.click();
            });

            // 檔案選擇事件
            fileInput.addEventListener('change', function () {
                if (fileInput.files.length === 0) {
                    alert('未選擇檔案');
                    selectedFile = null;
                    fileNameDisplay.textContent = '';
                    convertBtn.disabled = true;
                    return;
                }
                selectedFile = fileInput.files[0];

                fileNameDisplay.textContent = selectedFile.name;
                convertBtn.disabled = false;

                // 清除之前的下載連結
                if (geojsonUrl) {
                    URL.revokeObjectURL(geojsonUrl);
                    geojsonUrl = null;
                }
                downloadLink.style.display = 'none';
                downloadLink.href = '';
            });

            // 轉換按鈕點擊
            convertBtn.addEventListener('click', async () => {
                if (!selectedFile) {
                    alert('請先選擇檔案');
                    return;
                }

                const formData = new FormData();
                formData.append('file', selectedFile);

                try {
                    const response = await fetch('http://127.0.0.1:5000/api/convert', {
                        method: 'POST',
                        body: formData,
                    });

                    if (!response.ok) {
                        const err = await response.json();
                        alert('轉換錯誤: ' + (err.error || '未知錯誤'));
                        return;
                    }

                    // 取得 Flask API 回傳資料、取得 Blob 並建立下載 URL
                    const geojsonBlob = await response.blob();
                    if (geojsonUrl) {
                        URL.revokeObjectURL(geojsonUrl); // 釋放原本的blob
                    }
                    geojsonUrl = URL.createObjectURL(geojsonBlob);
                    downloadLink.href = geojsonUrl;
                    downloadLink.download = selectedFile.name.split('.')[0] + '.geojson';
                    downloadLink.style.display = 'inline-block';
                } catch (e) {
                    alert('API 呼叫失敗: ' + e.message);
                }
            });
        });
    </script>
    </form>
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
</body>
</html>