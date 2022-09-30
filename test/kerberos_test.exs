defmodule ExCurl.KerberosTest do
  use ExUnit.Case, async: true
  @moduletag :kerberos

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "retries 401s when http_auth_negotiate is enabled and kerberos is configured", %{
    bypass: bypass
  } do
    System.cmd("klist", ["-k", "test/support/files/krb5.keytab"])

    System.cmd("kinit", [
      "-k",
      "-t",
      "test/support/files/krb5.keytab",
      "HTTP/localhost@EXAMPLE.COM"
    ])

    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "authorization") do
        ["Negotiate " <> token] ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate #{token}")
          |> Plug.Conn.send_resp(200, "OK")

        _ ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate")
          |> Plug.Conn.send_resp(401, "Unauthorized")
      end
    end)

    resp =
      ExCurl.TestClient.get!("http://localhost:#{bypass.port}/test", http_auth_negotiate: true)

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "fails to retry 401s when http_auth_negotiate is enabled and kerberos is not configured",
       %{bypass: bypass} do
    output = System.cmd("klist", [])

    unless output == {"", 1} do
      System.cmd("bash", ["-c", "rm /tmp/krb*cc*"])
    end

    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "authorization") do
        ["Negotiate " <> token] ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate #{token}")
          |> Plug.Conn.send_resp(200, "OK")

        _ ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate")
          |> Plug.Conn.send_resp(401, "Unauthorized")
      end
    end)

    resp =
      ExCurl.TestClient.get!("http://localhost:#{bypass.port}/test", http_auth_negotiate: true)

    assert resp.status_code == 401
    assert resp.body == "Unauthorized"
  end

  test "does not retry 401s if http_auth_negotiate is not enabled even if kerberos is configured",
       %{bypass: bypass} do
    System.cmd("klist", ["-k", "test/support/files/krb5.keytab"])

    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "authorization") do
        ["Negotiate " <> token] ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate #{token}")
          |> Plug.Conn.send_resp(200, "OK")

        _ ->
          conn
          |> Plug.Conn.put_resp_header("WWW-Authenticate", "Negotiate")
          |> Plug.Conn.send_resp(401, "Unauthorized")
      end
    end)

    resp = ExCurl.TestClient.get!("http://localhost:#{bypass.port}/test")
    assert resp.status_code == 401
    assert resp.body == "Unauthorized"
  end
end
