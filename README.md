# CAST: CrowdStrike Archive Scan Tool

This tool is a quick scanner to walk filesystems looking for vulnerable versions of log4j.  Please
see our blog post [here](https://www.crowdstrike.com/blog/free-targeted-log4j-search-tool/) for more detailed discussion.

Currently, it scans a given set of directories for JAR, WAR, ZIP, or EAR files, then scans for files therein matching a known set of checksums.

## Releases

See [the releases page](https://github.com/CrowdStrike/CAST/releases) for a list of downloads

## Deployment

Please see the [deploy](./deploy) directory for scripts and guidance.

## Usage

This tool currently has two verbs: "version" and "scan"

```shell
# ./cast version
version: 0.5.1, commit: d8d184fc49315e19f0d37015ed95ae500b2cca1d, date: 2021-12-22T19:41:22Z, builtBy: unknown
```

```shell
# ./cast scan -h
Usage of ./cast:
  -maxmem uint
         maximum sub-archive size to recurse (default 104857600)
  -recursion uint
         maximum in-memory in-archive recursion (0 disables) (default 3)
  -xdev
         do not cross device boundaries (POSIX-only)
```

The options should be fairly self-explanatory, but some clarification:
- maxmem is specified in bytes only, no human sizes for now
- a recursion of 0 will disable sub-archive scanning, but will still check inside of any first-tier ZIP archive it encounters.
- xdev is only working on POSIX platforms today

An example of running against both a ZIP file and a set of directories
```shell
./cast scan -maxmem 1000000 -recursion 1 ~/tmp/zzz.zip /tmp ./
```

Note that you can specify individual files _AND/OR_ directories to recurse. This enables leveraging preindexed filesystems, e.g.:

```shell
locate -0 *.jar | xargs -0 ./cast scan
```

## Sample output

```json
{"container":"~/tmp/zzz.zip","member":{"path":"/log4j-core-2.13.3.jar/org/apache/logging/log4j/core/net/JndiManager.class","size":4885,"modified":"2020-05-10T12:08:46Z"},"sha256":"c3e95da6542945c1a096b308bf65bbd7fcb96e3d201e5a2257d85d4dedc6a078"}
{"container":"~/tmp/zzz.zip","member":{"path":"/log4j-core-2.13.3.jar/org/apache/logging/log4j/core/util/NetUtils.class","size":4315,"modified":"2020-05-10T12:08:44Z"},"sha256":"f96e82093706592b7c9009c1472f588fc2222835ea808ee2fa3e47185a4eba70"}
```
