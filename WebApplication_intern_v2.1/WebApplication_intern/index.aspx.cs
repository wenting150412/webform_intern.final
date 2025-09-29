using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication_intern
{
    public partial class index : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}

namespace Dataupload.Controllers
{
    [RoutePrefix("api/data")]
    public class ExcelUploadController : ApiController
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["sqlConn"].ConnectionString;

        // 確認 DataBase 連線
        [HttpGet, Route("db-ping")]
        public IHttpActionResult DbPing()
        {
            try
            {
                using (var conn = new SqlConnection(_connStr))
                // 測試資料表是否為空，有資料就回傳1，否則回傳0
                using (var cmd = new SqlCommand("SELECT TOP 1 1", conn))
                {
                    conn.Open();
                    var x = cmd.ExecuteScalar();
                    return Ok(new { ok = true, result = x });
                }
            }
            catch (Exception ex)
            {
                return Content(HttpStatusCode.InternalServerError, new { ok = false, error = ex.Message });
            }
        }

        [HttpPost]
        [Route("ExcelUpload")]
        public async Task<IHttpActionResult> UploadExcel()
        {
            try
            {
                // 判斷 HTTP 請求是否為 multipart/form-data 類型
                if (!Request.Content.IsMimeMultipartContent())
                    return Content(HttpStatusCode.BadRequest, new { ok = false, error = "請以 multipart/form-data 上傳檔案" });

                // 讀取、解析並取得裡面所有檔案與欄位內容
                var provider = await Request.Content.ReadAsMultipartAsync();
                if (provider.Contents.Count == 0)
                    return Content(HttpStatusCode.BadRequest, new { ok = false, error = "沒有檔案" });

                var file = provider.Contents[0];
                var bytes = await file.ReadAsByteArrayAsync(); // 把上傳的檔案「讀成二進位資料」方便伺服器後續操作

                // 使用EPPlus的方式讀取excel
                using (var pkg = new ExcelPackage(new System.IO.MemoryStream(bytes)))
                // 建立資料庫連線
                using (var conn = new SqlConnection(_connStr))
                {
                    //  只允許 .xlsx
                    var fileName = file.Headers.ContentDisposition.FileName?.Trim('"');
                    if (string.IsNullOrWhiteSpace(fileName) ||
                        !fileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
                        return Content(HttpStatusCode.BadRequest, new { ok = false, error = "僅支援 .xlsx 檔案，請另存為 .xlsx 後再上傳。" });

                    //  檢查是否有工作表
                    var sheets = pkg.Workbook?.Worksheets;
                    if (sheets == null || sheets.Count == 0)
                        return Content(HttpStatusCode.BadRequest, new { ok = false, error = "檔案中找不到任何工作表（Sheet）。" });

                    //  EPPlus 的索引從 1 開始，不是 0
                    var ws = sheets[1];

                    // （可選）先檢查標題是否完全符合
                    string[] expect = { "LAYER","ID","ORGAN","OP_CODE","BURY_DATE","NUM","LENGTH",
                            "MATERIAL","USEMODE","DATAMODE","NOTE","POINT_X","POINT_Y",
                            "TOWNSHIP","HEIGHT","MOD_DATE","STATE","DATA1","DATA2","LEVEL" };
                    for (int i = 0; i < expect.Length; i++)
                    {
                        var title = (ws.Cells[1, i + 1].Text ?? "").Trim();
                        if (!string.Equals(title, expect[i], StringComparison.OrdinalIgnoreCase))
                            return Content(HttpStatusCode.BadRequest, new { ok = false, error = $"Excel 欄位第 {i + 1} 欄應為 {expect[i]}，實際為「{title}」" });
                    }

                    // 建立 DataTable 準備轉換並匯入資料庫，新增欄位→名稱及資料型別
                    var dt = new DataTable();
                    dt.Columns.Add("LAYER", typeof(int));
                    dt.Columns.Add("ID", typeof(string));
                    dt.Columns.Add("ORGAN", typeof(string));
                    dt.Columns.Add("OP_CODE", typeof(int));
                    dt.Columns.Add("BURY_DATE", typeof(DateTime));
                    dt.Columns.Add("NUM", typeof(string));
                    dt.Columns.Add("LENGTH", typeof(decimal));
                    dt.Columns.Add("MATERIAL", typeof(string));
                    dt.Columns.Add("USEMODE", typeof(int));
                    dt.Columns.Add("DATAMODE", typeof(int));
                    dt.Columns.Add("NOTE", typeof(string));
                    dt.Columns.Add("POINT_X", typeof(decimal));
                    dt.Columns.Add("POINT_Y", typeof(decimal));
                    dt.Columns.Add("TOWNSHIP", typeof(string));
                    dt.Columns.Add("HEIGHT", typeof(decimal));
                    dt.Columns.Add("MOD_DATE", typeof(DateTime));
                    dt.Columns.Add("STATE", typeof(int));
                    dt.Columns.Add("DATA1", typeof(string));
                    dt.Columns.Add("DATA2", typeof(string));
                    dt.Columns.Add("LEVEL", typeof(string));

                    // 定義不同資料型別所做的轉換
                    int? ToInt(object v) { var s = v?.ToString().Trim(); return int.TryParse(s, out var i) ? i : (int?)null; }
                    decimal? ToDec(object v) { var s = v?.ToString().Trim().Replace(",", ""); return decimal.TryParse(s, out var d) ? d : (decimal?)null; }
                    DateTime? ToDate(object v) { if (v is DateTime d) return d.Date; var s = v?.ToString().Trim(); return DateTime.TryParse(s, out var d2) ? d2.Date : (DateTime?)null; }
                    string ToStr(object v) => v?.ToString().Trim();

                    // 讀取起點為第二列(第一列為欄位名稱)，計數匯入資料列數初始為0，跳過不匯入資料列數初始為0
                    int row = 2, rows = 0, skipRows = 0;
                    await conn.OpenAsync();

                    while (ws.Cells[row, 1].Value != null)
                    {
                        string currentID = ToStr(ws.Cells[row, 2].Value);
                        if (string.IsNullOrEmpty(currentID))
                        {
                            row++;
                            continue;
                        }

                        // 判斷ID是否已存在資料庫中
                        bool exists = false;
                        using (var cmd = new SqlCommand("SELECT COUNT(1) FROM [Cesium].[dbo].[streetlampData] WHERE ID = @ID", conn))
                        {
                            cmd.Parameters.AddWithValue("@ID", currentID);
                            var count = (int)await cmd.ExecuteScalarAsync();
                            exists = (count > 0);
                        }

                        if (exists)
                        {
                            skipRows++;
                            row++;
                            continue;  // 若是存在則跳過這筆，不加入DataTable
                        }

                        // 建立一個空白資料列 dr 存放新資料，再將資料加入 DataTable(dt)
                        var dr = dt.NewRow();
                        dr["LAYER"] = (object)ToInt(ws.Cells[row, 1].Value) ?? DBNull.Value;
                        dr["ID"] = ToStr(ws.Cells[row, 2].Value);
                        dr["ORGAN"] = ToStr(ws.Cells[row, 3].Value);
                        dr["OP_CODE"] = (object)ToInt(ws.Cells[row, 4].Value) ?? DBNull.Value;
                        dr["BURY_DATE"] = (object)ToDate(ws.Cells[row, 5].Value) ?? DBNull.Value;
                        dr["NUM"] = ToStr(ws.Cells[row, 6].Value);
                        dr["LENGTH"] = (object)ToDec(ws.Cells[row, 7].Value) ?? DBNull.Value;
                        dr["MATERIAL"] = ToStr(ws.Cells[row, 8].Value);
                        dr["USEMODE"] = (object)ToInt(ws.Cells[row, 9].Value) ?? DBNull.Value;
                        dr["DATAMODE"] = (object)ToInt(ws.Cells[row, 10].Value) ?? DBNull.Value;
                        dr["NOTE"] = ToStr(ws.Cells[row, 11].Value);
                        dr["POINT_X"] = (object)ToDec(ws.Cells[row, 12].Value) ?? DBNull.Value;
                        dr["POINT_Y"] = (object)ToDec(ws.Cells[row, 13].Value) ?? DBNull.Value;
                        dr["TOWNSHIP"] = ToStr(ws.Cells[row, 14].Value);
                        dr["HEIGHT"] = (object)ToDec(ws.Cells[row, 15].Value) ?? DBNull.Value;
                        dr["MOD_DATE"] = (object)ToDate(ws.Cells[row, 16].Value) ?? DBNull.Value;
                        dr["STATE"] = (object)ToInt(ws.Cells[row, 17].Value) ?? DBNull.Value;
                        dr["DATA1"] = ToStr(ws.Cells[row, 18].Value);
                        dr["DATA2"] = ToStr(ws.Cells[row, 19].Value);
                        dr["LEVEL"] = ToStr(ws.Cells[row, 20].Value);
                        dt.Rows.Add(dr);
                        row++;
                        rows++;
                    }

                    if (rows == 0)
                        return Ok(new { rows, skipRows });

                    using (var bulk = new SqlBulkCopy(conn))
                    {
                        bulk.DestinationTableName = "[Cesium].[dbo].[streetlampData]";
                        foreach (DataColumn c in dt.Columns)
                            bulk.ColumnMappings.Add(c.ColumnName, c.ColumnName);
                        await bulk.WriteToServerAsync(dt);
                    }

                    return Ok(new { rows, skipRows });
                }
            }
            catch (Exception ex)
            {
                return Content(HttpStatusCode.InternalServerError, new { ok = false, error = ex.Message });
            }

        }
    }
}

namespace WebApplication_intern
{
    // 讀取資料庫的table名稱以顯示在cesium上讓使用者可以選擇要看哪一筆資料
    public class TablesController : ApiController
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["sqlConn"].ConnectionString;

        [HttpGet]
        public IEnumerable<string> GetTableNames()
        {
            List<string> tableNames = new List<string>();
            using (var conn = new SqlConnection(_connStr))
            {
                conn.Open();
                var cmd = new SqlCommand("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'", conn);
                var reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    tableNames.Add(reader.GetString(0));
                }
            }

            // 過濾不想顯示的表名
            var filteredTableNames = tableNames
                .Where(name => name.ToLower() != "login" && name.ToLower() != "sysdiagrams");
            return filteredTableNames;
        }
    }
}

namespace WebApplication_intern.Api
{
    public class DataController : ApiController
    {
        private readonly string _connStr = ConfigurationManager.ConnectionStrings["sqlConn"].ConnectionString;

        [HttpGet]
        public IHttpActionResult Get(string tableName)
        {
            if (string.IsNullOrWhiteSpace(tableName))
                return BadRequest("tableName is required");
            try
            {
                // 1. 查詢整個資料表
                DataTable dt = new DataTable();
                using (var conn = new SqlConnection(_connStr))
                {
                    conn.Open();
                    string sql = $"SELECT * FROM [{tableName}]";
                    using (var adapter = new SqlDataAdapter(sql, conn))
                    {
                        adapter.Fill(dt);
                    }
                }

                // 2. 轉成GeoJSON
                string geojson = ConvertDataTableToGeoJson(dt);
                // 儲存成檔案
                string fileName = $"geojson_{Guid.NewGuid()}.json"; // 產生亂碼以確保不重複
                string folderPath = System.Web.Hosting.HostingEnvironment.MapPath("~/tmp"); // 暫存在 "WebApplication_intern_v2/WebApplication_intern/tmp"資料夾中
                if (!System.IO.Directory.Exists(folderPath))
                {
                    System.IO.Directory.CreateDirectory(folderPath);
                }
                string filePath = System.IO.Path.Combine(folderPath, fileName);
                System.IO.File.WriteAllText(filePath, geojson, Encoding.UTF8);

                // 回傳檔案 URL
                string url = $"{Request.RequestUri.GetLeftPart(UriPartial.Authority)}/tmp/{fileName}";
                return Ok(new { url = url });
            }
            catch (Exception ex)
            {
                return InternalServerError(ex);
            }
        }

        private string ConvertDataTableToGeoJson(DataTable table)
        {
            // 經緯度欄位候選清單（不區分大小寫）
            string[] x_candidates = { "POINT_X", "longitude", "lon", "lng", "x", "east", "經度", "X座標", "x座標" };
            string[] y_candidates = { "POINT_Y", "latitude", "lat", "y", "north", "緯度", "Y座標", "y座標" };

            string lonField = null;
            string latField = null;

            foreach (DataColumn col in table.Columns)
            {
                string colName = col.ColumnName.ToLower();
                if (lonField == null && Array.Exists(x_candidates, x => x.ToLower() == colName))
                    lonField = col.ColumnName;
                else if (latField == null && Array.Exists(y_candidates, y => y.ToLower() == colName))
                    latField = col.ColumnName;

                if (lonField != null && latField != null)
                    break;
            }

            if (lonField == null || latField == null)
            {
                throw new Exception("資料表中找不到符合的經緯度欄位");
            }

            // 用於組合字串
            var sb = new StringBuilder();
            sb.Append("{\"type\":\"FeatureCollection\",\"features\":[");

            bool first = true;
            foreach (DataRow row in table.Rows)
            {
                if (!first) sb.Append(",");
                first = false;

                double lon = Convert.ToDouble(row[lonField]);
                double lat = Convert.ToDouble(row[latField]);

                sb.Append("{\"type\":\"Feature\",");
                sb.Append("\"geometry\":{\"type\":\"Point\",\"coordinates\":["); // 宣告幾何形狀為point
                sb.Append(lon).Append(",").Append(lat).Append("]},");
                sb.Append("\"properties\":{");

                foreach (DataColumn col in table.Columns)
                {
                    string colName = col.ColumnName;
                    var val = row[col];
                    sb.Append("\"").Append(colName).Append("\":");
                    if (val == DBNull.Value)
                        sb.Append("null");
                    else if (col.DataType == typeof(string) || col.DataType == typeof(DateTime))
                        sb.Append("\"").Append(val.ToString().Replace("\"", "\\\"")).Append("\"");
                    else if (col.DataType == typeof(bool))
                        sb.Append(val.ToString().ToLower());
                    else
                        sb.Append(val.ToString());
                    sb.Append(",");
                }
                if (sb[sb.Length - 1] == ',') sb.Length--; // 去除尾逗號
                sb.Append("}}");
            }

            sb.Append("]}");
            return sb.ToString();
        }

    }
}
