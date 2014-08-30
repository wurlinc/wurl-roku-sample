# Wurl Index Example

The *Wurl Index Example* app is a repurposing of the
Roku videoplayer example that uses the Wurl Index
_JSON_ to provide and play back content.

To build it, first go to the file `source/appMain.brs`
and edit it to add your Wurl AppId and Secret:

````
  m.Wurl = CreateObject("roAssociativeArray")
  m.Wurl.AppId     = "YOUR_APP_ID"
  m.Wurl.AppSecret = "YOUR_APP_SECRET"
````

Then simply run make and install the resulting
Zip file into your Roku application.

The Roku videoplayer example demonstrates a hierarchical,
category based video playback application. You can find
the original example under a 'videoplayer' folder in the
examples of your Roku SDK.

Contents of the application directories are:

images   - Artwork that is embedded as part of 
           the application. In general, this 
           should be kept to a minimum to conserve 
           space on flash, and is usually just the 
           main menu icons, plus the logo and 
           overhang used for branding.
source   - The complete BrightScript source code 
           for the application
manifest - This file describes the application 
           package and is used on the main menu 
           prior to the start of execution for the 
           application.
Makefile - Optional method of building the application
           using "make". This has been provided for
           convenience and tested on OSX and linux.


Note: For information on the syntax of the JSON responses,
see the [Wurl API Reference](http://developers.wurl.com/pages/reference)

      **************************************************

The original videoplayer sample, as well as this code, uses the
following license:

http://creativecommons.org/licenses/by-nc-nd/3.0/


