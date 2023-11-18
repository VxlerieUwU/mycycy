import 'package:html/parser.dart';
import 'package:requests/requests.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class LoginService {
  static Future<String> login(name, password) async {
      var html_login = await Requests.get(
          "https://services-web.cyu.fr/calendar/LdapLogin");
      html_login.raiseForStatus();
      var document = parse(html_login.body).documentElement!;
      String? verif_token = document.queryXPath('//input[@name="__RequestVerificationToken"]').nodes.first.attributes["value"]; // veriftoken grab
      assert(verif_token.runtimeType == String); // must be a string

      var login_res = await Requests.post("https://services-web.cyu.fr/calendar/LdapLogin/Logon",
          body: {
            'Name': name,
            'Password': password,
            '__RequestVerificationToken': verif_token,
          },
          bodyEncoding: RequestBodyEncoding.FormURLEncoded);
      assert(login_res.statusCode == 302);
      //  password error path

      //assert(login_res.statusCode != 302);  // incorrect password

      Uri login_uri = Uri.parse(login_res.headers["location"]!);
      return login_uri.queryParameters["FederationIds"]!;
  }
}