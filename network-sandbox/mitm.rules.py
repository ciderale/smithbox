from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if flow.request.host == "httpbin.org":
        flow.request.headers["X-My-Header"] = "my-value"
    if flow.request.host == "httpbin.org" and flow.request.method == "POST":
        flow.response = http.Response.make(
            403,
            b"DELETE requests to httpbin.org are blocked",
            {"Content-Type": "text/plain"},
        )
