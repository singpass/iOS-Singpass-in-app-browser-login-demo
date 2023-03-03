# Migrating away from [WebView](https://developer.apple.com/documentation/webkit/wkwebview) for iOS Mobile app Singpass Logins

Usage of WebViews for web logins are not recommended due to security and usability reasons documented in [RFC8252](https://www.rfc-editor.org/rfc/rfc8252). Google has done the [same](https://developers.googleblog.com/2021/06/upcoming-security-changes-to-googles-oauth-2.0-authorization-endpoint.html) for Google Sign-in in 2021.

> This best current practice requires that only external user-agents
like the browser are used for OAuth by native apps.  It documents how
native apps can implement authorization flows using the browser as
the preferred external user-agent as well as the requirements for
authorization servers to support such usage.

*Quoted from RFC8252.*

This repository has codes for a sample iOS application implementing the recommended [Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636) for Singpass logins. The application will demonstrate the Singpass login flow with PKCE leveraging on the iOS [AppAuth](https://github.com/openid/AppAuth-iOS) library.

# Sequence Diagram
![Sequence Diagram](pkce_sequence_diagram.png)

<br>

*RP stands for **Relying Party**

- 1a) Call **RP Backend** to obtain backend generate `code_challenge`, `code_challenge_method` along with `state` and `nonce` if required. #
<br><br>
- 1b) **RP Backend** responds with the requested parameters. (`code_challenge`, `code_challenge_method`, `state`, `nonce`) #
  <br><br>
- 2a) Open the Authorization endpoint in web browser via [AppAuth](https://github.com/openid/AppAuth-iOS) providing query params of `redirect_uri`*, `client_id`, `scope`, `code_challenge`, `code_challenge_method` along with `state` and `nonce` if required. There can be other query params provided if needed. e.g. (`purpose_id` for myInfo use cases)
  <br><br>
- 2b) The `authorization code` will be delivered back to **RP Mobile App**.
<br><br>
- 3a) **RP Mobile App** Upon reception of `authorization code`, proceed to relay the Authorization code back to **RP Backend**. #
  <br><br>
- 3b) **RP Backend** will use the `authorization code` along with the generated `code_verifier` along with `state` and `nonce` if required, and do client assertion to call the token endpoint to obtain ID/access tokens.
<br><br>
- 3c) Token endpoint responds with the token payload to **RP Backend**.
  <br><br>
- 3d) **RP Backend** process the token payload and does its required operations and responds to **RP Mobile App** with the appropriate session state tokens or data. #
  <br><br>

&#8203;* - Take note that the `redirect_uri` should be a non-https url that represents the app link of the **RP Mobile App** as configured in the [AppAuth](https://github.com/openid/AppAuth-iOS) library.

&#8203;# - It is up to the RP to secure the connection between **RP Mobile App** and **RP Backend**

# Potential changes/enhancements for RP Backend
1. Implement endpoint to serve `code_challenge`, `code_challenge_method`, `state`, `nonce` and other parameters needed for **RP Mobile App** to initiate the login flow.
   <br><br>
2. Implement endpoint in receive `authorization code`, `state` and other required parameters.

# Potential changes/enhancements for RP Mobile App
1. Integrate [AppAuth](https://github.com/openid/AppAuth-iOS) library to handle launching of authorization endpoint webpage in an in app browser.
   <br><br>
2. Implement api call to **RP Backend** to request for `code_challenge`, `code_challenge_method`, `state` and `nonce` if required and other parameters.
   <br><br>
3. Implement api call to send `authorization code`, `state` and other needed parameters back to **RP Backend**.

# Other Notes
- Please use the query param `app_launch_url` when opening the authorization endpoint webpage for iOS to enable Singpass App to return to RP mobile app automatically.
  <br><br>
- Recommended to **NOT** use `redirect_uri` with a `https` scheme e.g. https://rp.redirectUri/callback due to potential UX issues when redirecting back to **RP Mobile App** from the external web browser. Use iOS URL scheme instead as the redirect_uri. e.g. sg.gov.singpass.app://ndisample.gov.sg/rp/sample
  <br><br>
- The sample mobile appplication code in this repository receives the token endpoint response from the RP Backend, RPs should **NOT** do this, **RP Backend** should the token response and do your appropriate processing.

# Implementation Details

## Required dependencies

AppAuth iOS Library
> pod 'AppAuth'

## Implementation

### In the ViewController

Set the necessary endpoints such as the `redirect_uri` and service configuration endpoints `issuer`, `authorizationEndpoint` and `tokenEndpoint`. 
```swift
let kRedirectURI: String = "sg.gov.singpass.app://ndisample.gov.sg/rp/sample"
let serviceConfigEndpoints: [String: String] = [
    "issuer": "https://test.api.myinfo.gov.sg",
    "authorizationEndpoint": "https://test.api.myinfo.gov.sg/com/v4/authorize",
    "tokenEndpoint": "https://test.api.myinfo.gov.sg/com/v4/token"
]
```
<br>

### 

The below code snippets OAuth authorization flow with [AppAuth](https://github.com/openid/AppAuth-iOS)

<br>

Create the Oauth service configuration
```swift
  // This is the dictionary that describes the current Oauth service
  // This example is using the test environment for MyInfo Singpass login 
  let configuration = OIDServiceConfiguration(authorizationEndpoint: authURL, tokenEndpoint: tokenURL, issuer: issuerURL)
```
<br>

Create the OAuth authorization request
```swift
// code_challenge and code_challenge_method generated from RP Backend
// Set code_challenge for code_verifier as AppAuth library
// Set code_verifier as nil
// as we are not calling token endpoint from the mobile app  

var request: OIDAuthorizationRequest {
    var dict: [String: String] = [appLaunchURL: appLinkURL]

    if myInfo {
        // MyInfo Singpass login does not need nonce and state
        // It needs purpose_id and has different scope values
        dict["purpose_id"] = "demonstration"

        return OIDAuthorizationRequest(configuration: configuration, // from the above section
                                        clientId: clientID, // RP client_id
                                        clientSecret: nil,
                                        scope: "name", // myinfo_scope
                                        redirectURL: redirectURI, // redirect_uri
                                        responseType: OIDResponseTypeCode, // code
                                        state: nil,
                                        nonce: nil,
                                        codeVerifier: nil,
                                        codeChallenge: codeChallenge,
                                        codeChallengeMethod: codeChallengeMethod,
                                        additionalParameters: dict)
    } else {
        return OIDAuthorizationRequest(configuration: configuration, // from the above section
                                        clientId: clientID, // RP client_id
                                        clientSecret: nil,
                                        scope: OIDScopeOpenID, // scope: openid
                                        redirectURL: redirectURI, // redirect_uri
                                        responseType: OIDResponseTypeCode,  // code
                                        state: state, // state generated from RP Backend
                                        nonce: nonce, // nonce generated from RP Backend
                                        codeVerifier: nil,
                                        codeChallenge: codeChallenge,
                                        codeChallengeMethod: codeChallengeMethod,
                                        additionalParameters: dict)
    }
}
```
<br>

Create the OAuth authorization service to perform authorization code exchange.
Upon reception of authorization code, proceed to relay the Authorization code back to the RP backend.
```swift
OIDAuthorizationService.present(request, presenting: self) { (response, error) in
    
    if let response = response {
        let authState = OIDAuthState(authorizationResponse: response)
        self.setAuthState(authState)
        
        printd("Authorization response with code: \(response.authorizationCode ?? "DEFAULT_CODE")")
        
        self.sampleView.setAuthCode(response.authorizationCode)
        
        if self.myInfo {
            self.postAuthCode()
        } else {
            self.postAuthCode(nonce: request.nonce, state: request.state)
        }
    } else {
        printd("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
    }
}
```
<br>

## Demo Video/s

| MyInfo Mockpass Demo                                                 |
|------------------------------------------------------------------------------------------------------------------|
| <img src="myinfo_pkce.gif" alt="Myinfo Mockpass flow video" width="300px" height="600px"></img> |