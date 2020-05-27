// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

func processData(_ data: Data?, storeReply: Bool = false) {
    if let data = data, let parsed = try? JSONSerialization.jsonObject(with: data, options: []), let dict = parsed as? JSONDictionary {
        processResponse(dict)
        
        if storeReply, let formatted = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("reply.json")
            try? formatted.write(to: url)
        }
    }
}

extension JSONDictionary {
    func nodes(named name: String) -> [JSONDictionary] {
        if let base = self[name] as? JSONDictionary, let nodes = base["nodes"] as? [JSONDictionary] {
            return nodes
        }
        
        return []
    }
}

func processRepos(_ repos: [JSONDictionary], for name: String) {
    print("\n\(name)")
    for repo in repos {
        if let name = repo["name"] as? String {
            print("- \(name)")
        }
    }
}
func processResponse(_ parsed: JSONDictionary) {
    if let data = parsed["data"] as? JSONDictionary, let viewer = data["viewer"] as? JSONDictionary {
        let repos = viewer.nodes(named: "repositories")
        processRepos(repos, for: "samdeane")
        
        let organisations = viewer.nodes(named: "organizations")
        for org in organisations {
            if let login = org["login"] as? String {
                if login == "elegantchaos" {
                    let repos = org.nodes(named: "repositories")
                    processRepos(repos, for: "elegantchaos")
                }
            }
        }
    }
}

func fakeRequest() {
    let json = #"{"data":{"viewer":{"organizations":{"nodes":[{"login":"elegantchaos","repositories":{"nodes":[{"name":"ECTouch"},{"name":"ECTwitter"},{"name":"ECHelper"},{"name":"ECInjection"},{"name":"ECUnitTests"},{"name":"ECCore"},{"name":"ECLogging"},{"name":"ECText"},{"name":"ECUnitTestsExample"},{"name":"ECConfig"},{"name":"ECLoggingExamples"},{"name":"ECIntegration"},{"name":"ECNetwork"},{"name":"ECAnalytics"},{"name":"ECAppKit"},{"name":"ECLocation"},{"name":"ECAquaticPrime"},{"name":"ECSparklePreferencesPane"},{"name":"ECOAuthConsumer"},{"name":"ECTwitterIntegration"},{"name":"ECRegexKitLite"},{"name":"ECAppNet"},{"name":"ECPreferencesWindow"},{"name":"ECPreferencesWindowExample"},{"name":"ECGL"},{"name":"ECLoggingShim"},{"name":"ECSecurity"},{"name":"ECEmptyLibraryTemplate"},{"name":"ECCommandLine"},{"name":"ECCommandLineTest"},{"name":"SwiftLogging"},{"name":"atom-elegantchaos-syntax-theme"},{"name":"Logger"},{"name":"plantation-syntax"},{"name":"DictionaryCoding"},{"name":"Builder"},{"name":"BuilderToolExample"},{"name":"BuilderBasicConfigure"},{"name":"docopt.swift"},{"name":"BuilderConfiguration"},{"name":"BuilderExample"},{"name":"JSBlock"},{"name":"iOSDevDirectory"},{"name":"BuilderBundler"},{"name":"BuilderExampleApp"},{"name":"atom-autocomplete-swift-sourcekitten"},{"name":"atom-swift-debugger"},{"name":"atom-macros"},{"name":"atom-ide-swift"},{"name":"Arguments"},{"name":"XPkg"},{"name":"shell-hooks"},{"name":"CSkia"},{"name":"Actions"},{"name":"SketchX"},{"name":"Runner"},{"name":"BookishModel"},{"name":"JSONDump"},{"name":"Coverage"},{"name":"ensembles-next"},{"name":"Bookish"},{"name":"Sparkle"},{"name":"ReleaseTools"},{"name":"CommandShell"},{"name":"Expressions"},{"name":"BookishCore"},{"name":"xpkg-homebrew"},{"name":"XPkgPackage"},{"name":"Localization"},{"name":"ActionsKit"},{"name":"EmbeddableTableView"},{"name":"TokenView"},{"name":"Datastore"},{"name":"XCTestExtensions"},{"name":"SwiftPMLibrary"},{"name":"DatastoreViewer"},{"name":"LayoutExtensions"},{"name":"ViewExtensions"},{"name":"ApplicationExtensions"},{"name":"IndexDetailViewController"},{"name":"slatify"},{"name":"Performance"},{"name":"CollectionExtensions"},{"name":"ActionStatus"},{"name":"SwiftUIExtensions"},{"name":"BindingsExtensions"},{"name":"CatalystSparkleExample"},{"name":"CatalystSparkle"},{"name":"SwiftUI-Introspect"},{"name":"ActionStatusCore"},{"name":"Hardware"},{"name":"Files"},{"name":"ToggleDisplayModes"},{"name":"Displays"},{"name":"swift-argument-parser"},{"name":"ISBN"},{"name":"BookishScanner"},{"name":"SemanticVersion"},{"name":"Bundles"},{"name":"Images"}]}},{"login":"nucleobytes","repositories":{"nodes":[{"name":"NBFoundation"},{"name":"SwiftHEXColors"}]}},{"login":"mentalfaculty","repositories":{"nodes":[{"name":"ensembles-next"},{"name":"Specs"},{"name":"SSZipArchive"},{"name":"Sparkle"},{"name":"ACEDrawingView"},{"name":"Anomalii"},{"name":"SwiftPMLibrary"},{"name":"blog"},{"name":"LLVS"}]}},{"login":"github-beta","repositories":{"nodes":[{"name":"github-desktop"},{"name":"unity-preview"}]}},{"login":"MomentaBV","repositories":{"nodes":[{"name":"Agenda"},{"name":"AgendaFoundation"},{"name":"CwlUtils"},{"name":"ZipArchive"},{"name":"GzipSwift"},{"name":"Dwifft"},{"name":"ZipZap"},{"name":"discount"},{"name":"Sparkle"},{"name":"LicenseServer"},{"name":"pusher-websocket-swift"},{"name":"Website"},{"name":"Materials"},{"name":"SideMenu"},{"name":"Kitura-CredentialsHTTP"},{"name":"SwiftyDropbox"},{"name":"Alamofire"}]}},{"login":"Safari-FIDO-U2F","repositories":{"nodes":[{"name":"Safari-FIDO-U2F"}]}},{"login":"notthestornowaytrust","repositories":{"nodes":[{"name":"notthestornowaytrust.github.io"}]}}]},"repositories":{"nodes":[{"name":"django-test"},{"name":"drupal-poster"},{"name":"dylan-xcode"},{"name":"linden"},{"name":"sketch-client"},{"name":"elegantchaos-top-level"},{"name":"sketcheroids"},{"name":"ecbless"},{"name":"ecdungeon"},{"name":"ecfoundation"},{"name":"ecmaps"},{"name":"ecpdf"},{"name":"environment-editor"},{"name":"feed-me"},{"name":"houston"},{"name":"ici"},{"name":"rotate-view"},{"name":"langserver-swift"},{"name":"Safari-FIDO-U2F"},{"name":"enjoyable"},{"name":"EliteSettings"},{"name":"EliteJournals"},{"name":"samdeane.github.io.old"},{"name":"so-simple-theme"},{"name":"carolinebrick.co.uk"},{"name":"network-manager"},{"name":"lanntair"},{"name":"archiver"},{"name":"Logger"},{"name":"neu"},{"name":"diagonal"},{"name":"escape"},{"name":"timekeeper"},{"name":"project-bob-client"},{"name":"project-bob-server"},{"name":"now-playing"},{"name":"notable"},{"name":"remote-player"},{"name":"samantha"},{"name":"slow-fade"},{"name":"twick"},{"name":"xcode-builder"},{"name":"dmg-limitation"},{"name":"Builder"},{"name":"UniversalBlock"},{"name":"Problem"},{"name":"notthestornowaytrust.github.io"},{"name":"xpkg-conky"},{"name":"xpkg-atom"},{"name":"xpkg-appledoc"},{"name":"xpkg-vim"},{"name":"xpkg-shell"},{"name":"xpkg-git"},{"name":"xpkg-swift"},{"name":"samdeane.github.io"},{"name":"Tuple"},{"name":"xpkg-xcode"},{"name":"xpkg-keyboard"},{"name":"xpkg-mouse"},{"name":"SkiaExperiments"},{"name":"downloads.elegantchaos.com"},{"name":"old.elegantchaos.com"},{"name":"sparkle.elegantchaos.com"},{"name":"xpkg-terminal"},{"name":"xpkg-coding-fonts"},{"name":"Bookish"},{"name":"xpkg-travis"},{"name":"gilliancook.com"},{"name":"xpkg-tabtab"},{"name":"ensembles2"},{"name":"amos-bash"},{"name":"SwiftHelloWorld"},{"name":"raspberry-pi-resin"},{"name":"Mac-admin-Scripts"},{"name":"bookish.elegantchaos.com"},{"name":"BookishCore"},{"name":"SPMIntegrationTest2"},{"name":"SPM-Integration-Tests"},{"name":"xpkg-homebrew"},{"name":"hackintosh-clover-config"},{"name":"XPkgPackage"},{"name":"SPMIntegrationTest3"},{"name":"Localization"},{"name":"ActionsKit"},{"name":"EmbeddableTableView"},{"name":"TokenView"},{"name":"TokenView"},{"name":"SkyrimScripts"},{"name":"skyrim-settings"},{"name":"Datastore"},{"name":"XCTestExtensions"},{"name":"smalls-support"},{"name":"Python"},{"name":"Unix-Linux"},{"name":"Ember"},{"name":"actionstatus.elegantchaos.com"},{"name":"Shared-Coding-Projects"},{"name":"neu-archive"},{"name":"xpkg-fish"},{"name":"github-api-test"}]}}}}"#
    processData(json.data(using: .utf8))
}

func makeRequest(token: String) {
    if let endpoint = URL(string: "https://api.github.com/graphql") {
        let authorization = "bearer \(token)"
        let query = """
            {
                viewer {
                    organizations(first: 10) {
                        nodes {
                            login
                            repositories(first: 100, orderBy: { direction: DESC, field: PUSHED_AT } ) {
                                nodes {
                                    name
                                }
                            }
                        }
                    }

                    repositories(first: 100, orderBy: { direction: DESC, field: PUSHED_AT } ) {
                        nodes {
                            name
                        }
                    }
                }
            }
            """
        
        let escaped = query.replacingOccurrences(of: "\n", with: " ")
        let json = """
        {
        "query": "query \(escaped)"
        }
        """
        
        var request = URLRequest(url: endpoint)
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = json.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error)
            }
            
            if let response = response {
                print(response)
            }
            
            processData(data)
        }
        
        task.resume()
    }
}
