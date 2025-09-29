<%@ Page Language="C#" AutoEventWireup="true" Inherits="Register" Codebehind="Register.aspx.cs" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>使用者註冊</title>
    <style>
        /* 外層方框容器 */
        .container {
            width: 360px;
            margin: 100px auto;
            padding: 25px 30px;
            border: 2px solid #444;
            border-radius: 8px;
            background-color: #fafafa;
            box-shadow: 0 0 8px rgba(0,0,0,0.1);
            font-family: Arial, sans-serif;
        }
        /* 標題 */
        .container h2 {
            text-align: center;
            margin-bottom: 20px;
            color: #333;
        }
        /* Label樣式 */
        .container label {
            display: block;
            margin-top: 12px;
            font-weight: bold;
            color: #222;
        }
        /* 文字方塊 */
        .container input[type="text"],
        .container input[type="password"],
        .container .aspTextBox {
            width: 100%;
            padding: 8px 10px;
            margin-top: 6px;
            border: 1px solid #ccc;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        /* button */
        .container input[type="submit"],
        .container .aspButton {
            margin-top: 20px;
            width: 100%;
            padding: 10px;
            background-color: #5c93bf;
            border: none;
            border-radius: 4px;
            color: white;
            font-size: 16px;
            cursor: pointer;
        }
        .container input[type="submit"]:hover,
        .container .aspButton:hover {
            background-color: #2a5db0;
        }
        /* 訊息label */
        #<%= lblMessage.ClientID %> {
            margin-top: 8px;
            display: block;
            color: red;
            font-weight: bold;
            text-align: center;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
    <div class="container">
        <h2>註冊新帳號</h2>
        <asp:Label ID="lblMessage" runat="server" ForeColor="Red"></asp:Label>

        <asp:Label ID="lblAccount" runat="server" Text="帳號:" AssociatedControlID="txtAccount"></asp:Label>
        <asp:TextBox ID="txtAccount" runat="server"></asp:TextBox>

        <asp:Label ID="lblPassword" runat="server" Text="密碼:" AssociatedControlID="txtPassword"></asp:Label>
        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password"></asp:TextBox>

        <asp:Label ID="lblConfirmPassword" runat="server" Text="確認密碼:" AssociatedControlID="txtConfirmPassword"></asp:Label>
        <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password"></asp:TextBox>

        <asp:Button ID="btnRegister" runat="server" Text="註冊" OnClick="btnRegister_Click" />
    </div>
    </form>
</body>
</html>
