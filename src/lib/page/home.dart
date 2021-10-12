import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterSecureStorage storage = const FlutterSecureStorage();
  final String _clientId = 'Todos_Flutter_2';
  static const String _issuer = 'https://1136-84-114-222-27.ngrok.io';
  final List<String> _scopes = <String>[
    'openid',
    'profile',
    'email',
    'offline_access',
    'Todos'
  ];
  String logoutUrl = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: storage.read(key: "accessToken"),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.hasData) {
                  return ElevatedButton(
                    child: const Text("Logout"),
                    onPressed: () async {
                      logout();
                      setState(() {
                      });
                    },
                  );
                }
                return ElevatedButton(
                  child: const Text("Login"),
                  onPressed: () async {
                    var tokenInfo = await authenticate(
                        Uri.parse(_issuer), _clientId, _scopes);
                    print(tokenInfo.accessToken);
                    setState(() {
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<TokenResponse> authenticate(
      Uri uri, String clientId, List<String> scopes) async {
    // create the client
    var issuer = await Issuer.discover(uri);
    var client = Client(issuer, clientId);

    // create a function to open a browser with an url
    urlLauncher(String url) async {
      if (await canLaunch(url)) {
        await launch(url, forceWebView: true, enableJavaScript: true);
      } else {
        throw 'Could not launch $url';
      }
    }

    // create an auth enticator
    var authenticator = Authenticator(
      client,
      scopes: scopes,
      urlLancher: urlLauncher,
      port: 3000,
    );

    // starts the authentication
    var c = await authenticator.authorize();
    // close the webview when finished
    closeWebView();

    var res = await c.getTokenResponse();
    print(res.accessToken);
    await updateTokens(
        res.accessToken, res.refreshToken, res.expiresAt.toString(), c.generateLogoutUrl().toString());
    return res;
  }

  Future<void> logout() async {
    var logoutUrl = await storage.read(key: "refreshUrl");
    if (await canLaunch(logoutUrl!)) {
      await launch(logoutUrl, forceWebView: true);
    } else {
      throw 'Could not launch $logoutUrl';
    }
    await resetTokens();
    await Future.delayed(const Duration(seconds: 2));
    closeWebView();
  }

  Future updateTokens(
      String? accessToken, String? refreshToken, String? expiration, String? refreshUrl) async {
    await storage.write(key: "accessToken", value: accessToken);
    await storage.write(key: "refreshToken", value: refreshToken);
    await storage.write(key: "accessTokenExpiration", value: expiration);
    await storage.write(key: "refreshUrl", value: refreshUrl);
  }

  Future<void> resetTokens() async {
    await storage.write(key: "accessToken", value: null);
    await storage.write(key: "refreshToken", value: null);
    await storage.write(key: "accessTokenExpiration", value: null);
    await storage.write(key: "refreshUrl", value: null);
  }
}
