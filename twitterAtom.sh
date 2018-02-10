#!/usr/bin/env bash
#Gaddox | February 10th, 2018


{
    readonly PROG_NAME=$(basename $0);
    readonly PROG_DIR=$(readlink -f $(dirname $0));
    readonly USER=$(whoami)
    readonly ARG_LIST=("$@");
    readonly ARG_AMOUNT="$#";
    readonly TITLE_CHANNEL="${TITLE_CHANNEL:=Custom Generated Twitter RSS Feed}";
    readonly TITLE_ITEM="${TITLE_ITEM:=$(date +%T)}";
    readonly ID_CHANNEL="${ID_CHANNEL:=tag:custom.generated.twitter.rss:/en//1}";
    readonly BLANK_TEXT="${BLANK_TEXT:=[No Text]}";
    readonly LINK_TEXT="${LINK_TEXT:=Link}";
    readonly CONFIG_PATH="${CONFIG_PATH:=/home/$USER/.newsboat/urls}";
    DEBUG_MODE="${DEBUG_MODE:=0}";
    INPUT_FILE=""
    OUTPUT_FILE=""
    HANDLES=();
    LINKS=();
    CONFIRM=0;
} ||\
	{
	    echo "Failed to declare readonlys";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
	}

process_arguments () {

    {
	
	if [ "$ARG_AMOUNT" -gt 0 ]; then
	    for (( i=0; "$i" < "$ARG_AMOUNT" ; i++ )); do	
		if [[ "${ARG_LIST[$i]}" == "--help" || "${ARG_LIST[$i]}" == "-h" ]]; then
		    { help_dialog; };
		elif [[ "${ARG_LIST[$i]}" == "-a" || "${ARG_LIST[$i]}" == "--append-config" ]]; then
		    local APPEND=1
		elif [[ "${ARG_LIST[$i]}" == "-n" || "${ARG_LIST[$i]}" == "--no-confirm" ]]; then
		    let CONFIRM=1;
		elif [[ "${ARG_LIST[$i]}" == "-o" || "${ARG_LIST[$i]}" == "--output-file" ]]; then
		    OUTPUT_FILE="${ARG_LIST[$((i+1))]}";
		    echo > "$OUTPUT_FILE";
		    if [ "$?" -eq 0 ]; then
			let i=$i+1;
			echo 'Writing to '"$OUTPUT_FILE"
			if [[ "$CONFIRM" -eq 1 ]]; then
			    :;
			else
			    read -p "Continue? (Y/N): " CONFIRM;
			    [[ "$CONFIRM" == [yY] ||\
				   "$CONFIRM" == [yY][eE][sS] ]] ||{
				echo "Aborting."
				{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
			    }
			fi
			:;
		    else
			echo "Can't write to output file";
			{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
		    fi
		    
		elif [[ "${ARG_LIST[$i]}" == "-i" || "${ARG_LIST[$i]}" == "--input-file" ]]; then
		    INPUT_FILE="${ARG_LIST[$((i+1))]}";
		    let i=$i+1;
		    if [ -s "$INPUT_FILE" ]; then
			while IFS='' read -r  line || [[ -n "$line" ]]; do
			    HANDLES+=("$line");
			done<"$INPUT_FILE"
		    else
			local INPUT_FILE_STATUS=1;
		        
		    fi
		elif [[ "${ARG_LIST[$i]}" =~ ^[a-zA-Z0-9_]{1,15}$ ]]; then
		    HANDLES+=("${ARG_LIST[$i]}");
		else
		    if [[ "${ARG_LIST[$i]}" =~ ^.{16,}$ ]]; then
			echo "FAILED: \"$i\" too long";
			{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
		    elif [[ "${ARG_LIST[$i]}" =~ [^[a-zA-Z0-9_]]* ]]; then
			echo "FAILED: \"$i\" has invalid characters";
			{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
		    else
			echo "Invalid arg.";
			{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
		    fi;
		fi;
	    done;
	    if [[ "$APPEND" -eq 1 ]]; then
		while grep -q "$PROG_NAME" "$CONFIG_PATH"; do
	            sed -i "\~$PROG_NAME~d" "$CONFIG_PATH";
		done
		{
		    {
			## Newsbeuter needs trailing newlines sometimes
			echo "\"exec:$PROG_DIR/$PROG_NAME ${HANDLES[@]}\"";
			echo ""
		    } >> "$CONFIG_PATH";
		    
		} ||\
		    {
			echo "Failed appending config. Try manually appending " \
			     "\"exec:$PROG_DIR/$PROG_NAME ${HANDLES[@]}\"" ; }
	    elif [ "${#HANDLES[@]}" -gt 0 ]; then
		:;
	    else
		if [[ "$INPUT_FILE_STATUS" -eq 1 ]]; then
		    echo "Input file is empty and";
		fi
		echo "No handles specified.";
		{ exit ; }
	    fi
	elif [ "$ARG_AMOUNT" -eq 0 ]; then
	    echo "FAILED: No arguments specified.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
	else
	    echo "FAILED: Unknown error with handles.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
	fi;
	
    } ||\
	{
	    echo "Failed to begin processing args.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
	}
}

generate_temporary_directory () {
    
    {
	local TEMPDIR=$(mktemp -d "/tmp/$PROG_NAME.XXXXXXX");
	trap 'rm -dRf "$TEMPDIR"' EXIT;
	echo "$TEMPDIR"; } ||\
	    {
		echo "Failed to create temp directory.";
		{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; }
	    }
}

generate_twitter_links () {
    
    {
	local HANDLES_AMOUNT=${#HANDLES[@]};
	
	for ((i=0; i < HANDLES_AMOUNT ; i++)); do
	    LINKS+=("https://twitter.com/${HANDLES[$i]} ");
	done;
	
    } ||\
	{
	    echo "Failed to generate links."
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}

download_page () {

    {
	local USERAGENT='Mozilla/5.0 (Windows NT 10.0; WOW64; rv:50.) Gecko/20100101 Firefox/50.0';
	for ((i=0;i < ${#HANDLES[@]} ; i++)); do
	    wget ${LINKS[$i]} -qO "$RAW_PAGE" -U "$USERAGENT";
	    shorten_page;
	done;
    } ||\
	{
	    echo "Failed to download page.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}

shorten_page () {
    
    {
	fmt -w 1000 "$RAW_PAGE" |\
	    awk -v ORIGIN="${HANDLES[$i]}" 'BEGIN{FS=OFS=" : ";x=""};
    	    /class="_timestamp/{gsub(/.*title="/,"",$0);gsub(/" .*/, "", $0);\
    	    gsub(/ - /, " ", $0); x = "<updated>"$0"<\/updated>";}\
    	    /<p class="TweetTextSize.*<\/p>/{print x "<origin=\""ORIGIN"\">" $0}' >> "$PAGE";
    } ||\
	{
	    echo "Failed to shorten page.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
    
}

format_page () {
    
    {
	while IFS='' read -r  line || [[ -n "$line" ]]; do

	    local CARRYOVER=$(mktemp "$TEMPDIR/CARRYOVER.XXXXXXX");
	    local CARRYOVER2=$(mktemp "$TEMPDIR/CARRYOVER2.XXXXXXX");
	    
	    local X="<p class=\"TweetTextSize TweetTextSize--normal js-tweet-text tweet-text\" lang=\"";
	    local N="\" data-aria-label-part=";
	    local Y="\" data-query-source=\"hashtag_click\" class=\"twitter-hashtag pretty-link js-nav\" dir=\"ltr\" >";
	    local Z="<a href=\"";
	    local W="rel=\"nofollow noopener\" dir=\"ltr\" data-expanded-url=\"";
	    local V="\" class=\"twitter-timeline-link";
	    local U="class=\"twitter-atreply";
	
	    local MAX_HASHTAG_CHAR=60;

	
	    sed "s/$X.\{0,4\}$N\".\">/<entry>/g" <( echo "$line" ) |\
		sed "s/<\/p>/<\/p><\/content><\/entry>/g" |\
		sed "s/$Z.\{0,$MAX_HASHTAG_CHAR\}$Y<s>\#<\/s>/\#/g" |\
		sed -r "s/<.{0,1}(b|s|a)>/ /g" | \
		sed "s/$Z.\{0,$MAX_HASHTAG_CHAR\}$W/<a href=\"/g" |\
		sed "s/$V.*span>/\"\/>/g" |\
		sed "s/$Z.\{0,$MAX_HASHTAG_CHAR\}$U.* >//g" |\
		sed -r "s/$Z\https?\:\/\/t\.co\/.{10}//g" |\
		sed "s/$V.*\" >/<img src=\"https\:\/\//g" |\
		sed "s/\&\#39\;/\'/g" |\
		sed "s/\&quot\;/\"/g" |\
		sed "s/  / /g" |\
		sed "s/ </</g" > "PAGE2";
	
	    ## Close img tags and move </p> tag forward
	    if [[ $(cat "PAGE2") =~ '<img src'.* ]]; then
		IMG="$( sed "s/<\/p>/<\/p>/" "PAGE2" | grep -o "<img src=\"https.*<\/p>" )";
		IMGX="$( sed "s/<\/p>/\" \/><\/p>/" <( echo "$IMG" ))";
		sed "s~$IMG~$IMGX~" "PAGE2" > "PAGE3";
		cat "PAGE3" > "PAGE2";
	    fi;
	
	    ## Close and format link tags properly
	    ## REMOVE: Moving link tags after paragraph tags
	    if [[ $(cat "PAGE2") =~ '<a href'.* ]]; then
		HREF="$( sed "s/<\/p>/<\/p>/" "PAGE2"| grep -o "<a href.*>" )";
       		HREFX="$( sed "s/\"\/>/\">$LINK_TEXT<\/a>/" <( echo "$HREF" ) )";
		sed "s~$HREF~$HREFX~" "PAGE2" | sed "s/<a href/ <a href/g" > "PAGE3";
		cat "PAGE3" > "PAGE2";
		HREF="$( grep -o "<a href.*\/a>" "PAGE2")";
	    
		## Move link tags before img tags or before paragraph tags
		if [[ $(cat "PAGE2") =~ '<img src'.* ]]; then
		    sed "s~$HREF~~g" "PAGE2" > "PAGE3";
		    sed "s~<img~$HREF<img~" "PAGE3" > "PAGE2";
		else
		    sed "s~$HREF~~g" "PAGE2" > "PAGE3";
		    sed "s~<\/p~$HREF<\/p~" "PAGE3" > "PAGE2";
		fi;
	    
		## Write [No Text] so blank tweets don't give newsbeuter a seizure
		if [[ $(cat "PAGE2") =~ '<entry> <a href'.* ]]; then
		    sed "s~<entry> ~<entry>$BLANK_TEXT~g" "PAGE2" > "PAGE3";
		    cat "PAGE3" > "PAGE2";
		fi;
	    fi;
	
	    ## Create tweet headers
	    ## REMOVE: Author + Name + Updated redundancy
	    sed "s/<origin=\"/<author><name>/" "PAGE2" | sed "s/\">/<\/name><\/author><content type=\"HTML\"><p>/" > "PAGE3";
	    cat "PAGE3" > "PAGE2";
	
	    ## Remove "Updated" and "Name" tags in header, and put in place header
	    AUTHOR=$( grep -o "<name>.*</name>" "PAGE2" | sed "s/<.\{0,1\}name>//g" );
	    DATE=$( grep -o "<updated>.*</updated>" "PAGE2" | sed "s/<.\{0,1\}updated>//g" );
	    sed "s/<p>/<h1>$AUTHOR | $DATE<\/h1><p>/" "PAGE2" > "PAGE3";
	    sed "s/<.\{0,1\}entry>//g" "PAGE3" | sed "s/<\/content>//g" |\
		sed "s/<content type=\"HTML\">//g" |\
		sed 's/<updated>.*<\/author>//g' > "PAGE2";
	
	    ## Convert quotes and ineqaulity (< and >) signs to HTML-friendly format
	    sed "s/</\&lt\;/g" "PAGE2" | sed "s/>/\&gt\;/g" | sed "s/\"/\&quot\;/g" >> "$PAGE3";
	
	done <"$PAGE";
    } ||\
	{
	    echo "Failed to format page.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}

extract_to_sort () {

    {
	local COUNTER=1;
	: > "$PAGE";
	
	## Extract all of the formatted tweets and format them for sorting
	while IFS='' read -r  line || [[ -n "$line" ]]; do
	    
	    ## Print line number
	    printf "%d||" "$COUNTER" >> "$PAGE";
	    
	    ## This is a hack, set PM and AM to unlikely numbers for easier sorting
	    grep -o ".*h1.*h1" <( echo "$line" ) | sed "s/ PM / 999999 /g" | sed "s/ AM / 999998 /g" |\
		sed "s/:/ : /g" >> "$PAGE";
	    let COUNTER=COUNTER+1;
	done <"$PAGE3";
    } ||\
	{
	    echo "Extracting to sort failed.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}


sort_extracted () {

    {
	: > "$PAGE2";
	
	## Sort all tweets by (in order): Year, Month, Date, PM/AM, Hour, Minute
	## Remove formatting hack
	sort -k9,9rn -k8,8rM -k7,7rn -k6,6rn -k3,3rn -k5,5rn "$PAGE" | sed "s/999999/PM/g" |\
	    sed "s/999998/AM/g" | sed "s/ : /:/g" >> "$PAGE2";
    } ||\
	{
	    echo "Sorting extract failed.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}
    
format_headers () {

    {
	local COUNTER=1;
	: > "$PAGE";
	
	## Copy sorted Tweet __Headers__ and append inline line number
	while IFS='' read -r  line || [[ -n "$line" ]]; do
	    sed "s/^/$COUNTER|/g" <( echo "$line") >> "$PAGE";
	    let COUNTER=COUNTER+1;
	done <"$PAGE2"
    } ||\
    {
	echo "Formatting headers failed.";
	{ if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	
    }
}

replace_sorted () {

    {
	: > "$PAGE2";
	
	## Find full tweet, using headers, and append them in sorted order to file
	## TO-DO: Inline this with the sorted Tweet Headers
	while IFS='' read -r  line || [[ -n "$line" ]]; do
	    MATCHNUM="$(grep -o "^.*|.*||" <( echo "$line") | grep -o "|.*$" | sed "s/|//g")";
	    sed -n "$MATCHNUM p" "$PAGE3" >> "$PAGE2";
	done <"$PAGE";
    } ||\
	{
	    echo "Replacing sorted failed.";
	    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
	}
}

output_xml () {

    {
	TEMPXML=$(mktemp "$TEMPDIR/TEMPXML.XXXXXXX");

	{
	    echo '<?xml version="1.0" encoding="UTF-8"?>';
	    echo '<rss version="2.0" xmlns:atom="https://www.w3.org/2005/Atom">';
	    echo '<channel>';
	    echo '<title>'"$TITLE_CHANNEL"'</title>';
	    echo '<id>'"$ID_CHANNEL"'</id>';
	    echo '<item>';
	    echo '<title>'"$TITLE_ITEM"'</title>';
	    echo '<description>';
	    cat "$PAGE2";
	    echo '</description>';
	    echo '</item>';
	    echo '</channel>';
	    echo '</rss>' ;}  >> "$TEMPXML";
	    if [ -s "$OUTPUT_FILE" ]; then
		touch "$OUTPUT_FILE";
		cat "$TEMPXML" > "$OUTPUT_FILE";
	    else
		cat "$TEMPXML";
	    fi; } ||\
		{
		    echo "Failed to output XML.";
		    { if [[ "$DEBUG_MODE" -eq 0 ]]; then exit 1; fi; };
		}
}

help_dialog (){

cat <<EOF
TwitterAtom                 General Commands Manual                TwitterAtom

SYNOPSIS
     ./twitterAtom.sh [-n] [-a] [-o output-file] [-i input-file] [handle] 

DESCRIPTION
     The twitterAtom.sh script reads given twitter handles, through
     an input file, regular spaced delimited arguments, or standard input,
     and generates a newsboat-compatible Atom syndication file to a 
     specified file or standard output. 

     Twitter handles must be within standard requirements of 1 to 15 
     characters in length. And only containing alphanumeric characters or 
     underscores. 

     Options:
     -i file				
     --input-file file	
          Specify the input file to read handles from. May be used in 
	  combination with standard input

     -o file
     --output-file file	
     	  Specify the output file, instead of using the standard output

     -a 
     --append-config
	  Append snownews exec hook into .newsboat/urls so script 
	  automatically fetches new tweets whenever newsboat is started.
	  Will remove previous config for the script if it exists.

     -n
     --no-confirm
	  Suspresses prompt for writing

     -d 
     --debug
	  Suppresses all exits that are caused by non-formatting errors
	  
     -h
     --help
          Display this help text

     The process starts by downloading the HTML pages of all handles
     specified. Then the HTML is formatted numerous times to extract
     only the text, links, and images from tweets. After, all of the
     formatted tweets are sorted in chronological order, regardless 
     of handle. Once sorting is finished, all of the tweets are 
     wrapped around Atom XML markup and pushed to output. 

     Output XML has been designed to be newsboat-friendly, by 
     grouping all of the tweets under one "description" tag to mimic
     a full article. Handles and dates are grouped under "h1" tags
     to better separate tweets. Bodies are between "p" tags. URLs 
     are coupled with "href" tags, which in turn are coupled with 
     "a" tags, which contain the text "Link" inbetween. This, and
     having the URLs at the end of the text, ensure proper markup
     and prevent underline-bleed. If underline bleed occurs, it's 
     likely a markup issue and the formatting parameters need to be
     changed. Good luck with that.

ENVIRONMENT
     TITLE_CHANNEL  If set, will change the default channel title
     		    of "Custom Generated Twitter RSS Feed"

     TITLE_ITEM	    If set, will change the default item title,
     		    instead of the time it was generated

     ID_CHANNEL	    If set, will change the default channel id of
     		    "tag:custom.generated.twitter.rss:/en//1</id>"

     BLANK_TEXT	    If set, will change the text outputed by 
     		    tweets without text. Default: "[No Text]"
		    Warning: Setting to empty will break format

     LINK_TEXT	    If set, will change the text of links from
     		    the default of "Link."
		    Warning: Setting to empty will break format

     DEBUG_MODE	    If set to anything besides 0, will suppress all 
     		    error exits. Useful for mapping out cross-environment 
		    incompatabilities

     CONFIRM	    If 0, always prompts before writing to output. If 1,
     		    skips.

     CONFIG_PATH    If set, overrides default .newsboat/url path   

EXIT STATUS
     The twitterAtom.sh script exits 0 on success, and 1 if any non-
     formatting errors occur. 

EXAMPLES
     To generate an Atom file for "@somebody1," "@somebody_2000," and 
     "@1some_body23":
     
	  $ ./twitterAtom.sh somebody1 somebody_2000 1somebody23

     To generate an Atom file for "@somebody," piped to "twitter.xml":

     	  $ ./twitterAtom.sh somebody > twitter.xml

     To use an input, handles.if, and output, output.of, file:

     	  $ ./twitterAtom.sh -i handles.if -o output.of

     To set no-text tweets to display "AAAAAAAAAAAAH," and use handle @bob

     	  $ LINK_TEXT="AAAAAAAAAAAAH" ./twitterAtom.sh bob

CAVEATS
     This utility is extremely unstable owing to Twitter's slaphappy 
     abuse of HTML as nothing more than a foundation for divs. As
     well as the natural instability of the web and the erratic web
     developers that guard it from the javascript-unenlightened. 
     Expect to see HTML markup in your feed. Expect to see no feed
     at all. 

AUTHOR
     Gaddox
           
                               February 10, 2018                               
EOF

exit 0
}

main () {

    local TEMPDIR=$(generate_temporary_directory);
    local RAW_PAGE=$(mktemp "$TEMPDIR/TEMPRAWPAGE.XXXXXXX");
    local PAGE=$(mktemp "$TEMPDIR/TEMPPAGE.XXXXXXX");
    local PAGE2=$(mktemp "$TEMPDIR/TEMPPAGE2.XXXXXXX");
    local PAGE3=$(mktemp "$TEMPDIR/TEMPFORMATTEDPAGE.XXXXXXX");

    process_arguments;
    generate_twitter_links;
    download_page;
    format_page;
    extract_to_sort;
    sort_extracted;
    format_headers;
    replace_sorted;
    output_xml;
    exit 0;
}

main;

