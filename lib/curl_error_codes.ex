defmodule ExCurl.CurlErrorCodes do
  @moduledoc """
  Helper functions to map [curl error codes](https://curl.se/libcurl/c/libcurl-errors.html) from their integer value to the string value and vice versa.
  """

  @all_error_codes [
    "OK",
    "UNSUPPORTED_PROTOCOL",
    "FAILED_INIT",
    "URL_MALFORMAT",
    "NOT_BUILT_IN",
    "COULDNT_RESOLVE_PROXY",
    "COULDNT_RESOLVE_HOST",
    "COULDNT_CONNECT",
    "WEIRD_SERVER_REPLY",
    "REMOTE_ACCESS_DENIED",
    "FTP_ACCEPT_FAILED",
    "FTP_WEIRD_PASS_REPLY",
    "FTP_ACCEPT_TIMEOUT",
    "FTP_WEIRD_PASV_REPLY",
    "FTP_WEIRD_227_FORMAT",
    "FTP_CANT_GET_HOST",
    "HTTP2",
    "FTP_COULDNT_SET_TYPE",
    "PARTIAL_FILE",
    "FTP_COULDNT_RETR_FILE",
    "OBSOLETE (20)",
    "QUOTE_ERROR",
    "HTTP_RETURNED_ERROR",
    "WRITE_ERROR",
    "OBSOLETE (24)",
    "UPLOAD_FAILED",
    "READ_ERROR",
    "OUT_OF_MEMORY",
    "OPERATION_TIMEDOUT",
    "OBSOLETE (29)",
    "FTP_PORT_FAILED",
    "FTP_COULDNT_USE_REST",
    "OBSOLETE (32)",
    "RANGE_ERROR",
    "HTTP_POST_ERROR",
    "SSL_CONNECT_ERROR",
    "BAD_DOWNLOAD_RESUME",
    "FILE_COULDNT_READ_FILE",
    "LDAP_CANNOT_BIND",
    "LDAP_SEARCH_FAILED",
    "OBSOLETE (40)",
    "FUNCTION_NOT_FOUND",
    "ABORTED_BY_CALLBACK",
    "BAD_FUNCTION_ARGUMENT",
    "OBSOLETE (44)",
    "INTERFACE_FAILED",
    "OBSOLETE (46)",
    "TOO_MANY_REDIRECTS",
    "UNKNOWN_OPTION",
    "SETOPT_OPTION_SYNTAX",
    "OBSOLETE (50)",
    "OBSOLETE (51)",
    "GOT_NOTHING",
    "SSL_ENGINE_NOTFOUND",
    "SSL_ENGINE_SETFAILED",
    "SEND_ERROR",
    "RECV_ERROR",
    "OBSOLETE (57)",
    "SSL_CERTPROBLEM",
    "SSL_CIPHER",
    "PEER_FAILED_VERIFICATION",
    "BAD_CONTENT_ENCODING",
    "OBSOLETE (62)",
    "FILESIZE_EXCEEDED",
    "USE_SSL_FAILED",
    "SEND_FAIL_REWIND",
    "SSL_ENGINE_INITFAILED",
    "LOGIN_DENIED",
    "TFTP_NOTFOUND",
    "TFTP_PERM",
    "REMOTE_DISK_FULL",
    "TFTP_ILLEGAL",
    "TFTP_UNKNOWNID",
    "REMOTE_FILE_EXISTS",
    "TFTP_NOSUCHUSER",
    "OBSOLETE (75)",
    "OBSOLETE (76)",
    "SSL_CACERT_BADFILE",
    "REMOTE_FILE_NOT_FOUND",
    "SSH",
    "SSL_SHUTDOWN_FAILED",
    "AGAIN",
    "SSL_CRL_BADFILE",
    "SSL_ISSUER_ERROR",
    "FTP_PRET_FAILED",
    "RTSP_CSEQ_ERROR",
    "RTSP_SESSION_ERROR",
    "FTP_BAD_FILE_LIST",
    "CHUNK_FAILED",
    "NO_CONNECTION_AVAILABLE",
    "SSL_PINNEDPUBKEYNOTMATCH",
    "SSL_INVALIDCERTSTATUS",
    "HTTP2_STREAM",
    "RECURSIVE_API_CALL",
    "AUTH_ERROR",
    "HTTP3",
    "QUIC_CONNECT_ERROR",
    "PROXY",
    "SSL_CLIENTCERT",
    "UNRECOVERABLE_POLL"
  ]

  @doc """
  Returns the integer code for the corresponding string error message.

  Returns `-1` if the message is not a valid curl error code.

  ## Examples


      iex> ExCurl.CurlErrorCodes.get_code("URL_MALFORMAT")
      3

      iex> ExCurl.CurlErrorCodes.get_code("DOESN'T EXIST")
      -1
  """
  def get_code(message) when message in @all_error_codes,
    do: Enum.find_index(@all_error_codes, &(&1 == message))

  def get_code(_), do: -1

  @doc """
  Returns the string message for a coresponding integer error code.

  Returns `"CODE_OUT_OF_RANGE` if the value is not a valid curl error code.

  ## Examples


      iex> ExCurl.CurlErrorCodes.get_message(3)
      "URL_MALFORMAT"

      iex> ExCurl.CurlErrorCodes.get_message(256)
      "CODE_OUT_OF_RANGE"
  """
  def get_message(code) when is_integer(code) and code >= 0 and code <= 99,
    do: Enum.at(@all_error_codes, code)

  def get_message(_), do: "CODE_OUT_OF_RANGE"
end
