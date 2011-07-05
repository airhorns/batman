#
# batman.jquery.coffee
# batman.js
# 
# Created by Nicholas Small
# Copyright 2011, JadedPixel Technologies, Inc.
#

# Include this file if you plan to use batman
# with node.js.

url = require 'url'
querystring = require 'querystring'

applyImplementation = (onto) ->
  onto.Request::send = (data) ->
    
    requestURL = url.parse(@get 'url', true)
    protocol = requestURL.protocol
    # Figure out which module to use
    requestModule = switch protocol
      when 'http:', 'https:'
        require protocol.slice(0,-1)
      else
        throw "Unrecognized request protocol #{protocol}"

    path = requestURL.pathname
    
    if @get('method') is 'GET'
      path += querystring.stringify onto.extend({}, requestURL.query, @get 'data')

    # Make the request and grab the ClientRequest object
    options = 
      path: path
      method: @get 'method'
      port: requestURL.port
      host: requestURL.hostname      

    request = requestModule.request options, (response) =>
      
      # Buffer all the chunks of data into an array
      data = []
      response.on 'data', (d) ->
        data.push d

      response.on 'end', () =>
        # Join the array and set it as the response
        data = data.join()
        @set 'response', data
        
        # Dispatch the appropriate event based on the status code
        status = response.statusCode
        if (status >= 200 and status < 300) or status is 304      
          @success data
        else
          @error data
    
    # Set auth if its given
    request.setHeader("Authorization", new Buffer(requestURL.auth).toString('base64')) if requestURL.auth

    if @get 'method' is 'POST'
      request.write JSON.stringify(@get 'data')
    request.end()

    request.on 'error', (e) -> 
      @set 'response', error
      @error error
    
    request

if Batman?
  applyImplementation(Batman)

if global.Batman?
  applyImplementation(global.Batman)

exports.apply = applyImplementation
