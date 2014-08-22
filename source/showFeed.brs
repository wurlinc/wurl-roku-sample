'**********************************************************
'**  Video Player Example Application - Show Feed 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'******************************************************
'** Set up the show feed connection object
'** This feed provides the detailed list of shows for
'** each subcategory (categoryLeaf) in the category
'** category feed. Given a category leaf node for the
'** desired show list, we'll hit the url and get the
'** results.     
'******************************************************

Function InitShowFeedConnection(category As Object) As Object

    if validateParam(category, "roAssociativeArray", "initShowFeedConnection") = false return invalid 

    conn = CreateObject("roAssociativeArray")
    conn.UrlShowFeed  = category.feed
    conn.UrlShowFeed = conn.UrlShowFeed + "?format=json"
    conn.UrlShowFeed = conn.UrlShowFeed + "&appid="  + m.Wurl.AppId
    conn.UrlShowFeed = conn.UrlShowFeed + "&secret=" + m.Wurl.AppSecret

    conn.Timer = CreateObject("roTimespan")

    conn.LoadShowFeed    = load_show_feed
    conn.ParseShowFeed   = parse_show_feed
    conn.InitFeedItem    = init_show_feed_item

    print "created feed connection for " + conn.UrlShowFeed
    return conn

End Function


'******************************************************
'Initialize a new feed object
'******************************************************
Function newShowFeed() As Object

    o = CreateObject("roArray", 100, true)
    return o

End Function


'***********************************************************
' Initialize a ShowFeedItem. This sets the default values
' for everything.  The data in the actual feed is sometimes
' sparse, so these will be the default values unless they
' are overridden while parsing the actual game data
'***********************************************************
Function init_show_feed_item() As Object
    o = CreateObject("roAssociativeArray")

    o.ContentId        = ""
    o.Title            = ""
    o.ContentType      = ""
    o.ContentQuality   = ""
    o.Synopsis         = ""
    o.Genre            = ""
    o.Runtime          = ""
    o.StreamQualities  = CreateObject("roArray", 5, true) 
    o.StreamBitrates   = CreateObject("roArray", 5, true)
    o.StreamUrls       = CreateObject("roArray", 5, true)

    return o
End Function


'*************************************************************
'** Grab and load a show detail feed. The url we are fetching 
'** is specified as part of the category provided during 
'** initialization. This feed provides a list of all shows
'** with details for the given category feed.
'*********************************************************
Function load_show_feed(conn As Object) As Dynamic

    if validateParam(conn, "roAssociativeArray", "load_show_feed") = false return invalid 

    print "url: " + conn.UrlShowFeed
    http = NewHttp(conn.UrlShowFeed)

    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    print "Request Time: " + itostr(m.Timer.TotalMilliseconds())

    feed = newShowFeed()
    json = ParseJSON(rsp)

    m.Timer.Mark()
    if json = invalid then
      print "Invalid JSON response"
      return invalid
    endif
    m.ParseShowFeed(json, feed)
    print "Show Feed Parse Took : " + itostr(m.Timer.TotalMilliseconds())

    return feed

End Function


'**************************************************************************
'**************************************************************************
Function parse_show_feed(json As Object, feed As Object) As Void

    showCount = 0
    for each episode in json.entities
    if episode.properties <> invalid and is_entity_of_class(episode, "wurl-episode") and episode.properties.playback <> invalid
        item = init_show_feed_item()
        'fetch all values from the xml for the current show
        item.hdImg            = episode.properties.thumbnails.default.url
        item.sdImg            = episode.properties.thumbnails.default.url
        'item.ContentId        = validstr(curShow.contentId.GetText()) 
        item.Title            = episode.properties.title
        item.Description      = episode.properties.description
        'item.ContentType      = validstr(curShow.contentType.GetText())
        'item.ContentQuality   = validstr(curShow.contentQuality.GetText())
        'item.Synopsis         = validstr(curShow.synopsis.GetText())
        'item.Genre            = validstr(curShow.genres.GetText())
        'item.Runtime          = validstr(curShow.runtime.GetText())
        'item.HDBifUrl         = validstr(curShow.hdBifUrl.GetText())
        'item.SDBifUrl         = validstr(curShow.sdBifUrl.GetText())
        'item.StreamFormat = validstr(curShow.streamFormat.GetText())
        'if item.StreamFormat = "" then  'set default streamFormat to mp4 if doesn't exist in xml
            'item.StreamFormat = "mp4"
        'endif

        'map xml attributes into screen specific variables
        item.ShortDescriptionLine1 = item.Title 
        item.ShortDescriptionLine2 = item.Description
        item.HDPosterUrl           = item.hdImg
        item.SDPosterUrl           = item.sdImg

        'item.Length = strtoi(item.Runtime)
        'item.Categories = CreateObject("roArray", 5, true)
        'item.Categories.Push(item.Genre)
        'item.Actors = CreateObject("roArray", 5, true)
        'item.Actors.Push(item.Genre)
        'item.Description = item.Synopsis

        'Set Default screen values for items not in feed
        item.HDBranded = false
        item.IsHD = false
        item.StarRating = "90"
        item.ContentType = "episode" 
        print episode.properties.playback[0]
        for each playback in episode.properties.playback
          if playback.mediaUrl <> invalid then
            ' TODO Get this out of playback entry
            item.StreamFormat = "mp4"
            item.StreamBitrates.Push(2000)
            item.StreamQualities.Push(false)
            item.StreamUrls.Push(playback.mediaUrl)
          endif

        next
        showCount = showCount + 1
        feed.Push(item)
        'skipitem:

    endif
    next

End Function
