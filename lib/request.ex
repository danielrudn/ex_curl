defmodule ExCurl.Request do
  @moduledoc false
  use ExCurl.Zig.MultiPlatformCurl

  ~Z"""
  const cURL = @cImport({
    @cInclude("curl.h");
  });

  const Header = struct {
    key: []u8,
    value: []u8
  };

  const RequestFlags = struct {
    follow_location: bool,
    ssl_verifyhost: bool,
    ssl_verifypeer: bool,
    return_metrics: bool,
    verbose: bool,
    http_auth_negotiate: bool,
  };

  const RequestConfiguration = struct {
    headers: []Header,
    url: []u8,
    method: []u8,
    body: []u8,
    flags: RequestFlags,
  };

  /// nif: request_dirty_cpu/1 dirty_cpu
  fn request_dirty_cpu(env: beam.env, json: []u8) !beam.term {
    return request(env, json);
  }

  /// nif: request/1
  fn request(env: beam.env, json: []u8) !beam.term {
    // initialize curl and vars
    var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena_state.deinit();

    const allocator = arena_state.allocator();

    const handle = cURL.curl_easy_init() orelse return beam.make_error_atom(env, "init_failed");
    defer cURL.curl_easy_cleanup(handle);

    var response_buffer = std.ArrayList(u8).init(allocator);
    var headers_buffer = std.ArrayList(u8).init(allocator);

    // superfluous when using an arena allocator, but
    // important if the allocator implementation changes
    defer response_buffer.deinit();
    defer headers_buffer.deinit();

    // set curl opts & callbacks
    var gpa = std.heap.GeneralPurposeAllocator(.{}){.backing_allocator = allocator};
    var config: RequestConfiguration = try parseRequestConfiguration(gpa.allocator(), json);
    defer std.json.parseFree(RequestConfiguration, config, .{
      .allocator = gpa.allocator(),
    });
    try setCurlOpts(allocator, handle, response_buffer, headers_buffer, config);
    // set headers
    var header_slist: [*c]cURL.curl_slist = null;
    defer cURL.curl_slist_free_all(header_slist);
    for (config.headers) |header| {
      var buf = try allocator.alloc(u8, header.key.len + 3 + header.value.len);
      _ = try std.fmt.bufPrint(buf, "{s}: {s}\x00", .{ header.key, header.value });
      header_slist = cURL.curl_slist_append(header_slist, buf.ptr);
      allocator.free(buf);
    }
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_HTTPHEADER, header_slist) != cURL.CURLE_OK)
      unreachable;

    // 3. perform request
    var result = cURL.curl_easy_perform(handle);
    if (result != cURL.CURLE_OK)
      return beam.make_error_term(env, beam.make_u64(env, result));

    // 4. getinfo and create response
    var response_list = try makeKeywordListResponse(env, handle, response_buffer, headers_buffer, config);
    return beam.make_ok_term(env, response_list);
  }

  fn parseRequestConfiguration(allocator: std.mem.Allocator, json: []u8) !RequestConfiguration {
    var stream = std.json.TokenStream.init(json);
    var parsedData = try std.json.parse(RequestConfiguration, &stream, .{
      .allocator = allocator,
      .ignore_unknown_fields = true,
    });
    return parsedData;
  }

  fn makeKeywordListResponse(env: beam.env, handle: *cURL.CURL, response_buffer: std.ArrayList(u8), headers_buffer: std.ArrayList(u8), config: RequestConfiguration) !beam.term {
    // metrics
    var total_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_TOTAL_TIME_T, &total_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var total_time_term = beam.make_f64(env, total_time);
    var total_time_tuple = try makeKeywordListTuple(env, "total_time", total_time_term);

    var namelookup_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_NAMELOOKUP_TIME_T, &namelookup_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var namelookup_time_term = beam.make_f64(env, namelookup_time);
    var name_lookup_tuple = try makeKeywordListTuple(env, "namelookup_time", namelookup_time_term);

    var connect_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_CONNECT_TIME_T, &connect_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var connect_time_term = beam.make_f64(env, connect_time);
    var connect_time_tuple = try makeKeywordListTuple(env, "connect_time", connect_time_term);

    var appconnect_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_APPCONNECT_TIME_T, &appconnect_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var appconnect_time_term = beam.make_f64(env, appconnect_time);
    var appconnect_time_tuple = try makeKeywordListTuple(env, "appconnect_time", appconnect_time_term);

    var pretransfer_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_PRETRANSFER_TIME_T, &pretransfer_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var pretransfer_time_term = beam.make_f64(env, pretransfer_time);
    var pretransfer_time_tuple = try makeKeywordListTuple(env, "pretransfer_time", pretransfer_time_term);

    var starttransfer_time: f64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_STARTTRANSFER_TIME_T, &starttransfer_time) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var starttransfer_time_term = beam.make_f64(env, starttransfer_time);
    var starttransfer_time_tuple = try makeKeywordListTuple(env, "starttransfer_time", starttransfer_time_term);

    var status_code: u64 = 0;
    if (cURL.curl_easy_getinfo(handle, cURL.CURLINFO_RESPONSE_CODE, &status_code) != cURL.CURLE_OK)
      return error.CURLGETINFO_FAILED;
    var status_code_term = beam.make_u64(env, status_code);
    var status_code_tuple = try makeKeywordListTuple(env, "status_code", status_code_term);

    var response_body_term = beam.make_slice(env, response_buffer.items);
    var response_body_tuple = try makeKeywordListTuple(env, "body", response_body_term);

    var headers_term = beam.make_slice(env, headers_buffer.items);
    var headers_tuple = try makeKeywordListTuple(env, "headers", headers_term);

    // response list
    var response_tuple_slice: []beam.term = undefined;
    if (config.flags.return_metrics) {
      response_tuple_slice = try beam.allocator.alloc(beam.term, 10);
      response_tuple_slice[0] = response_body_tuple;
      response_tuple_slice[1] = total_time_tuple;
      response_tuple_slice[2] = name_lookup_tuple;
      response_tuple_slice[3] = connect_time_tuple;
      response_tuple_slice[4] = appconnect_time_tuple;
      response_tuple_slice[5] = pretransfer_time_tuple;
      response_tuple_slice[6] = starttransfer_time_tuple;
      response_tuple_slice[7] = status_code_tuple;
      response_tuple_slice[8] = try makeKeywordListTuple(env, "metrics_returned", beam.make_bool(env, true));
      response_tuple_slice[9] = headers_tuple;
    } else {
      response_tuple_slice = try beam.allocator.alloc(beam.term, 3);
      response_tuple_slice[0] = response_body_tuple;
      response_tuple_slice[1] = status_code_tuple;
      response_tuple_slice[2] = headers_tuple;
    }
    defer beam.allocator.free(response_tuple_slice);

    return beam.make_term_list(env, response_tuple_slice);
  }

  fn makeKeywordListTuple(env: beam.env, key: []const u8, value: beam.term) !beam.term {
    var key_atom = beam.make_atom(env, key);
    var tuple_slice: []beam.term = try beam.allocator.alloc(beam.term, 2);
    defer beam.allocator.free(tuple_slice);
    tuple_slice[0] = key_atom;
    tuple_slice[1] = value;
    return beam.make_tuple(env, tuple_slice);
  }

  fn setCurlOpts(allocator: std.mem.Allocator, handle: *cURL.CURL, response_buffer: std.ArrayList(u8), headers_buffer: std.ArrayList(u8), config: RequestConfiguration) !void {
    if (config.flags.verbose) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_VERBOSE), @as(c_long, 1)) != cURL.CURLE_OK)
        unreachable;
    }

    if (config.flags.follow_location) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_FOLLOWLOCATION), @as(c_long, 1)) != cURL.CURLE_OK)
        unreachable;
    }

    if (config.flags.ssl_verifypeer) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_SSL_VERIFYPEER), @as(c_long, 1)) != cURL.CURLE_OK)
        unreachable;
    } else {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_SSL_VERIFYPEER), @as(c_long, 0)) != cURL.CURLE_OK)
        unreachable;
    }

    if (config.flags.ssl_verifyhost) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_SSL_VERIFYHOST), @as(c_long, 1)) != cURL.CURLE_OK)
        unreachable;
    } else {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_SSL_VERIFYHOST), @as(c_long, 0)) != cURL.CURLE_OK)
        unreachable;
    }

    // Set options to support RFC 4559 for SPNEGO-based Kerberos authentication
    // when this flag is enabled
    if (config.flags.http_auth_negotiate) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_HTTPAUTH), cURL.CURLAUTH_NEGOTIATE) != cURL.CURLE_OK)
        unreachable;
      if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_USERPWD, ":") != cURL.CURLE_OK)
        unreachable;
    }

    // HTTP Method
    if (std.mem.eql(u8, config.method, "POST")) {
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_POST), @as(c_long, 1)) != cURL.CURLE_OK)
        unreachable;
    } else if (!std.mem.eql(u8, config.method, "GET")) {
      var method_as_c_string = std.cstr.addNullByte(allocator, config.method) catch unreachable;
      defer allocator.free(method_as_c_string);
      if (cURL.curl_easy_setopt(handle, @bitCast(c_uint, cURL.CURLOPT_CUSTOMREQUEST), method_as_c_string.ptr) != cURL.CURLE_OK)
        unreachable;
    }

    // URL
    var url_as_c_string = std.cstr.addNullByte(allocator, config.url) catch unreachable;
    defer allocator.free(url_as_c_string);
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url_as_c_string.ptr) != cURL.CURLE_OK)
      unreachable;

    // Headers callback
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_HEADERFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
      unreachable;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_HEADERDATA, &headers_buffer) != cURL.CURLE_OK)
      unreachable;

    // Request body
    if (!std.mem.eql(u8, config.body, "")) {
      if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_READFUNCTION, readFn) != cURL.CURLE_OK)
        unreachable;
      if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_READDATA, &config) != cURL.CURLE_OK)
        unreachable;
    }

    // Response body callback
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
      unreachable;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, &response_buffer) != cURL.CURLE_OK)
      unreachable;
  }

  fn readFn(dest: [*]u8, size: usize, nmemb: usize, config: *RequestConfiguration) usize {
    const bufferSize = size * nmemb;
    if (config.body.len > 0) {
      const n = std.math.min(config.body.len, bufferSize);
      std.mem.copy(u8, dest[0..n], config.body[0..n]);
      config.body = config.body[n..];
      return n;
    }
    return 0;
  }

  fn writeToArrayListCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer = @intToPtr(*std.ArrayList(u8), @ptrToInt(user_data));
    var typed_data = @intToPtr([*]u8, @ptrToInt(data));
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
  }
  """
end
