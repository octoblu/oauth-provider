/**
 * Copyright 2013-present NightWorld.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
var debug = require('debug')('oauth-provider:auth-code-grant');

var error = require('oauth2-server/lib/error'),
  runner = require('oauth2-server/lib/runner'),
  token = require('oauth2-server/lib/token'),
  url  = require('url'),
  querystring = require('querystring'),
  _ = require('lodash');

module.exports = AuthCodeGrant;

/**
 * This is the function order used by the runner
 *
 * @type {Array}
 */
var fns = [
  checkParams,
  checkClient,
  checkUserApproved,
  generateCode,
  saveAuthCode,
  redirect
];

/**
 * AuthCodeGrant
 *
 * @param {Object}   config Instance of OAuth object
 * @param {Object}   req
 * @param {Object}   res
 * @param {Function} next
 */
function AuthCodeGrant(config, req, res, next, check) {
  this.config = config;
  this.model = config.model;
  this.req = req;
  this.res = res;
  this.check = check;

  var self = this;
  runner(fns, this, function (err) {
    if (err && res.oauthRedirect) {
      // Custom redirect error handler
      res.redirect(self.client.redirectUri + '?error=' + err.error +
        '&error_description=' + err.error_description + '&code=' + err.code);

      return self.config.continueAfterResponse ? next() : null;
    }

    next(err);
  });
}

/**
 * Check Request Params
 *
 * @param  {Function} done
 * @this   OAuth
 */
function checkParams (done) {
  var body = this.req.body;
  var query = this.req.query;
  if (!body && !query) return done(error('invalid_request'));

  // Response type
  this.responseType = body.response_type || query.response_type;
  if (this.responseType !== 'token') {
    return done(error('invalid_request',
      'Invalid response_type parameter (must be "token")'));
  }

  // Client
  this.clientId = body.client_id || query.client_id;
  if (!this.clientId) {
    return done(error('invalid_request',
      'Invalid or missing client_id parameter'));
  }

  // Redirect URI
  this.redirectUri = body.redirect_uri || query.redirect_uri;
  if (!this.redirectUri) {
    return done(error('invalid_request',
      'Invalid or missing redirect_uri parameter'));
  }

  done();
}

/**
 * Check client against model
 *
 * @param  {Function} done
 * @this   OAuth
 */
function checkClient (done) {
  var self = this;
  var redirectUris;

  this.model.getClient(this.clientId, null, function (err, client) {
    debug('got client', client);
    if (err) return done(error('server_error', false, err));

    if (!client) {
      return done(error('invalid_client', 'Invalid client credentials'));
    }

    redirectUris = client.redirectUri;

    if (!Array.isArray(redirectUris)) {
      redirectUris = [redirectUris];
    }

    redirectUris.forEach(function(uri){
      if (self.redirectUri.indexOf(uri) === 0) {
        client.redirectUri = self.redirectUri;
      }
    });

    if (client.redirectUri !== self.redirectUri) {
      return done(error('invalid_request', 'redirect_uri does not match'));
    }

    // The request contains valid params so any errors after this point
    // are redirected to the redirect_uri
    self.res.oauthRedirect = true;
    self.client = client;

    done();
  });
}

/**
 * Check client against model
 *
 * @param  {Function} done
 * @this   OAuth
 */
function checkUserApproved (done) {
  var self = this;
  this.check(this.req, function (err, allowed, user) {
    if (err) return done(error('server_error', false, err));

    if (!allowed) {
      return done(error('access_denied',
        'The user denied access to your application'));
    }

    self.user = user;
    done();
  });
}

/**
 * Check client against model
 *
 * @param  {Function} done
 * @this   OAuth
 */
function generateCode (done) {
  var self = this;
  token(this, 'client_credentials', function (err, code) {
    self.authCode = code;
    done(err);
  });
}

/**
 * Check client against model
 *
 * @param  {Function} done
 * @this   OAuth
 */
function saveAuthCode (done) {
  var expires = new Date();
  expires.setSeconds(expires.getSeconds() + this.config.authCodeLifetime);

  this.model.saveAuthCode(this.authCode, this.client.clientId, expires,
      this.user, function (err) {
    if (err) return done(error('server_error', false, err));
    done();
  });
}

/**
 * Check client against model
 *
 * @param  {Function} done
 * @this   OAuth
 */
function redirect (done) {
  var uriObject = url.parse(this.client.redirectUri, true);
  uriObject.query.access_token = this.authCode;
  uriObject.query.token_type = 'bearer';
  debug('redirecting (req.query.state)', this.req.query.state);
  if (this.req.query.state){
    uriObject.query.state = this.req.query.state;
  }
  uriObject.hash = querystring.stringify(uriObject.query);
  var uri = url.format(_.pick(uriObject, 'protocol', 'hostname', 'port', 'pathname', 'query', 'slashes', 'hash'));
  debug('Redirecting to URI', uri, uriObject);
  this.res.redirect(uri);

  if (this.config.continueAfterResponse)
    return done();
}
