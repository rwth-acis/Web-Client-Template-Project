# CoffeeScript
###
# requires moduleHelper.js
# requires JQuery 2.1.1
# requires http://open-app.googlecode.com/files/openapp.js
# requires http://dbis.rwth-aachen.de/gadgets/iwc/lib/iwc.js
###

@module "i5", ->
  @module "las2peer", ->
    @module "jsAPI", ->
      ###
        Simple manager for inter widget communication
        The callback given in the constructor is executed, whenever an intent is received
      ###
      class @IWCManager
        constructor: (@callback)->
          @iwcClient=new iwc.Client()
          @iwcClient.connect(@callback)
          
        sendIntent: (action,data,global=true)->
          intent = 
            "component": "",
            "data": data,
            "dataType": "text/xml",
            "action": action,
            "categories": ["", ""],
            "flags": ["PUBLISH_GLOBAL" if global],
            "extras": {}
          @publish(intent)    
          
        publish: (intent) ->
          if iwc.util.validateIntent(intent)
            @iwcClient.publish(intent)
