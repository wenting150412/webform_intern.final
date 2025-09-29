using System;
using System.Configuration;
using System.Data.SqlClient;

public partial class Register : System.Web.UI.Page
{
    protected void btnRegister_Click(object sender, EventArgs e)
    {
        string account = txtAccount.Text.Trim();
        string password = txtPassword.Text.Trim();
        string confirmPassword = txtConfirmPassword.Text.Trim();

        if (string.IsNullOrEmpty(account) || string.IsNullOrEmpty(password))
        {
            lblMessage.Text = "帳號和密碼不能為空";
            return;
        }

        string connStr = ConfigurationManager.ConnectionStrings["MyConnectionString"].ConnectionString;

        using (SqlConnection conn = new SqlConnection(connStr))
        {
            conn.Open();

            // 檢查帳號是否存在
            string checkSql = "SELECT COUNT(*) FROM login WHERE account = @account";
            using (SqlCommand checkCmd = new SqlCommand(checkSql, conn))
            {
                checkCmd.Parameters.AddWithValue("@account", account);
                int count = (int)checkCmd.ExecuteScalar();
                if (count > 0)
                {
                    lblMessage.Text = "帳號已存在";
                    txtAccount.Text = "";
                    txtPassword.Text = "";
                    txtConfirmPassword.Text = "";

                    return;
                }
            }

            if (password != confirmPassword)
            {
                lblMessage.Text = "密碼與確認密碼不符";
                return;
            }

            // 新增帳號密碼
            string insertSql = "INSERT INTO login (account, password) VALUES (@account, @password)";
            using (SqlCommand insertCmd = new SqlCommand(insertSql, conn))
            {
                insertCmd.Parameters.AddWithValue("@account", account);
                insertCmd.Parameters.AddWithValue("@password", password);
                insertCmd.ExecuteNonQuery();
            }
        }

        //if (password != confirmPassword)
        //{
        //    lblMessage.Text = "密碼與確認密碼不符";
        //    return;
        //}

        // 顯示成功訊息跳回登入頁
        ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('註冊成功，請重新登入');window.location='Login.aspx';", true);
    }
}
