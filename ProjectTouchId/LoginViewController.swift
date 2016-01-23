//
//    LoginViewController.swift
//    ProjectTouchId
//
//    Created by Stephen Turton on 1/16/16.
//    Copyright (c) 2016 Stephen Turton
//
//    The MIT License (MIT)
//
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

import UIKit
import LocalAuthentication

class LoginViewController: UIViewController {

    @IBOutlet weak var userNameText: UITextField!
    
    @IBOutlet weak var passwordText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.userNameText.borderStyle = .RoundedRect
        self.passwordText.borderStyle = .RoundedRect

        self.userNameText.placeholder = "username"
        self.passwordText.placeholder = "password"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if self.canUseTouchId() && self.hasStoredCredentials() {
            loginInWithTouchId()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func loginButtonClicked(sender: UIButton) {

        let username = self.userNameText.text ?? Constants.EmptyString
        let password = self.passwordText.text ?? Constants.EmptyString

        //For the purpose of this example - provide a way to delete
        //the keychain entries to allow for experimenting
        if username == "reset" && password == Constants.EmptyString {
            KeychainWrapper.setString(Constants.EmptyString, forKey:Constants.KeyChainKeys.usernameKey)
            KeychainWrapper.setString(Constants.EmptyString, forKey:Constants.KeyChainKeys.passwordKey)

            return
        }

        self.loginWithCredentials(username, password:password)
    }

    func loginWithCredentials(username: String?, password: String?) {

        let username = username ?? Constants.EmptyString
        let password = password ?? Constants.EmptyString

        if username != Constants.EmptyString && password != Constants.EmptyString {
            self.fakeLogin(username, password:password,

                    onCompletion: {
                        self.dismissViewControllerAnimated(true,completion:nil)
                    },

                    onFailure: {
                        let alert = UIAlertController(title: "Error", message: "Username or password is incorrect.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default,handler: nil))
                        self.presentViewController(alert, animated: true, completion:nil)
                    })
        } else {
            let alert = UIAlertController(title: "Error", message: "A username and password is required.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default,handler: nil))
            presentViewController(alert, animated: true, completion:nil)
        }
    }

    func canUseTouchId() -> Bool {

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        } else {
            print(error?.localizedDescription)
            return false
        }
    }

    func hasStoredCredentials() -> Bool {
        if (KeychainWrapper.hasValueForKey(Constants.KeyChainKeys.usernameKey) &&
                KeychainWrapper.hasValueForKey(Constants.KeyChainKeys.passwordKey)) {
            return true
        } else {
            return false
        }
    }

    func loginInWithTouchId() {

        let context = LAContext()

        context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Log in with Touch ID",
                reply: {

                    (success: Bool, error: NSError?) -> Void in

                    if success {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.loginWithCredentials(KeychainWrapper.stringForKey("username"), password: KeychainWrapper.stringForKey("password"))
                        }
                    } else {

                        if error != nil {

                            switch error!.code {
                                case LAError.AuthenticationFailed.rawValue:
                                    print("Authentication was not successful because the user failed to provide valid credentials.")

                                case LAError.UserCancel.rawValue:
                                    print("Authentication was canceled by the user—for example, the user tapped Cancel in the dialog.")

                                case LAError.UserFallback.rawValue:
                                    print("Authentication was canceled because the user tapped the fallback button (Enter Password).")

                                case LAError.SystemCancel.rawValue:
                                    print("Authentication was canceled by system—for example, if another application came to foreground while the authentication dialog was up.")

                                case LAError.PasscodeNotSet.rawValue:
                                    print("Authentication could not start because the passcode is not set on the device.")

                                case LAError.TouchIDNotAvailable.rawValue:
                                    print("Authentication could not start because Touch ID is not available on the device.")

                                case LAError.TouchIDNotEnrolled.rawValue:
                                    print("Authentication could not start because Touch ID has no enrolled fingers.")

                                default:
                                    print("Authentication failed")
                            }
                        }
                    }
                })

    }

    func fakeLogin(username:String, password: String, onCompletion: () -> (),
               onFailure : () -> ()) {

        SwiftSpinner.show("Logging In ...")

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {

            NSThread.sleepForTimeInterval(3.0)

            dispatch_async(dispatch_get_main_queue()) {

                //As we are faking - calling a backend webservice, set the username and password
                //if current values are empty
                if KeychainWrapper.stringForKey(Constants.KeyChainKeys.usernameKey) == Constants.EmptyString &&
                        KeychainWrapper.stringForKey(Constants.KeyChainKeys.passwordKey) == Constants.EmptyString {
                    KeychainWrapper.setString(username, forKey:Constants.KeyChainKeys.usernameKey)
                    KeychainWrapper.setString(password, forKey:Constants.KeyChainKeys.passwordKey)
                }

                SwiftSpinner.hide()

                if KeychainWrapper.stringForKey(Constants.KeyChainKeys.usernameKey) == username &&
                        KeychainWrapper.stringForKey("password") == password {
                    onCompletion()
                } else {
                    onFailure()
                }
            }
        }
    }
}

extension LoginViewController : UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.isEqual(self.userNameText) {
            self.passwordText.becomeFirstResponder()
        }
        else {
            self.userNameText.becomeFirstResponder()
        }
        return true
    }
}
