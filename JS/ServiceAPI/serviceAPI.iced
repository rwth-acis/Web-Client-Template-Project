# CoffeeScript
###
# requires moduleHelper.js
# requires JQuery 2.1.1
# requires b64.js
###


@module "i5", ->
  @module "las2peer", ->
    @module "jsAPI", ->
      ###
        Enum for various supportet login types.
        For now only BASIC Auth is supported.
      ###
      LoginTypes =
        NONE: 0 
        HTTP_BASIC: 1
      
      @LoginTypes = LoginTypes # make it public
      
      ###
        Login class manages login related tasks, e.g. base64 encoding etc.
      ###
      class @Login
        constructor: (@loginType) ->
        setUserAndPassword: (@user, @password) ->
        getBasicAuthLogin: () ->
          B64.encode(@user+":"+@password)
      
      ###
        Simple class for request objects.
      ###
      class @Request
        constructor: (@method, @uri, @content, @callback, @errorCallback) ->
          if not errorCallback?
            errorCallback = -> 
      ###
        Provides an easy way to send ajax requests.
      ###
      class @RequestSender
        ###
          Constructor takes a uri to the service and a login object to manage logins automatically.
          Additionally an ajax object can be given as a parameter to override default some values.
        ###
        constructor: (@baseURI, login, newBaseAjaxObj) ->
          basic = LoginTypes
          @baseAjaxObj  =
            contentType: "text/plain"
            crossDomain: true
            beforeSend: (xhr) ->
              if login.loginType is LoginTypes.HTTP_BASIC
                xhr.setRequestHeader("Authorization", "Basic " + login.getBasicAuthLogin())
            
                
          if newBaseAjaxObj?
            $.extend(true, @baseAjaxObj, newBaseAjaxObj)
        
         
         
        ###
          Sends a request to the given uri with the given method and content data.
          Two callbacks can be passed (the first for a successfull response, the second for error notification).
          The errorCallback is optional.
        ###
        sendRequest: (method,URI,content,callback,errorCallback)->
          requestURI = encodeURI(@baseURI+"/"+URI);
          
          newAjax =
            url: requestURI
            method: method.toUpperCase()
            data: content
            error: (xhr, errorType, error) ->
              errorText = error
              if xhr.responseText? and xhr.responseText.trim().length > 0
                errorText = xhr.responseText
              if xhr.status is 0
                errorText = "WebConnector does not respond"
              if errorCallback?
                errorCallback(xhr.status + " " + method + " " + requestURI + "\n" + errorText)
            success: (data, status, xhr) ->
              callback(xhr.responseText)
          $.extend(true, newAjax, @baseAjaxObj)          
          $.ajax(newAjax)
        
        ###
          This is a helper method for iced coffescript, which only supports one callback for deferrals.
          It combines both callbacks of sendRequest into one
        ###
        sendRequestCombined: (method,URI,content,callback) ->
          combined = {}
          @sendRequest method,URI,content, (data) ->
            combined.success = true
            combined.data = data
            callback combined
          , (error) ->
            combined.success = false
            combined.data = error
            callback combined
        
        ###
          Wrapper method to use sendRequest with a Request object.
        ###
        sendRequestObj: (requestObj) ->
          @sendRequest(requestObj.method, requestObj.uri, requestObj.content, requestObj.callback, requestObj.errorCallback)
  
  
        ###
          Sends requests in a given array synchronously (order is maintained, usefull if operations depend on each other's completion).
          When all requests are finished callback is called.
        ###
        sendRequestsSync: (requestObjArray, callback) ->
          for k,i in requestObjArray
           
            await @sendRequestCombined k.method, k.uri, k.content, defer(combined)
            
            if combined.success
              k.callback combined.data
            else if k.errorCallback?
              k.errorCallback combined.data
          callback()
          
            
        ###
          Sends requests in a given array asynchronously (order is arbitrary).
          When all requests are finished callback is called.
        ###
        sendRequestsAsync: (requestObjArray, callback) ->
          combined = []
          await
            for k,i in requestObjArray
              @sendRequestCombined k.method, k.uri, k.content, defer combined[i]
          
          for k,i in combined
            if k.success
              requestObjArray[i].callback(k.data)
            else if requestObjArray[i].errorCallback?
              requestObjArray[i].errorCallback(k.data)
          callback()
