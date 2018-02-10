# Twitter to Newsboat/RSS

### Works On:

| OS                       | Bash Version | Utils	       | Date               |
|:------------------------:|:-------------|:-------------------|:-------------------|
| OpenBSD AMD64 6.2 Stable | GNU Bash 4.4 | OpenBSD utils 6.2  | February 6th, 2018 |
| Fedora 27 x86_64         | GNU Bash 4.4 | GNU coreutils 8.27 | February 6th, 2018 |

| RSS Reader               | Versions                                               |
|:------------------------:|:-------------------------------------------------------|
| Newsboat                 | r2.10.2                                                |
| Newsbeuter               | 2.9                                                    |

## What is this?
A bash script that takes Twitter handles as arguments, downloads their feeds, and converts them to a newsboat-compatible, Atom RSS format.

## Usage
The simplest way to run it is
```
./twitterAtom.sh handle1 handle2 handle3
```
where handles are Twitter handles, with no preceding "@."

The script can take arguments from an input file, one handle per line. Output is normally sent to standard out and can be redirected to a file of choice, or used in tandem with newsboat's execurl hook. Output files are specified with the `-o` flag. Output file is echoed and confirmation is asked before writing. This can be suppressed by using the `-n` flag before an output flag. An execurl hook can be automatically appended to `.newsboat/urls` if the `-a` flag is used. This will appened the command and all of its handle arguments to an execurl statement, which allows newsboat to automatically fetch a new RSS feed.

`-h` or `--help` is also available for the mandoc.

## Outputted Format

Tweets are automatically sorted by date and time, newest first.

Example:
```
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="https://www.w3.org/2005/Atom">
     <channel>
	<title>Custom Generated Twitter RSS Feed</title>
	<id>tag:custom.generated.twitter.rss:/en//1</id>
	<item>
		<title>01:38:58</title>
		<description>
<h1>handle1 | 12:20 PM 5 Feb 2018</h1><p><Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed fringilla arcu sed est facilisis, in porta neque mattis. Suspendisse potenti. <img src="https://pic.twitter.com/123456789" /></p>
<h1>handl2 | 10:52 PM 5 Feb 2018</h1><p>Aliquam in magna lacinia, dictum nibh id, condimentum ligula. <a href="http://example.com/0">Link</a></p>
<h1>handle1 | 10:35 PM 5 Feb 2018</h1><p>Vestibulum sed viverra augue. Morbi turpis nulla, porttitor et erat eget, tempus imperdiet sem. <a href="http://example.com/1">Link</a><img src="https://pic.twitter.com/123456789" /></p>
<h1>handle3 | 10:11 PM 5 Feb 2018</h1><p>Fusce dolor enim, ullamcorper id varius in, elementum vel ligula. <a href="http://example.com/2">Link</a></p>
<h1>swiftonsecurity | 9:50 PM 5 Feb 2018</h1><p>Morbi vitae auctor turpis, vel mattis leo. In vitae mi ut libero sollicitudin pulvinar.</p>
<h1>handle1 | 9:09 PM 5 Feb 2018</h1><p>[No Text]</p>
	      	</description>
	</item>
    </channel>
</rss>
```

Quotes and ineqaulity symbols (< >) have been escaped for proper display. `"` converts to `&quot;`, `>` converts to `&gt`, and `<` to `&lt;`.

When run through newsboat, it comes out like:
```
Feed: Custom Generated Twitter RSS Feed
Title: 01:38:58
Date: Tue, 05 Feb 2018 01:38:58 -1000

handle1 | 12:20 PM 5 Feb 2018
------------------------------------

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed fringilla arcu sed est facilisis, in porta neque mattis. Suspendisse potenti.[image 1]

handle2 | 10:52 PM 5 Feb 2018
------------------------------------

Aliquam in magna lacinia, dictum nibh id, condimentum ligula. Link[2]

...

```

## Environment Variables

Environment variables can be set by adding `ENVIRONMENT_VARIABLE=VALUE` before the script name. Like:

```
TITLE_CHANNEL="My Twitter Feed" ./twitterAtom.sh handle1 handle2
```
| Variable      | Description									           | Default							   |
|:-------------:|:-----------------------------------------------------------------------------------------|:-------------------------------------------------------------:|
| TITLE_CHANNEL | Top level name of the RSS feed							   | Custom Generated Twitter RSS Feed				   |
| TITLE_ITEM    | Name for each feed collection               	      	     	       	      	     	   | date +%T							   |
| ID_CHANNEL    | Unique ID of the channel/feed		      	      	   		      	   	   | tag:custom.generated.twitter.rss:/en//1			   |
| BLANK_TEXT    | Changes the text outputed by tweets without text. If set to empty, will break formatting | [No Text]						   	   |
| LINK_TEXT     | Changes the text marking links. If set to empty, will break formatting	      	   | Link							   |
| DEBUG_MODE    | If set to anything besides 0, will suppress all  error exits 	    	         	   | 0								   |
| CONFIRM       | If 0, always prompts before writing to output. If 1, skips  	    	    		   | 0								   |
| CONFIG_PATH   | If set, overrides default  path 	    			      		   	   | .newsboat/url						   |
     

## CAVEATS
This utility is extremely unstable owing to Twitter's slaphappy abuse of HTML as nothing more than a foundation for divs. As well as the natural instability of the web and the erratic web developers that guard it from the javascript-unenlightened. Expect to see HTML markup in your feed. Expect to see no feed at all. 