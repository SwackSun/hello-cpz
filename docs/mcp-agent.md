# Publish hello-cpz through the CPZ MCP connection

Use this workflow when the developer asks you to publish an IPK. The developer can create a token with permission to publish their own apps and configure the client for Streamable HTTP at `https://cpz.firmiss.com/mcp`. [CPZ MCP settings](https://cpz.firmiss.com/admin/mcp/)

1. From the kit root, set `ipk="dist/hello-cpz_$(cat VERSION)_aarch64.ipk"`, or use the exact file supplied by the developer. Confirm the requested version. Read the package metadata with `ar p "$ipk" control.tar.gz | tar -xzO ./control` and record `sha256sum "$ipk"`. Use its English description. Call `list_my_submissions` to identify an existing hello-cpz revision or an already pending submission of this version and digest.
2. Upload the raw IPK over HTTPS with the same developer token as the MCP connection. Use a protected credential source. An interactive Bash example follows. The upload ID in the JSON response is valid for ten minutes.

   ```bash
   read -rsp 'CPZ MCP token: ' cpz_token
   printf '\n' >&2
   printf 'Authorization: Bearer %s\n' "$cpz_token" |
     curl --fail-with-body --silent --show-error -H @- \
       -H 'Content-Type: application/octet-stream' \
       --data-binary "@$ipk" https://cpz.firmiss.com/mcp/uploads
   unset cpz_token
   ```

3. Call `publish_package` with the returned `upload_id`, the package description and `draft: false` to submit for review. Include the current `revision` for updates. If the developer asked only for a draft, set `draft: true`.
4. Call `list_my_submissions` again. Verify the author, version, digest and review state. Report `pending` as awaiting review. After approval, `get_package` with `{"name":"hello-cpz"}` returns the public version, digest and download URL.
