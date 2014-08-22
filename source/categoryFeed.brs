'vim: ft=brs
'******************************************************
'**  Video Player Example Application -- Category Feed 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'******************************************************

'******************************************************
' Set up the category feed connection object
' This feed provides details about top level categories 
'******************************************************
Function InitPackageFeedConnection() As Object

    conn = CreateObject("roAssociativeArray")

    'conn.UrlPrefix   = "http://api.wurl.com/api"
    conn.UrlPrefix   = "https://api-wurl-com-yypon3fbasrf.runscope.net/api"
    conn.Url = conn.UrlPrefix + "/packages"
    conn.Url = conn.Url + "?format=json"
    conn.Url = conn.Url + "&appid="  + m.Wurl.AppId
    conn.Url = conn.Url + "&secret=" + m.Wurl.AppSecret

    conn.LoadCategoryFeed    = load_packages
    conn.GetCategoryNames    = get_package_names

    print "created package connection for " + conn.Url
    return conn

End Function

'*********************************************************
'** Create an array of names representing the children
'** for the current list of categories. This is useful
'** for filling in the filter banner with the names of
'** all the categories at the next level in the hierarchy
'*********************************************************
Function get_package_names(categories As Object) As Dynamic

    categoryNames = CreateObject("roArray", 100, true)

    for each category in categories.kids
      'print category.Title
      categoryNames.Push(category.Title)
    next

    return categoryNames

End Function


'******************************************************************
'** Given a connection object for a category feed, fetch,
'** parse and build the tree for the feed.  the results are
'** stored hierarchically with parent/child relationships
'** with a single default node named Root at the root of the tree
'******************************************************************
Function load_packages(conn As Object) As Dynamic

    http = NewHttp(conn.Url)

    Dbg("url: ", http.Http.GetUrl())
    m.Timer = CreateObject("roTimespan")


    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    Dbg("Took: ", m.Timer)
    json_response = ParseJSON(rsp)
    Dbg("Parse Took: ", m.Timer)

    m.Timer.Mark()

    if json_response = invalid then
      print "Invalid response - no Entities"
      return invalid
    endif

    topNode = MakeEmptyCatNode()
    topNode.Title = "root"
    topNode.isapphome = true

    allBundles = CreateObject("roArray", 100, true)
    for each package in json_response.entities
      for each bundle in package.entities
        allBundles.Push(bundle)
      next
    next

    for each entity in allBundles
      'title
      o = ParseJSONCollection(entity)
      if o <> invalid
        topNode.AddKid(o)
        AddPackagesToEntity(conn, o, entity)
      endif
    next

    Dbg("Traversing: ", m.Timer)

    return topNode

End Function

'******************************************************
'MakeEmptyCatNode - use to create top node in the tree
'******************************************************
Function MakeEmptyCatNode() As Object
    return init_category_item()
End Function

Function AddPackagesToEntity(conn, node, entity as Object) As Dynamic
  slug = entity.properties.slug
  print "Adding package: "+slug
  pkgConn = CreateObject("roAssociativeArray")
  pkgConn.Url = conn.UrlPrefix + "/package/" + slug
  pkgConn.Url = pkgConn.Url + "?format=json"
  pkgConn.Url = pkgConn.Url + "&appid="  + m.Wurl.AppId
  pkgConn.Url = pkgConn.Url + "&secret=" + m.Wurl.AppSecret
  entities = entity.entities
  for each subentity in entities
    'title
    o = ParseJSONCollection(subentity)
    node.AddKid(o)
    'load_package_contents(node, pkgConn)
  next
  return invalid
End Function


Function load_package_contents(package_node, conn As Object) As Dynamic

    http = NewHttp(conn.Url)

    Dbg("url: ", http.Http.GetUrl())
    m.Timer = CreateObject("roTimespan")


    m.Timer.Mark()
    rsp = http.GetToStringWithRetry()
    Dbg("Took: ", m.Timer)
    json_response = ParseJSON(rsp)
    Dbg("Parse Took: ", m.Timer)

    m.Timer.Mark()

    if json_response = invalid then
      print "Invalid response - no Entities"
      return invalid
    endif

    return ParseJSONCollection(package_node)



End Function

'***********************************************************
' Parse a Wurl JSON collection based on its rel type.
' Create them as what the Roku App understands as 
' "Category" nodes.
'***********************************************************
Function ParseJSONCollection(entity As Object) As dynamic

    if entity.properties = invalid
      return invalid
    endif

    o = init_category_item()

    print "ParseJSONCollection: " + entity.properties.title

    o.Type  = "normal"
    o.Title = entity.properties.title
    o.Description = entity.properties.title
    o.ShortDescriptionLine1 = entity.properties.title
    o.json_properties = entity.properties

    for each subentity in entity.entities
      ' This will read the wurl-bundles
      if is_entity_of_class(subentity, "wurl-bundle")
        ' These are bundles. We read the whole thing
        o_kid = ParseJSONCollection(subentity)
        o_kid.Description = subentity.properties.description
        if o_kid <> invalid
          o.AddKid(o_kid)
        endif
      endif
      ' This will read the entities with the top series
      if is_entity_of_class(subentity, "wurl-series")
        o_kid = ParseJSONSeries(subentity)
        ' TODO Set the Feed property here to the href
        'print entity.entities[0].properties.topSeries
        if o_kid <> invalid
          o.AddKid(o_kid)
          if o.SDPosterURL = "http://s3.amazonaws.com/wurl-alma/default-app-thumbnail.png"
            o.SDPosterURL = subentity.properties.thumbnails.default.url
            o.HDPosterURL = subentity.properties.thumbnails.default.url
          endif
        endif
      endif
    next

    return o

End Function

Function ParseJSONSeries(entity as Object) as dynamic
  o = init_category_item()
  print "ParseJSONSeries: "+entity.properties.title
  o.Type = "normal"
  o.Title = entity.properties.title
  o.Description = entity.properties.title
  o.ShortDescriptionLine1 = entity.properties.title
  o.Feed = entity.links[0].href+"/episodes" ' The HREF
  return o

End Function


'******************************************************
'Initialize a Category Item
'******************************************************
Function init_category_item() As Object
    o = CreateObject("roAssociativeArray")
    o.Title       = ""
    o.Type        = "normal"
    o.Description = ""
    o.Kids        = CreateObject("roArray", 100, true)
    o.Parent      = invalid
    o.Feed        = ""
    o.IsLeaf      = cn_is_leaf
    o.AddKid      = cn_add_kid
    o.SDPosterURL = "http://s3.amazonaws.com/wurl-alma/default-app-thumbnail.png"
    o.HDPosterURL = "http://s3.amazonaws.com/wurl-alma/default-app-thumbnail.png"
    return o
End Function


'********************************************************
'** Helper function for each node, returns true/false
'** indicating that this node is a leaf node in the tree
'********************************************************
Function cn_is_leaf() As Boolean
    if m.Kids.Count() > 0 return true
    if m.Feed <> "" return false
    return true
End Function


'*********************************************************
'** Helper function for each node in the tree to add a 
'** new node as a child to this node.
'*********************************************************
Sub cn_add_kid(kid As Object)
    if kid = invalid then
        print "skipping: attempt to add invalid kid failed"
        return
     endif

    kid.Parent = m
    m.Kids.Push(kid)
End Sub

Sub is_entity_of_class(entity As Object, expected_class as String) As Boolean
  if entity.class = invalid
    return false
  endif
  for each _class in entity.class
    if _class = expected_class
      return true
    endif
  next
End Sub

