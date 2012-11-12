assert = require('assert')
http = require('http')
request = require('supertest')
{MockingServer} = require '../mocking-server'

describe 'MockingServer', ->
  describe 'expectations', ->
    beforeEach ->
      @server = new MockingServer
      @server.setLoggingLevel('OFF')
      @http_server = http.createServer ((req, res) => @server.handleRequest req, res)

    it 'should match method', (done) ->
      @server.expectations = [{method: 'GET'}]
      request(@http_server)
        .get('/foobar')
        .expect(200, done)

    it 'should unmatch method', (done) ->
      @server.expectations = [{method: 'DELETE'}]
      request(@http_server)
        .post('/foobar')
        .expect(503, done)

    it 'should match url', (done) ->
      @server.expectations = [{url: '/foobar'}]
      request(@http_server)
        .get('/foobar')
        .expect(200, done)

    it 'should unmatch url', (done) ->
      @server.expectations = [{url: '/foobarbaz'}]
      request(@http_server)
        .get('/foobar')
        .expect(503, done)

    it 'should match request body', (done) ->
      @server.expectations = [{req_body: 'some_body'}]
      request(@http_server)
        .post('/foobar')
        .send('some_body')
        .expect(200, done)

    it 'should match request body', (done) ->
      @server.expectations = [{req_body: 'some_body'}]
      request(@http_server)
        .post('/foobar')
        .send('another_body')
        .expect(503, done)

    describe 'req_post_params', ->
      it 'should match application/x-www-form-urlencoded', (done) ->
        @server.expectations = [{req_post_params: {foo: 'bar', baz: 'qux'}}]
        request(@http_server)
          .post('/foobar')
          .send('foo=bar')
          .send('baz=qux')
          .expect(200, done)

      it 'should unmatch application/x-www-form-urlencoded', (done) ->
        @server.expectations = [{req_post_params: {foo: 'bar', baz: 'qux'}}]
        request(@http_server)
          .post('/foobar')
          .send('foo=bar')
          .send('baz=another qux')
          .expect(503, done)

      it 'should match multipart/form-data', (done) ->
        @server.expectations = [{req_post_params: {foo: 'bar', baz: 'qux'}}]
        req = request(@http_server)
          .post('/foobar')
        req
          .part()
          .set('Content-Disposition', 'form-data; name="foo"')
          .write('bar')
        req
          .part()
          .set('Content-Disposition', 'form-data; name="baz"')
          .write('qux')
        req
          .expect(200, done)

      it 'should unmatch multipart/form-data', (done) ->
        @server.expectations = [{req_post_params: {foo: 'bar', baz: 'qux'}}]
        req = request(@http_server)
          .post('/foobar')
        req
          .part()
          .set('Content-Disposition', 'form-data; name="foo"')
          .write('bar')
        req
          .part()
          .set('Content-Disposition', 'form-data; name="baz"')
          .write('another qux')
        req
          .expect(503, done)

    it 'should match request headers', (done) ->
      @server.expectations = []
      test = request(@http_server)
        .get('/foobar')
        .set('X-Header', 'value')
      @server.expectations = [{req_headers: {
        'x-header': 'value',
        'connection': 'keep-alive',
        'cookie': ''
        'host': test.serverAddress(@http_server, '').substr 7 # truncate 'http://'
      }}]
      test.expect(200, done)

    it 'should match request headers', (done) ->
      @server.expectations = [{req_headers: {'x-header': 'value'}}]
      request(@http_server)
        .get('/foobar')
        .set('X-Header', 'another value')
        .expect(503, done)
