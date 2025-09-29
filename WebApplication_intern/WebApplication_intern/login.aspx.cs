using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Principal;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Login : System.Web.UI.Page
{
    protected void btnLogin_Click(object sender, EventArgs e)
    {
        string account = txtAccount.Text.Trim();
        string password = txtPassword.Text.Trim();

        string connStr = ConfigurationManager.ConnectionStrings["MyConnectionString"].ConnectionString;

        using (SqlConnection conn = new SqlConnection(connStr))
        {
            conn.Open();
            string sql = "SELECT COUNT(*) FROM login WHERE account = @account AND password = @password";
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@account", account);
                cmd.Parameters.AddWithValue("@password", password);
                int count = (int)cmd.ExecuteScalar();

                // 如果資料庫有這筆資料，則 count= 1
                if (count > 0)
                {
                    Session["User"] = account;   // 紀錄登入狀態
                    Response.Redirect("index.aspx");  // 導向 Cesium 主頁
                }
                else
                {
                    lblMessage.Text = "帳號或密碼錯誤";
                }
            }
        }
    }
    protected void btnRegister_Click(object sender, EventArgs e)
    {
        Response.Redirect("Register.aspx");
    }

}