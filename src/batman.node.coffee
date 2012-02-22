#
# batman.node.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

# Include this file if you plan to use batman
# with node.js.

url = require 'url'
querystring = require 'querystring'

Batman = require './batman'
(require './extras/batman.rails')(Batman)
(require './extras/batman.i18n')(Batman)

Batman.mixin Batman.Request::,
  getModule: (protocol) ->
    requestModule = switch protocol
      when 'http:', 'https:'
        require protocol.slice(0,-1)
      when undefined
        require 'http'
      else
        throw "Unrecognized request protocol #{protocol}"

  send: (data) ->
    @fire 'loading'
    requestURL = url.parse(@get 'url', true)
    protocol = requestURL.protocol
    # Figure out which module to use
    requestModule = @getModule(protocol)
    path = requestURL.pathname

    if @get('method') is 'GET'
      getParams = @get('data')
      path += '?' if getParams
      path += if typeof getParams is 'string'
        getParams
      else
        querystring.stringify Batman.mixin({}, requestURL.query, getParams)

    # Make the request and grab the ClientRequest object
    options =
      path: path
      method: @get 'method'
      port: requestURL.port
      host: requestURL.hostname
      headers: @get 'headers'

   # Set auth if its given
    auth = if @get 'username'
      "#{@get 'username'}:#{@get 'password'}"
    else if requestURL.auth
      requestURL.auth

    if auth
      options.headers["Authorization"] = "Basic #{new Buffer(auth).toString('base64')}"

    if @get('method') in ["PUT", "POST"]
      options.headers["Content-type"] = @get 'contentType'
      body = @get 'data'
      options.headers["Content-length"] = Buffer.byteLength(body)

    request = requestModule.request options, (response) =>

      # Buffer all the chunks of data into an array
      data = []
      response.on 'data', (d) ->
        data.push d

      response.on 'end', () =>
        # Join the array and set it as the response
        data = data.join('')
        @set 'response', data

        # Dispatch the appropriate event based on the status code
        status = @set 'status', response.statusCode
        if (status >= 200 and status < 300) or status is 304
          @fire 'success', data
        else
          request.request = @
          @fire 'error', request
        @fire 'loaded'

    request.on 'error', (error) =>
      @set 'response', error
      @fire 'error', error
      @fire 'loaded'

    if @get('method') in ['POST', 'PUT']
      request.write body

    request.end()

    request

module.exports = Batman
