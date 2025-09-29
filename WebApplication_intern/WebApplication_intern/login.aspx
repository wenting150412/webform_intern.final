<%@ Page Language="C#" AutoEventWireup="true" Inherits="Login" Codebehind="Login.aspx.cs" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>user login</title>
    <style>
        body {
            background: #f5f5f5;
            margin: 0;
            padding: 0;
            height: 100vh;
        }
        .login-container {
            box-sizing: border-box;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.12);
            padding: 40px 32px;
            min-width: 300px;
            width: 340px;
        }
        .login-title {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 24px;
            text-align: center;
            color: #222;
        }
        .login-item {
            margin-bottom: 18px;
        }
        .login-label {
            font-size: 14px;
            color: #444;
            margin-bottom: 5px;
            display: block;
        }
        .login-input {
            width: 100%;
            font-size: 15px;
            padding: 7px 10px;
            border: 1px solid #dedede;
            border-radius: 5px;
            margin-bottom: 4px;
        }
        .login-btn {
            width: 100%;
            background: #5c93bf;
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 9px 0;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin-bottom: 12px;
        }
        .error-label {
            color: #d8000c;
            font-size: 13px;
            text-align: center;
            margin-top: 6px;
            min-height: 20px;
            display: block;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="login-container">
            <div class="login-title">cesium登入</div>

            <div class="login-item">
                <label class="login-label" for="txtAccount">帳號：</label>
                <asp:TextBox ID="txtAccount" runat="server" CssClass="login-input"></asp:TextBox>
            </div>

            <div class="login-item">
                <label class="login-label" for="txtPassword">密碼：</label>
                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="login-input"></asp:TextBox>
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="登入" OnClick="btnLogin_Click" CssClass="login-btn" />
            <asp:Button ID="btnRegister" runat="server" Text="註冊" OnClick="btnRegister_Click" CssClass="login-btn" />

            <asp:Label ID="lblMessage" runat="server" CssClass="error-label"></asp:Label>
        </div>
    </form>
</body>
</html>
